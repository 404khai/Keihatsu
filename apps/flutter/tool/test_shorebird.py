import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from argparse import Namespace

spec = importlib.util.spec_from_file_location('ota', Path(__file__).with_name('shorebird.py'))
ota = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ota)


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.app = Path(self.temp.name)
        self.app_patch = patch.object(ota, 'APP', self.app)
        self.app_patch.start()
        self.addCleanup(self.app_patch.stop)
        self.addCleanup(self.temp.cleanup)
        (self.app / 'pubspec.yaml').write_text('version: 0.1.0+7\nflutter:\n  assets:\n    - shorebird.yaml\n')
        (self.app / 'shorebird.yaml').write_text(
            'app_id: 12345678-1234-4234-8234-123456789abc\nauto_update: true\n')

    def args(self, **changes):
        values = dict(operation='release', platform='android', artifact='apk',
                      arch='universal', publish=False, no_codesign=False,
                      export_options=None)
        values.update(changes)
        return Namespace(**values)

    @patch.object(ota, 'cli', return_value='shorebird')
    def test_validation_and_android_arch_flags(self, _cli):
        data = dict(flutter_version='3.44.0', api_base_url='https://api.example.com')
        command = ota.build_command(self.args(arch='arm64'), data, '0.1.0+7')
        self.assertIn('--dry-run', command)
        self.assertLess(command.index('--target-platform'), command.index('--'))
        self.assertIn('android-arm64', command)
        self.assertEqual(command[command.index('--build-number') + 1], '7')

    @patch.object(ota, 'cli', return_value='shorebird')
    def test_patch_targets_only_exact_baseline_and_staging(self, _cli):
        data = dict(flutter_version='3.44.0', api_base_url='https://api.example.com')
        command = ota.build_command(self.args(operation='patch'), data, '0.1.0+7')
        self.assertEqual(command[command.index('--release-version') + 1], '0.1.0+7')
        self.assertEqual(command[command.index('--track') + 1], 'staging')
        self.assertNotIn('--flutter-version', command)  # Engine comes from baseline.
        self.assertNotIn('--allow-native-diffs', command)
        self.assertNotIn('--allow-asset-diffs', command)

    def test_init_prerequisites_and_background_mode(self):
        self.assertEqual(ota.app_id(), '12345678-1234-4234-8234-123456789abc')
        (self.app / 'shorebird.yaml').write_text('app_id: placeholder\nauto_update: false\n')
        with self.assertRaises(ValueError):
            ota.app_id()
        (self.app / 'shorebird.yaml').unlink()
        with self.assertRaisesRegex(ValueError, 'No Shorebird project'):
            ota.app_id()

    def test_settings_reject_credentials_or_insecure_api(self):
        for url in ['http://api.example.com', 'https://user:secret@api.example.com',
                    'https://api.example.com?token=secret']:
            (self.app / 'shorebird-release.json').write_text(json.dumps(
                dict(flutter_version='3.44.0', api_base_url=url)))
            with self.assertRaises(ValueError):
                ota.settings()

    def test_path_package_is_not_confused_with_the_hosted_path_dependency(self):
        (self.app / 'pubspec.yaml').write_text('dependencies:\n  path: ^1.9.0\n')
        ota.dependencies()
        (self.app / 'pubspec.yaml').write_text(
            'dependencies:\n  path: ^1.9.0\n  local:\n    path: missing-package\n')
        with self.assertRaisesRegex(ValueError, 'local path dependency is missing'):
            ota.dependencies()

    def test_fingerprint_detects_native_and_new_asset_changes_but_allows_dart(self):
        import subprocess
        subprocess.run(['git', 'init', '-q', str(self.app)], check=True)
        (self.app / 'android/app/src/main').mkdir(parents=True)
        native = self.app / 'android/app/src/main/AndroidManifest.xml'
        native.write_text('<manifest/>')
        (self.app / 'lib').mkdir()
        dart = self.app / 'lib/main.dart'
        dart.write_text('void main() {}')
        subprocess.run(['git', '-C', str(self.app), 'add', '.'], check=True)
        with patch.object(ota, 'REPO', self.app):
            original = ota.fingerprint('android')
            dart.write_text('void main() { print(1); }')
            self.assertEqual(original, ota.fingerprint('android'))
            native.write_text('<manifest><uses-permission/></manifest>')
            self.assertNotEqual(original, ota.fingerprint('android'))
            native.write_text('<manifest/>')
            (self.app / 'images').mkdir()
            (self.app / 'images/new.webp').write_bytes(b'new asset')
            self.assertNotEqual(original, ota.fingerprint('android'))

    def test_patch_rejects_latest_or_missing_baseline_before_build(self):
        (self.app / 'shorebird-release.json').write_text(json.dumps(
            dict(flutter_version='3.44.0', api_base_url='https://api.example.com')))
        for argv, message in [
            (['ota', 'patch', 'android', '--release-version', 'latest'], 'Patches require --release-version'),
            (['ota', 'patch', 'android', '--release-version', '0.1.0+7'], 'Patches require --baseline')]:
            with patch('sys.argv', argv), self.assertRaisesRegex(ValueError, message):
                ota.main()

    def test_unpublished_receipt_cannot_be_used_to_patch(self):
        (self.app / 'shorebird-release.json').write_text(json.dumps(
            dict(flutter_version='3.44.0', api_base_url='https://api.example.com')))
        receipt = self.app / 'baseline.json'
        receipt.write_text(json.dumps(dict(uploaded=False)))
        with patch('sys.argv', ['ota', 'patch', 'android', '--release-version', '0.1.0+7',
                                '--baseline', str(receipt)]):
            with self.assertRaisesRegex(ValueError, 'Baseline receipt does not match'):
                ota.main()

    def test_publish_requires_signed_executed_build(self):
        for flag in ['--no-codesign', '--plan']:
            with patch('sys.argv', ['ota', 'release', 'ios', '--publish', flag]):
                with self.assertRaisesRegex(ValueError, '--publish cannot'):
                    ota.main()

    @patch.object(ota.subprocess, 'run')
    def test_signing_identity_is_pinned_without_password_in_arguments(self, command):
        import hashlib
        store = self.app / 'android/app/upload-keystore.jks'
        store.parent.mkdir(parents=True)
        store.write_bytes(b'fixture')
        (self.app / 'android/key.properties').write_text(
            'storeFile=upload-keystore.jks\nstorePassword=fixture-password\n'
            'keyPassword=fixture-password\nkeyAlias=fixture-alias\n')
        (self.app / 'android/app/google-services.json').write_text('{}')
        (self.app / 'shorebird-release.json').write_text(json.dumps(
            dict(flutter_version='3.44.0', api_base_url='https://api.example.com',
                 android_signing_sha256=hashlib.sha256(b'certificate').hexdigest())))
        command.return_value.returncode = 0
        command.return_value.stdout = b'certificate'
        ota.signing()
        self.assertNotIn('fixture-password', command.call_args.args[0])
        self.assertIn('-storepass:env', command.call_args.args[0])
        command.return_value.stdout = b'wrong certificate'
        with self.assertRaisesRegex(ValueError, 'differs from distributed build 6'):
            ota.signing()


if __name__ == '__main__':
    unittest.main()

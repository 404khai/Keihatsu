#!/usr/bin/env python3
"""Keihatsu's local Shorebird workflow. Builds validate without upload by default."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from urllib.parse import urlsplit
import uuid

APP = Path(__file__).resolve().parents[1]
REPO = APP.parents[1]
VERSION = re.compile(r"\d+\.\d+\.\d+\+\d+")


def fail(message):
    raise ValueError(message)


def run(command, **kwargs):
    return subprocess.run(command, cwd=APP, check=True, **kwargs)


def cli():
    executable = shutil.which("shorebird")
    local = Path.home() / ".shorebird/bin/shorebird"
    if not executable and local.is_file():
        executable = str(local)
    if not executable:
        fail("Install Shorebird first: https://docs.shorebird.dev/quick-start/")
    return executable


def version():
    match = re.search(r"^version:\s*(\S+)", (APP / "pubspec.yaml").read_text(), re.M)
    if not match or not VERSION.fullmatch(match[1]):
        fail("pubspec.yaml must have an exact version including build number (x.y.z+n).")
    return match[1]


def settings():
    data = json.loads((APP / "shorebird-release.json").read_text())
    if not re.fullmatch(r"\d+\.\d+\.\d+", data["flutter_version"]):
        fail("Pin an exact Flutter version in shorebird-release.json.")
    url = urlsplit(data["api_base_url"])
    if (url.scheme != "https" or not url.hostname or url.username or url.password
            or url.query or url.fragment):
        fail("api_base_url must be an HTTPS URL without credentials/query/fragment.")
    return data


def app_id():
    path = APP / "shorebird.yaml"
    if not path.is_file():
        fail("No Shorebird project configured. Log in, then run tool/shorebird.py init.")
    text = path.read_text()
    match = re.search(r"^app_id:\s*([\w-]+)\s*$", text, re.M)
    if not match:
        fail("shorebird.yaml needs the real app_id from Shorebird, not a placeholder.")
    uuid.UUID(match[1])
    if not re.search(r"^auto_update:\s*true\s*$", text, re.M):
        fail("Use auto_update: true for nonblocking background downloads.")
    if not re.search(r"^\s+- shorebird\.yaml\s*$", (APP / "pubspec.yaml").read_text(), re.M):
        fail("shorebird.yaml must be bundled under flutter.assets in pubspec.yaml.")
    return match[1]


def signing():
    path = APP / "android/key.properties"
    if not path.is_file():
        fail("Android release signing is missing. Restore the EXISTING key.properties/keystore locally.")
    props = {}
    for line in path.read_text().splitlines():
        if line.strip() and not line.lstrip().startswith(('#', '!')) and '=' in line:
            key, value = line.split('=', 1)
            props[key.strip()] = value.strip()
    if any(not props.get(key) for key in ['storeFile', 'storePassword', 'keyAlias', 'keyPassword']):
        fail("Android key.properties is incomplete (values are never printed).")
    # Gradle file(...) resolves a relative storeFile against android/app.
    store = Path(props['storeFile'])
    if not store.is_absolute():
        store = APP / 'android/app' / store
    if not store.is_file():
        fail("The existing Android signing keystore cannot be found.")
    expected = settings().get('android_signing_sha256', '')
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        fail('Pin the existing public Android certificate SHA-256 in shorebird-release.json.')
    candidates = [Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/keytool',
                  Path('/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool')]
    keytool = next((str(path) for path in candidates if path.is_file()), shutil.which('keytool'))
    if not keytool:
        fail('A JDK with keytool is required to verify the existing signing identity.')
    signing_env = os.environ.copy()
    signing_env['KEIHATSU_OTA_STORE_PASSWORD'] = props['storePassword']
    result = subprocess.run([keytool, '-exportcert', '-keystore', str(store),
                             '-alias', props['keyAlias'], '-storepass:env', 'KEIHATSU_OTA_STORE_PASSWORD'],
                            env=signing_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        fail('Could not verify the local signing certificate; check signing configuration privately.')
    if hashlib.sha256(result.stdout).hexdigest() != expected:
        fail('Signing certificate differs from distributed build 6. Restore its original signing key.')
    if not (APP / "android/app/google-services.json").is_file():
        fail("Restore Android Firebase configuration locally (do not commit it).")


def dependencies():
    text = (APP / 'pubspec.yaml').read_text()
    for path in re.findall(r'^ {4,}path: *(.+) *$', text, re.M):
        dependency = APP / path.strip().strip('\"\'')
        if not (dependency / 'pubspec.yaml').is_file():
            fail("A local path dependency is missing. See docs/releases/SHOREBIRD_OTA.md.")


def require_clean_dependency_sources():
    text = (APP / 'pubspec.yaml').read_text()
    for dep in re.findall(r'^ {4,}path: *(.+) *$', text, re.M):
        root = (APP / dep.strip().strip('\"\'')).resolve()
        status = subprocess.run(['git', '-C', str(root), 'status', '--porcelain', '--', '.'],
                                check=True, stdout=subprocess.PIPE).stdout
        if status:
            fail('A path package has uncommitted source/config changes. Review and commit it before publication.')
    for name, dependency in settings().get('path_dependencies', {}).items():
        root = (APP / '../../../' / name).resolve()
        revision = subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip()
        if revision != dependency['revision']:
            fail('A path package revision differs from shorebird-release.json. Review the pins before publication.')


def fingerprint(platform):
    """Conservative native/assets guard. Shorebird additionally checks built diffs."""
    files = run(['git', '-C', str(REPO), 'ls-files', '-z', '--', str(APP.relative_to(REPO))],
                stdout=subprocess.PIPE).stdout.split(b'\0')
    hashes = {}
    for name in ['pubspec.yaml', 'pubspec.lock', 'shorebird.yaml', 'shorebird-release.json']:
        path = APP / name
        hashes[name] = hashlib.sha256(path.read_bytes() if path.is_file() else b'MISSING').hexdigest()
    for raw in files:
        if not raw:
            continue
        relative = Path(os.fsdecode(raw))
        local = relative.relative_to(APP.relative_to(REPO))
        # Include platform build/native files, bundled assets and dependency graph.
        if (local.parts[0] == platform or local.parts[0] == 'images'
                or str(local) in ['pubspec.yaml', 'pubspec.lock', 'shorebird.yaml',
                                  'shorebird-release.json', 'lib/data/chapters.json']
                or (local.parts[0] == 'packages' and local.suffix != '.dart')):
            path = REPO / relative
            content = path.read_bytes() if path.is_file() else b'MISSING'
            hashes[str(local)] = hashlib.sha256(content).hexdigest()
    # Include untracked new native files/assets, but never credentials/build outputs.
    for folder in [APP / platform / 'app/src' if platform == 'android' else APP / 'ios/Runner',
                   APP / 'images']:
        if folder.exists():
            for path in sorted(folder.rglob('*')):
                if path.is_file() and path.name != 'GoogleService-Info.plist':
                    hashes[str(path.relative_to(APP))] = hashlib.sha256(path.read_bytes()).hexdigest()
    # Path packages live outside this checkout. Guard their native/assets/config
    # too, while allowing their Dart-only fixes to be validated by Shorebird.
    for index, dep in enumerate(re.findall(r'^ {4,}path: *(.+) *$', (APP / 'pubspec.yaml').read_text(), re.M)):
        root = (APP / dep.strip().strip('\"\'')).resolve()
        paths = subprocess.run(['git', '-C', str(root), 'ls-files', '--full-name', '-z', '--', '.'],
                               check=True, stdout=subprocess.PIPE).stdout.split(b'\0')
        git_root = Path(subprocess.check_output(['git', '-C', str(root), 'rev-parse', '--show-toplevel'], text=True).strip())
        for raw in paths:
            if not raw:
                continue
            path = git_root / os.fsdecode(raw)
            if path.is_relative_to(root) and path.suffix != '.dart':
                hashes[f'dependency-{index}/{path.relative_to(root)}'] = hashlib.sha256(
                    path.read_bytes() if path.is_file() else b'MISSING').hexdigest()
    return hashes


def build_command(args, data, release_version, baseline=None):
    command = [cli(), args.operation, args.platform]
    if args.operation == 'release':
        command += ['--flutter-version', data['flutter_version']]
        if args.platform == 'android':
            command += ['--artifact', args.artifact, '--target-platform',
                        'android-arm64' if args.arch == 'arm64' else 'android-arm,android-arm64,android-x64']
    else:
        # Never infer the newest release. Shorebird uses this release's engine.
        command += ['--release-version', release_version, '--track', 'staging']
    if not args.publish:
        command.append('--dry-run')
    if args.platform == 'ios':
        if args.no_codesign:
            command.append('--no-codesign')
        elif args.export_options:
            command += ['--export-options-plist', str(Path(args.export_options).resolve())]
    name, number = release_version.split('+')
    command += ['--', '--build-name', name, '--build-number', number,
                '--dart-define=APP_VERSION=' + name,
                '--dart-define=API_BASE_URL=' + data['api_base_url']]
    return command


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['init', 'check', 'release', 'patch'])
    parser.add_argument('platform', nargs='?', choices=['android', 'ios'])
    parser.add_argument('--artifact', choices=['apk', 'aab'], default='apk')
    parser.add_argument('--arch', choices=['universal', 'arm64'], default='universal')
    parser.add_argument('--baseline', type=Path, help='Receipt from a published baseline release')
    parser.add_argument('--release-version', help='Exact baseline x.y.z+n; never latest')
    parser.add_argument('--no-codesign', action='store_true', help='iOS validation only')
    parser.add_argument('--export-options', help='Local iOS ExportOptions.plist')
    parser.add_argument('--plan', action='store_true', help='Print command; no build, upload or signing checks')
    parser.add_argument('--publish', action='store_true', help='Explicitly upload baseline or staging patch')
    args = parser.parse_args()
    if args.operation == 'init':
        if (APP / 'shorebird.yaml').exists():
            fail('Already initialized; refusing to replace an existing Shorebird app ID.')
        run([cli(), 'init', '--display-name', 'Keihatsu Flutter'])
        path = APP / 'shorebird.yaml'
        path.write_text(path.read_text() + '\n# Download on launch; apply on next full restart.\nauto_update: true\n')
        app_id()
        print('Configured the real app ID with background updates. No release published.')
        return
    if not args.platform:
        fail('Select android or ios.')
    if args.publish and (args.plan or args.no_codesign or args.operation == 'check'):
        fail('--publish cannot be combined with --plan, --no-codesign or check.')
    current_version = version()
    data = settings()
    identifier = app_id()
    dependencies()
    if args.platform == 'android' and int(current_version.split('+')[1]) <= 6:
        fail('The non-Shorebird build 6 needs a NEW baseline with build number > 6.')
    if args.operation == 'check':
        if args.platform == 'android':
            signing()
        print(f'{args.platform}: project, version, dependencies and local configuration checked.')
        print('Account, engine/build compatibility and runtime OTA still require Shorebird validation.')
        return
    baseline = None
    if args.operation == 'patch':
        if not args.release_version or not VERSION.fullmatch(args.release_version):
            fail('Patches require --release-version x.y.z+n, including the baseline build number.')
        if not args.baseline:
            fail('Patches require --baseline receipt.json from a published Shorebird release.')
        baseline = json.loads(args.baseline.read_text())
        expected = {'uploaded': True, 'platform': args.platform, 'app_id': identifier,
                    'release_version': args.release_version, 'settings': data}
        if any(baseline.get(key) != value for key, value in expected.items()):
            fail('Baseline receipt does not match the published app/platform/version/build settings.')
        if current_version != args.release_version:
            fail('Keep pubspec.yaml at the exact baseline version when creating its patch.')
        if baseline['fingerprint'] != fingerprint(args.platform):
            fail('Native files, assets, dependencies or build configuration changed: create a new baseline.')
    elif args.release_version:
        fail('Release version comes from pubspec.yaml. --release-version is for patch only.')
    command = build_command(args, data, current_version, baseline)
    print(shlex.join(command), flush=True)
    if args.plan:
        return
    if args.platform == 'android':
        signing()
    if args.platform == 'ios' and sys.platform != 'darwin':
        fail('iOS requires macOS, Xcode and a physical-device release build.')
    if args.publish:
        dirty = run(['git', 'status', '--porcelain'], stdout=subprocess.PIPE).stdout
        if dirty:
            fail('Commit/review the checkout before publishing a release or staging patch.')
        require_clean_dependency_sources()
    before = fingerprint(args.platform)
    run(command)
    if before != fingerprint(args.platform):
        fail('Build changed native/assets/dependency inputs; inspect changes and revalidate.')
    if args.operation == 'release':
        receipt = {'uploaded': args.publish, 'app_id': identifier, 'platform': args.platform,
                   'release_version': current_version, 'settings': data,
                   'artifact': args.artifact if args.platform == 'android' else 'ipa',
                   'arch': args.arch if args.platform == 'android' else 'arm64',
                   'commit': run(['git', 'rev-parse', 'HEAD'], stdout=subprocess.PIPE, text=True).stdout.strip(),
                   'fingerprint': before}
        status = 'published' if args.publish else 'validated'
        path = APP / 'build/shorebird' / f'keihatsu-{args.platform}-{current_version}-{status}.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(receipt, indent=2) + '\n')
        print(f'Baseline receipt: {path}')
    print('Uploaded to Shorebird only.' if args.publish else 'Validation completed; nothing uploaded.')
    print('No store submission, Firebase distribution or tester notification was performed.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        # Never print subprocess output, key.properties or environment values.
        print(f'ERROR: {error}', file=sys.stderr)
        sys.exit(1)

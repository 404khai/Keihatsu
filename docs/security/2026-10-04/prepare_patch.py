from pathlib import Path
import difflib
root = Path(__file__).resolve().parents[3]
out = root / 'docs/security/2026-10-04'
patch = ''
for name in ['apps/flutter/lib/services/file_service.dart', 'apps/ios/Keihatsu/Core/Storage/ChapterArchiveStore.swift']:
    original = (root/name).read_text()
    updated = original
    if name.endswith('.dart'):
        updated = updated.replace("      final fullPath = p.join(baseDir.path, subPath);", """      // API-provided identifiers must never become parent/absolute paths.
      final components = subPath.replaceAll('\\\\', '/').split('/');
      if (p.isAbsolute(subPath) ||
          components.any((part) => part == '.' || part == '..')) {
        throw ArgumentError.value(subPath, 'subPath', 'Unsafe download path');
      }
      final fullPath = p.normalize(p.join(baseDir.path, subPath));
      if (!p.isWithin(p.normalize(baseDir.path), fullPath)) {
        throw ArgumentError.value(subPath, 'subPath', 'Path escapes storage');
      }""")
        old = "    return value.replaceAll(RegExp(r'[<>:\"/\\\\|?*]'), '_').trim();"
        new = """    final component = value.replaceAll(RegExp(r'[<>:"/\\\\|?*]'), '_').trim();
    if (component.isEmpty || component == '.' || component == '..') {
      return '_';
    }
    return component;"""
        assert old in updated
        updated = updated.replace(old, new)
        (Path('/tmp')/'keihatsu-hardened-file-service.dart').write_text(updated)
    else:
        old = '        return value.components(separatedBy: forbidden).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)'
        new = '''        let component = value.components(separatedBy: forbidden).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !component.isEmpty, component != ".", component != ".." else { return "_" }
        return component'''
        assert old in updated
        updated = updated.replace(old,new)
        (Path('/tmp')/'KeihatsuHardenedChapterArchiveStore.swift').write_text(updated)
    assert original != updated
    patch += ''.join(difflib.unified_diff(original.splitlines(True),updated.splitlines(True),fromfile='a/'+name,tofile='b/'+name))
(out/'path-containment.patch').write_text(patch)
# Produce a hardened variant of each probe in /tmp; original evidence probes remain unchanged.
dart = (out/'flutter_security_test.dart').read_text().replace("package:keihatsu/services/file_service.dart", '/tmp/keihatsu-hardened-file-service.dart')
dart = dart.replace("expect(await victim.exists(), isFalse, reason: 'Confirms out-of-root recursive deletion');", "expect(await victim.exists(), isTrue, reason: 'Outside sentinel must survive');")
dart = dart.replace("expect(await File(p.join(sandbox.path, 'victim.png')).readAsString(), 'security-test-sentinel');", "expect(await File(p.join(sandbox.path, 'victim.png')).exists(), isFalse);")
Path('/tmp/keihatsu_hardened_test.dart').write_text(dart)
swift = (out/'NativeSecurityProbe.swift').read_text().replace('precondition(target.standardizedFileURL == victim.standardizedFileURL)', 'precondition(target.standardizedFileURL != victim.standardizedFileURL)').replace('precondition(!fm.fileExists(atPath: victim.path))','precondition(fm.fileExists(atPath: victim.path))').replace('SEC-04 CONFIRMED: actual ChapterArchiveStore deleted a sentinel outside Documents/downloads','SEC-04 PATCH PASS: outside sentinel survives')
Path('/tmp/KeihatsuHardenedProbe.swift').write_text(swift)

"""Query OSV for hosted Pub versions and all checked-in SwiftPM revisions."""
import json, re, urllib.request
from pathlib import Path
root = Path(__file__).resolve().parents[3]
queries, labels = [], []
lock = (root / 'apps/flutter/pubspec.lock').read_text()
for name, block in re.findall(r'^  (\w+):\n(.*?)(?=^  \w+:|^sdks:|\Z)', lock, re.M | re.S):
    if 'source: hosted' in block:
        version = re.search(r'    version: "([^"]+)"', block)[1]
        queries.append({'package': {'name': name, 'ecosystem': 'Pub'}, 'version': version})
        labels.append(f'Pub:{name}@{version}')
seen = set()
for path in (root / 'apps').rglob('Package.resolved'):
    if any(x in path.parts for x in ('build', '.symlinks', 'Pods', '.dart_tool')): continue
    for pin in json.loads(path.read_text()).get('pins', []):
        revision = pin.get('state', {}).get('revision')
        if revision and revision not in seen:
            seen.add(revision)
            queries.append({'commit': revision})
            labels.append(f"SwiftPM:{pin['identity']}@{revision}")
request = urllib.request.Request('https://api.osv.dev/v1/querybatch', data=json.dumps({'queries': queries}).encode(), headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(request, timeout=60) as response:
    results = json.load(response)['results']
output = {'query_count': len(queries), 'results': [{'dependency': label, **result} for label, result in zip(labels, results)]}
Path(__file__).with_name('dependency-results.json').write_text(json.dumps(output, indent=2) + '\n')
print('Queries:', len(queries))
for result in output['results']:
    if result.get('vulns') or result.get('next_page_token'): print(json.dumps(result))
print('Packages with matches:', sum(bool(r.get('vulns')) for r in results))

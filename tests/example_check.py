import json
from pathlib import Path
example = json.loads((Path(__file__).resolve().parents[1] / 'examples/test_build.json').read_text())
blocks = example['blocks']
assert len(blocks) == 4
assert all(b['type'] == 'wood' and b['rotation'] == {'x': 0, 'y': 0, 'z': 0} for b in blocks)
assert all(b['size'] == {'x': 2, 'y': 1, 'z': 2} for b in blocks)
assert all(b['position']['y'] == 0 for b in blocks)
assert {(b['position']['x'], b['position']['z']) for b in blocks} == {(0, 0), (2, 0), (0, 2), (2, 2)}
print('PASS example is a non-overlapping 2x2 raft')

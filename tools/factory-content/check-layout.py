"""Check authored D1 spatial budgets; this is not a production gameplay test."""
import json
import math
from collections import Counter, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LAYOUT = ROOT / 'client/scripts/checks/fixtures/factory_discovery_layout.json'
SIZES = {'collector': (2, 2), 'reactor': (3, 3), 'storage': (2, 2),
         'power_source': (3, 3), 'power_junction': (1, 1)}
BUDGET = {'collector': 8, 'reactor': 16, 'storage': 8, 'belt': 256,
          'power_source': 2, 'power_junction': 12}
checks = 0
failures = []


def expect(condition, message):
    global checks
    checks += 1
    if not condition:
        failures.append(message)


def center(entity):
    w, d = SIZES[entity['type']]
    return entity['x'] + w / 2, entity['z'] + d / 2


def touches_cell(a, b, cell):
    low, high = 0.0, 1.0
    for axis in range(2):
        delta = b[axis] - a[axis]
        if delta == 0:
            if not cell[axis] <= a[axis] <= cell[axis] + 1:
                return False
        else:
            ends = [(cell[axis] - a[axis]) / delta,
                    (cell[axis] + 1 - a[axis]) / delta]
            low, high = max(low, min(ends)), min(high, max(ends))
            if low > high:
                return False
    return True


def audit():
    data = json.loads(LAYOUT.read_text())
    results = []
    for stage in range(3):
        closed = {(x, z) for index, (left, right) in enumerate(data['walls'])
                  for x in range(left, right) for z in range(-32, 32)
                  if index >= stage or not -2 <= z < 2}
        occupied = {}
        entities = {e['id']: e for e in data['entities'] if e['stage'] <= stage}
        for entity in entities.values():
            w, d = SIZES[entity['type']]
            for x in range(entity['x'], entity['x'] + w):
                for z in range(entity['z'], entity['z'] + d):
                    cell = x, z
                    expect(-32 <= x < 32 and -32 <= z < 32, f'{stage}: out of bounds {cell}')
                    expect(cell not in closed and cell not in occupied, f'{stage}: blocked footprint {cell}')
                    occupied[cell] = entity['id']
            if entity['type'] == 'collector':
                expect([entity['x'], entity['z']] in data['ore_sites'], 'collector not on ore')
        belts = [b for b in data['belts'] if b['stage'] <= stage]
        belt_cells = set()
        for belt in belts:
            cell = belt['x'], belt['z']
            expect(cell not in occupied and cell not in closed and cell not in belt_cells,
                   f'{stage}: belt overlaps footprint or closed area: {cell}')
            belt_cells.add(cell)
        # Walkable belts are not treated as blocking buildings.
        start = tuple(data['actor'])
        visited, pending = {start}, deque([start])
        while pending:
            x, z = pending.popleft()
            for cell in [(x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)]:
                if (-32 <= cell[0] < 32 and -32 <= cell[1] < 32 and
                        cell not in visited and cell not in occupied and cell not in closed):
                    visited.add(cell)
                    pending.append(cell)
        for target in data['walk_targets']:
            required = 0 if target[0] < 4 else (1 if target[0] < 20 else 2)
            expect((tuple(target) in visited) == (stage >= required), f'{stage}: reachability {target}')
        links = 0
        for kind, limit in [('links', 12), ('feeds', 6)]:
            for first, second in data[kind]:
                if first not in entities or second not in entities:
                    continue
                a, b = center(entities[first]), center(entities[second])
                expect(math.dist(a, b) <= limit, f'{stage}: {kind} too long {first}/{second}')
                expect(not any(touches_cell(a, b, cell) for cell in closed),
                       f'{stage}: {kind} crosses mineral crust {first}/{second}')
                links += 1
        count = Counter(e['type'] for e in entities.values())
        count['belt'] = len(belts)
        for kind, amount in count.items():
            expect(amount <= BUDGET[kind], f'{stage}: supply exceeded {kind}')
        results.append(dict(open_gates=stage,counts=dict(count),connections=links,
                            reachable_cells=len(visited)))
    output = ROOT / 'tools/runtime-intake/check-runs/factory-discovery-v1/d1-layout'
    output.mkdir(parents=True, exist_ok=True)
    result = dict(scope='D1 spatial fixture only; no power simulation or player movement test',
                  assertions=checks,failures=failures,stages=results)
    (output / 'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(result,ensure_ascii=False))
    return 1 if failures else 0


if __name__ == '__main__':
    raise SystemExit(audit())

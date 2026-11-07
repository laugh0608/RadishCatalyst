#!/usr/bin/env python3
"""Audit the D2 layout, material budget and fixed-step power comparison."""
import argparse
from collections import deque
import json
from math import dist, floor
from pathlib import Path
import runpy

D1 = runpy.run_path(str(Path(__file__).with_name("audit-frontier-layout.py")))
HZ = 20
CORE_KW, GEN_KW = 360, 120
BURN = 60 * HZ
PERIOD = 120 * HZ
CAPACITY_J = 3_600_000
CHARGE_KW, DISCHARGE_KW = 60, 60
LOW_J, HIGH_J = 1_100_000, 2_000_000
WINDOW = 10 * HZ
HANDOFF_TICKS = HZ + 1
DEVICE_KW = {"I": 20, "Q": 20, "Kh": 20, "C": 20, "Ci": 20,
             "F": 60, "F2": 60, "Fd": 60, "R": 40, "E": 40, "A": 40}
PREPARE = {"I", "Q", "Kh", "C", "Ci"}
ALL = set(DEVICE_KW)
REGULAR = ALL - {"Fd", "A"}
COSTS = {
    "core_iii": {"construction_pack": 4, "metal_plate": 4, "porous_carrier": 2, "industrial_cell": 2},
    "grid_buffer": {"construction_pack": 2, "metal_plate": 2, "industrial_cell": 1},
    "timed_dispatch": {"metal_plate": 2, "catalyst": 1},
    "storage_feedback": {"metal_plate": 2, "porous_carrier": 1, "industrial_cell": 1},
    "load_management": {"construction_pack": 1, "metal_plate": 2, "porous_carrier": 2},
    "one_buffer": {"construction_pack": 2, "industrial_cell": 1},
    "one_dispatcher": {"construction_pack": 1},
    "fuel_overflow": {"construction_pack": 3},
}
RECIPES = {
    "construction_pack": {"metal_plate": 2, "porous_carrier": 1},
    "industrial_cell": {"metal_plate": 1, "carbon_powder": 2, "catalyst": 1},
    "metal_plate": {"iron_ore": 2},
    "porous_carrier": {"crystal": 3},
    "carbon_powder": {"carbon_ore": 1},
    "catalyst": {"crystal": 2},
}


def joules(kw):
    return kw * 1000 // HZ


def layout():
    base = D1["audit"]()
    entities = base["entities"]
    belts = {cell for route in base["routes"] if route["points"] for cell in D1["EXPAND"](route["points"])}
    fuel_route = next(route for route in base["routes"] if D1["endpoint_name"](route["target"]) == "G")
    fuel_path = D1["EXPAND"](fuel_route["points"])
    assert fuel_path[-2:] == [(-1, 21), (0, 21)]
    assert fuel_route["target"] == ("G", (0, 1), (-1, 0))
    buffer = (1, 22, 2, 2)
    splitter = (1, 25, 1, 1)
    warehouse = (2, 26, 2, 2)
    dispatcher = (*fuel_path[-1], 1, 1)
    assert fuel_path[:2] == [(1, 25), (2, 25)]
    overflow = [(1, 26), (1, 27)]
    assert not belts.intersection(overflow)
    belts.difference_update({splitter[:2], dispatcher[:2]})
    belts.update(overflow)
    occupied = set(belts)
    open_flags = D1["MODES"][-1]
    devices = [*entities.values(), buffer, splitter, warehouse, dispatcher]
    for x, z, w, d in devices:
        for cell in ((i, j) for i in range(x, x + w) for j in range(z, z + d)):
            assert D1["open_cell"](cell, open_flags) and cell not in occupied, cell
            occupied.add(cell)
    assert dist((2, 23), (2, 21)) <= 6 and D1["line_open"]((2, 23), (2, 21), open_flags)
    assert dist((2, 21), (-8, 25)) <= 12 and D1["line_open"]((2, 21), (-8, 25), open_flags)
    assert 5 * 12 < 200  # Even if all scheduled R12 output goes to the overflow terminal.

    def walkable(point):
        x, z = (v / 2 for v in point)
        return (all(D1["open_cell"]((floor(x + dx), floor(z + dz)), open_flags)
                    for dx in (-.3, .3) for dz in (-.3, .3))
                and all(D1["RECT_DISTANCE"]((x, z), rect) > .3 for rect in devices))

    start = (-16, 40)
    destinations = {(5, 49), (-1, 43), (5, 57), (3, 53)}
    assert walkable(start) and all(walkable(point) for point in destinations)
    seen, queue = {start}, deque([start])
    while queue and not destinations <= seen:
        x, z = queue.popleft()
        for cell in ((x - 1, z), (x + 1, z), (x, z - 1), (x, z + 1)):
            if cell not in seen and walkable(cell):
                seen.add(cell)
                queue.append(cell)
    assert destinations <= seen
    return {"base": base["layout"], "base_assertions": base["checks"], "buffer": buffer,
            "buffer_connection": "G", "dispatcher": dispatcher, "dispatcher_dir": "east",
            "overflow_splitter": splitter, "overflow_splitter_dir": "east",
            "overflow_belts": overflow, "overflow_warehouse": warehouse,
            "belt_count": len(belts), "junction_count": 10}


def materials():
    totals = {}
    for cost in COSTS.values():
        for item, amount in cost.items():
            totals[item] = totals.get(item, 0) + amount
    expanded = totals.copy()
    for product, ingredients in RECIPES.items():
        amount = expanded.pop(product, 0)
        for item, per_batch in ingredients.items():
            need = (amount + 1) // 2 if product == "carbon_powder" else amount
            expanded[item] = expanded.get(item, 0) + need * per_batch
    assert expanded == {"iron_ore": 86, "crystal": 66, "carbon_ore": 5}
    return {"costs": COSTS, "totals": totals, "direct_route_ore": expanded}


def phase_load(phase, shifted_assembly):
    if phase < 60 * HZ:
        active = PREPARE
    elif phase < 85 * HZ:
        active = ALL - {"A"} if shifted_assembly else ALL
    else:
        active = REGULAR | {"A"} if shifted_assembly and phase < 110 * HZ else REGULAR
    return sum(DEVICE_KW[device] for device in active), active


def simulate(*, storage=False, timed=False, feedback=False, delay=0,
             fuel_outage=False, shifted_assembly=False, periods=12, final_tick=None, resumed=None):
    state = dict(stored_j=0, burn_ticks=0, tick=0, permit=True, delivered=False,
                 activations=0, charge_j=0, discharge_j=0, loss_j=0, released_j=0,
                 core_j=0, demand_j=0, used_j=0, spill_j=0, deficit_j=0, deficit_ticks=0,
                 mix_work_ticks=0.0, assembly_work_ticks=0.0)
    if resumed is not None:
        state = resumed.copy()
    for tick in range(state["tick"], final_tick if final_tick is not None else PERIOD * periods):
        phase = tick % PERIOD
        if phase == 0:
            state["delivered"] = False
        if feedback:
            if state["stored_j"] <= LOW_J:
                state["permit"] = True
            elif state["stored_j"] >= HIGH_J:
                state["permit"] = False
        demand_kw, active = phase_load(phase, shifted_assembly)
        demand = joules(demand_kw)
        if state["burn_ticks"] == 0 and not fuel_outage:
            ready = HANDOFF_TICKS + delay <= phase < WINDOW and not state["delivered"]
            if not timed or (ready and state["permit"]):
                state["activations"] += 1
                state["burn_ticks"] = BURN
                state["delivered"] = True
        released = joules(GEN_KW) if state["burn_ticks"] else 0
        state["burn_ticks"] -= int(state["burn_ticks"] > 0)
        direct = min(demand, released)
        core = min(demand - direct, joules(CORE_KW))
        deficit = demand - direct - core
        surplus = released - direct
        before = state["stored_j"]
        # 90% charging efficiency. Admit groups of ten joules to keep the
        # retained charge and loss exact at the capacity boundary.
        charge = min(surplus, joules(CHARGE_KW), (CAPACITY_J - before) // 9 * 10) // 10 * 10 if storage else 0
        discharge = min(deficit, joules(DISCHARGE_KW), before) if storage else 0
        loss = charge // 10
        assert not (charge and discharge)
        state["stored_j"] = before + charge - loss - discharge
        used = direct + core + discharge
        spill = surplus - charge
        unmet = deficit - discharge
        assert core + released + before == used + spill + loss + state["stored_j"]
        assert 0 <= state["stored_j"] <= CAPACITY_J
        for key, value in {"charge_j": charge, "discharge_j": discharge, "loss_j": loss,
                           "released_j": released, "core_j": core, "demand_j": demand,
                           "used_j": used, "spill_j": spill, "deficit_j": unmet,
                           "deficit_ticks": int(unmet > 0)}.items():
            state[key] += value
        state["mix_work_ticks"] += used / demand if "F" in active else 0.0
        state["assembly_work_ticks"] += used / demand if "A" in active else 0.0
        state["tick"] = tick + 1
    assert state["activations"] * 7_200_000 == state["released_j"] + joules(GEN_KW) * state["burn_ticks"]
    assert state["core_j"] + state["released_j"] == state["used_j"] + state["spill_j"] + state["loss_j"] + state["stored_j"]
    assert state["demand_j"] == state["used_j"] + state["deficit_j"]
    return state


def report(checkpoint):
    assert [phase_load(t * HZ, False)[0] for t in (0, 60, 85)] == [100, 400, 300]
    normal = simulate()
    buffered = simulate(storage=True)
    scheduled = simulate(storage=True, timed=True)
    controlled = simulate(storage=True, timed=True, feedback=True)
    no_buffer = simulate(timed=True)
    late = simulate(storage=True, timed=True, feedback=True, delay=5 * HZ)
    missed = simulate(storage=True, timed=True, delay=10 * HZ, periods=1)
    outage = simulate(storage=True, fuel_outage=True, periods=1)
    shifted = simulate(storage=True, fuel_outage=True, shifted_assembly=True, periods=1)
    cold = simulate(storage=True, timed=True, feedback=True, periods=1)
    split = 65 * HZ + 7
    save = simulate(storage=True, timed=True, feedback=True, final_tick=split)
    reloaded = simulate(storage=True, timed=True, feedback=True, resumed=json.loads(json.dumps(save)))
    assert reloaded == controlled
    assert normal["activations"] == buffered["activations"] == 24 and normal["deficit_j"] == buffered["deficit_j"] == 0
    assert scheduled["activations"] == 12 and scheduled["deficit_j"] == controlled["deficit_j"] == late["deficit_j"] == 0
    assert 0 < controlled["activations"] <= scheduled["activations"] and controlled["stored_j"] > 0
    assert normal["mix_work_ticks"] == controlled["mix_work_ticks"]
    assert no_buffer["deficit_j"] > 0 and missed["activations"] == 0 and missed["deficit_j"] > 0
    assert cold["activations"] == 1 and cold["deficit_j"] == 0
    assert shifted["deficit_j"] == 0 and outage["deficit_j"] > 0
    assert shifted["mix_work_ticks"] == 60 * HZ and shifted["assembly_work_ticks"] == 25 * HZ
    halfway = simulate(storage=True, timed=True, feedback=True, periods=6)
    windows = []
    for start, end in (({"activations": 0, "deficit_j": 0, "mix_work_ticks": 0}, halfway), (halfway, controlled)):
        window = {key: end[key] - start[key] for key in ("activations", "deficit_j", "mix_work_ticks")}
        assert window["activations"] <= 9 and window["deficit_j"] == 0 and window["mix_work_ticks"] == 360 * HZ
        windows.append(window)
    data = {
        "layout": layout(), "materials": materials(),
        "schedule": {"period_s": 120, "phases": [[60, 100], [25, 400], [35, 300]], "periods": 12},
        "candidate": {"capacity_kj": CAPACITY_J / 1000, "charge_kw": CHARGE_KW, "discharge_kw": DISCHARGE_KW,
                      "charge_efficiency": .9, "lower_kj": LOW_J / 1000, "upper_kj": HIGH_J / 1000,
                      "window_s": WINDOW / HZ, "handoff_s": HANDOFF_TICKS / HZ},
        "power_comparison": {"continuous": normal, "buffered_continuous": buffered,
                             "timed_buffered": scheduled, "feedback": controlled},
        "sensitivity": {"cold_start": cold, "without_buffer": no_buffer, "five_seconds_late": late,
                        "missed_window": missed, "outage": outage, "shifted_assembly": shifted},
        "feedback_twelve_minute_windows": windows,
        "resumed_at_tick": split,
    }
    if checkpoint:
        buckets = json.loads(checkpoint.read_text())["before"]["state"]["statistics"]["buckets"]
        assert len(buckets) == 600 and all(bucket["ticks"] == HZ for bucket in buckets)
        data["reference_d1_tail"] = {"seconds": len(buckets),
                                    "min_one_second_mean_kw": min(b["requested_kj"] for b in buckets),
                                    "max_one_second_mean_kw": max(b["requested_kj"] for b in buckets),
                                    "spill_kj": sum(b["spill_kj"] for b in buckets)}
    return data


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--d1-checkpoint", type=Path)
    args = parser.parse_args()
    print(json.dumps(report(args.d1_checkpoint), indent=2))

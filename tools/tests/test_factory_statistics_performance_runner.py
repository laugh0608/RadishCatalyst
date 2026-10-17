import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("statistics_performance_runner", REPO / "tools/check-factory-statistics-performance.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class StatisticsSourceTests(unittest.TestCase):
    def setUp(self):
        root = runner.RUNS / "runner-tests"
        root.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=root)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.parent = self.root / "parent"
        self.parent.mkdir()
        self.child = self.root / "child"
        self.patch_runs = patch.object(runner, "RUNS", self.root)
        self.patch_c_runs = patch.object(runner, "C_RUNS", self.root)
        self.patch_runs.start()
        self.patch_c_runs.start()
        self.addCleanup(self.patch_runs.stop)
        self.addCleanup(self.patch_c_runs.stop)
        self.write("complete-read-result.json", {"assertions": 27, "failures": []})
        self.write("completion-read-final.json", {"sequence": 135})
        self.write("runner-result.json", {"exit_code": 0, "errors": [], "parent_unchanged": True})

    def write(self, name, value):
        (self.parent / name).write_text(json.dumps(value), encoding="utf-8")

    def prepared_parent(self):
        self.write("result.json", {"assertions": 20, "failures": [], "mode": "prepare-v5", "preparation_details": {"ready": True}})
        self.write("prepared.json", {"sequence": 1})
        self.write("continuation.json", {"sequence": 1, "time": 45})
        self.write("execution-inputs.json", {"code_sha256": runner.code_hashes()})
        self.write("runner-result.json", {"exit_code": 0, "errors": [], "parent_unchanged": True,
                                          "artifacts": {n: runner.digest(self.parent / n) for n in ("prepared.json", "continuation.json")}})

    def test_completed_c_source_is_copied_without_consumption(self):
        before = runner.file_hashes(self.parent)
        runner.prepare_inputs("prepare-v5", self.child, "parent")
        self.assertEqual(runner.load(self.child / "source.json"), {"sequence": 135})
        (self.child / "source.json").write_text("child-only", encoding="utf-8")
        self.assertEqual(before, runner.file_hashes(self.parent))
        self.assertFalse((self.child / "complete-read-result.json").exists())

    def test_prepare_artifacts_require_matching_source_code_and_hashes(self):
        self.prepared_parent()
        runner.prepare_inputs("verify-v5", self.child, "parent")
        self.assertTrue((self.child / "continuation.json").is_file())
        self.write("prepared.json", {"sequence": 2})
        with self.assertRaisesRegex(ValueError, "artifact changed"):
            runner.prepare_inputs("window-v5", self.root / "other", "parent")
        self.prepared_parent()
        self.write("execution-inputs.json", {"code_sha256": {}})
        with self.assertRaisesRegex(ValueError, "sources changed"):
            runner.prepare_inputs("window-v5", self.root / "other", "parent")

    def test_green_assertions_cannot_mask_runner_failure(self):
        for bad in ({"exit_code": 1, "errors": [], "parent_unchanged": True},
                    {"exit_code": 0, "errors": ["font"], "parent_unchanged": True},
                    {"exit_code": 0, "errors": [], "parent_unchanged": False}):
            self.write("runner-result.json", bad)
            with self.assertRaises(ValueError): runner.prepare_inputs("prepare-v5", self.child, "parent")
            self.assertFalse(self.child.exists())

    def test_lock_symlink_and_existing_batch_rejected(self):
        lock = self.parent / "session.lock"
        lock.mkdir()
        with self.assertRaises(ValueError): runner.prepare_inputs("prepare-v5", self.child, "parent")
        lock.rmdir()
        link = self.parent / "link"
        link.symlink_to(self.parent / "completion-read-final.json")
        with self.assertRaises(ValueError): runner.prepare_inputs("prepare-v5", self.child, "parent")
        link.unlink()
        self.child.mkdir()
        with self.assertRaises(FileExistsError): runner.prepare_inputs("prepare-v5", self.child, "parent")

    def test_consumed_probe_is_not_a_preparation(self):
        self.prepared_parent()
        self.write("result.json", {"assertions": 40, "failures": [], "mode": "verify-v5", "preparation_details": {"ready": True}})
        with self.assertRaises(ValueError): runner.prepare_inputs("window-v5", self.child, "parent")

    def test_paths_and_legacy_sources_stay_isolated(self):
        for name in ("../escape", "a/b", "", ".."):
            with self.assertRaises(ValueError): runner.batch_path(self.root, name)
        with self.assertRaises(ValueError): runner.real_path(REPO / "README.md", runner.INTAKE)
        runner.prepare_inputs("prepare", self.child, str(self.parent / "completion-read-final.json"))
        self.assertTrue((self.child / "source.json").is_file())

    def test_source_race_during_copy_is_rejected(self):
        copy = runner.shutil.copyfile

        def changed_copy(source, target):
            copy(source, target)
            source.write_text("changed source", encoding="utf-8")

        with patch.object(runner.shutil, "copyfile", side_effect=changed_copy):
            with self.assertRaisesRegex(ValueError, "changed"):
                runner.prepare_inputs("prepare-v5", self.child, "parent")

    def test_interruption_and_preparation_cannot_claim_performance(self):
        base = {"assertions": 10, "failures": [], "mode": "interrupt-v5", "interruption_check": True,
                "interrupted": True, "interruption_reason": "focus_lost", "phases": [], "performance_acceptance": False}
        self.assertEqual(runner.outcome_errors("interrupt-v5", base, "sampling"), [])
        self.assertTrue(runner.outcome_errors("interrupt-v5", base, "close"))
        base["performance_acceptance"] = True
        self.assertTrue(runner.outcome_errors("interrupt-v5", base, "sampling"))
        self.assertTrue(runner.outcome_errors("window-v5", {"assertions": 20, "failures": []}, None))


if __name__ == "__main__":
    unittest.main()

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("combination_runner", REPO / "tools/check-factory-combination.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RecoveryCopyTests(unittest.TestCase):
    def setUp(self):
        root = REPO / "tools/runtime-intake/check-runs/factory-conveyor-combination-v1/runner-tests"
        root.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=root)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "parent"
        self.child = self.root / "child"
        self.source.mkdir()
        self.write("write-result.json", {"assertions": 10, "failures": []})
        self.write("runner-result.json", {"exit_code": 0, "errors": [], "parent_unchanged": True})
        self.write("expected.json", {"sequence": 7})
        self.write("factory/world/autosave.json", {"sequence": 8})
        self.write("ids.json", {"g4": 12})
        self.write("source-trace.json", {"witnesses": [4]})

    def write(self, name, data):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    def test_copy_preserves_parent_and_hashes_without_inheriting_success(self):
        parent_hash = runner.digest(self.source / "factory/world/autosave.json")
        runner.prepare("background-read", self.child, self.source)
        origin = runner.load(self.child / "origin.json")
        self.assertEqual(origin["copied_files"]["factory/world/autosave.json"]["sha256"], parent_hash)
        self.assertFalse((self.child / "write-result.json").exists())
        (self.child / "factory/world/autosave.json").write_text("changed", encoding="utf-8")
        self.assertEqual(runner.digest(self.source / "factory/world/autosave.json"), parent_hash)

    def test_complete_read_selects_new_checkpoint(self):
        self.write("read-result.json", {"assertions": 5, "failures": []})
        self.write("completion-expected.json", {"sequence": 25})
        runner.prepare("background-complete-read", self.child, self.source)
        self.assertEqual(runner.load(self.child / "expected.json"), {"sequence": 25})
        self.assertEqual(runner.load(self.source / "expected.json"), {"sequence": 7})

    def test_failed_source_rejected_before_child_creation(self):
        self.write("write-result.json", {"assertions": 10, "failures": ["quota"]})
        with self.assertRaises(ValueError):
            runner.prepare("background-read", self.child, self.source)
        self.assertFalse(self.child.exists())

    def test_live_lock_and_consumed_write_are_rejected(self):
        (self.source / "factory/world/session.lock").mkdir()
        with self.assertRaises(ValueError):
            runner.prepare("background-read", self.child, self.source)
        self.assertFalse(self.child.exists())
        (self.source / "factory/world/session.lock").rmdir()
        self.write("read-result.json", {"assertions": 5, "failures": []})
        with self.assertRaises(ValueError):
            runner.prepare("background-read", self.child, self.source)

    def test_symlink_and_path_escape_are_rejected(self):
        (self.source / "linked.json").symlink_to(self.source / "expected.json")
        with self.assertRaises(ValueError):
            runner.prepare("background-read", self.child, self.source)
        for name in ("../escape", "/absolute", "x/y", "", ".."):
            with self.assertRaises(ValueError):
                runner.batch_path(name)

    def test_existing_child_is_never_overwritten(self):
        self.child.mkdir()
        marker = self.child / "keep.txt"
        marker.write_text("retained", encoding="utf-8")
        with self.assertRaises(FileExistsError):
            runner.prepare("background-read", self.child, self.source)
        self.assertEqual(marker.read_text(encoding="utf-8"), "retained")

    def test_runner_failure_cannot_be_rehabilitated_by_green_assertions(self):
        for result in (
            {"exit_code": 1, "errors": [], "parent_unchanged": True},
            {"exit_code": 0, "errors": ["font error"], "parent_unchanged": True},
            {"exit_code": 0, "errors": [], "parent_unchanged": False},
        ):
            self.write("runner-result.json", result)
            with self.assertRaises(ValueError):
                runner.prepare("background-read", self.child, self.source)
            self.assertFalse(self.child.exists())

    def test_missing_replay_context_rejected_before_child_creation(self):
        self.write("state-result.json", {"assertions": 10, "failures": []})
        self.write("state-partial.json", {})
        self.write("state-expected.json", {})
        with self.assertRaises(ValueError):
            runner.prepare("process-read", self.child, self.source)
        self.assertFalse(self.child.exists())


if __name__ == "__main__":
    unittest.main()

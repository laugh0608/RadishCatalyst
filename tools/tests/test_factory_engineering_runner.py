"""Boundary checks for immutable engineering evidence; no Godot process required."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("engineering_runner", ROOT / "tools/check-factory-engineering.py")
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class EngineeringRunnerTests(unittest.TestCase):
    def setUp(self):
        scratch = ROOT / "tools/runtime-intake/check-runs/factory-engineering-runner-tests"
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        patcher = patch.object(RUNNER, "RUNS", self.root)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_names_cannot_escape_evidence(self):
        for name in ["../escape", "/tmp/escape", "a/b", "", ".", "a b"]:
            with self.subTest(name=name), self.assertRaises(ValueError):
                RUNNER.batch_path(name)

    def test_links_cannot_redirect_input_or_output(self):
        target = self.root / "target"
        target.mkdir()
        (self.root / "linked").symlink_to(target, target_is_directory=True)
        with self.assertRaises(ValueError):
            RUNNER.batch_path("linked")
        (target / "source.json").symlink_to(ROOT / "client/project.godot")
        with self.assertRaises(ValueError):
            RUNNER.hashes(target)

    def test_locked_parent_is_rejected(self):
        parent = self.root / "parent"
        (parent / "world/session.lock").mkdir(parents=True)
        with self.assertRaises(ValueError):
            RUNNER.hashes(parent)

    def test_used_batch_is_never_overwritten(self):
        batch = self.root / "used"
        batch.mkdir()
        sentinel = batch / "keep.txt"
        sentinel.write_text("retained")
        with patch("sys.argv", ["runner", "identity", "used"]), self.assertRaises(ValueError):
            RUNNER.main()
        self.assertEqual(sentinel.read_text(), "retained")

    def parent(self):
        parent = self.root / "parent"
        parent.mkdir()
        RUNNER.write(parent / "result.json", {"assertions": 3, "failures": [], "ready": True})
        RUNNER.write(parent / "execution-inputs.json", {"mode": "prepare", "code_sha256": RUNNER.code_hashes()})
        for name in ["source.json", "continuation.json"]:
            RUNNER.write(parent / name, {"retained": name})
        RUNNER.write(parent / "runner-result.json", {"exit_code": 0, "errors": [], "parent_unchanged": True,
                     "artifacts": {name: RUNNER.digest(parent / name) for name in ["source.json", "continuation.json"]}})
        return parent

    def test_changed_artifact_refuses_before_child_creation(self):
        parent = self.parent()
        (parent / "source.json").write_text("changed")
        with patch("sys.argv", ["runner", "prepare-read", "child", "parent"]), self.assertRaises(ValueError):
            RUNNER.main()
        self.assertFalse((self.root / "child").exists())

    def test_script_assertions_do_not_override_failed_runner(self):
        parent = self.parent()
        report = json.loads((parent / "runner-result.json").read_text())
        report["errors"] = ["SCRIPT ERROR"]
        RUNNER.write(parent / "runner-result.json", report)
        with patch("sys.argv", ["runner", "prepare-read", "child", "parent"]), self.assertRaises(ValueError):
            RUNNER.main()
        self.assertFalse((self.root / "child").exists())

    def test_wrong_parent_mode_is_not_a_prepared_source(self):
        parent = self.parent()
        manifest = json.loads((parent / "execution-inputs.json").read_text())
        manifest["mode"] = "identity"
        RUNNER.write(parent / "execution-inputs.json", manifest)
        with patch("sys.argv", ["runner", "density", "child", "parent"]), self.assertRaises(ValueError):
            RUNNER.main()
        self.assertFalse((self.root / "child").exists())

    def test_parent_must_have_unchanged_receipt_and_ready_preparation(self):
        parent = self.parent()
        receipt = json.loads((parent / "runner-result.json").read_text())
        receipt["parent_unchanged"] = False
        RUNNER.write(parent / "runner-result.json", receipt)
        with self.assertRaises(ValueError):
            RUNNER.validated_parent(parent, "prepare-read")
        receipt["parent_unchanged"] = True
        RUNNER.write(parent / "runner-result.json", receipt)
        RUNNER.write(parent / "result.json", {"assertions": 3, "failures": [], "ready": False})
        with self.assertRaises(ValueError):
            RUNNER.validated_parent(parent, "prepare-read")

    def test_runtime_change_is_incompatible_but_new_consumer_is_not(self):
        parent = self.parent()
        manifest = json.loads((parent / "execution-inputs.json").read_text())
        manifest["code_sha256"]["tools/check-factory-engineering.py"] = "older producer runner"
        RUNNER.write(parent / "execution-inputs.json", manifest)
        RUNNER.validated_parent(parent, "prepare-read")
        manifest["code_sha256"][next(iter(RUNNER.state_hashes()))] = "different runtime"
        RUNNER.write(parent / "execution-inputs.json", manifest)
        with self.assertRaises(ValueError):
            RUNNER.validated_parent(parent, "prepare-read")

    def test_checkpoint_receipt_cannot_silently_use_a_late_hash(self):
        parent = self.parent()
        receipt = json.loads((parent / "runner-result.json").read_text())
        receipt["artifact_manifest_version"] = 2
        del receipt["artifacts"]["source.json"]
        RUNNER.write(parent / "runner-result.json", receipt)
        with self.assertRaises(ValueError):
            RUNNER.validated_parent(parent, "checkpoint-write")


if __name__ == "__main__":
    unittest.main()

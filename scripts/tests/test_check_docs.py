from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "check-docs.py"
SPEC = importlib.util.spec_from_file_location("check_docs", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("unable to load check-docs.py")
CHECK_DOCS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK_DOCS)


class AgentEntryChecks(unittest.TestCase):
    GUIDE = b"# Project guide\n\nProject intro.\n\n## Rules\n"

    def test_accepts_identical_entries(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            for name in ("AGENTS.md", "CLAUDE.md"):
                (root / name).write_bytes(self.GUIDE)
            errors: list[str] = []
            warnings: list[str] = []

            CHECK_DOCS.check_agent_entries(root, errors, warnings)

            self.assertEqual([], errors)
            self.assertEqual([], warnings)

    def test_rejects_any_difference(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "AGENTS.md").write_bytes(self.GUIDE)
            for original, changed in (
                (b"Project guide", b"Claude guide"),
                (b"Project intro.", b"Claude intro."),
                (b"## Rules", b"## Other rules"),
                (b"\n", b"\r\n"),
            ):
                with self.subTest(original=original):
                    (root / "CLAUDE.md").write_bytes(self.GUIDE.replace(original, changed, 1))
                    errors: list[str] = []
                    warnings: list[str] = []

                    CHECK_DOCS.check_agent_entries(root, errors, warnings)

                    self.assertEqual(["AGENTS.md and CLAUDE.md must have identical contents"], errors)


if __name__ == "__main__":
    unittest.main()

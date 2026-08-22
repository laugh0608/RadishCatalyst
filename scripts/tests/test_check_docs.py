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
    def write_entries(self, root: Path, agents_body: str, claude_body: str) -> None:
        (root / "AGENTS.md").write_text(
            f"# AGENTS 指南\n\nAgent intro.\n{agents_body}",
            encoding="utf-8",
        )
        (root / "CLAUDE.md").write_text(
            f"# CLAUDE 指南\n\nClaude intro.\n{claude_body}",
            encoding="utf-8",
        )

    def test_accepts_distinct_intros_with_matching_shared_body(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.write_entries(root, "\n## Shared\n", "\n## Shared\n")
            errors: list[str] = []
            warnings: list[str] = []

            CHECK_DOCS.check_agent_entries(root, errors, warnings)

            self.assertEqual([], errors)
            self.assertEqual([], warnings)

    def test_rejects_divergent_shared_body(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.write_entries(root, "\n## Agents\n", "\n## Claude\n")
            errors: list[str] = []
            warnings: list[str] = []

            CHECK_DOCS.check_agent_entries(root, errors, warnings)

            self.assertIn(
                "AGENTS.md and CLAUDE.md must match exactly from line 4",
                errors,
            )


if __name__ == "__main__":
    unittest.main()

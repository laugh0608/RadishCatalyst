from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "check-repo.py"
SPEC = importlib.util.spec_from_file_location("check_repo", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("unable to load check-repo.py")
CHECK_REPO = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK_REPO)


class MarkdownLinkChecks(unittest.TestCase):
    def test_accepts_existing_relative_and_external_links(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            target = root / "target.md"
            source = root / "README.md"
            target.write_text("# Target\n", encoding="utf-8")
            source.write_text(
                "[local](target.md) [external](https://example.com)\n",
                encoding="utf-8",
            )
            errors: list[str] = []

            CHECK_REPO.check_markdown_links(root, [source, target], errors)

            self.assertEqual([], errors)

    def test_rejects_missing_relative_link(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "README.md"
            source.write_text("[missing](docs/missing.md)\n", encoding="utf-8")
            errors: list[str] = []

            CHECK_REPO.check_markdown_links(root, [source], errors)

            self.assertEqual(
                ["broken relative link: README.md -> docs/missing.md"],
                errors,
            )

    def test_rejects_link_escaping_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "README.md"
            source.write_text("[outside](../outside.md)\n", encoding="utf-8")
            errors: list[str] = []

            CHECK_REPO.check_markdown_links(root, [source], errors)

            self.assertEqual(
                ["relative link escapes repository: README.md -> ../outside.md"],
                errors,
            )

    def test_ignores_archived_historical_links(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "docs" / "archive" / "history.md"
            source.parent.mkdir(parents=True)
            source.write_text("[historical](../moved.md)\n", encoding="utf-8")
            errors: list[str] = []

            CHECK_REPO.check_markdown_links(root, [source], errors)

            self.assertEqual([], errors)


class GovernanceContractChecks(unittest.TestCase):
    def test_commit_subject_contract(self) -> None:
        self.assertTrue(CHECK_REPO.is_allowed_commit_subject("docs(repo): add policy"))
        self.assertTrue(CHECK_REPO.is_allowed_commit_subject("Merge pull request #12 from topic"))
        self.assertFalse(CHECK_REPO.is_allowed_commit_subject("update policy"))

    def test_required_file_contract_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            errors: list[str] = []

            CHECK_REPO.check_required_files(Path(temp_dir), errors)

            self.assertIn("missing required file: SECURITY.md", errors)


if __name__ == "__main__":
    unittest.main()

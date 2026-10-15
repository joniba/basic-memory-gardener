import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests" / "Find-GardenCandidates-tests"
HELPER = ROOT / "skills" / "memory-garden" / "scripts" / "Find-GardenCandidates.ps1"


def file_hashes():
    return {
        path.relative_to(FIXTURES).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in FIXTURES.rglob("*.md")
    }


def inventory(*, include_unchanged=True, folder=""):
    def quote(value):
        return str(value).replace("'", "''")

    command = f"& '{quote(HELPER)}' -Root '{quote(FIXTURES)}'"
    if include_unchanged:
        command += " -IncludeUnchanged"
    if folder:
        command += f" -Folder '{quote(folder)}'"
    command += " | ConvertTo-Json -Depth 6"
    return subprocess.run(
        ["pwsh", "-NoProfile", "-NonInteractive", "-Command", command],
        capture_output=True, text=True, encoding="utf-8", timeout=30,
    )


class InventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if shutil.which("pwsh") is None:
            raise RuntimeError("PowerShell 7 is required; inventory tests were not run.")
        cls.before = file_hashes()
        result = inventory()
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.rows = {row["Path"]: row for row in json.loads(result.stdout)}

    @classmethod
    def tearDownClass(cls):
        if file_hashes() != cls.before:
            raise AssertionError("The read-only inventory changed synthetic source files.")

    def test_all_scoped_markdown_files_are_discovered(self):
        self.assertEqual(set(self.rows), set(file_hashes()))

    def test_all_captures_have_body_protection_regardless_of_status(self):
        for name in ("active", "completed", "legacy", "duplicate-status", "unfamiliar-status", "status-only", "empty-thread"):
            with self.subTest(name=name):
                row = self.rows[f"captures/{name}.md"]
                self.assertTrue(row["IsCapture"])
                self.assertEqual(row["Protection"], "capture-body")
        self.assertEqual(self.rows["captures/active.md"]["CaptureStatus"], "active")
        self.assertIsNone(self.rows["captures/legacy.md"]["CaptureStatus"])

    def test_duplicate_legacy_status_does_not_relax_body_protection(self):
        row = self.rows["captures/duplicate-status.md"]
        self.assertTrue(row["AmbiguousCaptureMetadata"])
        self.assertEqual(row["Protection"], "capture-body")

    def test_completed_is_separate_from_archival_and_authority(self):
        row = self.rows["captures/completed.md"]
        self.assertEqual(row["CaptureStatus"], "completed")
        self.assertFalse(row["Archived"])
        self.assertEqual(row["Protection"], "capture-body")
        self.assertEqual(row["Reason"], "unchanged")

    def test_archived_capture_remains_protected(self):
        self.assertEqual(self.rows["captures/archived.md"]["Protection"], "archived-capture")

    def test_duplicate_archive_cannot_remove_capture_protection(self):
        row = self.rows["captures/duplicate-archive.md"]
        self.assertTrue(row["Archived"])
        self.assertTrue(row["AmbiguousCaptureMetadata"])
        self.assertEqual(row["Protection"], "archived-capture")

    def test_unterminated_frontmatter_cannot_certify_unchanged(self):
        row = self.rows["captures/unterminated.md"]
        self.assertTrue(row["AmbiguousCaptureMetadata"])
        self.assertEqual(row["Reason"], "invalid-frontmatter")
        self.assertEqual(row["Protection"], "capture-body")

    def test_source_reference_does_not_duplicate_capture_identity(self):
        row = self.rows["topics/canonical.md"]
        self.assertFalse(row["IsCapture"])
        self.assertIsNone(row["CaptureStatus"])
        self.assertEqual(row["NoteRole"], "canonical_topic")

    def test_nested_metadata_and_body_literals_do_not_establish_identity(self):
        self.assertFalse(self.rows["topics/nested.md"]["IsCapture"])
        self.assertEqual(self.rows["topics/nested.md"]["Reason"], "missing-canonical-modified")
        self.assertFalse(self.rows["topics/plain.md"]["IsCapture"])

    def test_source_protection_survives_conflicting_roles(self):
        for name in ("evidence", "duplicate-role"):
            self.assertEqual(self.rows[f"sources/{name}.md"]["Protection"], "source-evidence")
        self.assertTrue(self.rows["sources/duplicate-role.md"]["AmbiguousCaptureMetadata"])

    def test_unknown_timestamps_stay_eligible(self):
        self.assertEqual(self.rows["topics/naive-timestamp.md"]["Reason"], "invalid-or-ambiguous-canonical-modified")
        self.assertEqual(self.rows["topics/invalid-watermark.md"]["Reason"], "invalid-watermark")

    def test_reviewed_active_capture_with_equivalent_offsets_is_unchanged(self):
        row = self.rows["captures/reviewed-active.md"]
        self.assertEqual(row["CaptureStatus"], "active")
        self.assertEqual(row["Protection"], "capture-body")
        self.assertEqual(row["Reason"], "unchanged")

    def test_metadata_stamp_equality_does_not_cause_repeat_review(self):
        row = self.rows["captures/reviewed-equal.md"]
        self.assertEqual(row["Modified"], row["LastGardenedAt"])
        self.assertEqual(row["Reason"], "unchanged")

    def test_later_capture_modification_is_eligible_with_old_stamp(self):
        row = self.rows["captures/changed-after-review.md"]
        self.assertEqual(row["Reason"], "modified-since-gardening")
        self.assertEqual(row["LastGardenedAt"],
                         self.rows["captures/reviewed-equal.md"]["LastGardenedAt"])

    def test_duplicate_timestamps_cannot_certify_unchanged(self):
        for name in ("duplicate-modified", "duplicate-watermark"):
            with self.subTest(name=name):
                row = self.rows[f"topics/{name}.md"]
                self.assertTrue(row["AmbiguousTimestamps"])
                self.assertEqual(row["Reason"], "ambiguous-timestamps")

    def test_imported_evidence_with_capture_identity_remains_immutable(self):
        row = self.rows["sources/capture-identity.md"]
        self.assertTrue(row["IsCapture"])
        self.assertEqual(row["Protection"], "source-evidence")

    def test_default_inventory_skips_only_timestamp_unchanged_notes(self):
        result = inventory(include_unchanged=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        names = {row["Path"] for row in json.loads(result.stdout)}
        self.assertNotIn("captures/completed.md", names)
        self.assertNotIn("captures/legacy.md", names)
        self.assertNotIn("topics/canonical.md", names)
        self.assertNotIn("captures/reviewed-active.md", names)
        self.assertNotIn("captures/reviewed-equal.md", names)
        self.assertIn("captures/changed-after-review.md", names)
        self.assertIn("topics/duplicate-modified.md", names)
        self.assertIn("topics/duplicate-watermark.md", names)
        self.assertIn("captures/duplicate-status.md", names)

    def test_folder_scope_and_escape_rejection(self):
        result = inventory(folder="captures")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all(row["Path"].startswith("captures/") for row in json.loads(result.stdout)))
        escaped = inventory(folder="..")
        self.assertNotEqual(escaped.returncode, 0)
        self.assertIn("Folder must be inside", escaped.stderr)

    def test_no_raw_thread_identifiers_in_inventory_output(self):
        self.assertFalse(any("ThreadId" in row for row in self.rows.values()))
        self.assertNotIn("example-active-thread", json.dumps(self.rows))


class PolicyConsistencyTests(unittest.TestCase):
    def test_plugin_skill_assets_and_relative_links_exist(self):
        manifest = json.loads((ROOT / "plugin.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["$schema"], "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json")
        self.assertEqual(manifest["version"], "0.2.0")
        self.assertTrue(HELPER.is_file())
        for path in (ROOT / "skills").glob("*/SKILL.md"):
            text = path.read_text(encoding="utf-8")
            description = re.search(r"^description:\s*(.+)$", text, re.M).group(1)
            self.assertLessEqual(len(description), 1024)
            for link in re.findall(r"\]\(([^)]+)\)", text):
                if "://" not in link and not link.startswith("#"):
                    self.assertTrue((path.parent / link.split("#")[0]).exists(), (path, link))

    def test_shared_contract_is_referenced_by_both_skills(self):
        for name in ("memory-garden", "memory-capture"):
            text = (ROOT / "skills" / name / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("capture-lifecycle-design.md", text)
            self.assertIn("pointer-only", text)
            self.assertIn("last_gardened_at", text)
            self.assertIn("modified", text)

    def test_gardener_preserves_bodies_and_stamps_successfully_processed_captures(self):
        text = " ".join((ROOT / "skills" / "memory-garden" / "SKILL.md").read_text(encoding="utf-8").split())
        self.assertIn("already covered | update | create | defer", text)
        self.assertIn("including active ones", (ROOT / "README.md").read_text(encoding="utf-8"))
        self.assertIn("Keep topic outcomes in the run report, not in the capture body", text)
        self.assertIn("partial, deferred, failed or proposal-only", text)
        self.assertIn("active or finished", text)
        self.assertIn("metadata-only", text)
        self.assertIn("complete source body", text)

    def test_capture_preserves_stamp_and_guards_without_new_lifecycle_or_compaction(self):
        text = (ROOT / "skills" / "memory-capture" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("Never filter exact thread identity lookup by archive state", text)
        self.assertIn("preserving unrelated frontmatter", text)
        self.assertIn("existing `last_gardened_at` exactly", text)
        self.assertIn("do not create, advance or clear it", text)
        self.assertNotIn("capture_status: active", text)
        self.assertNotIn('"capture_status":', text)
        self.assertNotIn("Compact handoffs after verified promotion", text)
        self.assertNotIn("An automatic checkpoint alone must stop", text)

    def test_local_decisions_directory_is_git_ignored(self):
        self.assertIn("/.local/", (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines())

    def test_inventory_does_not_use_file_or_git_timestamps_or_write(self):
        text = HELPER.read_text(encoding="utf-8")
        self.assertNotIn("LastWriteTime", text)
        self.assertNotIn("Get-Date", text)
        self.assertNotRegex(text, r"(?m)^\s*(?:Set-Content|Add-Content|Remove-Item|Move-Item|git)\b")

    def test_consultation_limit_and_manual_acceptance_are_not_mislabeled(self):
        design = (ROOT / "docs" / "capture-lifecycle-design.md").read_text(encoding="utf-8")
        scenarios = (ROOT / "tests" / "capture-lifecycle-scenarios.md").read_text(encoding="utf-8")
        self.assertIn("consultation is pending", design)
        self.assertIn("not** prove LLM semantic", design)
        self.assertIn("not an automated LLM acceptance result", " ".join(scenarios.split()))


if __name__ == "__main__":
    unittest.main()

"""Exercise packaging and failure handling without using signing credentials."""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest
import zipfile


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MOCK_TOOL = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['MOCK_LOG'], 'a') as log:
    log.write(json.dumps([tool, *args]) + '\\n')
if tool == 'swift':
    if '--show-bin-path' in args:
        print(Path('.build/custom-release').resolve())
    else:
        if os.environ.get('MOCK_BUILD_FAILURE'):
            sys.exit(1)
        binary = Path('.build/custom-release/Standup')
        binary.parent.mkdir(parents=True, exist_ok=True)
        binary.write_text('test executable')
        binary.chmod(0o755)
elif tool == 'codesign':
    if '--sign' in args and os.environ.get('MOCK_SIGN_FAILURE'):
        sys.exit(1)
    if '--verify' in args and os.environ.get('MOCK_VERIFY_FAILURE'):
        sys.exit(1)
elif tool == 'lipo':
    print(os.environ.get('MOCK_ARCH', 'arm64'))
elif tool == 'ditto':
    if os.environ.get('MOCK_ARCHIVE_FAILURE'):
        Path(args[-1]).write_bytes(b'partial archive')
        sys.exit(1)
    os.execv('/usr/bin/ditto', ['ditto', *args])
"""


class ReleaseBuildTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="standup build tests ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        shutil.copy2(PROJECT_ROOT / "build.sh", self.root / "build.sh")
        resources = self.root / "Resources"
        resources.mkdir()
        (resources / "AppIcon.icns").write_bytes(b"test icon")
        (resources / "standup_0.png").write_bytes(b"test frame")
        mocks = self.root / "mock-bin"
        mocks.mkdir()
        for name in ("swift", "codesign", "lipo", "ditto"):
            tool = mocks / name
            tool.write_text(MOCK_TOOL)
            tool.chmod(0o755)
        self.log = self.root / "tools.jsonl"
        self.environment = dict(os.environ)
        self.environment.pop("SIGNING_IDENTITY", None)
        self.environment.update(PATH=f"{mocks}:{os.environ['PATH']}", MOCK_LOG=str(self.log))
        self.output = self.root / "build/signed"

    def run_build(self, *args, **environment):
        return subprocess.run(
            ["/bin/bash", str(self.root / "build.sh"), *args],
            cwd=self.root.parent,
            env={**self.environment, **environment},
            capture_output=True,
            text=True,
            timeout=30,
        )

    def calls(self, tool):
        if not self.log.exists():
            return []
        return [call[1:] for line in self.log.read_text().splitlines()
                if (call := json.loads(line))[0] == tool]

    def assert_no_archive(self):
        self.assertEqual(list(self.output.glob("*.zip")), [])
        self.assertEqual(list(self.output.glob("*.sha256")), [])

    def test_default_build_preserves_local_workflow_and_bundle_metadata(self):
        result = self.run_build()
        self.assertEqual(result.returncode, 0, result.stderr)
        contents = self.root / "build/Standup.app/Contents"
        with (contents / "Info.plist").open("rb") as file:
            metadata = plistlib.load(file)
        self.assertEqual(metadata["CFBundleIdentifier"], "fun.built4.standup")
        self.assertEqual(metadata["CFBundleShortVersionString"], "1.0.4")
        self.assertEqual(metadata["CFBundleVersion"], "5")
        self.assertEqual(metadata["CFBundleIconFile"], "AppIcon.icns")
        self.assertEqual(metadata["LSMinimumSystemVersion"], "13.0")
        self.assertTrue(metadata["LSUIElement"])
        self.assertEqual((contents / "MacOS/Standup").read_text(), "test executable")
        self.assertTrue((contents / "Resources/AppIcon.icns").exists())
        self.assertEqual(self.calls("codesign"), [])
        self.assert_no_archive()

    def test_signed_build_verifies_before_packaging_and_generates_valid_checksum(self):
        result = self.run_build("--signed")
        self.assertEqual(result.returncode, 0, result.stderr)
        sign, verify = self.calls("codesign")
        self.assertEqual(sign[sign.index("--sign") + 1], "Developer ID Application")
        self.assertEqual(sign[sign.index("--options") + 1], "runtime")
        self.assertIn("--timestamp", sign)
        self.assertNotIn("--deep", sign)
        for option in ("--verify", "--deep", "--strict", "--test-requirement"):
            self.assertIn(option, verify)
        requirement = subprocess.run(
            ["csreq", "-r", verify[verify.index("--test-requirement") + 1], "-t"],
            capture_output=True, text=True,
        )
        self.assertEqual(requirement.returncode, 0, requirement.stderr)
        archive = self.output / "Standup-v1.0.4-macOS-arm64-signed.zip"
        with zipfile.ZipFile(archive) as zipped:
            self.assertIn("Standup.app/Contents/Info.plist", zipped.namelist())
            self.assertIn("Standup.app/Contents/Resources/standup_0.png", zipped.namelist())
        checksum = subprocess.run(
            ["shasum", "-a", "256", "-c", archive.name + ".sha256"],
            cwd=self.output, capture_output=True, text=True,
        )
        self.assertEqual(checksum.returncode, 0, checksum.stderr)
        self.assertIn("Not notarized", result.stdout)

    def test_custom_identity_is_passed_as_one_argument(self):
        identity = "Developer ID Application: Example Developer (TEAM123456)"
        result = self.run_build("--signed", SIGNING_IDENTITY=identity)
        self.assertEqual(result.returncode, 0, result.stderr)
        sign = self.calls("codesign")[0]
        self.assertEqual(sign[sign.index("--sign") + 1], identity)

    def test_archive_name_uses_binary_architecture(self):
        result = self.run_build("--signed", MOCK_ARCH="x86_64")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.output / "Standup-v1.0.4-macOS-x86_64-signed.zip").exists())

    def test_failed_build_removes_stale_candidate(self):
        self.output.mkdir(parents=True)
        (self.output / "Standup-old-signed.zip").write_bytes(b"stale candidate")
        result = self.run_build("--signed", MOCK_BUILD_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assert_no_archive()
        self.assertEqual(self.calls("codesign"), [])

    def test_signing_failure_never_falls_back_to_unsigned_archive(self):
        result = self.run_build("--signed", MOCK_SIGN_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assert_no_archive()
        self.assertEqual(len(self.calls("codesign")), 1)

    def test_verification_failure_blocks_archive(self):
        result = self.run_build("--signed", MOCK_VERIFY_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assert_no_archive()
        self.assertEqual(len(self.calls("codesign")), 2)

    def test_unexpected_architecture_blocks_mislabeled_archive(self):
        result = self.run_build("--signed", MOCK_ARCH="unexpected")
        self.assertNotEqual(result.returncode, 0)
        self.assert_no_archive()

    def test_packaging_failure_does_not_expose_partial_zip_as_candidate(self):
        result = self.run_build("--signed", MOCK_ARCHIVE_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assert_no_archive()

    def test_invalid_arguments_do_not_start_build(self):
        for args in [("--unknown",), ("--signed", "extra"), ("--help", "extra")]:
            with self.subTest(args=args):
                result = self.run_build(*args)
                self.assertEqual(result.returncode, 2)
        self.assertEqual(self.calls("swift"), [])

    def test_help_does_not_start_build(self):
        result = self.run_build("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--signed", result.stdout)
        self.assertEqual(self.calls("swift"), [])


if __name__ == "__main__":
    unittest.main()

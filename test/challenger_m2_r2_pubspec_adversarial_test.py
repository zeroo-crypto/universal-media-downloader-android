#!/usr/bin/env python3
"""test/challenger_m2_r2_pubspec_adversarial_test.py
--------------------------------------------------------------------------------
Adversarial Verification Suite for Milestone 2 (Round 2)
Agent: teamwork_preview_challenger_m2_r2_1 (Empirical Challenger)

Mission:
  Empirically and adversarially test pubspec.yaml dependency constraints,
  verify zero matches for wildcard 'any', test semantic version range constraints
  (specifically archive: ^3.6.1, flutter_foreground_task: ^8.17.0,
  receive_sharing_intent: ^1.8.1, path: ^1.9.0), test YAML parsing,
  and verify build.gradle and AndroidManifest.xml modernization integrity.

Test Suites:
  1. YAML Parsing, Schema & Formatting Stress Tests
  2. Strict Zero Wildcard 'any' Elimination Audit
  3. Semantic Version Range & Bound Oracle Verification
  4. AST Cross-File Import & Direct Dependency Coverage Audit
  5. YAML Mutation & Adversarial Fault Injection Resilience
  6. AGP 8+ Gradle & Manifest Modernization Integrity
--------------------------------------------------------------------------------
"""

import os
import re
import sys
import unittest
import xml.etree.ElementTree as ET
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PUBSPEC_PATH = os.path.join(REPO_ROOT, "pubspec.yaml")
BUILD_GRADLE_PATH = os.path.join(REPO_ROOT, "android", "app", "build.gradle")
MANIFEST_PATH = os.path.join(REPO_ROOT, "android", "app", "src", "main", "AndroidManifest.xml")
LIB_DIR = os.path.join(REPO_ROOT, "lib")


class VersionMatcher:
    """Helper to parse and test Dart semver caret constraints."""
    def __init__(self, constraint_str):
        self.raw = constraint_str.strip()
        m = re.match(r"^\^(\d+)\.(\d+)\.(\d+)(?:\+.*)?$", self.raw)
        if m:
            major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
            self.min_version = (major, minor, patch)
            if major > 0:
                self.max_exclusive = (major + 1, 0, 0)
            elif minor > 0:
                self.max_exclusive = (0, minor + 1, 0)
            else:
                self.max_exclusive = (0, 0, patch + 1)
        else:
            self.min_version = None
            self.max_exclusive = None

    def satisfies(self, version_str):
        m = re.match(r"^(\d+)\.(\d+)\.(\d+)", version_str.strip())
        if not m:
            raise ValueError(f"Invalid semver test string: {version_str}")
        v = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
        if self.min_version and self.max_exclusive:
            return self.min_version <= v < self.max_exclusive
        return False


class TestPubspecYamlParsingAndStructure(unittest.TestCase):
    """Suite 1: Validate YAML parsing, structure, schema, and syntax formatting."""

    def setUp(self):
        self.assertTrue(os.path.exists(PUBSPEC_PATH), f"pubspec.yaml not found at {PUBSPEC_PATH}")
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            self.raw_content = f.read()
        self.parsed = yaml.safe_load(self.raw_content)

    def test_yaml_safe_load_returns_valid_dict(self):
        self.assertIsInstance(self.parsed, dict, "Parsed pubspec.yaml must be a top-level dictionary")

    def test_mandatory_root_keys_present(self):
        required_keys = ["name", "description", "publish_to", "version", "environment", "dependencies", "dev_dependencies", "flutter"]
        for key in required_keys:
            self.assertIn(key, self.parsed, f"Required root key '{key}' is missing from pubspec.yaml")

    def test_no_tab_characters_in_pubspec(self):
        """YAML specification forbids tabs for indentation."""
        lines = self.raw_content.splitlines()
        for idx, line in enumerate(lines, start=1):
            self.assertNotIn("\t", line, f"Tab character found in pubspec.yaml at line {idx}")

    def test_environment_sdk_constraint(self):
        env = self.parsed.get("environment", {})
        self.assertIn("sdk", env, "Missing 'sdk' constraint in environment")
        sdk_constraint = env["sdk"]
        self.assertEqual(sdk_constraint, ">=3.1.0 <4.0.0", f"Unexpected sdk constraint: {sdk_constraint}")

    def test_flutter_configuration(self):
        flutter_config = self.parsed.get("flutter", {})
        self.assertTrue(flutter_config.get("uses-material-design"), "uses-material-design must be true")


class TestPubspecWildcardElimination(unittest.TestCase):
    """Suite 2: Empirically prove zero wildcard 'any' specifiers exist in pubspec.yaml."""

    def setUp(self):
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            self.raw_content = f.read()
        self.parsed = yaml.safe_load(self.raw_content)

    def test_raw_regex_scan_for_word_boundary_any(self):
        """No instance of word boundary 'any' should exist in the entire pubspec.yaml."""
        matches = re.findall(r"\bany\b", self.raw_content, flags=re.IGNORECASE)
        self.assertEqual(len(matches), 0, f"Expected 0 occurrences of 'any', found {len(matches)}: {matches}")

    def test_dependency_values_contain_no_any(self):
        """Inspect all values in dependencies and dev_dependencies."""
        all_deps = {}
        all_deps.update(self.parsed.get("dependencies", {}))
        all_deps.update(self.parsed.get("dev_dependencies", {}))

        for dep_name, dep_val in all_deps.items():
            if isinstance(dep_val, str):
                self.assertNotEqual(dep_val.strip().lower(), "any", f"Dependency '{dep_name}' has wildcard 'any' value")
                self.assertNotIn("any", dep_val.lower(), f"Dependency '{dep_name}' contains 'any': {dep_val}")
                self.assertFalse(dep_val.startswith("*"), f"Dependency '{dep_name}' has wildcard '*': {dep_val}")
            elif isinstance(dep_val, dict):
                # e.g., sdk: flutter
                for k, v in dep_val.items():
                    self.assertNotEqual(str(v).strip().lower(), "any", f"Dependency '{dep_name}.{k}' has 'any'")

    def test_no_empty_or_unbounded_dependencies(self):
        all_deps = {}
        all_deps.update(self.parsed.get("dependencies", {}))
        all_deps.update(self.parsed.get("dev_dependencies", {}))

        for dep_name, dep_val in all_deps.items():
            self.assertIsNotNone(dep_val, f"Dependency '{dep_name}' is None/empty")
            if isinstance(dep_val, str):
                self.assertTrue(len(dep_val.strip()) > 0, f"Dependency '{dep_name}' has empty version string")
                self.assertNotEqual(dep_val.strip(), ">=0.0.0", f"Dependency '{dep_name}' has unbounded constraint")


class TestSemanticVersionRangeConstraints(unittest.TestCase):
    """Suite 3: Verify semver bounds and caret compatibility oracles."""

    def setUp(self):
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            self.parsed = yaml.safe_load(f)
        self.deps = self.parsed.get("dependencies", {})
        self.dev_deps = self.parsed.get("dev_dependencies", {})

    def test_archive_semver_constraint(self):
        """archive must be ^3.6.1 and strictly reject >=4.0.0 due to file.content type change."""
        self.assertIn("archive", self.deps)
        constraint_str = self.deps["archive"]
        self.assertEqual(constraint_str, "^3.6.1")

        matcher = VersionMatcher(constraint_str)
        self.assertEqual(matcher.min_version, (3, 6, 1))
        self.assertEqual(matcher.max_exclusive, (4, 0, 0))

        # Allowed versions
        self.assertTrue(matcher.satisfies("3.6.1"))
        self.assertTrue(matcher.satisfies("3.6.2"))
        self.assertTrue(matcher.satisfies("3.7.0"))
        self.assertTrue(matcher.satisfies("3.9.9"))

        # Critical rejected versions
        self.assertFalse(matcher.satisfies("4.0.0"), "archive 4.0.0 must be rejected (breaks file.content as List<int>)")
        self.assertFalse(matcher.satisfies("4.1.0"))
        self.assertFalse(matcher.satisfies("3.6.0"))
        self.assertFalse(matcher.satisfies("2.0.0"))

    def test_flutter_foreground_task_semver_constraint(self):
        """flutter_foreground_task must be ^8.17.0, satisfying requirement >=8.6.0 for ForegroundTaskEventAction.repeat."""
        self.assertIn("flutter_foreground_task", self.deps)
        constraint_str = self.deps["flutter_foreground_task"]
        self.assertEqual(constraint_str, "^8.17.0")

        matcher = VersionMatcher(constraint_str)
        self.assertEqual(matcher.min_version, (8, 17, 0))
        self.assertEqual(matcher.max_exclusive, (9, 0, 0))

        # Confirms lower bound is >= 8.6.0
        self.assertGreaterEqual(matcher.min_version, (8, 6, 0))

        # Allowed versions
        self.assertTrue(matcher.satisfies("8.17.0"))
        self.assertTrue(matcher.satisfies("8.17.1"))
        self.assertTrue(matcher.satisfies("8.18.0"))

        # Rejected versions
        self.assertFalse(matcher.satisfies("8.6.0"), "8.6.0 is below pinned 8.17.0 lower bound")
        self.assertFalse(matcher.satisfies("8.16.9"))
        self.assertFalse(matcher.satisfies("9.0.0"), "9.0.0 is major breaking change")

    def test_receive_sharing_intent_semver_constraint(self):
        """receive_sharing_intent must be ^1.8.1, satisfying requirement >=1.7.0 for ReceiveSharingIntent.instance."""
        self.assertIn("receive_sharing_intent", self.deps)
        constraint_str = self.deps["receive_sharing_intent"]
        self.assertEqual(constraint_str, "^1.8.1")

        matcher = VersionMatcher(constraint_str)
        self.assertEqual(matcher.min_version, (1, 8, 1))
        self.assertEqual(matcher.max_exclusive, (2, 0, 0))

        # Confirms lower bound is >= 1.7.0
        self.assertGreaterEqual(matcher.min_version, (1, 7, 0))

        # Allowed versions
        self.assertTrue(matcher.satisfies("1.8.1"))
        self.assertTrue(matcher.satisfies("1.8.2"))
        self.assertTrue(matcher.satisfies("1.9.0"))

        # Rejected versions
        self.assertFalse(matcher.satisfies("1.7.0"), "1.7.0 is below pinned 1.8.1 lower bound")
        self.assertFalse(matcher.satisfies("1.8.0"))
        self.assertFalse(matcher.satisfies("2.0.0"), "2.0.0 is major breaking change")

    def test_path_package_declared_directly(self):
        """path must be declared directly as ^1.9.0 rather than leaking through transitive deps."""
        self.assertIn("path", self.deps)
        constraint_str = self.deps["path"]
        self.assertEqual(constraint_str, "^1.9.0")

        matcher = VersionMatcher(constraint_str)
        self.assertEqual(matcher.min_version, (1, 9, 0))
        self.assertEqual(matcher.max_exclusive, (2, 0, 0))

        self.assertTrue(matcher.satisfies("1.9.0"))
        self.assertTrue(matcher.satisfies("1.9.1"))
        self.assertFalse(matcher.satisfies("1.8.3"))
        self.assertFalse(matcher.satisfies("2.0.0"))

    def test_all_expected_dependencies_pinned_with_caret(self):
        expected_pins = {
            "dio": "^5.4.3+1",
            "http": "^1.2.1",
            "flutter_foreground_task": "^8.17.0",
            "permission_handler": "^11.3.1",
            "receive_sharing_intent": "^1.8.1",
            "path_provider": "^2.1.5",
            "open_filex": "^4.5.0",
            "ffmpeg_kit_flutter_new": "^4.6.7",
            "archive": "^3.6.1",
            "mime": "^2.1.0",
            "path": "^1.9.0",
            "provider": "^6.1.2",
            "shared_preferences": "^2.3.2",
            "intl": "^0.19.0",
        }
        for pkg, expected_val in expected_pins.items():
            self.assertIn(pkg, self.deps, f"Missing expected dependency '{pkg}'")
            self.assertEqual(self.deps[pkg], expected_val, f"Dependency '{pkg}' mismatch: expected {expected_val}, got {self.deps[pkg]}")

        self.assertEqual(self.dev_deps.get("flutter_lints"), "^4.0.0")


class TestCrossFileImportDependencyCoverage(unittest.TestCase):
    """Suite 4: Cross-reference all package imports in lib/ against pubspec.yaml dependencies."""

    def setUp(self):
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            self.parsed = yaml.safe_load(f)
        self.deps = self.parsed.get("dependencies", {})
        self.app_name = self.parsed.get("name", "universal_media_downloader")

    def test_all_imported_packages_are_declared_dependencies(self):
        imported_packages = set()
        import_regex = re.compile(r"""(?:import|export)\s+['"]package:([^/]+)/[^'"]+['"]""")

        for root, _, files in os.walk(LIB_DIR):
            for file in files:
                if file.endswith(".dart"):
                    file_path = os.path.join(root, file)
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as df:
                        content = df.read()
                        matches = import_regex.findall(content)
                        for m in matches:
                            imported_packages.add(m)

        # Allow self package and sdk packages
        system_packages = {self.app_name, "flutter", "flutter_test"}
        third_party_imports = imported_packages - system_packages

        for pkg in third_party_imports:
            self.assertIn(pkg, self.deps, f"Package '{pkg}' is imported in lib/ but NOT declared in pubspec.yaml dependencies!")

    def test_code_contracts_in_dependent_files(self):
        # 1. Verify ffmpeg_processor.dart uses archive and casts file.content as List<int>
        ffmpeg_proc_path = os.path.join(LIB_DIR, "core", "processors", "ffmpeg_processor.dart")
        self.assertTrue(os.path.exists(ffmpeg_proc_path))
        with open(ffmpeg_proc_path, "r", encoding="utf-8") as f:
            proc_code = f.read()
        self.assertIn("import 'package:archive/archive.dart';", proc_code)
        self.assertIn("file.content as List<int>", proc_code)

        # 2. Verify main.dart uses ForegroundTaskEventAction.repeat
        main_path = os.path.join(LIB_DIR, "main.dart")
        with open(main_path, "r", encoding="utf-8") as f:
            main_code = f.read()
        self.assertIn("ForegroundTaskEventAction.repeat(5000)", main_code)

        # 3. Verify share_intent_service.dart uses ReceiveSharingIntent.instance
        share_service_path = os.path.join(LIB_DIR, "services", "share_intent_service.dart")
        with open(share_service_path, "r", encoding="utf-8") as f:
            share_code = f.read()
        self.assertIn("ReceiveSharingIntent.instance", share_code)


class TestYamlFaultInjectionResilience(unittest.TestCase):
    """Suite 5: Stress test parser and validator against adversarial mutations."""

    def test_adversarial_mutation_rejects_any_injection(self):
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            original = f.read()

        mutated = original.replace("archive: ^3.6.1", "archive: any")
        data = yaml.safe_load(mutated)
        self.assertEqual(data["dependencies"]["archive"], "any")
        # Validate that our scanner detects this regression
        matches = re.findall(r"\bany\b", mutated)
        self.assertGreater(len(matches), 0)

    def test_adversarial_mutation_rejects_tab_indentation(self):
        with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
            original = f.read()

        mutated = original.replace("  archive: ^3.6.1", "\tarchive: ^3.6.1")
        # Standard YAML safe_load raises ScannerError on tab indentation
        with self.assertRaises(yaml.scanner.ScannerError):
            yaml.safe_load(mutated)


class TestGradleAndManifestModernization(unittest.TestCase):
    """Suite 6: Modernization tests for build.gradle and AndroidManifest.xml."""

    def test_build_gradle_agp8_packaging_and_kotlin(self):
        self.assertTrue(os.path.exists(BUILD_GRADLE_PATH))
        with open(BUILD_GRADLE_PATH, "r", encoding="utf-8") as f:
            gradle = f.read()

        self.assertIn('id "org.jetbrains.kotlin.android"', gradle)
        self.assertNotIn("kotlin-stdlib-jdk8", gradle)
        self.assertNotIn("packagingOptions", gradle)
        self.assertIn("packaging {", gradle)
        self.assertIn("jniLibs {", gradle)
        self.assertIn("pickFirsts +=", gradle)
        self.assertIn("'**/libc++_shared.so'", gradle)
        self.assertIn("'**/libflutter.so'", gradle)
        self.assertIn("v1SigningEnabled true", gradle)
        self.assertIn("v2SigningEnabled true", gradle)

    def test_android_manifest_no_deprecated_package_attribute(self):
        self.assertTrue(os.path.exists(MANIFEST_PATH))
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            manifest_content = f.read()

        # Parse XML AST
        root = ET.fromstring(manifest_content)
        self.assertEqual(root.tag, "manifest")
        # Verify no package attribute in manifest root element
        self.assertNotIn("package", root.attrib, "Deprecated 'package' attribute found in AndroidManifest.xml root")

        # Verify essential components
        services = root.findall(".//service")
        self.assertTrue(any("ForegroundService" in s.attrib.get("{http://schemas.android.com/apk/res/android}name", "") for s in services))


def run_all_tests():
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    suite.addTests(loader.loadTestsFromTestCase(TestPubspecYamlParsingAndStructure))
    suite.addTests(loader.loadTestsFromTestCase(TestPubspecWildcardElimination))
    suite.addTests(loader.loadTestsFromTestCase(TestSemanticVersionRangeConstraints))
    suite.addTests(loader.loadTestsFromTestCase(TestCrossFileImportDependencyCoverage))
    suite.addTests(loader.loadTestsFromTestCase(TestYamlFaultInjectionResilience))
    suite.addTests(loader.loadTestsFromTestCase(TestGradleAndManifestModernization))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)

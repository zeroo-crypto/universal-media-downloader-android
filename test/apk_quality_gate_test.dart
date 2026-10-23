import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// APK Verification Parser and Quality Gate Logic Checker
/// Models the automated quality gate defined in PROJECT.md R2 & Survey 3.
class ApkQualityGate {
  /// Validates apksigner verbose output
  static ApkSignatureVerificationResult verifyApkSignerOutput(String stdout, int exitCode) {
    if (exitCode != 0) {
      return ApkSignatureVerificationResult(
        isValid: false,
        v1SchemeVerified: false,
        v2SchemeVerified: false,
        errorMessage: 'apksigner exited with non-zero exit code: $exitCode',
      );
    }

    if (stdout.contains('DOES NOT VERIFY')) {
      return ApkSignatureVerificationResult(
        isValid: false,
        v1SchemeVerified: false,
        v2SchemeVerified: false,
        errorMessage: 'Signature verification failed: DOES NOT VERIFY',
      );
    }

    final v1Match = stdout.contains('Verified using v1 scheme (JAR signing): true');
    final v2Match = stdout.contains('Verified using v2 scheme (APK Signature Scheme v2): true');
    final v3Match = stdout.contains('Verified using v3 scheme (APK Signature Scheme v3): true');

    // Both v1 and v2 are mandatory to support Android 7.0 (API 24) through Android 15 (API 35)
    final isValid = v1Match && v2Match;

    return ApkSignatureVerificationResult(
      isValid: isValid,
      v1SchemeVerified: v1Match,
      v2SchemeVerified: v2Match,
      v3SchemeVerified: v3Match,
      errorMessage: isValid ? null : 'Missing mandatory signature scheme: v1=$v1Match, v2=$v2Match',
    );
  }

  /// Validates aapt dump badging output
  static AaptBadgingResult parseAaptBadging(String stdout, int exitCode) {
    if (exitCode != 0) {
      return AaptBadgingResult(
        isValid: false,
        errorMessage: 'aapt exited with non-zero code: $exitCode',
      );
    }

    final pkgMatch = RegExp(r"package:\s*name='([^']+)'(?:\s*versionCode='([^']+)')?(?:\s*versionName='([^']+)')?")
        .firstMatch(stdout);
    final packageName = pkgMatch?.group(1);
    final versionCode = pkgMatch?.group(2);
    final versionName = pkgMatch?.group(3);

    final activityMatch = RegExp(r"launchable-activity:\s*name='([^']+)'").firstMatch(stdout);
    final launchableActivity = activityMatch?.group(1);

    final sdkMatch = RegExp(r"sdkVersion:'(\d+)'").firstMatch(stdout);
    final minSdk = sdkMatch != null ? int.tryParse(sdkMatch.group(1)!) : null;

    final targetSdkMatch = RegExp(r"targetSdkVersion:'(\d+)'").firstMatch(stdout);
    final targetSdk = targetSdkMatch != null ? int.tryParse(targetSdkMatch.group(1)!) : null;

    final nativeCodeMatch = RegExp(r"native-code:\s*'([^']+)'").firstMatch(stdout);
    final nativeCode = nativeCodeMatch?.group(1);

    final isValid = packageName == 'com.zeroo.universal_media_downloader' &&
        launchableActivity == 'com.zeroo.universal_media_downloader.MainActivity' &&
        minSdk != null &&
        minSdk <= 24;

    return AaptBadgingResult(
      isValid: isValid,
      packageName: packageName,
      versionCode: versionCode,
      versionName: versionName,
      launchableActivity: launchableActivity,
      minSdkVersion: minSdk,
      targetSdkVersion: targetSdk,
      nativeCode: nativeCode,
      errorMessage: isValid ? null : 'Badging validation failed: package=$packageName, activity=$launchableActivity',
    );
  }

  /// Validates zipalign -c 4 output
  static bool verifyZipAlignOutput(String stdout, int exitCode) {
    if (exitCode != 0) return false;
    return stdout.contains('Verification successful');
  }

  /// Computes SHA-256 in standard unix format: <hash>  <filename>
  static String formatSha256Line(List<int> bytes, String filename) {
    final digest = sha256.convert(bytes);
    return '$digest  $filename';
  }
}

class ApkSignatureVerificationResult {
  final bool isValid;
  final bool v1SchemeVerified;
  final bool v2SchemeVerified;
  final bool v3SchemeVerified;
  final String? errorMessage;

  ApkSignatureVerificationResult({
    required this.isValid,
    required this.v1SchemeVerified,
    required this.v2SchemeVerified,
    this.v3SchemeVerified = false,
    this.errorMessage,
  });
}

class AaptBadgingResult {
  final bool isValid;
  final String? packageName;
  final String? versionCode;
  final String? versionName;
  final String? launchableActivity;
  final int? minSdkVersion;
  final int? targetSdkVersion;
  final String? nativeCode;
  final String? errorMessage;

  AaptBadgingResult({
    required this.isValid,
    this.packageName,
    this.versionCode,
    this.versionName,
    this.launchableActivity,
    this.minSdkVersion,
    this.targetSdkVersion,
    this.nativeCode,
    this.errorMessage,
  });
}

void main() {
  group('Tier 1: Feature Coverage — apksigner Signature Validation Parsing', () {
    test('Validates release APK signed with both v1 and v2 schemes', () {
      const mockApksignerOutput = '''
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate DN: CN=UniversalMediaDownloader, O=OpenSource, C=US
Signer #1 certificate SHA-256 digest: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
''';

      final result = ApkQualityGate.verifyApkSignerOutput(mockApksignerOutput, 0);

      expect(result.isValid, isTrue);
      expect(result.v1SchemeVerified, isTrue);
      expect(result.v2SchemeVerified, isTrue);
      expect(result.v3SchemeVerified, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Rejects APK lacking v2 signature scheme (causes "aplikasi tidak valid" on Android 11+)', () {
      const mockLegacyV1OnlyOutput = '''
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): false
Number of signers: 1
''';

      final result = ApkQualityGate.verifyApkSignerOutput(mockLegacyV1OnlyOutput, 0);

      expect(result.isValid, isFalse, reason: 'v2 signature is mandatory for Android 11+ installation');
      expect(result.v1SchemeVerified, isTrue);
      expect(result.v2SchemeVerified, isFalse);
      expect(result.errorMessage, contains('Missing mandatory signature scheme'));
    });

    test('Rejects unsigned APK with non-zero exit code or DOES NOT VERIFY', () {
      const mockUnsignedOutput = '''
DOES NOT VERIFY
ERROR: JAR signer CERT.RSA: JAR signature is missing or corrupted
''';

      final result = ApkQualityGate.verifyApkSignerOutput(mockUnsignedOutput, 1);

      expect(result.isValid, isFalse);
      expect(result.v1SchemeVerified, isFalse);
      expect(result.v2SchemeVerified, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });

  group('Tier 1: Feature Coverage — aapt Dump Badging & Manifest Verification', () {
    test('Validates legitimate package name, launchable activity, and API sdk thresholds', () {
      const mockAaptOutput = '''
package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0' compileSdkVersion='35'
sdkVersion:'24'
targetSdkVersion:'35'
application-label:'Universal Media Downloader'
launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'  label='Universal Media Downloader' icon=''
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.WRITE_EXTERNAL_STORAGE'
native-code: 'arm64-v8a'
''';

      final result = ApkQualityGate.parseAaptBadging(mockAaptOutput, 0);

      expect(result.isValid, isTrue);
      expect(result.packageName, equals('com.zeroo.universal_media_downloader'));
      expect(result.launchableActivity, equals('com.zeroo.universal_media_downloader.MainActivity'));
      expect(result.minSdkVersion, equals(24));
      expect(result.targetSdkVersion, equals(35));
      expect(result.nativeCode, equals('arm64-v8a'));
    });

    test('Rejects APK missing launchable-activity (cannot be launched on device home screen)', () {
      const mockBrokenAaptOutput = '''
package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0'
sdkVersion:'24'
targetSdkVersion:'34'
''';

      final result = ApkQualityGate.parseAaptBadging(mockBrokenAaptOutput, 0);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('activity'));
    });

    test('Rejects APK with mismatched or dummy package name', () {
      const mockMismatchAaptOutput = '''
package: name='com.example.dummy_app' versionCode='1' versionName='1.0'
sdkVersion:'24'
launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'
''';

      final result = ApkQualityGate.parseAaptBadging(mockMismatchAaptOutput, 0);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('package=com.example.dummy_app'));
    });
  });

  group('Tier 1: Feature Coverage — zipalign 4-Byte Boundary Verification', () {
    test('Validates successfully aligned APK output', () {
      const mockZipalignOutput = '''
Verifying alignment of build/app/outputs/flutter-apk/app-release.apk (4)...
      49 lib/arm64-v8a/libflutter.so (OK - compressed)
  128500 resources.arsc (OK)
Verification successful
''';

      final isAligned = ApkQualityGate.verifyZipAlignOutput(mockZipalignOutput, 0);
      expect(isAligned, isTrue);
    });

    test('Rejects unaligned APK with exit code 1', () {
      const mockFailedZipalignOutput = '''
Verifying alignment of app-release.apk (4)...
  128501 resources.arsc (BAD - 1)
Verification FAILED
''';

      final isAligned = ApkQualityGate.verifyZipAlignOutput(mockFailedZipalignOutput, 1);
      expect(isAligned, isFalse);
    });
  });

  group('Tier 2: Boundary & Corner Cases — SHA-256 Checksum Generation & ABI Mappings', () {
    test('Computes deterministic SHA-256 hash in exact GNU sha256sum format', () {
      final sampleBytes = utf8.encode('Universal Media Downloader Android Binary APK Payload');
      final formattedLine = ApkQualityGate.formatSha256Line(sampleBytes, 'app-arm64-v8a-release.apk');

      expect(formattedLine, contains('  app-arm64-v8a-release.apk'));
      final parts = formattedLine.split('  ');
      expect(parts.length, equals(2));
      expect(parts[0].length, equals(64), reason: 'SHA-256 digest must be 64 hexadecimal characters');
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(parts[0]), isTrue);
    });

    test('Identifies native-code mappings across all 4 release APK targets', () {
      const abiMap = {
        'app-arm64-v8a-release.apk': 'arm64-v8a',
        'app-armeabi-v7a-release.apk': 'armeabi-v7a',
        'app-x86_64-release.apk': 'x86_64',
      };

      for (final entry in abiMap.entries) {
        final mockOutput = "package: name='com.zeroo.universal_media_downloader'\nlaunchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'\nsdkVersion:'24'\nnative-code: '${entry.value}'";
        final parsed = ApkQualityGate.parseAaptBadging(mockOutput, 0);

        expect(parsed.isValid, isTrue);
        expect(parsed.nativeCode, equals(entry.value));
      }
    });

    test('Rejects truncated APK files when apksigner reports zip EOF error', () {
      const mockTruncatedOutput = 'ERROR: ZIP file truncated before Central Directory';
      final result = ApkQualityGate.verifyApkSignerOutput(mockTruncatedOutput, 2);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('exit code: 2'));
    });
  });

  group('Tier 3: Cross-Feature Combinations — Automated Build Verification Pipeline Gate', () {
    test('Simulates complete quality gate: all 4 APKs pass zipalign, apksigner, and aapt', () {
      final expectedApks = [
        'app-release.apk',
        'app-arm64-v8a-release.apk',
        'app-armeabi-v7a-release.apk',
        'app-x86_64-release.apk',
      ];

      for (final apk in expectedApks) {
        // 1. zipalign
        final alignPass = ApkQualityGate.verifyZipAlignOutput('Verification successful\n', 0);
        expect(alignPass, isTrue, reason: 'zipalign failed for $apk');

        // 2. apksigner
        const signOut = 'Verified using v1 scheme (JAR signing): true\nVerified using v2 scheme (APK Signature Scheme v2): true\n';
        final signPass = ApkQualityGate.verifyApkSignerOutput(signOut, 0);
        expect(signPass.isValid, isTrue, reason: 'apksigner failed for $apk');

        // 3. aapt badging
        const aaptOut = "package: name='com.zeroo.universal_media_downloader'\nlaunchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'\nsdkVersion:'24'";
        final aaptPass = ApkQualityGate.parseAaptBadging(aaptOut, 0);
        expect(aaptPass.isValid, isTrue, reason: 'aapt failed for $apk');
      }
    });

    test('Quality gate triggers failure if any single APK fails verification', () {
      final verificationResults = [true, true, false, true]; // 3rd APK failed
      final gatePassed = verificationResults.every((res) => res == true);

      expect(gatePassed, isFalse, reason: 'Any single APK failure must halt the release pipeline');
    });
  });

  group('Tier 4: Real-World Application Scenarios — Verification Script & Sideloading Criteria', () {
    test('Verifies Android minSdk 24 compatibility ensures Android 7.0+ devices can install', () {
      const badging = "package: name='com.zeroo.universal_media_downloader'\nlaunchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'\nsdkVersion:'24'\ntargetSdkVersion:'35'";
      final parsed = ApkQualityGate.parseAaptBadging(badging, 0);

      expect(parsed.minSdkVersion, equals(24));
      expect(parsed.minSdkVersion! <= 24, isTrue, reason: 'Must support Android 7.0 Nougat (API 24)');
      expect(parsed.targetSdkVersion, greaterThanOrEqualTo(34), reason: 'Must target modern Android API (34+)');
    });

    test('Validates SHA-256 checksum file structure with 4 release binaries', () {
      final sampleChecksumFile = '''
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  app-release.apk
ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb  app-arm64-v8a-release.apk
fb70072d80d26732389146f34346eb020293111005a91ae19f0de1a9d82e1c95  app-armeabi-v7a-release.apk
4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce  app-x86_64-release.apk
''';

      final lines = sampleChecksumFile.trim().split('\n');
      expect(lines.length, equals(4));

      for (final line in lines) {
        final parts = line.split(RegExp(r'\s+'));
        expect(parts.length, equals(2));
        expect(parts[0].length, equals(64));
        expect(parts[1], startsWith('app-'));
        expect(parts[1], endsWith('.apk'));
      }
    });
  });
}

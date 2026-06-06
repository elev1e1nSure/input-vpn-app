import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.sha256,
    this.releaseNotes,
  });

  final String version;
  final String downloadUrl;

  /// Expected SHA-256 (lowercase hex) of the installer, sourced from the
  /// release. Used to verify integrity before the installer is ever executed.
  final String? sha256;
  final String? releaseNotes;
}

/// Thrown when a downloaded installer fails integrity/authenticity checks.
/// The installer is never executed when this is thrown.
class UpdateVerificationException implements Exception {
  const UpdateVerificationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _latestReleaseUrl =
      'https://api.github.com/repos/elev1e1nSure/input-vpn-app/releases/latest';

  /// Substring expected in the Authenticode signer certificate subject. Set by
  /// the signing setup (Phase 6). When non-empty, the installer's signer must
  /// match or the update is rejected.
  static const String _expectedPublisher = '';

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final response = await _dio.get<dynamic>(
      _latestReleaseUrl,
      options: Options(
        headers: const {'Accept': 'application/vnd.github+json'},
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final data = response.data as Map<String, dynamic>;
    final tag = (data['tag_name'] as String?)?.replaceFirst('v', '');
    if (tag == null || _compareVersions(tag, currentVersion) <= 0) {
      return null;
    }

    final assets =
        (data['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final installer = assets.firstWhere(
      (asset) =>
          (asset['name'] as String?)?.toLowerCase().contains('setup') ?? false,
      orElse: () => <String, dynamic>{},
    );
    final downloadUrl = installer['browser_download_url'] as String?;
    if (downloadUrl == null) {
      return null;
    }

    final sha256Hex = await _resolveExpectedSha256(installer, assets);

    return UpdateInfo(
      version: tag,
      downloadUrl: downloadUrl,
      sha256: sha256Hex,
      releaseNotes: data['body'] as String?,
    );
  }

  /// Resolve the expected SHA-256 for [installer], preferring the GitHub asset
  /// `digest` field (`sha256:...`) and falling back to a published
  /// `checksums.txt` / `*.sha256` asset. Returns null if none is available.
  Future<String?> _resolveExpectedSha256(
    Map<String, dynamic> installer,
    List<Map<String, dynamic>> assets,
  ) async {
    final digest = installer['digest'] as String?;
    if (digest != null && digest.toLowerCase().startsWith('sha256:')) {
      return digest.substring('sha256:'.length).trim().toLowerCase();
    }

    final installerName = (installer['name'] as String?)?.toLowerCase();
    final checksums = assets.firstWhere(
      (a) {
        final n = (a['name'] as String?)?.toLowerCase() ?? '';
        return n == 'checksums.txt' || n.endsWith('.sha256');
      },
      orElse: () => <String, dynamic>{},
    );
    final checksumsUrl = checksums['browser_download_url'] as String?;
    if (checksumsUrl == null) return null;

    try {
      final res = await _dio.get<String>(
        checksumsUrl,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseChecksums(res.data ?? '', installerName);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Parse a `sha256sum`-style file: each line is `<hex>  <filename>`. Returns
  /// the hash for [installerName] if present, otherwise the first hash found
  /// (covers single-line `*.sha256` files).
  static String? _parseChecksums(String body, String? installerName) {
    String? firstHash;
    for (final raw in body.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = RegExp(r'^([0-9a-fA-F]{64})\b\s*\*?(.*)$').firstMatch(line);
      if (m == null) continue;
      final hash = m.group(1)!.toLowerCase();
      firstHash ??= hash;
      final name = m.group(2)!.trim().toLowerCase();
      if (installerName != null && name.endsWith(installerName)) {
        return hash;
      }
    }
    return firstHash;
  }

  Future<String> downloadInstaller(
    UpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('inputvpn-update-');
    final file =
        File('${tempDir.path}${Platform.pathSeparator}InputVPN-Setup.exe');

    await _dio.download(
      info.downloadUrl,
      file.path,
      onReceiveProgress: onProgress,
      options: Options(responseType: ResponseType.bytes),
    );

    // Verify BEFORE the file is ever handed to installAndExit. On any failure
    // the file is deleted and we throw — the installer never runs.
    try {
      await _verifyInstaller(file, info);
    } on UpdateVerificationException {
      try {
        await tempDir.delete(recursive: true);
      } on Exception catch (_) {}
      rethrow;
    }

    return file.path;
  }

  /// Verify the downloaded installer's integrity (SHA-256) and authenticity
  /// (Authenticode signature + publisher). Throws [UpdateVerificationException]
  /// if any check fails.
  Future<void> _verifyInstaller(File file, UpdateInfo info) async {
    // 1) Integrity: SHA-256 must match the hash published with the release.
    final expected = info.sha256;
    if (expected == null || expected.isEmpty) {
      throw const UpdateVerificationException(
        'No published checksum for this release; refusing to run an '
        'unverified installer.',
      );
    }
    final digest = await sha256.bind(file.openRead()).first;
    final actual = digest.toString().toLowerCase();
    if (actual != expected.toLowerCase()) {
      throw UpdateVerificationException(
        'Installer checksum mismatch — download may be corrupt or tampered.\n'
        'Expected: $expected\nActual:   $actual',
      );
    }

    // 2) Authenticity: the installer must carry a valid Authenticode signature
    //    (and, when configured, a matching publisher).
    await _verifyAuthenticode(file.path);
  }

  Future<void> _verifyAuthenticode(String path) async {
    final command =
        "\$s = Get-AuthenticodeSignature -LiteralPath '$path'; "
        "Write-Output \"\$(\$s.Status)|\$(\$s.SignerCertificate.Subject)\"";
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      command,
    ]);
    final out = (result.stdout as String).trim();
    final parts = out.split('|');
    final status = parts.isNotEmpty ? parts.first.trim() : '';
    final subject = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';

    if (status != 'Valid') {
      throw UpdateVerificationException(
        'Installer is not validly signed (Authenticode status: '
        '${status.isEmpty ? 'unknown' : status}). Refusing to run it.',
      );
    }
    if (_expectedPublisher.isNotEmpty &&
        !subject.toLowerCase().contains(_expectedPublisher.toLowerCase())) {
      throw const UpdateVerificationException(
        'Installer signed by an unexpected publisher. Refusing to run it.',
      );
    }
  }

  Future<void> installAndExit(String installerPath) async {
    if (!Platform.isWindows) {
      throw const ProcessException(
          'InputVPN-Setup.exe', [], 'Updates supported only on Windows');
    }

    await Process.start(
      installerPath,
      const [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CLOSEAPPLICATIONS'
      ],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final maxLen =
        aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < maxLen; i++) {
      final aNum = i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
      final bNum = i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;
      if (aNum != bNum) return aNum.compareTo(bNum);
    }
    return 0;
  }
}

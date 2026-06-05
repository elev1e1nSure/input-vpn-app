import 'dart:io';

import 'package:dio/dio.dart';

class UpdateInfo {
  const UpdateInfo(
      {required this.version, required this.downloadUrl, this.releaseNotes});

  final String version;
  final String downloadUrl;
  final String? releaseNotes;
}

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _latestReleaseUrl =
      'https://api.github.com/repos/elev1e1nSure/input-vpn-app/releases/latest';

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

    return UpdateInfo(
      version: tag,
      downloadUrl: downloadUrl,
      releaseNotes: data['body'] as String?,
    );
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

    return file.path;
  }

  Future<void> installAndExit(String installerPath) async {
    if (!Platform.isWindows) {
      throw const ProcessException(
          'InputVPN-Setup.exe', [], 'Updates supported only on Windows');
    }

    await Process.start(
      installerPath,
      const ['/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART'],
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

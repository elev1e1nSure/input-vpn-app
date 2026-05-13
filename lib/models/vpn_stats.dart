/// Throughput sample exposed by the VPN backend.
class VpnStats {
  const VpnStats({
    required this.downloadBytesPerSec,
    required this.uploadBytesPerSec,
    required this.pingMs,
  });
  final double downloadBytesPerSec;
  final double uploadBytesPerSec;
  final int pingMs;

  static const empty = VpnStats(
    downloadBytesPerSec: 0,
    uploadBytesPerSec: 0,
    pingMs: 0,
  );

  String get downloadHuman => _humanize(downloadBytesPerSec);
  String get uploadHuman => _humanize(uploadBytesPerSec);

  static String _humanize(double bps) {
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

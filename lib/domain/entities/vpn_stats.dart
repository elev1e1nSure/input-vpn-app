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
}

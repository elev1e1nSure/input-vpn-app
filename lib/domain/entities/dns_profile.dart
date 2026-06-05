class DnsProfile {
  const DnsProfile({
    required this.id,
    required this.name,
    required this.primary,
    this.secondary,
  });

  final String id;
  final String name;
  final String primary;
  final String? secondary;

  List<String> get servers =>
      [primary, if (secondary != null && secondary!.isNotEmpty) secondary!];
}

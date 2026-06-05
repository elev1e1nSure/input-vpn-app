class NetworkInfoState {
  final String? publicIp;
  final String? countryCode;
  final bool isRefreshing;

  const NetworkInfoState({
    this.publicIp,
    this.countryCode,
    this.isRefreshing = false,
  });

  NetworkInfoState copyWith({
    String? publicIp,
    String? countryCode,
    bool? isRefreshing,
  }) {
    return NetworkInfoState(
      publicIp: publicIp ?? this.publicIp,
      countryCode: countryCode ?? this.countryCode,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

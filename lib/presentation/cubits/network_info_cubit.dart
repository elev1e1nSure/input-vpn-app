import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';
import 'package:input_vpn/domain/usecases/refresh_network_info.dart';
import 'package:input_vpn/presentation/cubits/network_info_state.dart';

class NetworkInfoCubit extends Cubit<NetworkInfoState> {
  NetworkInfoCubit({
    required NetworkInfoRepository networkInfoRepository,
    required RefreshNetworkInfo refreshNetworkInfo,
  })  : _networkInfoRepository = networkInfoRepository,
        _refreshNetworkInfo = refreshNetworkInfo,
        super(const NetworkInfoState()) {
    final publicIpResult = _networkInfoRepository.getPublicIp();
    final countryCodeResult = _networkInfoRepository.getCountryCode();
    emit(NetworkInfoState(
      publicIp: publicIpResult.value,
      countryCode: countryCodeResult.value,
    ));
  }

  final NetworkInfoRepository _networkInfoRepository;
  final RefreshNetworkInfo _refreshNetworkInfo;

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true));
    _refreshNetworkInfo();
    final publicIpResult = _networkInfoRepository.getPublicIp();
    final countryCodeResult = _networkInfoRepository.getCountryCode();
    emit(NetworkInfoState(
      publicIp: publicIpResult.value,
      countryCode: countryCodeResult.value,
    ));
  }

  void clear() {
    _networkInfoRepository.clear();
    emit(const NetworkInfoState());
  }
}

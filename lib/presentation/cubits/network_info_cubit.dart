import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';
import 'package:input_vpn/domain/usecases/refresh_network_info.dart';
import 'package:input_vpn/presentation/cubits/network_info_state.dart';

class NetworkInfoCubit extends Cubit<NetworkInfoState> {
  NetworkInfoCubit({
    required NetworkInfoRepository networkInfoRepository,
    required RefreshNetworkInfo refreshNetworkInfo,
  })  : _networkInfoRepository = networkInfoRepository,
        _refreshNetworkInfo = refreshNetworkInfo {
    emit(NetworkInfoState(
      publicIp: _networkInfoRepository.publicIp,
      countryCode: _networkInfoRepository.countryCode,
    ));
  }

  final NetworkInfoRepository _networkInfoRepository;
  final RefreshNetworkInfo _refreshNetworkInfo;

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true));
    await _refreshNetworkInfo();
    emit(NetworkInfoState(
      publicIp: _networkInfoRepository.publicIp,
      countryCode: _networkInfoRepository.countryCode,
      isRefreshing: false,
    ));
  }

  void clear() {
    _networkInfoRepository.clear();
    emit(const NetworkInfoState());
  }
}

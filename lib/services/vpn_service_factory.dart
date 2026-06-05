import 'dart:io';

import 'package:input_vpn/services/vpn/android/android_vpn_service.dart';
import 'package:input_vpn/services/vpn/fallback/mock_vpn_service.dart';
import 'package:input_vpn/services/vpn/windows/singbox_vpn_service.dart';
import 'package:input_vpn/services/vpn_service.dart';

/// Factory for creating platform-specific [VpnService] instances.
class VpnServiceFactory {
  /// Creates a [VpnService] instance based on the current platform.
  ///
  /// Returns:
  /// - [SingBoxVpnService] on Windows
  /// - [AndroidVpnService] on Android (stub implementation)
  /// - [MockVpnService] on other platforms or when explicitly requested
  static VpnService createVpnService({VpnPlatform? platform}) {
    final targetPlatform = platform ?? _detectPlatform();

    switch (targetPlatform) {
      case VpnPlatform.windows:
        return SingBoxVpnService();
      case VpnPlatform.android:
        return AndroidVpnService();
      case VpnPlatform.mock:
        return MockVpnService();
    }
  }

  /// Detects the current platform based on [Platform].
  static VpnPlatform _detectPlatform() {
    if (Platform.isWindows) {
      return VpnPlatform.windows;
    } else if (Platform.isAndroid) {
      return VpnPlatform.android;
    } else {
      // Fallback to mock for unsupported platforms
      return VpnPlatform.mock;
    }
  }
}

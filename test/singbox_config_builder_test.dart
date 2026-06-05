import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/services/vpn/windows/singbox_config_builder.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';

void main() {
  group('SingBoxConfigBuilder', () {
    const builder = SingBoxConfigBuilder();

    Map<String, dynamic> outboundFor(String shareLink) {
      final p = VpnUrlParser.parse(shareLink);
      return builder.buildJson(p)['outbounds'][0] as Map<String, dynamic>;
    }

    test('VLESS+WS+TLS produces ws transport and tls', () {
      final out = outboundFor(
        'vless://uuid-1@example.com:443'
        '?type=ws&security=tls&sni=example.com&path=%2Fws&host=cdn.example.com'
        '#srv',
      );
      expect(out['type'], 'vless');
      expect(out['server'], 'example.com');
      expect(out['server_port'], 443);
      expect(out['uuid'], 'uuid-1');
      expect(out['transport']['type'], 'ws');
      expect(out['transport']['path'], '/ws');
      expect(out['transport']['headers']['Host'], 'cdn.example.com');
      expect(out['tls']['enabled'], true);
      expect(out['tls']['server_name'], 'example.com');
    });

    test('VLESS REALITY emits reality block', () {
      final out = outboundFor(
        'vless://uuid-2@1.2.3.4:443'
        '?type=tcp&security=reality&pbk=PUBKEY&sid=abcd&fp=chrome'
        '&flow=xtls-rprx-vision#reality',
      );
      expect(out['flow'], 'xtls-rprx-vision');
      expect(out['tls']['reality']['enabled'], true);
      expect(out['tls']['reality']['public_key'], 'PUBKEY');
      expect(out['tls']['reality']['short_id'], 'abcd');
      expect(out['tls']['utls']['fingerprint'], 'chrome');
    });

    test('Trojan defaults to TLS', () {
      final out = outboundFor(
          'trojan://pwd@trojan.example.com:443?sni=trojan.example.com#t');
      expect(out['type'], 'trojan');
      expect(out['password'], 'pwd');
      expect(out['tls']['enabled'], true);
    });

    test('Shadowsocks SIP002 builds shadowsocks outbound', () {
      final userinfo = base64Url.encode(utf8.encode('aes-256-gcm:secret'));
      final out = outboundFor('ss://$userinfo@1.2.3.4:8388#ss');
      expect(out['type'], 'shadowsocks');
      expect(out['method'], 'aes-256-gcm');
      expect(out['password'], 'secret');
      expect(out['server_port'], 8388);
    });

    test('config has TUN inbound and clash_api enabled', () {
      final out = builder.buildJson(VpnUrlParser.parse(
        'vless://uuid@1.2.3.4:443?security=tls#x',
      ));
      final inbound = (out['inbounds'] as List).first as Map<String, dynamic>;
      expect(inbound['type'], 'tun');
      expect(inbound['auto_route'], true);
      expect(inbound['strict_route'], true);

      final exp = out['experimental'] as Map<String, dynamic>;
      expect(exp['clash_api']['external_controller'], '127.0.0.1:9090');
    });

    test('serializes to valid JSON', () {
      final cfg = builder.build(VpnUrlParser.parse(
        'vless://uuid@1.2.3.4:443?security=tls#x',
      ));
      // Re-parse to confirm valid JSON.
      final reparsed = jsonDecode(cfg);
      expect(reparsed, isA<Map<String, dynamic>>());
    });
  });
}

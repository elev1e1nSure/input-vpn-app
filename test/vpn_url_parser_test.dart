import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/models/proxy_type.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';

void main() {
  group('VpnUrlParser', () {
    test('parses VLESS over TLS+WS', () {
      const link =
          'vless://b831381d-6324-4d53-ad4f-8cda48b30811@server.example.com:443'
          '?type=ws&security=tls&sni=server.example.com&path=%2Fws#NL%20Server';
      final c = VpnUrlParser.parse(link);
      expect(c.type, ProxyType.vless);
      expect(c.server, 'server.example.com');
      expect(c.port, 443);
      expect(c.uuid, 'b831381d-6324-4d53-ad4f-8cda48b30811');
      expect(c.network, 'ws');
      expect(c.security, 'tls');
      expect(c.sni, 'server.example.com');
      expect(c.path, '/ws');
      expect(c.remark, 'NL Server');
    });

    test('parses VLESS REALITY', () {
      const link =
          'vless://uuid-1234@1.2.3.4:443?security=reality&pbk=PUBKEY&sid=abcd'
          '&fp=chrome&type=tcp&flow=xtls-rprx-vision#reality';
      final c = VpnUrlParser.parse(link);
      expect(c.security, 'reality');
      expect(c.publicKey, 'PUBKEY');
      expect(c.shortId, 'abcd');
      expect(c.fingerprint, 'chrome');
      expect(c.flow, 'xtls-rprx-vision');
    });

    test('parses VMess base64 JSON', () {
      final body = base64.encode(
        utf8.encode(jsonEncode({
          'v': '2',
          'ps': 'my-vmess',
          'add': 'example.com',
          'port': '443',
          'id': 'vmess-uuid',
          'aid': '0',
          'net': 'ws',
          'type': 'none',
          'host': 'cdn.example.com',
          'path': '/vm',
          'tls': 'tls',
          'sni': 'cdn.example.com',
        })),
      );
      final c = VpnUrlParser.parse('vmess://$body');
      expect(c.type, ProxyType.vmess);
      expect(c.server, 'example.com');
      expect(c.port, 443);
      expect(c.uuid, 'vmess-uuid');
      expect(c.remark, 'my-vmess');
      expect(c.network, 'ws');
      expect(c.path, '/vm');
      expect(c.host, 'cdn.example.com');
    });

    test('parses Shadowsocks SIP002', () {
      final userinfo = base64Url.encode(utf8.encode('aes-256-gcm:secret'));
      final c = VpnUrlParser.parse('ss://$userinfo@1.2.3.4:8388#SS-Test');
      expect(c.type, ProxyType.shadowsocks);
      expect(c.method, 'aes-256-gcm');
      expect(c.password, 'secret');
      expect(c.server, '1.2.3.4');
      expect(c.port, 8388);
      expect(c.remark, 'SS-Test');
    });

    test('parses Shadowsocks legacy', () {
      final whole =
          base64.encode(utf8.encode('aes-256-gcm:secret@1.2.3.4:8388'));
      final c = VpnUrlParser.parse('ss://$whole#Legacy');
      expect(c.method, 'aes-256-gcm');
      expect(c.password, 'secret');
      expect(c.server, '1.2.3.4');
      expect(c.port, 8388);
    });

    test('parses Trojan', () {
      const link =
          'trojan://pa%24sword@trojan.example.com:443?sni=trojan.example.com#Trojan';
      final c = VpnUrlParser.parse(link);
      expect(c.type, ProxyType.trojan);
      expect(c.password, r'pa$sword');
      expect(c.server, 'trojan.example.com');
      expect(c.sni, 'trojan.example.com');
    });

    test('parses Hysteria2', () {
      const link = 'hy2://auth@hy.example.com:443?sni=hy.example.com#HY2';
      final c = VpnUrlParser.parse(link);
      expect(c.type, ProxyType.hysteria2);
      expect(c.password, 'auth');
    });

    test('tryParse returns null on garbage', () {
      expect(VpnUrlParser.tryParse('not a url'), isNull);
      expect(VpnUrlParser.tryParse(''), isNull);
      expect(VpnUrlParser.tryParse('vless://'), isNull);
    });
  });

  group('SubscriptionService.parseContent', () {
    final subs = SubscriptionService();

    test('parses plain newline-separated body', () {
      const body = 'vless://uuid@a.example.com:443?security=tls#a\n'
          'trojan://pwd@b.example.com:443?sni=b#b\n';
      final r = subs.parseContent(body);
      expect(r.configs, hasLength(2));
      expect(r.configs.first.type, ProxyType.vless);
      expect(r.configs[1].type, ProxyType.trojan);
    });

    test('parses base64 wrapped body', () {
      const inner = 'vless://uuid@a.example.com:443?security=tls#a\n'
          'trojan://pwd@b.example.com:443?sni=b#b';
      final encoded = base64.encode(utf8.encode(inner));
      final r = subs.parseContent(encoded);
      expect(r.configs, hasLength(2));
    });

    test('extracts profile-title from inline header comment', () {
      const body = '# profile-title: My Subscription\n'
          'vless://uuid@a.example.com:443#a';
      final r = subs.parseContent(body);
      expect(r.title, 'My Subscription');
    });

    test('parses subscription-userinfo', () {
      const body =
          '# subscription-userinfo: upload=100; download=200; total=1000; expire=1735689600\n'
          'vless://uuid@a.example.com:443#a';
      final r = subs.parseContent(body);
      final info = r.info!;
      expect(info.upload, 100);
      expect(info.download, 200);
      expect(info.total, 1000);
      expect(info.expire, isNotNull);
    });
  });
}

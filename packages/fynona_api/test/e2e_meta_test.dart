@Tags(['e2e'])
library;

import 'dart:io' as io;

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

/// End to end against a running sandbox server (cards client-api criterion 6,
/// client-version criterion 5):
/// `FYNONA_API_URL=http://127.0.0.1:8080 dart test test/e2e_meta_test.dart`.
void main() {
  final baseUrl = io.Platform.environment['FYNONA_API_URL'];
  final skip = baseUrl == null || baseUrl.isEmpty
      ? 'FYNONA_API_URL is not set; start the sandbox server and set it to run this test'
      : false;

  ApiTransport transport({String declared = contractVersion}) {
    final transport = ApiTransport(
      baseUrl: baseUrl!,
      clientVersion: '0.1.0',
      platform: 'linux',
      declaredContractVersion: declared,
    );
    addTearDown(transport.close);
    return transport;
  }

  test(
    'GET /v1/meta serves the contract version this client was built against',
    () async {
      final api = transport();
      final meta = await api.call((api) => api.meta.getMeta());
      expect(meta.apiVersion, 'v1');
      expect(meta.serverVersion, isNotEmpty);
      expect(meta.contractVersion, contractVersion);
      expect(await api.checkContract(), ContractCompatibility.compatible);
    },
    skip: skip,
  );

  test('a client built against major 2 is outdated', () async {
    expect(
      await transport(declared: '2.0.0').checkContract(),
      ContractCompatibility.clientOutdated,
    );
  }, skip: skip);
}

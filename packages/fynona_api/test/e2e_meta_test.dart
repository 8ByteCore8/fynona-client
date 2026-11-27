@Tags(['e2e'])
library;

import 'dart:io' as io;

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

/// End to end against a running server (card client-api criterion 6):
/// `FYNONA_API_URL=http://127.0.0.1:8080 dart test`.
void main() {
  final baseUrl = io.Platform.environment['FYNONA_API_URL'];

  test(
    'GET /v1/meta through the full transport returns api_version v1',
    () async {
      final transport = ApiTransport(
        baseUrl: baseUrl!,
        clientVersion: '0.1.0',
        platform: 'linux',
      );
      addTearDown(transport.close);
      final meta = await transport.call((api) => api.meta.getMeta());
      expect(meta.apiVersion, 'v1');
      expect(meta.serverVersion, isNotEmpty);
    },
    skip: baseUrl == null || baseUrl.isEmpty
        ? 'FYNONA_API_URL is not set; start the sandbox server and set it to run this test'
        : false,
  );
}

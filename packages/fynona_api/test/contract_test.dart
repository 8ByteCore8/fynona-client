import 'dart:io' as io;

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  test('contractVersion equals info.version of api/openapi.yaml', () {
    final spec = io.File('../../api/openapi.yaml').readAsStringSync();
    final version = RegExp(
      r'^info:\n(?:  .*\n)*?  version: (\S+)$',
      multiLine: true,
    ).firstMatch(spec)![1];
    expect(contractVersion, version);
    expect(() => SemVer.parse(contractVersion), returnsNormally);
  });

  group('checkContract over GET /v1/meta', () {
    Future<ContractCompatibility> check(
      Responder responder, {
      String declared = '1.0.0',
    }) => fakeTransport(
      FakeAdapter([responder]),
      declaredContractVersion: declared,
    ).transport.checkContract();

    test('same contract → compatible', () async {
      expect(
        await check(status(200, json: metaJson), declared: contractVersion),
        ContractCompatibility.compatible,
      );
    });

    test('older server minor → server behind', () async {
      expect(
        await check(
          status(200, json: metaWith(server: '1.0.0')),
          declared: '1.4.0',
        ),
        ContractCompatibility.serverBehind,
      );
    });

    test('below min_contract_version → client outdated', () async {
      expect(
        await check(
          status(
            200,
            json: metaWith(server: '1.4.2', minimum: '1.4.1'),
          ),
          declared: '1.4.0',
        ),
        ContractCompatibility.clientOutdated,
      );
    });

    for (final code in [404, 410]) {
      test('$code on /v1/meta → client outdated', () async {
        expect(
          await check(
            status(
              code,
              json: problemJson(code, 'not_found'),
              contentType: 'application/problem+json',
            ),
          ),
          ContractCompatibility.clientOutdated,
        );
        expect(await check(status(code)), ContractCompatibility.clientOutdated);
      });
    }

    test('426 api_version_unsupported → client outdated', () async {
      expect(
        await check(
          status(
            426,
            json: problemJson(426, apiVersionUnsupportedCode),
            contentType: 'application/problem+json',
          ),
        ),
        ContractCompatibility.clientOutdated,
      );
    });

    test('an unparsable contract_version is a typed error', () async {
      await expectLater(
        check(
          status(
            200,
            json: metaWith(server: 'next', minimum: '1.0.0'),
          ),
        ),
        throwsA(isA<ContractVersionException>()),
      );
    });

    test('a server error is no verdict', () async {
      await expectLater(check(status(500)), throwsA(isA<ApiHttpException>()));
    });
  });

  test(
    'any 426 api_version_unsupported is reported on contractRejections',
    () async {
      final adapter = FakeAdapter([
        status(
          426,
          json: problemJson(426, apiVersionUnsupportedCode),
          contentType: 'application/problem+json',
        ),
      ]);
      final transport = fakeTransport(adapter).transport;
      final rejected = transport.contractRejections.first;
      await expectLater(
        transport.call((api) => api.meta.getOpenAPI()),
        throwsA(isA<UpgradeRequiredException>()),
      );
      expect((await rejected).code, apiVersionUnsupportedCode);
    },
  );
}

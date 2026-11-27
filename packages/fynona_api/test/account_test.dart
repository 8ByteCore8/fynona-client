import 'dart:convert';

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

const _profile = <String, Object?>{
  'id': '0193a1b2-0000-7000-8000-0000000000aa',
  'email': 'user@example.com',
  'email_verified': true,
  'display_name': 'Olena',
  'locale': 'uk',
  'display_currency': 'UAH',
  'created_at': '2026-11-27T12:00:00Z',
};

void main() {
  group('account calls with versions (API-23)', () {
    test('getProfile returns the profile and its ETag', () async {
      final adapter = FakeAdapter([
        status(200, json: _profile, headers: {'ETag': '"3"'}),
      ]);
      final t = fakeTransport(adapter);
      final profile = await t.transport.getProfile();
      expect(profile.value.displayName, 'Olena');
      expect(profile.etag, '"3"');
      expect(adapter.requests.single.method, 'GET');
    });

    test(
      'updateProfile sends If-Match, a key and only the changed fields',
      () async {
        final adapter = FakeAdapter([
          status(
            200,
            json: {..._profile, 'display_name': 'O.'},
            headers: {'ETag': '"4"'},
          ),
        ]);
        final t = fakeTransport(adapter);
        final updated = await t.transport.updateProfile(
          const ProfileUpdate(displayName: 'O.'),
          etag: '"3"',
        );
        final request = adapter.requests.single;
        expect(request.method, 'PATCH');
        expect(request.path, '/v1/me');
        expect(request.headers['If-Match'], '"3"');
        expect(request.headers['Idempotency-Key'], isNotNull);
        expect(jsonDecode(request.body!), {'display_name': 'O.'});
        expect(updated.etag, '"4"');
      },
    );

    test(
      'changeEmail sends no Idempotency-Key: the body has a password',
      () async {
        final adapter = FakeAdapter([
          status(200, json: {..._profile, 'pending_email': 'new@example.com'}),
        ]);
        final t = fakeTransport(adapter);
        final changed = await t.transport.changeEmail(
          const EmailChangeRequest(
            email: Email('new@example.com'),
            password: 'pw',
          ),
          etag: '"3"',
        );
        final request = adapter.requests.single;
        expect(request.path, '/v1/me/email');
        expect(request.headers['If-Match'], '"3"');
        expect(request.headers, isNot(contains('Idempotency-Key')));
        expect(changed.value.pendingEmail?.value, 'new@example.com');
      },
    );

    test('downloadExportArchive returns the raw archive', () async {
      final adapter = FakeAdapter([
        status(200, json: {'format': 'fynona-export-v1', 'generated_at': 'x'}),
      ]);
      final t = fakeTransport(adapter);
      final bytes = await t.transport.downloadExportArchive('e1');
      expect(adapter.requests.single.path, '/v1/me/export/e1/archive');
      expect(
        jsonDecode(utf8.decode(bytes)),
        containsPair('format', 'fynona-export-v1'),
      );
    });
  });

  group('402 entitlement.exceeded (MON-4)', () {
    test(
      'is a typed exception naming the entitlement and is broadcast',
      () async {
        final adapter = FakeAdapter([
          status(
            402,
            json: {
              ...problemJson(402, 'entitlement.exceeded'),
              'entitlement': 'connections.max',
            },
            contentType: 'application/problem+json',
          ),
        ]);
        final t = fakeTransport(adapter);
        final seen = <EntitlementExceededException>[];
        final sub = t.transport.entitlementRejections.listen(seen.add);
        addTearDown(sub.cancel);
        await expectLater(
          t.transport.call((api) => api.account.getMe()),
          throwsA(
            isA<EntitlementExceededException>()
                .having((e) => e.entitlement, 'entitlement', 'connections.max')
                .having((e) => e.status, 'status', 402),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(seen.single.entitlement, 'connections.max');
      },
    );

    test('another 402 stays a plain problem and is not broadcast', () async {
      final adapter = FakeAdapter([
        status(
          402,
          json: problemJson(402, 'payment.required'),
          contentType: 'application/problem+json',
        ),
      ]);
      final t = fakeTransport(adapter);
      final seen = <EntitlementExceededException>[];
      final sub = t.transport.entitlementRejections.listen(seen.add);
      addTearDown(sub.cancel);
      await expectLater(
        t.transport.call((api) => api.account.getMe()),
        throwsA(
          isA<ApiProblemException>().having(
            (e) => e is EntitlementExceededException,
            'typed',
            isFalse,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);
    });
  });
}

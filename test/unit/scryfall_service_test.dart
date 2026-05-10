import 'dart:convert';

import 'package:edhtracker/scryfall_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_scryfall_client.dart';

void main() {
  late MockHttpClient client;
  late ScryfallService service;

  setUpAll(() {
    registerHttpFallbacks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockHttpClient();
    service = ScryfallService(client: client);
  });

  group('searchCards', () {
    test('returns empty list for patterns shorter than 3 chars without HTTP', () async {
      final result = await service.searchCardsInstance('ab');
      expect(result, isEmpty);
      verifyNever(() => client.get(any(), headers: any(named: 'headers')));
    });

    test('hits /cards/search for default commander query', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({
              'object': 'list',
              'data': [
                {'name': 'Zur the Enchanter'},
                {'name': 'Zurgo Helmsmasher'},
              ],
            })),
      );

      final names = await service.searchCardsInstance('zur');
      expect(names, ['Zur the Enchanter', 'Zurgo Helmsmasher']);

      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;
      expect(captured.host, 'api.scryfall.com');
      expect(captured.path, '/cards/search');
      expect(captured.queryParameters['q'], 'name:"zur" is:commander');
    });

    test('appends is:partner when isPartner is true', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({'object': 'list', 'data': []})),
      );

      await service.searchCardsInstance('thra', isPartner: true);

      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;
      expect(captured.queryParameters['q'], contains('is:partner'));
    });

    test('uses /cards/autocomplete + catalog parsing for unconventional', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({
              'object': 'catalog',
              'data': ['Cool Card', 'Cooler Card'],
            })),
      );

      final names = await service.searchCardsInstance(
        'coo',
        unconventionalCommanders: true,
      );
      expect(names, ['Cool Card', 'Cooler Card']);

      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;
      expect(captured.path, '/cards/autocomplete');
    });

    test('retries once on 429 and returns the eventual 200', () async {
      var calls = 0;
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async {
        calls++;
        if (calls == 1) return status(429);
        return okJson(jsonEncode({
          'object': 'list',
          'data': [{'name': 'Atraxa, Praetors\' Voice'}],
        }));
      });

      final names = await service.searchCardsInstance('atr');
      expect(names, ['Atraxa, Praetors\' Voice']);
      expect(calls, 2);
    });
  });

  group('getCardArtUrl', () {
    test('returns image_uris.art_crop for a normal card', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({
              'image_uris': {'art_crop': 'https://example.com/atraxa.jpg'},
            })),
      );

      final url = await service.getCardArtUrlInstance('Atraxa, Praetors\' Voice');
      expect(url, 'https://example.com/atraxa.jpg');
    });

    test('returns first card_face image for transform cards', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({
              'card_faces': [
                {
                  'image_uris': {'art_crop': 'https://example.com/front.jpg'},
                },
                {
                  'image_uris': {'art_crop': 'https://example.com/back.jpg'},
                },
              ],
            })),
      );

      final url = await service.getCardArtUrlInstance('Brightclimb Pathway');
      expect(url, 'https://example.com/front.jpg');
    });

    test('caches successful lookups and skips HTTP on second call', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => okJson(jsonEncode({
              'image_uris': {'art_crop': 'https://example.com/cached.jpg'},
            })),
      );

      await service.getCardArtUrlInstance('Krenko, Mob Boss');
      await service.getCardArtUrlInstance('Krenko, Mob Boss');

      verify(() => client.get(any(), headers: any(named: 'headers'))).called(1);
    });

    test('429 retry returns the eventual 200', () async {
      var calls = 0;
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async {
        calls++;
        if (calls == 1) return status(429);
        return okJson(jsonEncode({
          'image_uris': {'art_crop': 'https://example.com/after-retry.jpg'},
        }));
      });

      final url = await service.getCardArtUrlInstance('Sliver Overlord');
      expect(url, 'https://example.com/after-retry.jpg');
      expect(calls, 2);
    });
  });
}

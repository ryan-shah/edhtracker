import 'dart:convert';
import 'package:http/http.dart' as http;

class ScryfallService {
  static Future<List<String>> searchCards(String pattern, {bool isPartner = false}) async {
    if (pattern.length < 3) {
      return Future.value([]);
    }
    String query = 'name:"$pattern" is:commander';
    if (isPartner) {
      query += ' is:partner';
    }

    final uri = Uri.https('api.scryfall.com', '/cards/search', {
      'q': query,
      'order': 'edhrec',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'EDHTracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['object'] == 'list' && data['data'] != null) {
        final cards = data['data'] as List;
        return cards.map((card) => card['name'] as String).toList();
      }
    }
    return [];
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _cacheKey = 'scryfall_art_cache';

class _CacheEntry {
  final String value;
  final DateTime expiry;

  _CacheEntry(this.value, this.expiry);

  // Convert a _CacheEntry to a JSON-serializable map
  Map<String, dynamic> toJson() => {
    'value': value,
    'expiry': expiry.toIso8601String(),
  };

  // Create a _CacheEntry from a JSON map
  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      json['value'] as String,
      DateTime.parse(json['expiry'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class ScryfallService {
  static DateTime? _lastRequestTime;
  static const Duration _minDelay = Duration(milliseconds: 50);
  static const Duration _retryDelay = Duration(milliseconds: 100);
  static const Duration _cacheDuration = Duration(hours: 24);

  static final Map<String, _CacheEntry> _artCropCache = {};
  static bool _cacheInitialized = false;

  // Initialize cache from SharedPreferences
  static Future<void> _initCache() async {
    if (_cacheInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);
    if (cachedString != null) {
      final Map<String, dynamic> decodedCache = json.decode(cachedString);
      _artCropCache.clear();
      decodedCache.forEach((key, value) {
        _artCropCache[key] = _CacheEntry.fromJson(value);
      });
    }
    _cacheInitialized = true;
  }

  // Save cache to SharedPreferences
  static Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serializableCache = {};
    _artCropCache.forEach((key, entry) {
      if (!entry.isExpired) { // Only save non-expired entries
        serializableCache[key] = entry.toJson();
      }
    });
    await prefs.setString(_cacheKey, json.encode(serializableCache));
  }

  static Future<void> _throttleRequests() async {
    // Ensure cache is loaded before any requests that might use it
    await _initCache(); 

    if (_lastRequestTime != null) {
      final now = DateTime.now();
      final timeSinceLastRequest = now.difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minDelay) {
        final delayNeeded = _minDelay - timeSinceLastRequest;
        await Future.delayed(delayNeeded);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  static Future<List<String>> searchCards(String pattern, {bool isPartner = false, int retryCount = 0}) async {
    if (pattern.length < 3) {
      return Future.value([]);
    }

    await _throttleRequests();

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
    } else if (response.statusCode == 429 && retryCount < 1) {
      await Future.delayed(_retryDelay);
      return searchCards(pattern, isPartner: isPartner, retryCount: retryCount + 1);
    }
    return [];
  }

  static Future<String?> getCardArtUrl(String cardName, {int retryCount = 0}) async {
    await _initCache();

    if (_artCropCache.containsKey(cardName) && !_artCropCache[cardName]!.isExpired) {
      return _artCropCache[cardName]!.value;
    }

    await _throttleRequests();

    final uri = Uri.https('api.scryfall.com', '/cards/named', {
      'exact': cardName,
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
      String? artCropUrl;
      // Handle normal cards
      if (data['image_uris'] != null && data['image_uris']['art_crop'] != null) {
        artCropUrl = data['image_uris']['art_crop'] as String;
      }
      // Handle transform cards (double-faced)
      else if (data['card_faces'] != null && data['card_faces'] is List) {
        final faces = data['card_faces'] as List;
        if (faces.isNotEmpty && faces[0]['image_uris'] != null) {
          artCropUrl = faces[0]['image_uris']['art_crop'] as String;
        }
      }

      if (artCropUrl != null) {
        _artCropCache[cardName] = _CacheEntry(artCropUrl, DateTime.now().add(_cacheDuration));
        _saveCache(); // Save cache after modification
      }
      return artCropUrl;
    } else if (response.statusCode == 429 && retryCount < 1) {
      await Future.delayed(_retryDelay);
      return getCardArtUrl(cardName, retryCount: retryCount + 1);
    }
    return null;
  }
}

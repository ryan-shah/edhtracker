import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _cacheKey = 'scryfall_art_cache';

class _CacheEntry {
  final String value;
  final DateTime expiry;

  _CacheEntry(this.value, this.expiry);

  Map<String, dynamic> toJson() => {
    'value': value,
    'expiry': expiry.toIso8601String(),
  };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      json['value'] as String,
      DateTime.parse(json['expiry'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Instance-based Scryfall API client. The default singleton (accessed via
/// the static convenience methods) uses the real http.Client; tests can
/// construct an instance with a mock client.
class ScryfallService {
  static const Duration _minDelay = Duration(milliseconds: 50);
  static const Duration _retryDelay = Duration(milliseconds: 100);
  static const Duration _cacheDuration = Duration(hours: 24);

  static ScryfallService _defaultInstance = ScryfallService();

  /// Replace the default singleton (used by static wrappers). Tests call this
  /// in setUp and restore the original in tearDown.
  static void setDefaultInstance(ScryfallService instance) {
    _defaultInstance = instance;
  }

  static ScryfallService resetDefaultInstance() {
    _defaultInstance = ScryfallService();
    return _defaultInstance;
  }

  final http.Client _client;
  final Map<String, _CacheEntry> _artCropCache = {};
  bool _cacheInitialized = false;
  DateTime? _lastRequestTime;

  ScryfallService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> _initCache() async {
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

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serializableCache = {};
    _artCropCache.forEach((key, entry) {
      if (!entry.isExpired) {
        serializableCache[key] = entry.toJson();
      }
    });
    await prefs.setString(_cacheKey, json.encode(serializableCache));
  }

  Future<void> _throttleRequests() async {
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

  Future<List<String>> searchCardsInstance(
    String pattern, {
    bool isPartner = false,
    int retryCount = 0,
    bool unconventionalCommanders = false,
  }) async {
    if (pattern.length < 3) {
      return Future.value([]);
    }

    await _throttleRequests();

    Uri uri;
    if (unconventionalCommanders) {
      uri = Uri.https('api.scryfall.com', '/cards/autocomplete', {
        'q': pattern,
      });
    } else {
      String query = 'name:"$pattern" is:commander';
      if (isPartner) {
        query += ' is:partner';
      }
      uri = Uri.https('api.scryfall.com', '/cards/search', {
        'q': query,
        'order': 'edhrec',
      });
    }

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'EDHTracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'] is List) {
        if (unconventionalCommanders) {
          if (data['object'] == 'catalog') {
            return (data['data'] as List).map((name) => name as String).toList();
          }
        } else {
          if (data['object'] == 'list') {
            final cards = data['data'] as List;
            return cards.map((card) => card['name'] as String).toList();
          }
        }
      }
    } else if (response.statusCode == 429 && retryCount < 1) {
      await Future.delayed(_retryDelay);
      return searchCardsInstance(
        pattern,
        isPartner: isPartner,
        retryCount: retryCount + 1,
        unconventionalCommanders: unconventionalCommanders,
      );
    }
    return [];
  }

  Future<String?> getCardArtUrlInstance(String cardName, {int retryCount = 0}) async {
    await _initCache();

    if (_artCropCache.containsKey(cardName) && !_artCropCache[cardName]!.isExpired) {
      return _artCropCache[cardName]!.value;
    }

    await _throttleRequests();

    final uri = Uri.https('api.scryfall.com', '/cards/named', {
      'exact': cardName,
    });

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'EDHTracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String? artCropUrl;
      if (data['image_uris'] != null && data['image_uris']['art_crop'] != null) {
        artCropUrl = data['image_uris']['art_crop'] as String;
      } else if (data['card_faces'] != null && data['card_faces'] is List) {
        final faces = data['card_faces'] as List;
        if (faces.isNotEmpty && faces[0]['image_uris'] != null) {
          artCropUrl = faces[0]['image_uris']['art_crop'] as String;
        }
      }

      if (artCropUrl != null) {
        _artCropCache[cardName] = _CacheEntry(artCropUrl, DateTime.now().add(_cacheDuration));
        _saveCache();
      }
      return artCropUrl;
    } else if (response.statusCode == 429 && retryCount < 1) {
      await Future.delayed(_retryDelay);
      return getCardArtUrlInstance(cardName, retryCount: retryCount + 1);
    }
    return null;
  }

  // ---- Static convenience wrappers (delegate to the default singleton). ----

  static Future<List<String>> searchCards(
    String pattern, {
    bool isPartner = false,
    int retryCount = 0,
    bool unconventionalCommanders = false,
  }) {
    return _defaultInstance.searchCardsInstance(
      pattern,
      isPartner: isPartner,
      retryCount: retryCount,
      unconventionalCommanders: unconventionalCommanders,
    );
  }

  static Future<String?> getCardArtUrl(String cardName, {int retryCount = 0}) {
    return _defaultInstance.getCardArtUrlInstance(cardName, retryCount: retryCount);
  }
}

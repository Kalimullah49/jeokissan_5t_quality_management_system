import 'dart:convert';
import 'package:flutter/services.dart';

class QualityTierData {
  final String tier;
  final String attributes;

  QualityTierData({required this.tier, required this.attributes});
}

class CommodityQualityData {
  final String commodityName;
  final List<QualityTierData> tiers;

  CommodityQualityData({
    required this.commodityName,
    required this.tiers,
  });
}

class QualityManualService {
  // Removed singleton pattern to allow fresh instances per language
  
  late Map<String, CommodityQualityData> _commoditiesData;
  bool _isInitialized = false;
  String _currentLanguage = 'en'; // 'en' or 'ur'

  /// Initialize by loading JSON from assets based on language
  /// Supports English (quality_manual_data.json) and Urdu (quality_manual_data_urdu.json)
  Future<void> initialize({String language = 'en'}) async {
    if (_isInitialized && _currentLanguage == language) return;

    try {
      _currentLanguage = language;
      
      // Determine which JSON file to load
      final jsonFileName = language == 'ur' 
        ? 'assets/quality_manual_data_urdu.json'
        : 'assets/quality_manual_data.json';
      
      final jsonString = await rootBundle.loadString(jsonFileName);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      _commoditiesData = {};

      // Parse JSON and build commodity map
      // Format: { "Sindhri": { "tiers": [ { "tier": "Excellent", "attributes": "..." }, ... ] }, ... }
      jsonData.forEach((commodityName, commodityJson) {
        if (commodityJson is Map<String, dynamic>) {
          final tiers = (commodityJson['tiers'] as List<dynamic>? ?? [])
              .map((tierJson) {
                if (tierJson is Map<String, dynamic>) {
                  return QualityTierData(
                    tier: (tierJson['tier'] as String? ?? '').trim(),
                    attributes: (tierJson['attributes'] as String? ?? '').trim(),
                  );
                }
                return null;
              })
              .whereType<QualityTierData>()
              .toList();

          if (tiers.isNotEmpty) {
            _commoditiesData[commodityName.trim()] = CommodityQualityData(
              commodityName: commodityName.trim(),
              tiers: tiers,
            );
          }
        }
      });

      _isInitialized = true;
      final langName = language == 'ur' ? 'Urdu' : 'English';
      print('Quality Manual loaded ($langName): ${_commoditiesData.length} commodities');
    } catch (e) {
      print('Error initializing Quality Manual: $e');
      rethrow;
    }
  }

  /// Search for a commodity by name
  /// Returns the first exact or partial match (case-insensitive)
  /// Supports partial matching: "apple" matches "Apple Ber", "mango" matches any mango variety
  Future<CommodityQualityData?> searchCommodity(String searchQuery) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (searchQuery.trim().isEmpty) {
      return null;
    }

    try {
      final query = searchQuery.toLowerCase().trim();

      // First try exact match
      final exactMatch = _commoditiesData.keys.firstWhere(
        (key) => key.toLowerCase() == query,
        orElse: () => '',
      );

      if (exactMatch.isNotEmpty) {
        return _commoditiesData[exactMatch];
      }

      // Then try partial match
      final partialMatch = _commoditiesData.keys.firstWhere(
        (key) => key.toLowerCase().contains(query),
        orElse: () => '',
      );

      if (partialMatch.isNotEmpty) {
        return _commoditiesData[partialMatch];
      }

      return null;
    } catch (e) {
      print('Error searching commodity: $e');
      return null;
    }
  }

  /// Get all commodities that match the search query (exact and partial)
  Future<List<CommodityQualityData>> searchCommodities(String searchQuery) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (searchQuery.trim().isEmpty) {
      final allCommodities = _commoditiesData.values.toList();
      allCommodities.sort((a, b) => a.commodityName.compareTo(b.commodityName));
      return allCommodities;
    }

    try {
      final query = searchQuery.toLowerCase().trim();

      final matches = _commoditiesData.entries
          .where((entry) => entry.key.toLowerCase().contains(query))
          .map((entry) => entry.value)
          .toList();

      matches.sort((a, b) => a.commodityName.compareTo(b.commodityName));
      return matches;
    } catch (e) {
      print('Error searching commodities: $e');
      return [];
    }
  }

  /// Get all available commodity names
  List<String> getAllCommodities() {
    if (!_isInitialized) return [];
    final list = _commoditiesData.keys.toList();
    list.sort();
    return list;
  }

  /// Get all commodity data sorted by name
  List<CommodityQualityData> getAllCommodityData() {
    if (!_isInitialized) return [];
    final list = _commoditiesData.values.toList();
    list.sort((a, b) => a.commodityName.compareTo(b.commodityName));
    return list;
  }
}

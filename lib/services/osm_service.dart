import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class OSMService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'FlutterRestaurantApp/1.0';

  /// Search for restaurants in Vietnam using OpenStreetMap Nominatim API
  /// 
  /// [query] - The search query (restaurant name or location)
  /// Returns a list of Restaurant objects parsed from OSM data
  Future<List<Restaurant>> searchRestaurants(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Build URL with required parameters
      // countrycodes=vn ensures results are strictly within Vietnam
      // format=json&addressdetails=1 for JSON format with address details
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'countrycodes': 'vn', // Vietnam only
        'limit': '20', // Limit results to 20
        'featuretype': 'amenity', // Focus on amenities (restaurants, cafes, etc.)
      });

      // Make HTTP request with custom User-Agent header (required by OSM usage policy)
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filter for restaurants, cafes, and food-related amenities
        final restaurantTypes = ['restaurant', 'cafe', 'fast_food', 'food_court', 'bar', 'pub'];
        
        final restaurants = data
            .where((item) {
              final type = item['type']?.toString().toLowerCase() ?? '';
              final category = item['class']?.toString().toLowerCase() ?? '';
              return restaurantTypes.contains(type) || 
                     restaurantTypes.contains(category) ||
                     (item['name']?.toString().toLowerCase().contains('nhà hàng') ?? false) ||
                     (item['name']?.toString().toLowerCase().contains('restaurant') ?? false);
            })
            .map((item) => Restaurant.fromOSM(item))
            .toList();

        return restaurants;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Please check User-Agent header.');
      } else {
        throw Exception('Failed to search restaurants: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error searching restaurants: ${e.toString()}');
    }
  }
}


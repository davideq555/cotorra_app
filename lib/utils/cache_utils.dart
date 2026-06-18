import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Utilidad para operaciones de caché con TTL.
/// Maneja persistencia en SharedPreferences y expiración por tiempo.
class CacheUtils {
  /// Obtiene datos en caché si no expiraron.
  /// Retorna null si no hay caché o expiró.
  static Future<T?> get<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    required Duration ttl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null) return null;

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['_timestamp'] as String);
      final elapsed = DateTime.now().difference(timestamp);

      if (elapsed > ttl) {
        await prefs.remove(key);
        return null;
      }

      return fromJson(data);
    } catch (e) {
      await prefs.remove(key);
      return null;
    }
  }

  /// Guarda datos en caché con timestamp.
  static Future<void> set<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = toJson(data);
    json['_timestamp'] = DateTime.now().toIso8601String();
    await prefs.setString(key, jsonEncode(json));
  }

  /// Guarda una lista en caché con timestamp.
  static Future<void> setList<T>({
    required String key,
    required List<T> data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = data.map((item) {
      final json = toJson(item);
      json['_timestamp'] = DateTime.now().toIso8601String();
      return json;
    }).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Obtiene una lista en caché si no expiró.
  static Future<List<T>?> getList<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    required Duration ttl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null) return null;

    try {
      final dataList = jsonDecode(cached) as List;
      if (dataList.isEmpty) return null;

      // Usa el timestamp del primer item (todos tienen el mismo)
      final firstItem = dataList.first as Map<String, dynamic>;
      final timestamp = DateTime.parse(firstItem['_timestamp'] as String);
      final elapsed = DateTime.now().difference(timestamp);

      if (elapsed > ttl) {
        await prefs.remove(key);
        return null;
      }

      return dataList
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await prefs.remove(key);
      return null;
    }
  }

  /// Invalidates (deletes) cached data.
  static Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

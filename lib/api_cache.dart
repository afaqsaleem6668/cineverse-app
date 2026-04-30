/// Global in-memory cache for API responses
/// Data ek baar fetch hota hai, phir cache se milta hai
class ApiCache {
  static final ApiCache _instance = ApiCache._internal();
  factory ApiCache() => _instance;
  ApiCache._internal();

  final Map<String, dynamic> _cache = {};

  bool has(String key) => _cache.containsKey(key);

  T? get<T>(String key) => _cache[key] as T?;

  void set(String key, dynamic value) => _cache[key] = value;

  void clear() => _cache.clear();
}

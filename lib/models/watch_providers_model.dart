import 'dart:convert';

// Watch Providers Model
List<WatchProvider> watchProviderFromJson(String str) =>
    List<WatchProvider>.from(json.decode(str).map((x) => WatchProvider.fromJson(x)));

String watchProviderToJson(List<WatchProvider> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class WatchProvidersResponse {
  final Map<String, ProviderResults> results;

  WatchProvidersResponse({required this.results});

  factory WatchProvidersResponse.fromJson(Map<String, dynamic> json) {
    Map<String, ProviderResults> res = {};
    if (json['results'] != null) {
      (json['results'] as Map<String, dynamic>).forEach((key, value) {
        res[key] = ProviderResults.fromJson(value);
      });
    }
    return WatchProvidersResponse(results: res);
  }
}

class ProviderResults {
  final List<WatchProvider> link;
  final List<WatchProvider> rent;
  final List<WatchProvider> buy;
  final List<WatchProvider> flatrate;

  ProviderResults({
    this.link = const [],
    this.rent = const [],
    this.buy = const [],
    this.flatrate = const [],
  });

  factory ProviderResults.fromJson(Map<String, dynamic> json) {
    return ProviderResults(
      // 'link' is a URL string in TMDB API, not a List — skip it
      link: const [],
      rent: json['rent'] != null && json['rent'] is List
          ? (json['rent'] as List).map((e) => WatchProvider.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      buy: json['buy'] != null && json['buy'] is List
          ? (json['buy'] as List).map((e) => WatchProvider.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      flatrate: json['flatrate'] != null && json['flatrate'] is List
          ? (json['flatrate'] as List)
              .map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class WatchProvider {
  final String? logoPath;
  final int providerId;
  final String providerName;
  final int? displayPriority;

  WatchProvider({
    this.logoPath,
    required this.providerId,
    required this.providerName,
    this.displayPriority,
  });

  factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      logoPath: json['logo_path'],
      providerId: json['provider_id'] ?? 0,
      providerName: json['provider_name'] ?? '',
      displayPriority: json['display_priority'],
    );
  }

  Map<String, dynamic> toJson() => {
        'logo_path': logoPath,
        'provider_id': providerId,
        'provider_name': providerName,
        'display_priority': displayPriority,
      };
}

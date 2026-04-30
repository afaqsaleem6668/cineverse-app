// To parse this JSON data, do
//
//     final tvShowsTrailer = tvShowsTrailerFromJson(jsonString);

import 'dart:convert';

List<TvShowsTrailer> tvShowsTrailerFromJson(String str) => List<TvShowsTrailer>.from(json.decode(str).map((x) => TvShowsTrailer.fromJson(x)));

String tvShowsTrailerToJson(List<TvShowsTrailer> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TvShowsTrailer {
  String iso6391;
  String iso31661;
  String name;
  String key;
  DateTime publishedAt;
  String site;
  int size;
  String type;
  bool official;
  String id;

  TvShowsTrailer({
    required this.iso6391,
    required this.iso31661,
    required this.name,
    required this.key,
    required this.publishedAt,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.id,
  });

  factory TvShowsTrailer.fromJson(Map<String, dynamic> json) => TvShowsTrailer(
    iso6391: json["iso_639_1"] ?? '',
    iso31661: json["iso_3166_1"] ?? '',
    name: json["name"] ?? '',
    key: json["key"] ?? '',
    publishedAt: json["published_at"] != null
        ? DateTime.parse(json["published_at"])
        : DateTime.now(),
    site: json["site"] ?? '',
    size: json["size"] ?? 0,
    type: json["type"] ?? '',
    official: json["official"] ?? false,
    id: json["id"]?.toString() ?? '',  // fix: int → String
  );

  Map<String, dynamic> toJson() => {
    "iso_639_1": iso6391,
    "iso_3166_1": iso31661,
    "name": name,
    "key": key,
    "published_at": publishedAt.toIso8601String(),
    "site": site,
    "size": size,
    "type": type,
    "official": official,
    "id": id,
  };
}

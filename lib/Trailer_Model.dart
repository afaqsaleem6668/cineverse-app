import 'dart:convert';

List<Trailer> trailerFromJson(String str) =>
    List<Trailer>.from(json.decode(str).map((x) => Trailer.fromJson(x)));

String trailerToJson(List<Trailer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Trailer {
  String iso6391;
  String iso31661;
  String name;
  String key;
  String site;
  int size;
  String type;
  bool official;
  DateTime publishedAt;
  String id;

  Trailer({
    required this.iso6391,
    required this.iso31661,
    required this.name,
    required this.key,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.publishedAt,
    required this.id,
  });

  factory Trailer.fromJson(Map<String, dynamic> json) => Trailer(
        iso6391: json["iso_639_1"] ?? '',
        iso31661: json["iso_3166_1"] ?? '',
        name: json["name"] ?? '',
        key: json["key"] ?? '',
        site: json["site"] ?? '',
        size: json["size"] ?? 0,
        type: json["type"] ?? '',
        official: json["official"] ?? false,
        publishedAt: json["published_at"] != null
            ? DateTime.parse(json["published_at"])
            : DateTime.now(),
        id: json["id"]?.toString() ?? '', // fix: int → String
      );

  Map<String, dynamic> toJson() => {
        "iso_639_1": iso6391,
        "iso_3166_1": iso31661,
        "name": name,
        "key": key,
        "site": site,
        "size": size,
        "type": type,
        "official": official,
        "published_at": publishedAt.toIso8601String(),
        "id": id,
      };
}

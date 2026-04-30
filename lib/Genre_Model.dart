// To parse this JSON data, do
//
//     final genre = genreFromJson(jsonString);

import 'dart:convert';

List<Genre> genreFromJson(String str) => List<Genre>.from(json.decode(str).map((x) => Genre.fromJson(x)));

String genreToJson(List<Genre> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Genre {
  int id;
  String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

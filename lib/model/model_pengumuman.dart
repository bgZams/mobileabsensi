import 'dart:convert';

class ModelPengumuman {
  int? id;
  String? title;
  String? date_tgl;
  String? content;
  String? thumbnail;
  String? created_by;
  int? dilihat;

  ModelPengumuman({
    this.id,
    this.title,
    this.date_tgl,
    this.content,
    this.thumbnail,
    this.created_by,
    this.dilihat,
  });

  factory ModelPengumuman.fromJson(Map<String, dynamic> json) {
    return ModelPengumuman(
      id: json['id'],
      title: json['title'],
      date_tgl: json['date_tgl'],
      content: json['content'],
      thumbnail: json['thumbnail'],
      created_by: json['created_by'],
      dilihat: json['dilihat'],
    );
  }

  // Fungsi untuk mendapatkan objek ModelPengumuman dari JSON string
  factory ModelPengumuman.fromJsonString(String jsonString) {
    final jsonData = json.decode(jsonString);
    return ModelPengumuman.fromJson(jsonData);
  }
}

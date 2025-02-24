import 'dart:convert';

class ModelPengumuman {
  int? id;
  String? title;
  String? dateTgl;
  String? content;
  String? thumbnail;
  String? createdBy;
  int? dilihat;

  ModelPengumuman({
    this.id,
    this.title,
    this.dateTgl,
    this.content,
    this.thumbnail,
    this.createdBy,
    this.dilihat,
  });

  factory ModelPengumuman.fromJson(Map<String, dynamic> json) {
    return ModelPengumuman(
      id: json['id'],
      title: json['title'],
      dateTgl: json['dateTgl'],
      content: json['content'],
      thumbnail: json['thumbnail'],
      createdBy: json['createdBy'],
      dilihat: json['dilihat'],
    );
  }

  // Fungsi untuk mendapatkan objek ModelPengumuman dari JSON string
  factory ModelPengumuman.fromJsonString(String jsonString) {
    final jsonData = json.decode(jsonString);
    return ModelPengumuman.fromJson(jsonData);
  }
}

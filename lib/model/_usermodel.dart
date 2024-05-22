// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';
import 'dart:ffi';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    required this.idInstansi,
    required this.idGroups,
    required this.idUser,
    required this.idServer,
    required this.idUserPimpinan,
    required this.idAdminInstansi,
    required this.idPimpinan,
    required this.username,
    required this.usernameAdmin,
    required this.namaLengkap,
    required this.namaInstansi,
    required this.typeOpd,
    required this.validasi,
  });

  Int idInstansi;
  Int idGroups;
  Int idUser;
  Int idServer;
  Int idUserPimpinan;
  Int idAdminInstansi;
  Int idPimpinan;
  String username;
  String usernameAdmin;
  String namaLengkap;
  String namaInstansi;
  String typeOpd;
  String validasi;

  factory User.fromJson(Map<String, dynamic> json) => User(
        idInstansi: json["id_instansi"],
        idGroups: json["id_groups"],
        idUser: json["id_user"],
        idServer: json["id_server"],
        idUserPimpinan: json["id_user_pimpinan"],
        idAdminInstansi: json["id_admin_instansi"],
        idPimpinan: json["id_pimpinan"],
        username: json["username"],
        usernameAdmin: json["username_admin"],
        namaLengkap: json["nama_lengkap"],
        namaInstansi: json["nama_instansi"],
        typeOpd: json["type_opd"],
        validasi: json["validasi"],
      );

  Map<String, dynamic> toJson() => {
        "id_instansi": idInstansi,
        "id_groups": idGroups,
        "id_user": idUser,
        "id_server": idServer,
        "id_user_pimpinan": idUserPimpinan,
        "id_admin_instansi": idAdminInstansi,
        "id_pimpinan": idPimpinan,
        "username": username,
        "username_admin": usernameAdmin,
        "nama_lengkap": namaLengkap,
        "nama_instansi": namaInstansi,
        "type_opd": typeOpd,
        "validasi": validasi,
      };
}

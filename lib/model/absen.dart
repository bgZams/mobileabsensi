import 'dart:convert';

class AbsenModel {
    int? idAbsen;
    DateTime? tglAbsen;
    String? idUser;
    String? idAdminInstansi;
    String? username;
    String? namaLengkap;
    String? instansi;
    DateTime? timestampMasuk;
    String? ssid;
    String? bssid;
    DateTime? timestampPulang;
    String? ssidPulang;
    String? bssidPulang; 
    String? status; 

    AbsenModel({
        this.idAbsen,
        this.tglAbsen,
        this.idUser,
        this.idAdminInstansi,
        this.username,
        this.namaLengkap,
        this.instansi,
        this.timestampMasuk,
        this.ssid,
        this.bssid,
        this.timestampPulang,
        this.ssidPulang,
        this.bssidPulang, 
        this.status, 
    });

    factory AbsenModel.fromJson(Map<String, dynamic> json) {
    return AbsenModel(
      idAbsen: json['idAbsen'],
      tglAbsen: json['tglAbsen'],
      idUser: json['idUser'],
      idAdminInstansi: json['idAdminInstansi'],
      username: json['username'],
      namaLengkap: json['namaLengkap'],
      instansi: json['instansi'],
      timestampMasuk: json['timestampMasuk'],
      ssid: json['ssid'],
      bssid: json['bssid'],
      timestampPulang: json['timestampPulang'],
      ssidPulang: json['ssidPulang'],
      bssidPulang: json['bssidPulang'], 
      status: json['status'], 
    );
  }

    // Fungsi untuk mendapatkan objek AbsenModel dari JSON string
  factory AbsenModel.fromJsonString(String jsonString) {
    final jsonData = json.decode(jsonString);
    return AbsenModel.fromJson(jsonData);
  }
}

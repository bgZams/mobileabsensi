import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sp_util/sp_util.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _isLoading = false;
  var idUser = SpUtil.getString("id_user");
  DateTime? lastFetchTime;

  @override
  void initState() {
    super.initState();
  }

  void _syncData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ambildata();
    } catch (error) {
      if (kDebugMode) {
        print("Error during data synchronization: $error");
      }
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: "Gagal memperbarui data. Coba lagi nanti.",
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // WidgetNavbar positioned at the top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WidgetNavbar(title: 'Profil'),
          ),

          // Profile content container, starting below the navbar but with overlap
          Positioned.fill(
            top: size.height * 0.15, // This value aligns well with a typical AppBar/Navbar height
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                children: [
                  // Header image and logo within the scrollable area
                  // Changed to full width by using a simple Container with DecorationImage
                  Container(
                    width: double.infinity, // Ensures full width
                    height: size.height * 0.2,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: AssetImage('assets/images/profil.png'),
                        fit: BoxFit.cover, // Ensures the image covers the area
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100, // Slightly reduced logo size
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // User Details Card
                  _buildProfileCard(
                    context,
                    icon: Icons.person,
                    title: 'Detail Pengguna',
                    children: [
                      _buildInfoRow('ID Server', SpUtil.getString('id_server') ?? '-'),
                      _buildInfoRow('ID User', SpUtil.getString('id_user') ?? '-'),
                      _buildInfoRow('Username', SpUtil.getString('username') ?? '-'),
                      _buildInfoRow('Nama Lengkap', SpUtil.getString('nama_lengkap') ?? '-'),
                      _buildInfoRow('Nama Instansi', SpUtil.getString('nama_instansi') ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Supervisor Details Card
                  _buildProfileCard(
                    context,
                    icon: Icons.supervisor_account,
                    title: 'Detail Atasan',
                    children: [
                      _buildInfoRow('Nama', SpUtil.getString('nama_atasan') ?? '-'),
                      _buildInfoRow('NIP', SpUtil.getString('nip_atasan') ?? '-'),
                      _buildInfoRow('Jabatan', SpUtil.getString('jabatan_atasan') ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Synchronize Data Button
                  Center(
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.sync_rounded, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Sedang Sinkronisasi...' : 'Sinkronkan Data',
                        style: const TextStyle(fontSize: 14, color: Colors.white), // Font size adjusted
                      ),
                      onPressed: _isLoading ? null : _syncData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        fixedSize: const Size(180, 45), // Slightly smaller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent profile cards
  Widget _buildProfileCard(BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: Colors.pinkAccent,
                  size: 24.0, // Icon size adjusted
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith( // Adjusted text style
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper method to build consistent information rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Vertical padding adjusted
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13, // Font size adjusted
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 13, // Font size adjusted
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> ambildata() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!) < const Duration(minutes: 1)) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          text: "Sinkronisasi data minimal 1 menit sekali!",
        );
      }
      return;
    }

    try {
      http.Response datapegawai = await http.get(
        Uri.parse(
            'https://simpel.pasamanbaratkab.go.id/api_android/simaya/getByIdUser.php?id_user=$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json'
        },
      );

      if (datapegawai.statusCode == 200) {
        var responseData = json.decode(datapegawai.body);
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          var user = responseData['data'][0];
          
          SpUtil.putString('id_server', user['id_server']?.toString() ?? '');
          SpUtil.putString('id_user', user['id_user']?.toString() ?? '');
          SpUtil.putString('id_instansi', user['id_instansi']?.toString() ?? '');
          SpUtil.putString('id_groups', user['id_groups']?.toString() ?? '');
          SpUtil.putString('id_user_pimpinan', user['id_user_parent']?.toString() ?? '');
          SpUtil.putString('id_admin_instansi', user['id_admin_instansi']?.toString() ?? '');
          SpUtil.putString('id_pimpinan', user['id_pimpinan']?.toString() ?? '');
          
          SpUtil.putString('username', (user['username'] as String?)?.replaceAll('"', '') ?? '');
          SpUtil.putString('username_admin', (user['username_admin'] as String?)?.replaceAll('"', '') ?? '');
          SpUtil.putString('nama_lengkap', (user['nama_lengkap'] as String?)?.replaceAll('"', '') ?? '');
          SpUtil.putString('nama_instansi', user['nama_instansi'] ?? '');
          SpUtil.putString('nama_atasan', user['nama_atasan'] ?? '');
          SpUtil.putString('nip_atasan', user['nip_atasan'] ?? '');
          SpUtil.putString('jabatan_atasan', user['jabatan_atasan'] ?? '');
          SpUtil.putString('url', user['url'] ?? '');

          lastFetchTime = DateTime.now();

          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: "Data berhasil diperbarui!",
            );
          }
        } else {
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.info,
              text: "Tidak ada data pengguna ditemukan.",
            );
          }
        }
      } else {
        if (kDebugMode) {
          print("HTTP Error: ${datapegawai.statusCode} - ${datapegawai.body}");
        }
        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            text: "Gagal mengambil data dari server. Kode: ${datapegawai.statusCode}",
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: "Terjadi kesalahan jaringan atau koneksi.",
        );
      }
    }
  }
}
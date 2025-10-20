import 'package:flutter/material.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/admin/berita.dart';
import 'package:mobileabsensi/frontend/admin/kehadiran.dart';
import 'package:mobileabsensi/frontend/admin/pegawai.dart';
import 'package:mobileabsensi/frontend/admin/apel.dart';
import 'package:mobileabsensi/frontend/admin/pengumuman/list.dart';
import 'package:mobileabsensi/frontend/admin/tentang.dart';
import 'package:mobileabsensi/frontend/admin/wifi/list_wifi.dart';
import 'package:sp_util/sp_util.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:  Stack(
          children: [
            Container(
                decoration: const BoxDecoration(
                                image: DecorationImage(image: AssetImage('assets/new/home-header-bg.png'),
                                fit: BoxFit.cover,),
                              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                 const SizedBox(height: 30),

                    Text(SpUtil.getString('nama_lengkap').toString(),style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),),
                        
                 const SizedBox(height: 10),
                
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Pegawai()));
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Pegawai',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                                 InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WifiOpd()));
                        
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.wifi,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          Text('Wifi',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                      ],),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Kehadiran()));
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.login,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Kehadiran',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                                 InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ApelAdmin()));
                        
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Apel',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                      ],),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListPengumuman()));
                          
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.campaign,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Pengumuman',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                                 InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BeritaAdmin()));
                        
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.newspaper,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Berita',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                      ],),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TentangAdmin()));
                        
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.info,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Tentang',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                                 InkWell(
                      onTap: () {
                        SpUtil.clear();
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue.shade100,
                              ),
                              child: const Icon(
                                Icons.exit_to_app,
                                size: 60,
                                color: Color.fromARGB(255, 0, 71, 128),
                              ),
                            ),
                          ),
                          const Text('Keluar',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                      ],),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }
}
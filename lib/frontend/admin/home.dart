import 'package:flutter/material.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/admin/berita.dart';
import 'package:mobileabsensi/frontend/admin/kehadiran.dart';
import 'package:mobileabsensi/frontend/admin/pegawai.dart';
import 'package:mobileabsensi/frontend/admin/apel.dart';
import 'package:mobileabsensi/frontend/admin/pengumuman/list.dart';
import 'package:mobileabsensi/frontend/admin/tentang.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:sp_util/sp_util.dart';

class Admin extends StatefulWidget {
  const Admin({Key? key}) : super(key: key);

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
                                image: DecorationImage(image: AssetImage('assets/images/admin/bg.png'),
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
                          SizedBox(width: 120,height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/pegawai.png'),
                                fit: BoxFit.cover,),
                                
                              ),
                            ),
                          ),
                          const Text('Pegawai',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color:Color.fromARGB(255, 0, 71, 128)),)
                        ],
                      ),
                                  ),
                                 InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListWifi()));
                        
                      },
                      child: Column(
                        children: [
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/wifi.png'),
                                fit: BoxFit.cover,),
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
                          SizedBox(width: 120,height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/masuk.png'),
                                fit: BoxFit.cover,),
                                
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
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/apel.png'),
                                fit: BoxFit.cover,),
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
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/pengumuman.png'),
                                fit: BoxFit.cover,),
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
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/berita.png'),
                                fit: BoxFit.cover,),
                                
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
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/tentang.png'),
                                fit: BoxFit.cover,),
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
                          SizedBox(width: 120,height: 120,
                            child: Container( 
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: const DecorationImage(image: AssetImage('assets/images/admin/exit.png'),
                                fit: BoxFit.cover,),
                                
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
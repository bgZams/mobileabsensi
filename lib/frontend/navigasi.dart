import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/panduan.dart';
import 'package:mobileabsensi/frontend/profile.dart';
import 'package:mobileabsensi/frontend/teknis/list_opd.dart';
import 'package:mobileabsensi/frontend/teknis/list_wifi.dart';
import 'package:mobileabsensi/frontend/tentang.dart';
import 'package:sp_util/sp_util.dart';

class Navigasi extends StatefulWidget {
  const Navigasi({Key? key}) : super(key: key);

  @override
  State<Navigasi> createState() => _NavigasiState();
}

class _NavigasiState extends State<Navigasi> {

  @override
  Widget build(BuildContext context) {
      String namaLengkap = SpUtil.getString('nama_lengkap') ?? '';
      String namaInstansi = SpUtil.getString('nama_instansi') ?? '';
      String idUser = SpUtil.getString('id_user') ?? '';

      if (namaLengkap.length > 30) {
        namaLengkap = '${namaLengkap.substring(0, 30)}...';
        namaInstansi = '${namaInstansi.substring(0, 30)}...';
      }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body:Container(
        color:  const Color.fromARGB(255, 228, 224, 224),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color:  const Color.fromARGB(255, 228, 224, 224),
              child: Padding(padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
                },
                child: Card(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.asset('assets/images/profile.png',width: 50,),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 namaLengkap,
                                 style: const TextStyle(
                                   fontSize: 18,
                                   color: Color.fromARGB(255, 3, 53, 139),
                                   fontWeight: FontWeight.bold,
                                 ),
                                 overflow: TextOverflow.ellipsis,  // Menambahkan overflow untuk memotong teks yang terlalu panjang
                                 maxLines: 1,  // Menentukan maksimal baris teks yang ditampilkan
                               ),
                               Text(
                                 namaInstansi,
                                 style: const TextStyle(
                                   fontSize: 11,
                                   color: Color.fromARGB(255, 3, 53, 139),
                                   fontWeight: FontWeight.bold,
                                 ),
                                 overflow: TextOverflow.ellipsis,  // Menambahkan overflow untuk memotong teks yang terlalu panjang
                                 maxLines: 1,  // Menentukan maksimal baris teks yang ditampilkan
                               ),
                             ],
                           ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ),
          Container(
            color:  const Color.fromARGB(255, 255, 255, 255),
            child:  Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ListWifi()));
                  },
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text('Daftar Wifi'),
                      ),
                    ),
                    Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                    SizedBox(width: 25,)
                  ],
                                  ),
                ),
                Container(height: 2,color: const Color.fromARGB(255, 223, 223, 223),),
                    InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Panduan()));
                  },
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Padding(
                                              padding: EdgeInsets.only(left: 10),
                  
                        child: Text('Panduan'),
                      ),
                    ),
                    Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                    SizedBox(width: 25,)
                                  
                  ],
                                  ),
                ), 
                Container(height: 2,color: const Color.fromARGB(255, 223, 223, 223),),

                    InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Tentang()));
                  },
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Padding(
                                              padding: EdgeInsets.only(left: 10),
                  
                        child: Text('Tentang'),
                      ),
                    ),
                    Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                    SizedBox(width: 25,)
                                  
                  ],
                                  ),
                ),
              ],
            ),
          ),
          Container(
                  color: const Color.fromARGB(255, 228, 224, 224),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Teknis'),
                  ),
                ),
                Container(
            color:  const Color.fromARGB(255, 255, 255, 255),
            child:  Column(
              children: [
                  InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ListOPD()));
                  },
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Padding(
                                              padding: EdgeInsets.only(left: 10),
                        child: Text('OPD'),
                      ),
                    ),
                    Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                    SizedBox(width: 25,)
                  ],
                                  ),
                ),
                Container(height: 2,color: const Color.fromARGB(255, 223, 223, 223),),

                    InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WifiOpd()));
                  },
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Padding(
                                              padding: EdgeInsets.only(left: 10),
                        child: Text('Daftar Wifi OPD'),
                      ),
                    ),
                    Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,color: Color.fromARGB(255, 3, 53, 139),),
                    SizedBox(width: 25,)
                  ],
                                  ),
                ),
              ],
            ),),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Versi Aplikasi 1.1.0',style: TextStyle(color: Colors.blue),),
          ),
          SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined,size: 10,),
                      label: const Text('Keluar',
                        style: TextStyle(
                            fontSize: 16, color: Colors.white, shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1))
                        ],),
                      ),
                      onPressed: (){
                        SpUtil.clear();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
                      },
                      clipBehavior: Clip.hardEdge,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 17, 110, 160),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),),),
                    ),
                  ),
                ),
          ],
        ),
      )
    );
  }
}
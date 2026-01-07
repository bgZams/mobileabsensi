import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/panduan.dart';
import 'package:mobileabsensi/frontend/profile.dart';
import 'package:mobileabsensi/frontend/teknis/list_opd.dart';
import 'package:mobileabsensi/frontend/teknis/list_wifi.dart';
import 'package:mobileabsensi/frontend/tentang.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:sp_util/sp_util.dart';

class Navigasi extends StatefulWidget {
  const Navigasi({super.key});

  @override
  State<Navigasi> createState() => _NavigasiState();
}

class _NavigasiState extends State<Navigasi> {
 

  @override
  Widget build(BuildContext context) {
    String namaLengkap = SpUtil.getString('nama_lengkap') ?? '';
    String namaInstansi = SpUtil.getString('nama_instansi') ?? '';

    if (namaLengkap.length > 30) {
      namaLengkap = '${namaLengkap.substring(0, 30)}...';
      namaInstansi = '${namaInstansi.substring(0, 30)}...';
    }
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background header that extends beyond what's visible
          WidgetNavbar(title: 'Menu'),

          // Scrollable content area taking most of the screen
          Column(
            children: [
              // Spacer to push content down to create overlap
              SizedBox(height: size.height * 0.15),

              // Content area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Container(
                    color: const Color.fromARGB(255, 228, 224, 224),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: const Color.fromARGB(255, 228, 224, 224),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                      Image.asset(
                                        'assets/images/profile.png',
                                        width: 50,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 210,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                namaLengkap,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color.fromARGB(255, 3, 53, 139),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                namaInstansi,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color.fromARGB(255, 3, 53, 139),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Color.fromARGB(255, 3, 53, 139),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 2,
                                color: const Color.fromARGB(255, 223, 223, 223),
                              ),
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
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color.fromARGB(255, 3, 53, 139),
                                    ),
                                    SizedBox(
                                      width: 25,
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                height: 2,
                                color: const Color.fromARGB(255, 223, 223, 223),
                              ),
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
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color.fromARGB(255, 3, 53, 139),
                                    ),
                                    SizedBox(
                                      width: 25,
                                    )
                                  ],
                                ),
                              ),
                              if ([
                                '9025',
                                '4934',
                                '7745',
                                '9024',
                                '9026',
                                '4937'
                              ].contains(SpUtil.getString('id_user')))
                                Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      color: const Color.fromARGB(255, 228, 224, 224),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Teknis'),
                                      ),
                                    ),
                                    Container(
                                      color: const Color.fromARGB(255, 255, 255, 255),
                                      child: Column(
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
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Color.fromARGB(255, 3, 53, 139),
                                                ),
                                                SizedBox(
                                                  width: 25,
                                                )
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 2,
                                            color: const Color.fromARGB(255, 223, 223, 223),
                                          ),
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
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Color.fromARGB(255, 3, 53, 139),
                                                ),
                                                SizedBox(
                                                  width: 25,
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              else
                                Container()
                            ],
                          ),
                        ),
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Center(
                            
                                child: Column(
                                  children: [
                                    Text(
                                                                  'App version 1.0.11',
                                                                  style: TextStyle(color: const Color.fromARGB(255, 186, 0, 0), fontWeight: FontWeight.w200, fontSize: 12),
                                                                ),
                                                                Text(
                            'Dev by Zamaluddin, S.Kom',
                            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.w100, fontSize: 11),
                          )
                                  ],
                                ),),
                         ),  
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 70,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.logout,
                                size: 25,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
                                  ],
                                ),
                              ),
                              onPressed: () {
                                SpUtil.putBool('is_login', false);
                                // SpUtil.clear();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (Route<dynamic> route) => false,
                                );
                              },
                              clipBehavior: Clip.hardEdge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 17, 110, 160),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

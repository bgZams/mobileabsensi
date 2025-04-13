import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/absen/laporan_harian.dart';
import 'package:mobileabsensi/frontend/navigasi.dart';
import 'package:sp_util/sp_util.dart';

class Header {
  Widget header(BuildContext context) {
  String? nama = SpUtil.getString("nama_lengkap").toString();
  String? instansi = SpUtil.getString("nama_instansi").toString();
        Size size = MediaQuery.of(context).size;
    double deviceWidth = MediaQuery.of(context).size.width;

    return Container(
              height: size.height * 0.20,
              width: deviceWidth,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/new/home-header-bg.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Navigasi()),
                        );
                      },
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.08,
                        backgroundImage:
                            const AssetImage('assets/images/profile.png'),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama ?? '',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.03,color: Colors.white
                            ),
                          ),
                          Text(
                            instansi ?? '',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.03,color: Colors.white
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // StreamBuilder<String>(
                    //   stream: _jlhIzinController.stream,
                    //   builder: (context, snapshot) {
                    //     return IconButton(
                    //       icon: SizedBox(
                    //         width: MediaQuery.of(context).size.width * 0.15,
                    //         height: MediaQuery.of(context).size.width * 0.08,
                    //         child: Stack(
                    //           alignment: Alignment.bottomRight,
                    //           children: [
                    //             const Icon(Icons.notifications),
                    //             if (snapshot.hasData && snapshot.data != null)
                    //               Positioned(
                    //                 top: 0,
                    //                 child: Container(
                    //                   padding: const EdgeInsets.all(1),
                    //                   decoration: BoxDecoration(
                    //                     color: Colors.red,
                    //                     borderRadius: BorderRadius.circular(8),
                    //                   ),
                    //                   constraints: BoxConstraints(
                    //                     minWidth:
                    //                         MediaQuery.of(context).size.width *
                    //                             0.05,
                    //                     minHeight:
                    //                         MediaQuery.of(context).size.width *
                    //                             0.05,
                    //                   ),
                    //                   child: Text(
                    //                     notif ?? '0',
                    //                     style: TextStyle(
                    //                       color: Colors.white,
                    //                       fontSize: MediaQuery.of(context)
                    //                               .size
                    //                               .width *
                    //                           0.03,
                    //                     ),
                    //                     textAlign: TextAlign.center,
                    //                   ),
                    //                 ),
                    //               ),
                    //           ],
                    //         ),
                    //       ),
                    //       onPressed: () {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (context) => const KonfirmasiIzin(),
                    //           ),
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
                    IconButton(
                          icon: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.08,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                const Icon(Icons.note_alt, color: Color(0xFFC983DE),size: 40,),
                              ],
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LaporanHarian(),
                              ),
                            );
                          },
                        ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02,
                    ),
                  ],
                ),
              ),
            );
  }
}

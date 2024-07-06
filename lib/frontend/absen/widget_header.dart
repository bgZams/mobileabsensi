import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/frontend/statistik.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';

class Header {
  Widget headerMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 14, 60, 129), width: 3),
          color: const Color.fromARGB(255, 1, 74, 184),
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 14, 60, 129),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.envelope,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Pesan',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 14, 60, 129),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.usersBetweenLines,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Apel()),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Apel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 14, 60, 129),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.wifi,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListWifi()),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Wifi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 14, 60, 129),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Statistik()),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 14, 60, 129),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.bullhorn,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Pengumuman()),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Info',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }
}

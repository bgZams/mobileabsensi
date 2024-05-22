import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:sp_util/sp_util.dart';

class Navigasi extends StatelessWidget {
  const Navigasi({Key? key}) : super(key: key);

  final title = "Menu";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        itemCount: choices.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: ChoiceCard(
              choice: choices[index],
              onTap: () {
                // Navigate to the corresponding screen based on the selected choice
                switch (index) {
                  case 0: // Profil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(),
                      ),
                    );
                    break;
                  case 1: // Daftar Wifi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListWifi(),
                      ),
                    );
                    break;
                  case 2: // Daftar Wifi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListWifi(),
                      ),
                    );
                    break;
                  case 3: // Daftar Wifi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListWifi(),
                      ),
                    );
                    break;
                  case 4: // Daftar Wifi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListWifi(),
                      ),
                    );
                    break;
                  case 5: // Daftar Wifi
                    SpUtil.getInstance().then((sp) {
                      SpUtil.clear()?.then((success) {
                        if (success) {
                          // if (kDebugMode) {
                          //   print('Cache cleared successfully.'); 
                          // }
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()),
                            );
                        } else {
                          if (kDebugMode) {
                            print('Failed to clear cache.');
                          }
                        }
                      }).catchError((error) {
                        if (kDebugMode) {
                          print('Error: $error');
                        }
                      });
                    }).catchError((error) {
                      if (kDebugMode) {
                        print(
                            'Error getting SharedPreferences instance: $error');
                      }
                    });

                    break;

                  // Add cases for other choices here
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class Choice {
  const Choice({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

List<Choice> choices = <Choice>[
  const Choice(title: 'Profil', icon: Icons.person),
  const Choice(title: 'Daftar Wifi', icon: Icons.wifi),
  const Choice(title: 'Kendala Absen', icon: Icons.warning_amber),
  const Choice(title: 'Panduan', icon: Icons.book),
  const Choice(title: 'Tentang', icon: Icons.abc_outlined),
  const Choice(title: 'Keluar', icon: Icons.logout),
];

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    Key? key,
    required this.choice,
    required this.onTap,
  }) : super(key: key);

  final Choice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    TextStyle? textStyle = Theme.of(context).textTheme.headline6;
    return InkWell(
      onTap: onTap,
      child: Card(
        color: const Color.fromARGB(255, 236, 236, 236),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                choice.icon,
                size: 60.0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 25),
                child: Text(
                  choice.title,
                  style: textStyle,
                  textAlign: TextAlign.left,
                  maxLines: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

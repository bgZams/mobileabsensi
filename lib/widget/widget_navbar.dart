import 'package:flutter/material.dart';

class WidgetNavbar extends StatefulWidget {
  final String title;
  const WidgetNavbar({super.key, required this.title,});

  @override
  WidgetNavbarState createState() => WidgetNavbarState();
}

class WidgetNavbarState extends State<WidgetNavbar> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {

        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceWidth = size.width;
    return Container( 
      height: size.height * 0.20,
      width: deviceWidth,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/new/home-header-bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 15,),
            SizedBox(
            width: 40,
            height: 40,
            child: InkWell(
              onTap: () {
              Navigator.maybePop(context);
              },
              splashColor: const Color.fromARGB(60, 179, 2, 218),
              highlightColor: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              child: Center(
              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
            ),
          SizedBox(width: deviceWidth * 0.05),
          Text(widget.title, style: TextStyle(color: Colors.white,fontSize: 18),)
        ],
      ),
    );
  }
}

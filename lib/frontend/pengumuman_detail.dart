import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sp_util/sp_util.dart';
import 'dart:convert';

class DetailPengumuman extends StatefulWidget {
  final int postId;

  const DetailPengumuman({super.key, required this.postId});

  @override
  State<DetailPengumuman> createState() => _DetailPengumumanState();
}

class _DetailPengumumanState extends State<DetailPengumuman> {
  var url = SpUtil.getString("url");
  late Future<Map<String, dynamic>> _pengumumanFuture;

  @override
  void initState() {
    super.initState();
    _pengumumanFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$url/api/pengumuman-detail/${widget.postId}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );


      if (response.statusCode == 200) {

        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (error) {
      throw Exception('Gagal memuat data');
    }
  }

  @override
  Widget build(BuildContext context) {
        double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Detail Pengumuman',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
         leading: IconButton(
              icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
                    height: deviceHeight * 1.2,
          color:const Color.fromARGB(255, 240, 239, 239),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _pengumumanFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final pengumuman = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       pengumuman['thumbnail'] == null ?
                        Container()
                        :
                        Image.network(pengumuman['thumbnail']) 
                        ,
                        const SizedBox(height: 16),
                        Text(
                          pengumuman['title'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Row(children: [
                              const Icon(Icons.remove_red_eye,color: Colors.blue,),
                              Text(
                              '${pengumuman['dilihat']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            ],),
                            const SizedBox(width: 15,),
                            Text(
                              'Tanggal: ${pengumuman['date_tgl']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pengumuman['content'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dibuat oleh: ${pengumuman['created_by']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

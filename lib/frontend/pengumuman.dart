import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/pengumuman_detail.dart';
import 'package:mobileabsensi/model/model_pengumuman.dart';
import 'package:sp_util/sp_util.dart';

class Pengumuman extends StatefulWidget {
  const Pengumuman({Key? key}) : super(key: key);

  @override
  State<Pengumuman> createState() => _PengumumanState();
}

class _PengumumanState extends State<Pengumuman> {
  var url = SpUtil.getString("url");
  Future<List<ModelPengumuman>>? postsFuture;
  late String domain;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() {
      // _isLoading = true;
      postsFuture = getPosts();
    });
  }

  Future<List<ModelPengumuman>> getPosts() async {
    http.Response response = await http.get(
      Uri.parse('$url/api/pengumuman'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);

      return body.map((e) => ModelPengumuman.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<ModelPengumuman>>(
          future: postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              final posts = snapshot.data!;
              return buildPosts(posts);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            } else {
              return const Text("No data available");
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          refreshData();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget buildPosts(List<ModelPengumuman> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPengumuman(postId: post.id ?? 0),
              ),
            );
          },
          child: Container(
  color: Colors.grey.shade300,
  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 1,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top:15),
            child: Image.network(
              post.thumbnail ?? "assets/images/logo.png",
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                post.title ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Row(
                children: [
                  const Icon(
                  Icons.calendar_month_sharp,
                  color: Colors.red,
                  size: 20,
                ),
                  Text(
                    post.date_tgl ?? "",
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.remove_red_eye,
                  color: Colors.blue,
                  size: 20,
                ),
                Text(
                  "Dilihat: ${post.dilihat.toString() ?? ''}",
                ),
              ],
            )
          ],
        ),
      ),
    ],
  ),
),


        );
      },
    );
  }
}

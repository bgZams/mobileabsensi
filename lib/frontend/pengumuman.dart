import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/pengumuman_detail.dart';
import 'package:mobileabsensi/model/model_pengumuman.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/services/refresh.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:sp_util/sp_util.dart';

class Pengumuman extends StatefulWidget {
  const Pengumuman({super.key});

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
    if (SyncLimiter.canSync()) {
      if (mounted) {
        setState(() {
          postsFuture = getPosts();
        });
      }
    } else {
      if (mounted) {
        Alert.alertwarning(context, "Refresh maksimal 3 kali dalam 1 menit!");
      }
    }
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
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background header that extends beyond what's visible
          Header().header(context),

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
                  child: FutureBuilder<List<ModelPengumuman>>(
                    future: postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasData) {
                        final posts = snapshot.data!;
                        return buildPosts(posts);
                      } else if (snapshot.hasError) {
                        return Center(child: Text("${snapshot.error}"));
                      } else {
                        return const Center(
                            child: Text("No data available"));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    post.thumbnail ?? "",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "assets/images/logo.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_sharp,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            post.dateTgl ?? "",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Dilihat: ${post.dilihat.toString()}",
                          ),
                        ],
                      ),
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

// import 'dart:io';

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:skripsi_app/api_service.dart';
import 'package:skripsi_app/auth_page.dart';

import 'const.dart';
import 'register_mhs.dart';
// import 'package:skripsi_app/register_mhs.dart';

class Dashboard_Mahasiswa extends StatefulWidget {
  const Dashboard_Mahasiswa({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<Dashboard_Mahasiswa> createState() => _Dashboard_mahasiswaState();
}

class _Dashboard_mahasiswaState extends State<Dashboard_Mahasiswa> {
  final ServiceKu _apiService = ServiceKu();

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/bg_auth.png"),  fit: BoxFit.cover)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              // height: 370,
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    margin: const EdgeInsets.all(20),
                    child: Image.asset(
                      "assets/logo_ups.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      "Selamat Datang!",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: darkblue),
                      maxLines: 5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const SizedBox(
                    // height: 400,
                    width: double.infinity,
                    child: Text(
                      "Mahasiswa :",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: darkblue),
                      maxLines: 5,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      // height: 400,
                      width: double.infinity,
                      child: Text(
                        "${widget.user['username']}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: darkblue),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      // height: 400,
                      width: double.infinity,
                      child: Text(
                        "${widget.user['npm']}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: darkblue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            CommonButton(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CameraCapture(
                                npm: widget.user['npm'],
                                username: widget.user['username'],
                              )));
                },
                text: "Perbarui Data Wajah",
                isLoginButton: false),
            Spacer(),
            ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(yellow),
                    foregroundColor: WidgetStatePropertyAll(darkblue)),
                onPressed: () async {
                  await _apiService.box.remove('user');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("Keluar")),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      )),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  "assets/bg_dashboard.png",
                  fit: BoxFit.cover,
                )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Text(
                      "Data Presensi ${widget.user['username']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkblue),
                    )),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _apiService.firestore
                        .collection('attendance')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final raw = snapshot.data;
                        if (raw == null) {
                          return const Center(
                            child: Text("no data"),
                          );
                        }
                        final data = raw.docs
                            .where(
                              (element) => element['npm'] == widget.user['npm'],
                            )
                            .toList();

                        return SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                              data.length,
                              (index) {
                                final absen = data[index].data();
                                Uint8List bytes =
                                    base64Decode(absen['photo_base64']);
                                // var date = DateTime.fromMillisecondsSinceEpoch(absen['createdAt'] * 1000);

                                return Container(
                                  // width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      color: Colors.white),
                                  child: Column(
                                    children: [
                                      Image.memory(
                                        bytes,
                                        fit: BoxFit.contain,
                                        // width: double.infinity,
                                        height: 250,
                                      ),
                                      ListTile(
                                        title: Text(
                                          absen['username'],
                                          style:
                                              const TextStyle(color: darkblue),
                                        ),
                                        subtitle: Text(
                                            formatTimestamp(absen['createdAt']),
                                            style: const TextStyle(
                                                color: darkblue)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return const Center(
                        child: Text("error"),
                      );
                    },
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

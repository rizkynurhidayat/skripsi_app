import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'api_service.dart';
import 'auth_page.dart';
import 'const.dart';

class Dashboard_Dosen extends StatefulWidget {
  const Dashboard_Dosen({super.key});

  @override
  State<Dashboard_Dosen> createState() => _Dashboard_DosenState();
}

class _Dashboard_DosenState extends State<Dashboard_Dosen> {
  final ServiceKu _apiService = ServiceKu();
  final mulaiController = TextEditingController();
  final selesaiController = TextEditingController();
  TimeOfDay? mulai;
  TimeOfDay? selesai;
  bool isWrongTime = false;
  bool isExecuteStream = false;
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MM/dd/yyyy, hh:mm a').format(dateTime);
  }

  bool compareTime() {
    if (mulai != null && selesai != null) {
      // Konversi ke menit untuk memudahkan perbandingan
      int mulaiMenit = mulai!.hour * 60 + mulai!.minute;
      int selesaiMenit = selesai!.hour * 60 + selesai!.minute;
      return isWrongTime = selesaiMenit <= mulaiMenit;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: Expanded(
          child: Stack(
            children: [
              SizedBox(
                  width: width,
                  height: height,
                  child: Image.asset(
                    "assets/bg_auth.png",
                    fit: BoxFit.cover,
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    SizedBox(
                      height: 350,
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
                            child: Center(
                              child: Text(
                                "Aplikasi Presensi Mahasiswa\nProdi Informatika\nUniversitas Pancasakti Tegal",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: darkblue),
                                maxLines: 5,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(yellow),
                            foregroundColor: WidgetStatePropertyAll(darkblue)),
                        onPressed: () async {
                          await _apiService.box.remove('user');
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyHomePage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: const Text("Keluar")),
                    const SizedBox(
                      height: 50,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
                width: width,
                height: height,
                child: Image.asset(
                  "assets/bg_dashboard.png",
                  fit: BoxFit.cover,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        "Isi data waktu mata kuliah",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkblue),
                      )),
                  SizedBox(
                    width: width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "  Mulai",
                              style: TextStyle(color: darkblue),
                            ),
                            Container(
                              width: width / 2 - 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white,
                                  border: (isWrongTime == true)
                                      ? Border.all(color: Colors.red)
                                      : null),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              child: InkWell(
                                onTap: () async {
                                  final timePicked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: darkblue, // Warna utama
                                            onPrimary: Colors
                                                .white, // Warna teks pada primary
                                            surface: Colors
                                                .white, // Warna background
                                            onSurface:
                                                darkblue, // Warna teks pada surface
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (timePicked != null) {
                                    mulai = timePicked;
                                    final hour =
                                        mulai!.hour.toString().padLeft(2, '0');
                                    final minute = mulai!.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    mulaiController.text = '$hour:$minute';
                                    setState(() {
                                      // Format waktu ke format 24 jam (HH:mm)

                                      // mulai = mulai;
                                    });
                                  }
                                },
                                child: TextField(
                                  controller: mulaiController,
                                  enabled:
                                      false, // Membuat TextField tidak bisa diedit langsung
                                  decoration: InputDecoration(
                                    hintText: "Mulai",
                                    prefixIcon: Icon(Icons.access_time,
                                        color: (isWrongTime == true)
                                            ? Colors.red
                                            : darkblue),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "  Selesai",
                              style: TextStyle(color: darkblue),
                            ),
                            Container(
                              width: width / 2 - 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                border: (isWrongTime == true)
                                    ? Border.all(color: Colors.red)
                                    : null,
                              ),
                              //
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              child: InkWell(
                                onTap: () async {
                                  final timePicked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: darkblue, // Warna utama
                                            onPrimary: Colors
                                                .white, // Warna teks pada primary
                                            surface: Colors
                                                .white, // Warna background
                                            onSurface:
                                                darkblue, // Warna teks pada surface
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (timePicked != null) {
                                    selesai = timePicked;
                                    print("mulai :" + mulai.toString());
                                    print("selesai :" + selesai.toString());
                                    isWrongTime = compareTime();
                                    final hour = selesai!.hour
                                        .toString()
                                        .padLeft(2, '0');
                                    final minute = selesai!.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    selesaiController.text = '$hour:$minute';
                                    setState(() {
                                      // isWrongTime = false;
                                      // Format waktu ke format 24 jam (HH:mm)

                                      // selesai = selesai;
                                    });
                                  }
                                },
                                child: TextField(
                                  controller: selesaiController,
                                  enabled:
                                      false, // Membuat TextField tidak bisa diedit langsung
                                  decoration: InputDecoration(
                                      hintText: "Selesai",
                                      prefixIcon: Icon(Icons.access_time,
                                          color: (isWrongTime == true)
                                              ? Colors.red
                                              : darkblue),
                                      border: InputBorder.none,
                                      fillColor: (isWrongTime == true)
                                          ? Colors.red
                                          : darkblue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  CommonButton(
                      onTap: () {
                        if (mulai != null && selesai != null) {
                          if (!isWrongTime) {
                            isExecuteStream = true;
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'waktu yang dipilih salah !!!',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Isi waktu mata kuliah terlebih dahulu !!!',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      text: "lihat data presensi",
                      isLoginButton: false),
                  Expanded(
                    child: (!isExecuteStream)
                        ? const SizedBox()
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                                final data = raw.docs;

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
                                              borderRadius:
                                                  BorderRadius.circular(13),
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
                                                  style: const TextStyle(
                                                      color: darkblue),
                                                ),
                                                subtitle: Text(
                                                    formatTimestamp(
                                                        absen['createdAt']),
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
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mulaiController.dispose();
    selesaiController.dispose();
    super.dispose();
  }
}

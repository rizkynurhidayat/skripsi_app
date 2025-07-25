// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skripsi_app/api_service.dart';
import 'package:skripsi_app/const.dart';
import 'package:skripsi_app/dashboard_dsn.dart';
import 'package:skripsi_app/dashboard_mhs.dart';

// import 'presensi.dart';
import 'presensi.dart';
import 'preview_image.dart';
// import 'register_mhs.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _npmCOntroller = TextEditingController();
  final namaController = TextEditingController();
  final ServiceKu api = ServiceKu();
  bool isDataset = false;
  String username = '';
  String npm = '';
  List<String> datasetList = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.microtask(() => init());
  }

  void init() async {
    final data = await api.getUsrData();
    final dataset = await api.getDataset();
    final usr_temp = await api.getUsername();
    final npm_temp = await api.getNpm();

    if (dataset != null && usr_temp != null && npm_temp != null) {
      datasetList = dataset.map((e) => e.toString()).toList();
      print(dataset);
      username = usr_temp;
      npm = npm_temp;
      if (datasetList.length != 0) {
        isDataset = true;
      }
      setState(() {});
    }
    if (data != null && data['npm'] != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => Dashboard_Mahasiswa(
                  user: data,
                )),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    namaController.dispose();
    _npmCOntroller.dispose();
    _usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Home Page')),
      // extendBody: true,
      body: Stack(
        // alignment: Alignment.center,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Image.asset(
                  "assets/bg_auth.png",
                  fit: BoxFit.cover,
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Container(
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
                          child: Center(
                            child: Text(
                              "Selamat Datang!",
                              style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w900,
                                  color: darkblue),
                              maxLines: 5,
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                  const SizedBox(
                    height: 50,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration.collapsed(
                        hintText: "NPM",
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CommonButton(
                      onTap: () {
                        if (_usernameController.text == '') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'TOLONG ISI NPM TELEBIH DAHULU !!!',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        if (_usernameController.text == "admin") {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Dashboard_Dosen()),
                            (Route<dynamic> route) => false,
                          );
                        } else if (_usernameController.text == "presensi") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PresensiPage()),
                          );
                        } else {
                          final api = ServiceKu();
                          api.authMhs(_usernameController.text).then((value) {
                            if (value['status'] == false) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('NPM tidak terdaftar di database'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Login Berhasil'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Dashboard_Mahasiswa(
                                          user: value['data'],
                                        )),
                                (Route<dynamic> route) => false,
                              );
                            }
                          });
                        }
                      },
                      text: "Masuk",
                      isLoginButton: true),
                  const SizedBox(
                    height: 10,
                  ),
                  Builder(
                    builder: (context) {
                      if (isDataset) {
                        return TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ImagePreview(
                                          images: datasetList,
                                          npm: npm,
                                          username: username)));
                            },
                            child: const Text(
                              "Lanjutkan kirim data wajah",
                            ));
                      } else {
                        return SizedBox();
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
  CommonButton(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            final TextEditingController ipController =
                                TextEditingController();
                            return AlertDialog(
                              title: const Text(
                                'Isi Alamat IP ESP',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: yellow,
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 15),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(200),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: ipController,
                                      keyboardType: TextInputType.number,
                                      decoration:
                                          const InputDecoration.collapsed(
                                        hintText:
                                            "Alamat IP (misal: 192.168.1.10)",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: const ButtonStyle(
                                    backgroundColor:
                                        WidgetStatePropertyAll(darkblue),
                                    foregroundColor:
                                        WidgetStatePropertyAll(Colors.white),
                                  ),
                                  onPressed: () async {
                                    String ip = ipController.text.trim();
                                    final ipRegex = RegExp(
                                        r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}
*/

//dialog daftar lama
/*
showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                'Daftar',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: yellow,
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 15),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(200),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: namaController,
                                      decoration:
                                          const InputDecoration.collapsed(
                                        hintText: "NAMA",
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 15),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(200),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: _npmCOntroller,
                                      keyboardType: TextInputType.number,
                                      decoration:
                                          const InputDecoration.collapsed(
                                        hintText: "NPM",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: const ButtonStyle(
                                    backgroundColor:
                                        WidgetStatePropertyAll(darkblue),
                                    foregroundColor:
                                        WidgetStatePropertyAll(Colors.white),
                                  ),
                                  onPressed: () {
                                    if (namaController.text != '' &&
                                        _npmCOntroller.text != '') {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => CameraCapture(
                                                  npm: _npmCOntroller.text,
                                                  username: namaController.text,
                                                )),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'TOLONG ISIKAN NAMA DAN NPM!!!'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Daftar'),
                                ),
                              ],
                            );
                          },
                        );
*/
//end dialog

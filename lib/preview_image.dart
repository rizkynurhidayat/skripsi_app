import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:skripsi_app/dashboard_mhs.dart';

import 'api_service.dart';
import 'auth_page.dart';
import 'package:image/image.dart' as img;

import 'const.dart';

class ImagePreview extends StatefulWidget {
  final List<String> images;
  final String npm;
  final String username;
  // final bool? isUpdate;

  const ImagePreview({
    required this.images,
    required this.npm,
    required this.username,
  });

  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool isLoading = false;
  final ServiceKu apiService = ServiceKu();
  List<String> base64Images = [];
  final box = GetStorage();

  Future<void> sendImagesToServer(
    List<String> imageList,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final message =
          await apiService.register(imageList, widget.username, widget.npm);

      if (message != null) {
        Navigator.pop(context); // Tutup dialog loading
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () async {
          await box.remove("dataset");
          await box.remove("username_temp");
          await box.remove("npm_temp");
          final data = await box.read('user');
          if (data != null && data['npm'] != null) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Dashboard_Mahasiswa(
                          user: data,
                        )));
          }
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const MyHomePage()));
        });
      }
    } catch (e) {
      Navigator.pop(context); // Tutup dialog loading
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<String>> convertImagesToBase64(List<String> images) async {
    List<String> base64Images = [];
    for (var image in images) {
      final File a = File(image);
      final bytes = await a.readAsBytes();
      // Menggunakan library 'image' untuk membalik gambar secara horizontal
      final img.Image imgImage = img.decodeImage(bytes)!;
      final img.Image flippedImage = img.flipHorizontal(imgImage);
      final flippedBytes = img.encodeJpg(flippedImage);
      final base64Image = base64Encode(flippedBytes);
      base64Images.add(base64Image);
    }
    await box.write('username_temp', widget.username);
    await box.write('npm_temp', widget.npm);
    await box.write("dataset", widget.images);
    return base64Images;
  }

  // @override
  // void initState() {
  //   super.initState();

  // }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: yellow,
      appBar: AppBar(
        title: Text('Preview Gambar'),
      ),
      body: SafeArea(
          child: FutureBuilder(
              future: convertImagesToBase64(widget.images),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              itemCount: widget.images.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 150,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                topRight: Radius.circular(15)),
                                            image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: FileImage(
                                                  File(widget.images[index]),
                                                ))),
                                      ),
                                      Container(
                                        height: 20,
                                        child: Center(
                                          child: Text("Gambar ke ${index+1}"),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                              height: 80,
                              color: yellow,
                              child: Center(
                                  child: CommonButton(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: yellow,
                                              title: Text(
                                                "Konfirmasi",
                                                style:
                                                    TextStyle(color: darkblue),
                                              ),
                                              content: Text(
                                                "Apakah Anda yakin ingin mengirim gambar?",
                                                style:
                                                    TextStyle(color: darkblue),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text(
                                                    "Batal",
                                                    style: TextStyle(
                                                        color: darkblue),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              darkblue),
                                                  child: Text(
                                                    "Kirim",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  onPressed: () async {
                                                    Navigator.of(context).pop();
                                                    // final imageList = .map((e) => File(e.path)).toList();

                                                    await sendImagesToServer(
                                                        data);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      text: "kirim",
                                      isLoginButton: false)))
                        ],
                      ));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Memuat gambar...",
                          style: TextStyle(
                            fontSize: 22,
                          ),
                        ),
                        CircularProgressIndicator(
                          color: darkblue,
                        )
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text("Error"),
                );
              })),
    );
  }
}

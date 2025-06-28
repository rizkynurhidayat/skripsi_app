import 'dart:convert';
import 'dart:io';
// import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:skripsi_app/api_service.dart';
import 'package:image/image.dart' as img;
import 'package:skripsi_app/auth_page.dart';

import 'const.dart';
import 'preview_image.dart';
// import 'package:http/http.dart' as http;

class CameraCapture extends StatefulWidget {
  const CameraCapture({
    required this.npm,
    required this.username,
    // this.isUpdate,
    Key? key,
  }) : super(key: key);
  final String username;
  final String npm;
  // final bool? isUpdate;
  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  final ServiceKu apiService = ServiceKu();
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool isReady = false;
  bool isLoading = false;
  String? capturedImagePath;

  @override
  void initState() {
    super.initState();
    print("nama: ${widget.npm} | ${widget.username}");
    initCamera();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg);
    await _controller.initialize();
    setState(() {
      isReady = true;
    });
  }

  

  Future<List<String>> captureImages(
    BuildContext context,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    List<String> fileList = [];
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    for (int i = 0; i < 10; i++) {
      try {
        final XFile file = await _controller.takePicture();
        fileList.add(file.path);
        print("gambar ke-${i + 1} berhasil diambil");

        // Tunggu 1 detik sebelum ambil gambar berikutnya
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error gambar ${i + 1}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Semua gambar berhasil diambil!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(
      const Duration(seconds: 1),
    );

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ImagePreview(
                  images: fileList,
                  npm: widget.npm,
                  username: widget.username,
                )));
    return fileList;
  }

  Future<void> captureAndSendImages(BuildContext context) async {
    setState(() {
      isLoading = true;
    });
    try {
      final imageList = await captureImages(context);

      // await sendImagesToServer(imageList);
    } catch (e) {
      print('Error dalam proses: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perekaman Wajah"),
        backgroundColor: yellow,
        foregroundColor: darkblue,
      ),
      body: isReady
          ? Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 4.5 / 3 * MediaQuery.of(context).size.width,
                  // padding: const EdgeInsets.symmetric(vertical: 20),
                  // color: yellow,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(1.0, 1.0, -1.0),
                        child: AspectRatio(
                          aspectRatio: 1 / _controller.value.aspectRatio,
                          child: CameraPreview(_controller),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 4.5 / 3 * MediaQuery.of(context).size.width,
                        // color: yellow,
                        child: Image.asset(
                          'assets/cam_guided3.png',
                          fit: BoxFit.cover,
                          // scale: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: Container(
                  color: blueAccent,
                  child: Center(child: Builder(
                    builder: (context) {
                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(darkblue),
                            foregroundColor:
                                WidgetStatePropertyAll(Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            captureAndSendImages(context);
                            // captureImages(context);
                            // setState(() {
                            //   isLoading = false;
                            // });
                            // captureSingleImage();
                          },
                          child: const Text("Ambil Gambar"),
                        );
                      }
                    },
                  )),
                ))
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
              color: Colors.white,
            )),
    );
  }
}

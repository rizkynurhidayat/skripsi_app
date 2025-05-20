import 'dart:convert';
import 'dart:io';
// import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:skripsi_app/api_service.dart';
import 'package:image/image.dart' as img;

import 'const.dart';
// import 'package:http/http.dart' as http;

class CameraCapture extends StatefulWidget {
  const CameraCapture({
    required this.npm,
    required this.username,
    Key? key,
  }) : super(key: key);
  final String username;
  final String npm;
  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  final ServiceKu apiService = ServiceKu();
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool isReady = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.jpeg);
    await _controller.initialize();
    setState(() {
      isReady = true;
    });
  }

  Future<void> captureAndSendImages() async {
    setState(() {
      isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    List<String> imageList = [];

    for (int i = 0; i < 10; i++) {
      // Tampilkan countdown SnackBar
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Mengambil gambar ${i + 1} dari 10...'),
          duration: const Duration(milliseconds: 300),
        ),
      );

      final XFile file = await _controller.takePicture();
      final img.Image capturedImage =
          img.decodeImage(await file.readAsBytes())!;
      final img.Image orientedImage = img.bakeOrientation(capturedImage);
      final fixedFile = File(file.path)
        ..writeAsBytesSync(img.encodeJpg(orientedImage));

      // final XFile file = await _controller.takePicture();

      final bytes = await fixedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      imageList.add(base64Image);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Mengirim Gambar ke Server ....'),
        backgroundColor: Colors.green,
        // duration: Duration(milliseconds: 500),
      ),
    ); // Kirim semua gambar sekaligus
    final message =
        await apiService.register(imageList, widget.username, widget.npm);

    

    // SnackBar selesai
    if (message != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
    setState(() {
      isLoading = false;
    });

    print('Semua gambar udah dikirim beb 😘');
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: yellow,
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1 / _controller.value.aspectRatio,
                              child: CameraPreview(_controller),
                            ),
                          ),
                        ),
                        // Center(
                        //   child: Image.asset(
                        //     'assets/face_guide.png',
                        //     width: MediaQuery.of(context).size.width * 0.7,
                        //     height: MediaQuery.of(context).size.width * 0.7,
                        //     fit: BoxFit.contain,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: Container(
                  color: blueAccent,
                  child: Center(child: Builder(
                    builder: (context) {
                      if (isLoading) {
                        return Center(
                          child: CircularProgressIndicator(),
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
                            captureAndSendImages();
                          },
                          child: const Text("Ambil Gambar"),
                        );
                      }
                    },
                  )),
                ))
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white,)),
    );
  }
}

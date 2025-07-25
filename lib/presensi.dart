import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'api_service.dart';
import 'const.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
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

    _controller = CameraController(frontCamera, ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg);
    await _controller.initialize();
    setState(() {
      isReady = true;
    });
  }

  Future<void> captureSingleImage() async {
    try {
      final XFile file = await _controller.takePicture();
      final img.Image capturedImage =
          img.decodeImage(await file.readAsBytes())!;
      final img.Image orientedImage =
          img.flipHorizontal(img.bakeOrientation(capturedImage));
      // Membalik gambar secara horizontal
      // final img.Image flippedImage = img.flipHorizontal(orientedImage);

      final fixedFile = File(file.path)
        ..writeAsBytesSync(img.encodeJpg(orientedImage));
      final bytes = await fixedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) =>
      //             ImagePreview(imagePath: capturedImagePath!)));
      try {
        final message = await apiService.absen(base64Image);

        if (message != null) {
          print("response: $message");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('berhasil: $message'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("err: $e");
        ;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                            // setState(() {
                            //   isLoading = true;
                            // });
                            // captureAndSendImages(context);
                            // captureImages(context);
                            // setState(() {
                            //   isLoading = false;
                            // });
                            captureSingleImage();
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

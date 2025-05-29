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

    _controller = CameraController(frontCamera, ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.jpeg);
    await _controller.initialize();
    setState(() {
      isReady = true;
    });
  }

  Future<void> captureSingleImage() async {
    setState(() {
      isLoading = true;
    });

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
      setState(() {
        capturedImagePath = fixedFile.path;
        isLoading = false;
      });
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) =>
      //             ImagePreview(imagePath: capturedImagePath!)));
      try {
        final message = await apiService.absen(base64Image);

        if (message != null) {
          print("response: $message");
        }
      } catch (e) {
        print("err: $e");
        ;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<String>> captureImages(BuildContext context) async {
    List<String> imageList = [];
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    for (int i = 0; i < 10; i++) {
      try {
        final XFile file = await _controller.takePicture();
        final img.Image capturedImage =
            img.decodeImage(await file.readAsBytes())!;
        final img.Image orientedImage =
            img.flipHorizontal(img.bakeOrientation(capturedImage));
        final fixedFile = File(file.path)
          ..writeAsBytesSync(img.encodeJpg(orientedImage));

        final bytes = await fixedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        imageList.add(base64Image);
        print("gambar ke-${i + 1} berhasil diambil");

        // Tunggu 1 detik sebelum ambil gambar berikutnya
        await Future.delayed(const Duration(seconds: 1));
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
        content: Text('Semua gambar berhasil diambil! 💖'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );

    return imageList;
  }

  Future<void> sendImagesToServer(List<String> imageList) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Mengirim gambar.. '),
          backgroundColor: Colors.blue,
        ),
      );

      final message =
          await apiService.register(imageList, widget.username, widget.npm);

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
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> captureAndSendImages(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      final imageList = await captureImages(context);
      await sendImagesToServer(imageList);
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
                        height: 4.5 / 3 * MediaQuery.of(context).size.width ,
                        // color: Colors.red,
                        child: Image.asset('assets/cam_guided.png', fit: BoxFit.fill,),
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

class ImagePreview extends StatelessWidget {
  final String imagePath;

  const ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.file(File(imagePath), fit: BoxFit.contain);
  }
}

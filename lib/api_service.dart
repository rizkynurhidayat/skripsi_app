import 'dart:convert';
// import 'dart:io';
// import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ServiceKu {
  // static String baseUrl = "http://172.20.10.2:5000/api/register";
  // static String baseUrl = "http://192.168.1.104:5000/api/register";
  // static String baseUrl = "https://3000-firebase-cobaapi-1748147920733.cluster-pgviq6mvsncnqxx6kr7pbz65v6.cloudworkstations.dev/api/register";
  static String baseUrl = "http://202.155.132.124:5000/api";
  // static String baseUrl = "https://3000-firebase-cobaapi-1748147920733.cluster-pgviq6mvsncnqxx6kr7pbz65v6.cloudworkstations.dev/";

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final box = GetStorage();

  Future<Map<String, dynamic>> authMhs(String npm) async {
    Map<String, dynamic> hasil = {};
    await firestore.collection('students').doc(npm).get().then((value) async {
      if (value.exists) {
        hasil['status'] = true;
        hasil['data'] = value.data();
        await box.write('user', value.data());
        print("simpan data: " + value.data().toString());
      } else {
        hasil['status'] = false;
        hasil['data'] = null;
      }
    });
    return hasil;
  }

  Future<Map<String, dynamic>?> getUsrData() async {
    final data = await box.read('user');
    return data;
  }

  Future<List<dynamic>?> getDataset() async {
    final data = await box.read('dataset');
    return data;
  }

  Future<String?> getUsername() async {
    final String? data = await box.read('username_temp');
    return data;
  }

  Future<String?> getNpm() async {
    final String? data = await box.read('npm_temp');
    return data;
  }

  Future<String?> register(
      List<String> base64Image, String username, String npm) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'npm': npm, 'username': username, 'images': base64Image}),
      );
      print("response register: ");
      print(res.body);
      final json = jsonDecode(res.body);
      return json['message'];
    } catch (e) {
      print("err: $e");
    }
  }

  Future<Map<String, dynamic>?> manualPresensi(String base64Image,
      String username, String npm, String keterangan, String idMatkul) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/manual-attendance"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'npm': npm,
          'username': username,
          'photo_base64': base64Image,
          "id_matkul": idMatkul,
          "keterangan": keterangan
        }),
      );
      print("response Manual presensi: ");
      print(res.body);
      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      print("err: $e");
    }
  }

  Future<String?> absen(String image) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/detect"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': image}),
      );
      print("response register: ");
      print(res.body);
      final json = jsonDecode(res.body);
      return json['message'];
    } catch (e) {
      print("err: $e");
    }
  }
}

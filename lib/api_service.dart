import 'dart:convert';
// import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ServiceKu {
  // static String baseUrl = "http://172.20.10.2:5000/api/register";
  static String baseUrl = "http://192.168.1.104:5000/api/register";
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

  Future<Map<String, dynamic>> getUsrData() async {
    final data = await box.read('user');
    return data;
  }

  Future<String?> register(
      List<String> base64Image, String username, String npm) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
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
}

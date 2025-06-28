import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'const.dart';

class InputPresensiPage extends StatefulWidget {
  const InputPresensiPage({super.key});

  @override
  State<InputPresensiPage> createState() => _InputPresensiPageState();
}

class _InputPresensiPageState extends State<InputPresensiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController npmController = TextEditingController();
  final _api = ServiceKu();
  String? photoBase64;
  File? imageFile;
  bool isLoading = false;
  Map<String, dynamic>? user = {};
  String? keterangan;
  List<Map<String, dynamic>> listMatkul = [];
  Map<String, dynamic>? selectedMatkul;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
      final bytes = await picked.readAsBytes();
      setState(() {
        photoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        photoBase64 == null ||
        selectedMatkul == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field dan foto wajib diisi!')),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('attendance').add({
        'username': user?['username'],
        'npm': user?['npm'],
        'keterangan': keterangan,
        'photo_base64': photoBase64,
        'createdAt': Timestamp.now(),
        'id_matkul': selectedMatkul!['id'],
        'matkul': {
          'nama_matkul': selectedMatkul!['nama_matkul'],
          'ruangan': selectedMatkul!['ruangan'],
          'dosen': selectedMatkul!['dosen'],
          'startTime': selectedMatkul!['startTime'],
          'finishTime': selectedMatkul!['finishTime'],
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presensi berhasil disimpan!')),
      );
      setState(() {
        imageFile = null;
        photoBase64 = null;
        selectedMatkul = null;
        keterangan = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
    setState(() => isLoading = false);
  Navigator.pop(context);
  }

  void init() async {
    user = await _api.getUsrData();
  }

  Future<void> loadMatkul() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('matkul').get();
    setState(() {
      listMatkul = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
    loadMatkul();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Presensi manual'),
        backgroundColor: yellow,
        foregroundColor: darkblue,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/bg_dashboard.png",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedMatkul,
                          decoration: const InputDecoration(
                            labelText: 'Mata Kuliah',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: listMatkul.map((matkul) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: matkul,
                              child: Text(
                                "${matkul['nama_matkul']} - ${matkul['ruangan']}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMatkul = value;
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Mata kuliah wajib dipilih' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: keterangan,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Izin', child: Text('Izin')),
                            DropdownMenuItem(
                                value: 'Sakit', child: Text('Sakit')),
                            DropdownMenuItem(
                                value: 'Lainnya', child: Text('Lainnya')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              keterangan = value;
                            });
                          },
                          validator: (v) => v == null || v.isEmpty
                              ? 'Keterangan wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 370,
                            height: 370,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(imageFile!,
                                        fit: BoxFit.cover),
                                  )
                                : const Center(
                                    child: Icon(Icons.camera_alt,
                                        size: 40, color: Colors.grey),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Klik kotak di atas untuk tambah foto'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkblue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Simpan Presensi',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

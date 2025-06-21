import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_app/exportedPDF.dart';
import 'dart:convert';

import 'api_service.dart';
import 'auth_page.dart';
import 'const.dart';
import 'datapresensi_dosen.dart';

class Dashboard_Dosen extends StatefulWidget {
  const Dashboard_Dosen({super.key});

  @override
  State<Dashboard_Dosen> createState() => _Dashboard_DosenState();
}

class _Dashboard_DosenState extends State<Dashboard_Dosen> {
  final ServiceKu _apiService = ServiceKu();
  final mulaiController = TextEditingController();
  final selesaiController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
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

  void showTambahMatkulDialog() {
    final namaMatkulController = TextEditingController();
    final dosenController = TextEditingController();
    String? selectedRuangan;
    TimeOfDay? mulai;
    TimeOfDay? selesai;
    String? errorMsg;
    bool namaError = false,
        dosenError = false,
        ruanganError = false,
        mulaiError = false,
        selesaiError = false;

    final List<String> ruanganList = [
      "Lab RPL",
      "Lab Multimedia",
      "Lab IoT",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: yellow,
              title: const Text('Tambah Mata Kuliah'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama Matkul
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: namaError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: namaMatkulController,
                        decoration: InputDecoration(
                            labelText: 'Nama Matkul',
                            errorText: namaError ? 'Tidak boleh kosong' : null,
                            border: InputBorder.none
                            // filled: true,
                            // fillColor: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dosen
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: namaError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: dosenController,
                        decoration: InputDecoration(
                            labelText: 'Dosen',
                            errorText: dosenError ? 'Tidak boleh kosong' : null,
                            border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Ruangan Dropdown
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: namaError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedRuangan,
                        decoration: InputDecoration(
                          labelText: 'Ruangan',
                          border: InputBorder.none,
                          errorText: ruanganError ? 'Pilih ruangan' : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ruanganList
                            .map((ruangan) => DropdownMenuItem(
                                  value: ruangan,
                                  child: Text(ruangan),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRuangan = value;
                            ruanganError = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Jam Mulai & Selesai
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      selesaiError ? Colors.red : Colors.white,
                                )),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    mulai = picked;
                                    mulaiError = false;
                                    errorMsg = null;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Mulai',
                                    // errorText:
                                    //     mulaiError ? 'Pilih jam mulai' : null,
                                    border: InputBorder.none),
                                child: Text(
                                  mulai == null
                                      ? 'Pilih Jam'
                                      : '${mulai!.hour.toString().padLeft(2, '0')}:${mulai!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      selesaiError ? Colors.red : Colors.white,
                                )),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selesai = picked;
                                    selesaiError = false;
                                    errorMsg = null;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Selesai',
                                    // errorText:
                                    //     selesaiError ? 'Pilih jam selesai' : null,
                                    border: InputBorder.none
                                    // filled: true,
                                    // fillColor: Colors.white,
                                    ),
                                child: Text(
                                  selesai == null
                                      ? 'Pilih Jam'
                                      : '${selesai!.hour.toString().padLeft(2, '0')}:${selesai!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMsg!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: darkblue,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkblue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      namaError = namaMatkulController.text.isEmpty;
                      dosenError = dosenController.text.isEmpty;
                      ruanganError = selectedRuangan == null;
                      mulaiError = mulai == null;
                      selesaiError = selesai == null;
                      errorMsg = null;
                    });

                    if (namaError ||
                        dosenError ||
                        ruanganError ||
                        mulaiError ||
                        selesaiError) {
                      setState(() {
                        errorMsg = 'Semua field harus diisi!';
                      });
                      return;
                    }

                    int startTime = mulai!.hour * 60 + mulai!.minute;
                    int finishTime = selesai!.hour * 60 + selesai!.minute;

                    if (startTime >= finishTime) {
                      setState(() {
                        errorMsg = 'Periksa kembali waktu yang Anda masukkan!';
                        mulaiError = true;
                        selesaiError = true;
                      });
                      return;
                    }

                    final createdAt = DateTime.now();

                    await FirebaseFirestore.instance.collection('matkul').add({
                      'nama_matkul': namaMatkulController.text,
                      'dosen': dosenController.text,
                      'ruangan': selectedRuangan,
                      'startTime': startTime,
                      'finishTime': finishTime,
                      'createdAt': createdAt,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mata kuliah berhasil ditambahkan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Mata Kuliah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/bg_auth.png"), fit: BoxFit.cover),
          ),
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
              CommonButton(
                onTap: () {
                  showTambahMatkulDialog();
                },
                text: "Tambah Matkul",
                isLoginButton: false,
              ),
              const SizedBox(height: 15,),
              CommonButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ExportedPdfPage()),
                  );
                },
                text: "Lihat PDF Tersimpan",
                isLoginButton: false,
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
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Image.asset(
                    "assets/bg_dashboard.png",
                    fit: BoxFit.cover,
                  ),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: buildListMatkul(),
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
    searchController.dispose();
    super.dispose();
  }

  Widget buildListMatkul() {
    return Column(
      children: [
        // Widget pencarian
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari matkul, dosen, atau ruangan...',
              iconColor: darkblue,
              prefixIcon: const Icon(
                Icons.search,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: darkblue)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                searchText = value.toLowerCase();
              });
            },
          ),
        ),
        // List matkul
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('matkul')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Terjadi kesalahan, coba lagi.',
                        style: TextStyle(color: Colors.white)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('Belum ada data mata kuliah.',
                        style: TextStyle(color: Colors.white)));
              }
              final docs = snapshot.data!.docs;

              // Filter berdasarkan pencarian
              final filteredDocs = docs.where((doc) {
                final data = doc.data();
                final nama =
                    (data['nama_matkul'] ?? '').toString().toLowerCase();
                final dosen = (data['dosen'] ?? '').toString().toLowerCase();
                final ruangan =
                    (data['ruangan'] ?? '').toString().toLowerCase();
                return nama.contains(searchText) ||
                    dosen.contains(searchText) ||
                    ruangan.contains(searchText);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                    child: Text('Data tidak ditemukan.',
                        style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final matkul = filteredDocs[index].data();
                  final docId = filteredDocs[index].id;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PresensiMhsPage(
                                      idMatkul: docId,
                                      namaMk:
                                          "${matkul["nama_matkul"]}",
                                    )));
                      },
                      title: Text(
                        matkul['nama_matkul'] ?? '-',
                        style: const TextStyle(fontSize: 22),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dosen: ${matkul['dosen'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Ruangan: ${matkul['ruangan'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Jam: ${_formatJam(matkul['startTime'])} - ${_formatJam(matkul['finishTime'])}',
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: darkblue),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            showEditMatkulDialog(docId, matkul);
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: yellow,
                                title: const Text('Konfirmasi'),
                                content: const Text(
                                    'Yakin ingin menghapus matkul ini?'),
                                actions: [
                                  TextButton(
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor: Colors.red,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('matkul')
                                    .doc(docId)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Mata kuliah berhasil dihapus!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menghapus: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Fungsi untuk mengubah menit ke format jam:menit
  String _formatJam(int? menit) {
    if (menit == null) return '-';
    final jam = (menit ~/ 60).toString().padLeft(2, '0');
    final mnt = (menit % 60).toString().padLeft(2, '0');
    return '$jam:$mnt';
  }

  void showEditMatkulDialog(String docId, Map<String, dynamic> matkul) {
    final namaMatkulController =
        TextEditingController(text: matkul['nama_matkul']);
    final dosenController = TextEditingController(text: matkul['dosen']);
    String? selectedRuangan = matkul['ruangan'];
    TimeOfDay? mulai = matkul['startTime'] != null
        ? TimeOfDay(
            hour: (matkul['startTime'] ~/ 60),
            minute: (matkul['startTime'] % 60))
        : null;
    TimeOfDay? selesai = matkul['finishTime'] != null
        ? TimeOfDay(
            hour: (matkul['finishTime'] ~/ 60),
            minute: (matkul['finishTime'] % 60))
        : null;
    String? errorMsg;
    bool namaError = false,
        dosenError = false,
        ruanganError = false,
        mulaiError = false,
        selesaiError = false;

    final List<String> ruanganList = [
      "Lab RPL",
      "Lab Multimedia",
      "Lab IoT",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: yellow,
              title: const Text('Edit Mata Kuliah'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama Matkul
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: namaError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: namaMatkulController,
                        decoration: InputDecoration(
                          labelText: 'Nama Matkul',
                          errorText: namaError ? 'Tidak boleh kosong' : null,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dosen
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: dosenError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: dosenController,
                        decoration: InputDecoration(
                          labelText: 'Dosen',
                          errorText: dosenError ? 'Tidak boleh kosong' : null,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Ruangan Dropdown
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: ruanganError ? Colors.red : Colors.white,
                          )),
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: DropdownButtonFormField<String>(
                        value: selectedRuangan,
                        decoration: InputDecoration(
                          labelText: 'Ruangan',
                          border: InputBorder.none,
                          errorText: ruanganError ? 'Pilih ruangan' : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ruanganList
                            .map((ruangan) => DropdownMenuItem(
                                  value: ruangan,
                                  child: Text(ruangan),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRuangan = value;
                            ruanganError = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Jam Mulai & Selesai
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color:
                                      mulaiError ? Colors.red : Colors.white),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: mulai ?? TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    mulai = picked;
                                    mulaiError = false;
                                    errorMsg = null;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Mulai',
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  mulai == null
                                      ? 'Pilih Jam'
                                      : '${mulai!.hour.toString().padLeft(2, '0')}:${mulai!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color:
                                      selesaiError ? Colors.red : Colors.white),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selesai ?? TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selesai = picked;
                                    selesaiError = false;
                                    errorMsg = null;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Selesai',
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  selesai == null
                                      ? 'Pilih Jam'
                                      : '${selesai!.hour.toString().padLeft(2, '0')}:${selesai!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMsg!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: darkblue,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkblue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      namaError = namaMatkulController.text.isEmpty;
                      dosenError = dosenController.text.isEmpty;
                      ruanganError = selectedRuangan == null;
                      mulaiError = mulai == null;
                      selesaiError = selesai == null;
                      errorMsg = null;
                    });

                    if (namaError ||
                        dosenError ||
                        ruanganError ||
                        mulaiError ||
                        selesaiError) {
                      setState(() {
                        errorMsg = 'Semua field harus diisi!';
                      });
                      return;
                    }

                    int startTime = mulai!.hour * 60 + mulai!.minute;
                    int finishTime = selesai!.hour * 60 + selesai!.minute;

                    if (startTime >= finishTime) {
                      setState(() {
                        errorMsg = 'Periksa kembali waktu yang Anda masukkan!';
                        mulaiError = true;
                        selesaiError = true;
                      });
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('matkul')
                          .doc(docId)
                          .update({
                        'nama_matkul': namaMatkulController.text,
                        'dosen': dosenController.text,
                        'ruangan': selectedRuangan,
                        'startTime': startTime,
                        'finishTime': finishTime,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mata kuliah berhasil diupdate!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        errorMsg = 'Gagal update: $e';
                      });
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}



// Expanded(
//                     child:  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                             stream: _apiService.firestore
//                                 .collection('attendance')
//                                 .orderBy('createdAt', descending: true)
//                                 .snapshots(),
//                             builder: (context, snapshot) {
//                               if (snapshot.hasData) {
//                                 final raw = snapshot.data;
//                                 if (raw == null) {
//                                   return const Center(
//                                     child: Text("no data"),
//                                   );
//                                 }
//                                 final now = DateTime.now();
//                                 final startOfDay = DateTime(now.year, now.month,
//                                     now.day, mulai!.hour, mulai!.minute);
//                                 final endOfDay = DateTime(now.year, now.month,
//                                     now.day, selesai!.hour, selesai!.minute);
//                                 final data = raw.docs.where((doc) {
//                                   final DateTime createdAt =
//                                       DateTime.parse(doc['createdAt']);
//                                   return createdAt.isAfter(startOfDay) &&
//                                       createdAt.isBefore(endOfDay);
//                                 }).toList();
//                                 if (data.length == 0) {
//                                   return const Center(
//                                     child: Text("Data Absen tidak ada"),
//                                   );
//                                 }
//                                 return SingleChildScrollView(
//                                   child: Column(
//                                     children: List.generate(
//                                       data.length,
//                                       (index) {
//                                         final absen = data[index].data();
//                                         Uint8List bytes =
//                                             base64Decode(absen['photo_base64']);
//                                         // var date = DateTime.fromMillisecondsSinceEpoch(absen['createdAt'] * 1000);

//                                         return Container(
//                                           // width: double.infinity,
//                                           padding: const EdgeInsets.all(10),
//                                           margin: const EdgeInsets.symmetric(
//                                               horizontal: 20, vertical: 10),
//                                           decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(13),
//                                               color: Colors.white),
//                                           child: Column(
//                                             children: [
//                                               Image.memory(
//                                                 bytes,
//                                                 fit: BoxFit.contain,
//                                                 // width: double.infinity,
//                                                 height: 250,
//                                               ),
//                                               ListTile(
//                                                 title: Text(
//                                                   absen['username'],
//                                                   style: const TextStyle(
//                                                       color: darkblue),
//                                                 ),
//                                                 subtitle: Text(
//                                                     formatTimestamp(
//                                                         absen['createdAt']),
//                                                     style: const TextStyle(
//                                                         color: darkblue)),
//                                               ),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 );
//                               }
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const Center(
//                                   child: CircularProgressIndicator(),
//                                 );
//                               }
//                               return const Center(
//                                 child: Text("error"),
//                               );
//                             },
//                           ),
//                   ),
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'api_service.dart';
import 'const.dart';

class PresensiMhsPage extends StatefulWidget {
  const PresensiMhsPage(
      {super.key, required this.idMatkul, required this.namaMk});
  final String idMatkul;
  final String namaMk;

  @override
  State<PresensiMhsPage> createState() => _PresensiMhsPageState();
}

class _PresensiMhsPageState extends State<PresensiMhsPage> {
  final ServiceKu _apiService = ServiceKu();

  DateTime? tanggalMulai;
  DateTime? tanggalSelesai;

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('EEEE, dd/MM/yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    int retry = 0;
    while (!status.isGranted && retry < 2) {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin penyimpanan ditolak permanen. Silakan aktifkan di pengaturan aplikasi.'),
          ),
        );
        openAppSettings();
        return false;
      }
      if (status.isDenied) {
        retry++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Izin penyimpanan diperlukan untuk export PDF!')),
        );
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Izin penyimpanan tetap ditolak. Export PDF dibatalkan.')),
      );
    }
    return status.isGranted;
  }

  Future<void> exportToPDF(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Laporan Presensi Mahasiswa - ${widget.namaMk}',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (context) => pw.Footer(
          title: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) {
          // Mengambil info ruangan dari data pertama
          final String ruanganInfo = data.isNotEmpty
              ? (data.first.data()['matkul']?['ruangan'] ?? 'N/A')
              : 'N/A';

          return [
            // ====== BAGIAN DETAIL LAPORAN ======
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'Detail Laporan',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(height: 8, thickness: 1),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mata Kuliah: ${widget.namaMk}'),
                        pw.Text('Ruangan: $ruanganInfo'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'Periode: ${tanggalMulai != null ? DateFormat('d MMM yyyy', 'id_ID').format(tanggalMulai!) : 'Semua'} - ${tanggalSelesai != null ? DateFormat('d MMM yyyy', 'id_ID').format(tanggalSelesai!) : 'Semua'}'),
                        pw.Text(
                            'Dibuat pada: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),
            // ====== END DETAIL LAPORAN ======

            // ====== TABEL DATA PRESENSI DENGAN FOTO DAN KETERANGAN ======
            pw.Table(
              border: pw.TableBorder.all(),
              // Atur lebar kolom agar sesuai
              columnWidths: {
                0: const pw.FixedColumnWidth(25),   // No
                1: const pw.FlexColumnWidth(1.2),   // Nama
                2: const pw.FlexColumnWidth(1.5),   // Waktu Presensi
                3: const pw.FixedColumnWidth(50),   // Keterangan
                4: const pw.FixedColumnWidth(50),   // Foto
              },
              children: [
                // Header Tabel
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('No',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Nama',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Waktu Presensi',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Keterangan',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Foto',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),

                // Data Mahasiswa
                ...List.generate(data.length, (index) {
                  final absen = data[index].data();
                  final tanggal = formatTimestamp(absen['createdAt']);
                  final nama = absen['username'] ?? '';
                  final keterangan = absen['keterangan'] ?? '-';
                  final photoBase64 = absen['photo_base64'] ?? '';
                  pw.Widget fotoWidget;

                  try {
                    // Coba decode gambar dari base64
                    final photoBytes = base64Decode(photoBase64);
                    fotoWidget = pw.Image(
                      pw.MemoryImage(photoBytes),
                      width: 40,
                      height: 40,
                      fit: pw.BoxFit.cover,
                    );
                  } catch (e) {
                    // Jika gagal, tampilkan teks kosong
                    fotoWidget = pw.Text('-');
                  }

                  return pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text((index + 1).toString(),
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(nama)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(tanggal)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(keterangan, textAlign: pw.TextAlign.center)),
                      pw.Container(
                        margin: const pw.EdgeInsets.all(2),
                        alignment: pw.Alignment.center,
                        height: 40,
                        child: fotoWidget,
                      ),
                    ],
                  );
                }),
              ],
            ),
            // ====== END TABEL DATA PRESENSI ======
          ];
        },
      ),
    );

    // Simpan ke folder Download/Data_Absen/
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download/Data_Absen');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    final filePath =
        '${downloadsDir.path}/Presensi_${widget.namaMk}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Notifikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF berhasil disimpan!'),
        action: SnackBarAction(
          label: 'Buka',
          onPressed: () {
            OpenFile.open(filePath);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Presensi ${widget.namaMk}"),
          actions: const [],
        ),
        backgroundColor: yellow,
        body: SafeArea(
            child: Column(
          children: [
            // ====== FILTER TANGGAL ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalMulai ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tanggalMulai = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tanggalMulai == null
                              ? 'Tanggal Mulai'
                              : DateFormat('dd/MM/yyyy').format(tanggalMulai!),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalSelesai ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tanggalSelesai = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tanggalSelesai == null
                              ? 'Tanggal Selesai'
                              : DateFormat('dd/MM/yyyy')
                                  .format(tanggalSelesai!),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Ambil data yang sudah difilter
                      final snapshot = await _apiService.firestore
                          .collection('attendance')
                          .orderBy('createdAt', descending: true)
                          .get();

                      var data = snapshot.docs
                          .where((element) =>
                              element.data()["id_matkul"] == widget.idMatkul)
                          .toList();

                      if (tanggalMulai != null && tanggalSelesai != null) {
                        final start = DateTime(
                          tanggalMulai!.year,
                          tanggalMulai!.month,
                          tanggalMulai!.day,
                          0,
                          0,
                          0,
                        );
                        final end = DateTime(
                          tanggalSelesai!.year,
                          tanggalSelesai!.month,
                          tanggalSelesai!.day,
                          23,
                          59,
                          59,
                        );
                        data = data.where((element) {
                          final Timestamp ts = element['createdAt'];
                          final dt = ts.toDate();
                          return dt.isAfter(
                                  start.subtract(const Duration(seconds: 1))) &&
                              dt.isBefore(end.add(const Duration(seconds: 1)));
                        }).toList();
                      }

                      if (data.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tidak ada data untuk diexport')),
                        );
                        return;
                      }

                      await exportToPDF(data);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkblue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // ====== END FILTER TANGGAL ======
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _apiService.firestore
                    .collection('attendance')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final raw = snapshot.data;
                    if (raw == null) {
                      return const Center(
                        child: Text("no data"),
                      );
                    }
                    // Filter berdasarkan id_matkul
                    // print(raw.docs[0].data());
                    var data = raw.docs
                        .where(
                          (element) =>
                              element.data()["id_matkul"] == widget.idMatkul,
                        )
                        .toList();

                    // Filter berdasarkan tanggal jika dipilih
                    if (tanggalMulai != null && tanggalSelesai != null) {
                      final start = DateTime(
                        tanggalMulai!.year,
                        tanggalMulai!.month,
                        tanggalMulai!.day,
                        0,
                        0,
                        0,
                      );
                      final end = DateTime(
                        tanggalSelesai!.year,
                        tanggalSelesai!.month,
                        tanggalSelesai!.day,
                        23,
                        59,
                        59,
                      );
                      data = data.where((element) {
                        final Timestamp ts = element['createdAt'];
                        final dt = ts.toDate();
                        return dt.isAfter(
                                start.subtract(const Duration(seconds: 1))) &&
                            dt.isBefore(end.add(const Duration(seconds: 1)));
                      }).toList();
                    }
                    if (data.isEmpty) {
                      return const Center(child: Text("Belum ada data"));
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          data.length,
                          (index) {
                            final absen = data[index].data();
                            Uint8List bytes =
                                base64Decode(absen['photo_base64']);
                            return Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  color: Colors.white),
                              child: Column(
                                children: [
                                  Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                    height: 250,
                                  ),
                                  ListTile(
                                    title: Text(
                                      absen['username'],
                                      style: const TextStyle(color: darkblue),
                                    ),
                                    subtitle: Text(
                                        formatTimestamp(absen['createdAt']),
                                        style:
                                            const TextStyle(color: darkblue)),
                                    trailing: Column(
                                            children: [
                                              Text(
                                                absen['matkul']
                                                        ?['nama_matkul'] ??
                                                    '',
                                                style: const TextStyle(
                                                    color: darkblue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              ),
                                              Text(
                                                absen['keterangan'] ?? '',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: ((absen[
                                                                'keterangan'] ==
                                                            'Sakit'))
                                                        ? Colors.red
                                                        : ((absen['keterangan'] ==
                                                                'Izin'))
                                                            ? Colors.amber
                                                            : darkblue,
                                                            fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          )
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return const Center(
                    child: Text("error"),
                  );
                },
              ),
            ),
          ],
        )));
  }
}

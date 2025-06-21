import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skripsi_app/const.dart'; // Pastikan path ini benar

class ExportedPdfPage extends StatefulWidget {
  const ExportedPdfPage({super.key});

  @override
  State<ExportedPdfPage> createState() => _ExportedPdfPageState();
}

class _ExportedPdfPageState extends State<ExportedPdfPage> {
  late Future<List<File>> _pdfFilesFuture;

  @override
  void initState() {
    super.initState();
    _pdfFilesFuture = _loadPdfFiles();
  }

  Future<List<File>> _loadPdfFiles() async {
    try {
      Directory? downloadsDir;
      // Menentukan direktori Download sesuai platform
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download/Data_Absen');
      } else {
        // Fallback untuk iOS atau platform lain
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (await downloadsDir.exists()) {
        final files = downloadsDir.listSync();
        var pdfFiles = files
            .where((item) => item.path.endsWith('.pdf'))
            .map((item) => File(item.path))
            .toList();

        // Mengurutkan file dari yang terbaru (newest first)
        pdfFiles.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        return pdfFiles;
      } else {
        // Direktori tidak ditemukan
        return [];
      }
    } catch (e) {
      // Menangani error, misal karena izin
      debugPrint("Error loading PDF files: $e");
      return [];
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _formatFileDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("File PDF Tersimpan"),
        backgroundColor: yellow,
        foregroundColor: darkblue,
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "assets/bg_dashboard.png", // Sesuaikan path jika perlu
              fit: BoxFit.cover,
            ),
          ),
          FutureBuilder<List<File>>(
            future: _pdfFilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: darkblue),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Gagal memuat file.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              final pdfFiles = snapshot.data;

              if (pdfFiles == null || pdfFiles.isEmpty) {
                return const Center(
                  child: Text(
                    "Belum ada PDF yang diekspor.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pdfFiles.length,
                itemBuilder: (context, index) {
                  final file = pdfFiles[index];
                  final fileName = _getFileName(file.path);
                  final lastModified = file.lastModifiedSync();

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                        size: 40,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkblue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Dibuat: ${_formatFileDate(lastModified)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onTap: () {
                        OpenFile.open(file.path);
                      },
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: yellow,
                                  title: const Text('Konfirmasi Hapus', style: TextStyle(color: darkblue)),
                                  content: Text(
                                      'Anda yakin ingin menghapus file "$fileName"?', style: const TextStyle(color: darkblue),),
                                  actions: <Widget>[
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor: darkblue),
                                      child: const Text('Batal'),
                                       
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Hapus'),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              try {
                                await file.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '"$fileName" berhasil dihapus.')),
                                );
                                setState(() {
                                  _pdfFilesFuture = _loadPdfFiles();
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Gagal menghapus file: $e')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
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
        ],
      ),
    );
  }
}

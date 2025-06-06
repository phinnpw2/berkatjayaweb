import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Mengimpor intl untuk format tanggal
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences untuk mengambil riwayat transaksi

class RiwayatTransaksiScreen extends StatefulWidget {
  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  String searchQuery = ""; // Variabel untuk pencarian nama pelanggan
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> transactions = [];

  TextEditingController searchController = TextEditingController(); // Kontrol pencarian

  // Fungsi untuk mengambil riwayat transaksi dari SharedPreferences
  Future<void> loadTransactionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      List<Map<String, dynamic>> loadedTransactions = transactionStrings
          .map((e) => Map<String, dynamic>.from(json.decode(e)))
          .toList();
      setState(() {
        transactions = loadedTransactions; // Menyimpan transaksi
      });
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  // Fungsi untuk menghapus riwayat transaksi tertentu
  Future<void> deleteTransaction(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    
    // Menghapus transaksi yang dipilih
    transactionStrings.removeAt(index);
    await prefs.setStringList('transactions', transactionStrings);

    // Memuat ulang transaksi
    loadTransactionsFromPrefs();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil dihapus')));
  }

  @override
  void initState() {
    super.initState();
    loadTransactionsFromPrefs(); // Panggil fungsi untuk memuat transaksi saat aplikasi dimulai
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase(); // Memperbarui searchQuery saat input
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // Making the AppBar transparent
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: searchController,
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query.toLowerCase(); // Memperbarui pencarian
                    });
                  },
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White and bold text
                  decoration: InputDecoration(
                    labelText: 'Cari Nama Pelanggan',
                    labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White and bold label
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    ),
                  ),
                ),
              ),
              // Pilih Tanggal Mulai
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => selectStartDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      startDate == null ? 'Pilih Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White and bold text
                    ),
                  ),
                  SizedBox(width: 10),
                  // Pilih Tanggal Akhir
                  ElevatedButton(
                    onPressed: () => selectEndDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      endDate == null ? 'Pilih Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White and bold text
                    ),
                  ),
                ],
              ),
              // Menampilkan riwayat transaksi
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transaction = transactions[index];

                    // Filter berdasarkan nama pelanggan dan tanggal
                    if (!transaction['customerName']
                        .toLowerCase()
                        .contains(searchQuery)) {
                      return Container(); // Lewati transaksi yang tidak sesuai
                    }

                    return Card(
                      elevation: 5,
                      color: Colors.blueGrey.shade50,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pelanggan: ${transaction['customerName']}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text('Tanggal: ${transaction['date']}'),
                            SizedBox(height: 10),
                            Text('Total: Rp ${transaction['totalAmount']}'),
                            SizedBox(height: 10),
                            Text('Pengembalian: Rp ${transaction['change']}'),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Konfirmasi penghapusan transaksi
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Hapus Transaksi'),
                                        content: Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Menutup dialog
                                            },
                                            child: Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Menutup dialog
                                              deleteTransaction(index); // Menghapus transaksi
                                            },
                                            child: Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memilih tanggal mulai
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  // Fungsi untuk memilih tanggal akhir
  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> transactions = [];
  TextEditingController searchController = TextEditingController();

  // Fungsi untuk memuat transaksi dari Firestore
  Future<void> loadTransactionsFromFirestore() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi').get();
      List<Map<String, dynamic>> loadedTransactions = [];
      snapshot.docs.forEach((doc) {
        Map<String, dynamic> transaction = doc.data();
        loadedTransactions.add(transaction);
      });
      setState(() {
        transactions = loadedTransactions; // Menyimpan transaksi yang diambil dari Firestore
      });
    } catch (e) {
      print("Error loading transactions from Firestore: $e");
    }
  }

  // Fungsi untuk memuat transaksi dari SharedPreferences
  Future<void> loadTransactionsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    List<Map<String, dynamic>> loadedTransactions = [];

    for (var transactionString in transactionStrings) {
      Map<String, dynamic> transaction = json.decode(transactionString);
      loadedTransactions.add(transaction);
    }

    setState(() {
      transactions = loadedTransactions;
    });
  }

  // Fungsi untuk menyimpan transaksi ke SharedPreferences
  Future<void> saveTransactionToSharedPreferences(Map<String, dynamic> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    String transactionString = json.encode(transaction);
    transactionStrings.add(transactionString);

    await prefs.setStringList('transactions', transactionStrings);
  }

  // Fungsi untuk menghapus transaksi dari Firestore
  Future<void> deleteTransactionFromFirestore(String invoiceNumber) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('riwayattransaksi')
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete(); // Menghapus dokumen dari Firestore
      }

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil dihapus dari Firestore!')));
    } catch (e) {
      print("Error deleting transaction from Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus transaksi dari Firestore!')));
    }
  }

  // Fungsi untuk menghapus transaksi dari SharedPreferences
  Future<void> deleteTransaction(String invoiceNumber) async {
    setState(() {
      // Tampilkan indikator pemuatan sementara
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      transactionStrings.removeWhere((transactionJson) {
        final transaction = json.decode(transactionJson);
        return transaction['invoiceNumber'] == invoiceNumber; // Menghapus transaksi berdasarkan invoiceNumber
      });
      await prefs.setStringList('transactions', transactionStrings);

      // Menghapus transaksi dari Firestore
      await deleteTransactionFromFirestore(invoiceNumber);

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil dihapus')));

      // Memuat ulang transaksi setelah penghapusan
      loadTransactionsFromSharedPreferences(); // Memuat transaksi setelah penghapusan
    } catch (e) {
      print("Error deleting transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus transaksi')));
    }
  }

  @override
  void initState() {
    super.initState();
    loadTransactionsFromFirestore(); // Memuat data transaksi dari Firestore
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f),
        elevation: 0,
      ),
      body: transactions.isEmpty
          ? Center(child: Text('Tidak ada transaksi untuk ditampilkan.')) // Pesan ketika tidak ada transaksi
          : Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Cari Nama Pelanggan',
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                // Date Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => selectStartDate(context),
                      child: Text(
                        startDate == null ? 'Pilih Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => selectEndDate(context),
                      child: Text(
                        endDate == null ? 'Pilih Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // ListView untuk menampilkan transaksi
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      var transaction = transactions[index];

                      // Filter transaksi berdasarkan pencarian nama pelanggan
                      if (!transaction['customerName']
                          .toLowerCase()
                          .contains(searchQuery)) {
                        return Container();
                      }

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Rincian Produk'),
                              content: Container(
                                height: 250,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Metode Pembayaran: ${transaction['paymentMethod']?.toString() ?? 'Tidak ada metode'}'),
                                      SizedBox(height: 10),
                                      Text("Total Harga : ${transaction['totalAmount']?.toString() ?? 'Tidak ada total'}"),
                                      SizedBox(height: 10),
                                      Text('Rincian Produk:'),
                                      SizedBox(height: 10),
                                      if (transaction['orderDetails'] != null && transaction['orderDetails'].isNotEmpty)
                                        Column(
                                          children: List.generate(transaction['orderDetails'].length, (i) {
                                            var product = transaction['orderDetails'][i];
                                            double totalPrice = product['price'] * product['quantity'];
                                            return Card(
                                              margin: EdgeInsets.only(bottom: 10),
                                              elevation: 5,
                                              color: Colors.blueGrey.shade100,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product['name']?.toString() ?? 'Nama Produk Tidak Tersedia',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text('Jumlah: ${product['quantity']}'),
                                                    Text('Harga per Unit: Rp ${product['price']}'),
                                                    Text('Total: Rp ${totalPrice}'),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        )
                                      else
                                        Text('Tidak ada produk untuk transaksi ini'),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Card(
                            elevation: 5,
                            color: Colors.blueGrey.shade50,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nomor Nota: ${transaction['invoiceNumber']?.toString() ?? 'N/A'}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text('Pelanggan: ${transaction['customerName']?.toString() ?? 'Tidak Ada Nama'}'),
                                  SizedBox(height: 5),
                                  Text('Tanggal: ${transaction['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date'])) : 'Tidak ada tanggal'}'),
                                  SizedBox(height: 5),
                                  Text('Total: Rp ${transaction['totalAmount']?.toString() ?? '0.0'}'),
                                  SizedBox(height: 5),
                                  Text('Pengembalian: Rp ${transaction['change']?.toString() ?? '0.0'}'),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Hapus Transaksi'),
                                              content: Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    deleteTransaction(transaction['invoiceNumber']); // Menghapus transaksi berdasarkan invoiceNumber
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

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

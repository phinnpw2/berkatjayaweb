import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanScreen extends StatefulWidget {
  @override
  _LaporanScreenState createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  double totalTransactionValue = 0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactionsFromFirestore(); // Memuat transaksi langsung dari Firestore
  }
  //disini
  // Fungsi untuk memuat transaksi dari Firestore
  Future<void> loadTransactionsFromFirestore() async {
    try {
      // Ambil transaksi dari Firestore
      final snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi').get();
      List<Map<String, dynamic>> loadedTransactions = [];

      snapshot.docs.forEach((doc) {
        Map<String, dynamic> transactionData = doc.data() as Map<String, dynamic>;

        // Tambahkan transaksi hanya jika belum ada duplikasi
        bool isDuplicate = loadedTransactions.any((existingTransaction) =>
            existingTransaction['invoiceNumber'] == transactionData['invoiceNumber']);
        
        if (!isDuplicate) {
          loadedTransactions.add(transactionData);
        }
      });

      setState(() {
        transactions = loadedTransactions;
      });

      // Hitung total transaksi
      generateReport();
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  // Fungsi untuk menghitung total transaksi
  void generateReport() {
    double total = 0;

    for (var transaction in transactions) {
      total += transaction['totalAmount'] ?? 0.0;
    }

    setState(() {
      totalTransactionValue = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f), // Sesuaikan dengan warna Riwayat Transaksi
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Laporan Transaksi - Total
            _buildLaporanTransaksi(),

            // Laporan Nota (Detail Transaksi) dalam bentuk Tabel
            _buildLaporanNota(),
          ],
        ),
      ),
    );
  }

  // Laporan Transaksi - Total
  Widget _buildLaporanTransaksi() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Total Transaksi: Rp ${totalTransactionValue.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Laporan Nota (Detail Transaksi) dalam bentuk Tabel
  Widget _buildLaporanNota() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 3)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Nota Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Table(
              border: TableBorder.all(
                color: Colors.black,
                width: 1,
                style: BorderStyle.solid,
              ),
              children: [
                TableRow(
                  children: [
                    _buildTableCell('No', isHeader: true),
                    _buildTableCell('No. Nota', isHeader: true),
                    _buildTableCell('Pelanggan', isHeader: true),
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                    _buildTableCell('Keterangan', isHeader: true),
                  ],
                ),
                // Daftar transaksi ditampilkan dalam baris tabel
                ...transactions.map<TableRow>((transaction) {
                  String productDetails = _getProductDetails(transaction['orderDetails']);
                  return TableRow(
                    children: [
                      _buildTableCell((transactions.indexOf(transaction) + 1).toString()),
                      _buildTableCell(transaction['invoiceNumber'] ?? 'N/A'),
                      _buildTableCell(transaction['customerName'] ?? 'N/A'),
                      _buildTableCell(_formatDate(transaction['date'])),
                      _buildTableCell('Rp ${transaction['totalAmount']}'),
                      _buildTableCell(productDetails),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Membuat cell untuk tabel
  Widget _buildTableCell(String content, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  // Mengambil rincian produk dari orderDetails
  String _getProductDetails(List<dynamic> orderDetails) {
    List<String> productDetails = [];

    if (orderDetails != null) {
      for (var product in orderDetails) {
        productDetails.add('${product['name']} (${product['quantity']} pcs)');
      }
    }

    return productDetails.join('\n');
  }

  // Format tanggal menjadi hanya tanggal saja (tanpa waktu)
  String _formatDate(String dateTime) {
    if (dateTime == null) return 'N/A';
    DateTime date = DateTime.parse(dateTime);
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

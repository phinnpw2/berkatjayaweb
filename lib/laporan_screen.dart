import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    loadTransactionsFromPrefs(); // Memuat transaksi saat inisialisasi
  }

  // Fungsi untuk memuat transaksi dari SharedPreferences
  Future<void> loadTransactionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      List<Map<String, dynamic>> loadedTransactions = transactionStrings
          .map((e) => Map<String, dynamic>.from(json.decode(e)))
          .toList();
      setState(() {
        transactions = loadedTransactions;
      });
      generateReport(); // Panggil generateReport setelah transaksi dimuat
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

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
        title: Text('Laporan Transaksi'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Laporan Transaksi - Total (memanjang)
            _buildLaporanTransaksi(),

            // Laporan Nota (Detail Transaksi) menggunakan Tabel
            _buildLaporanNota(),
          ],
        ),
      ),
    );
  }

  // Laporan Transaksi
  Widget _buildLaporanTransaksi() {
    return Container(
      width: double.infinity,  // Membuat lebar memanjang
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

  // Laporan Nota (Detail Transaksi) dalam bentuk tabel
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

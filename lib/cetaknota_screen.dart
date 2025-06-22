import 'dart:convert';
import 'package:berkatjaya_web/kasir_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Mengimpor intl package
import 'package:shared_preferences/shared_preferences.dart';
import 'notatempo_screen.dart'; // Impor NotaTempoScreen

class CetakNotaScreen extends StatelessWidget {
  final String customerName; 
  final List<Map<String, dynamic>> orderMenu;
  final double totalAmount;
  final double change;
  final String paymentMethod;
  final String invoiceNumber;  // Menerima parameter invoiceNumber
  final Timestamp? originalTimestamp;  // Menyimpan timestamp asli, opsional

  CetakNotaScreen({
    required this.customerName,
    required this.orderMenu,
    required this.totalAmount,
    required this.change,
    required this.paymentMethod,
    required this.invoiceNumber,  // Menerima parameter invoiceNumber
    this.originalTimestamp,  // Menambahkan timestamp asli sebagai opsional
  });

  @override
  Widget build(BuildContext context) {
    // Jika originalTimestamp ada, gunakan tanggal tersebut, jika tidak gunakan DateTime.now()
    DateTime orderDate = originalTimestamp?.toDate() ?? DateTime.now();  // Jika originalTimestamp tidak ada, gunakan waktu saat ini
    DateTime printDate = DateTime.now();  // Waktu nota dicetak (waktu sekarang)

    return Scaffold(
      appBar: AppBar(
        title: Text('Cetak Nota', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView( 
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.blue.shade200], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: 350,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Toko
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        'LOGO TOKO', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Nama Toko dan Alamat
                    Text(
                      'Toko Berkat Jaya\nJl. Slamet Riady', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    // Tanggal dan Waktu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          originalTimestamp != null ? 'Tanggal Nota Dibuat: ${DateFormat('yyyy-MM-dd').format(orderDate)}' : '', 
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ), 
                        SizedBox(height: 5),
                        Text(
                           'Tanggal Cetak: ${DateFormat('yyyy-MM-dd').format(printDate)}',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),                     
                      ],
                    ),
                    SizedBox(height: 15),
                    // Nomor Nota dan Kasir ditempatkan di atas garis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nomor Nota: ${invoiceNumber}', style: TextStyle(fontSize: 14, color: Colors.black)),
                        Text('Kasir: Evy', style: TextStyle(fontSize: 14, color: Colors.black)), // Kasir lebih kecil dan abu-abu
                      ],
                    ),
                    SizedBox(height: 10),
                    // Garis Pemisah
                    SizedBox(height: 15),
                    Divider(color: Colors.black),
                    SizedBox(height: 10),
                    
                    // Rincian Produk
                    Text('Detail Pembelian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        children: orderMenu.map((item) {
                          return ListTile(
                            title: Text('${item['name']} (x${item['quantity']})', style: TextStyle(fontSize: 14, color: Colors.black)),
                            subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.black)),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.black),
                    Text('Nama Pelanggan: $customerName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),
                    Text('Total Harga: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),
                    Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 15),
                    Text('Metode Pembayaran : $paymentMethod', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 20),
                    // Tombol Transaksi Baru
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Arahkan ke KasirScreen untuk transaksi baru
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => KasirScreen()), 
                            (Route<dynamic> route) => false, 
                          );
                        },
                        child: Text('Transaksi Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,  // Mengubah warna tombol menjadi hijau
                          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Tombol Nota Tempo
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Arahkan ke NotaTempoScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotaTempoScreen()),
                          );
                        },
                        child: Text('Nota Tempo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,  // Mengubah warna tombol menjadi oranye
                          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
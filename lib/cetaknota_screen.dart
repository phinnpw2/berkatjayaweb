import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Mengimpor intl package

class CetakNotaScreen extends StatelessWidget {
  final String customerName; 
  final List<Map<String, dynamic>> orderMenu;
  final double totalAmount;
  final double change;
  final String paymentMethod;  

  CetakNotaScreen({
    required this.customerName,
    required this.orderMenu,
    required this.totalAmount,
    required this.change,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    // Mendapatkan tanggal dan waktu saat ini
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Nota Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView( // Membungkus body dengan SingleChildScrollView untuk mencegah overflow
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.blue.shade200], // Background gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Toko
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        'LOGO TOKO', 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Nama Toko dan Alamat
                    Text(
                      'Toko Berkat Jaya\nJl. Slamet Riady', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),

                    // Tanggal dan Waktu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tanggal: $currentDate', style: TextStyle(fontSize: 16, color: Colors.black)),
                        Text('Waktu: $currentTime', style: TextStyle(fontSize: 16, color: Colors.black)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(color: Colors.black),
                    SizedBox(height: 10),

                    // Nama Kasir
                    Text('Kasir: Evy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),

                    // Detail Pembelian
                    Text('Detail Pembelian:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
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
                            title: Text('${item['name']} (x${item['quantity']})', style: TextStyle(fontSize: 16, color: Colors.black)),
                            subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.black)),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.black),

                    // Menampilkan Nama Pelanggan
                    Text('Nama Pelanggan: $customerName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),

                    // Total Harga dan Pengembalian
                    Text('Total Harga: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 10),
                    Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 20),

                    // Menampilkan metode pembayaran
                    Text('Bayar dengan: $paymentMethod', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),

                    SizedBox(height: 30),

                    // Tombol untuk kembali ke KasirScreen
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tombol untuk kembali
                        },
                        child: Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,  // Mengubah warna tombol menjadi hijau
                          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Mengimpor intl package

class NotaScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orderMenu;
  final double totalAmount;
  final double change;
  final String paymentMethod;  // Menambahkan parameter untuk metode pembayaran

  NotaScreen({required this.orderMenu, required this.totalAmount, required this.change, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    // Mendapatkan tanggal dan waktu saat ini
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());  // Menggunakan format tanpa milliseconds

    return Scaffold(
      appBar: AppBar(
        title: Text('Nota Pembayaran'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: Padding(
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
                // Tanggal dan Waktu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tanggal: $currentDate', style: TextStyle(fontSize: 16, color: Colors.black)),
                    SizedBox(width: 10),
                    Text('Waktu: $currentTime', style: TextStyle(fontSize: 16, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 20),
                Divider(color: Colors.black),
                SizedBox(height: 10),

                // Detail Pembelian
                Text('Detail Pembelian:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        title: Text('${item['name']} (x${item['quantity']})'),
                        subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Divider(color: Colors.black),

                // Total Harga dan Pengembalian
                Text('Total Harga: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                // Menampilkan metode pembayaran
                Text('Bayar dengan: $paymentMethod', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),

                SizedBox(height: 30),

                // Tombol untuk kembali ke KasirScreen
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Kembali ke Kasir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

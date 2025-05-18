import 'package:berkatjaya_web/kasir_screen.dart';
import 'package:flutter/material.dart';

class PembayaranScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orderMenu;  // Menerima parameter orderMenu

  // Konstruktor untuk menerima data orderMenu
  PembayaranScreen({required this.orderMenu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon centang dan pesan transaksi berhasil
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100.0,
            ),
            SizedBox(height: 10),
            Text(
              'Good Job!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Transaksi berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Menampilkan rincian produk yang dipesan
            Text(
              'Rincian Produk:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: orderMenu.length,
                itemBuilder: (context, index) {
                  final item = orderMenu[index];
                  return ListTile(
                    title: Text('${item['name']} (x${item['quantity']})'),
                    subtitle: Text('Rp ${item['price']}'),
                  );
                },
              ),
            ),

            // Tombol untuk "Transaksi baru" dengan padding dan warna abu-abu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  // Fungsi untuk kembali ke KasirScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => KasirScreen()),
                  );
                },
                child: Text(
                  'Transaksi baru',
                  style: TextStyle(fontWeight: FontWeight.bold), // Menebalkan teks
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.grey, // Tombol berwarna abu-abu
                ),
              ),
            ),
            
            // Tombol untuk "Cetak Struk" dengan padding dan warna abu-abu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  // Fungsi untuk mencetak struk
                  // Anda dapat menambahkan kode di sini untuk mencetak struk
                },
                child: Text(
                  'Cetak Struk',
                  style: TextStyle(fontWeight: FontWeight.bold), // Menebalkan teks
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.grey, // Tombol berwarna abu-abu
                ),
              ),
            ),

            // Tombol untuk "Kirim Email" dengan padding dan warna kuning
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  // Fungsi untuk mengirim email
                  // Anda bisa menambahkan logika pengiriman email di sini
                },
                child: Text(
                  'Kirim Email',
                  style: TextStyle(fontWeight: FontWeight.bold), // Menebalkan teks
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.yellow, // Tombol Pro style dengan warna kuning
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

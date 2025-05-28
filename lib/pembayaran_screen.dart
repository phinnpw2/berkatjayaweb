import 'package:flutter/material.dart';
import 'nota_screen.dart';  // Mengimpor NotaScreen

class PembayaranScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderMenu;
  PembayaranScreen({required this.orderMenu});

  @override
  _PembayaranScreenState createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  late double totalAmount;
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController customerNameController = TextEditingController(); // Menambahkan controller untuk nama pelanggan
  double change = 0.0;
  String paymentMethod = 'Cash';  // Default payment method

  @override
  void initState() {
    super.initState();
    totalAmount = widget.orderMenu.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Fungsi untuk menghitung pengembalian
  void calculateChange() {
    double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
    setState(() {
      if (amountPaid >= totalAmount) {
        change = amountPaid - totalAmount;
      } else {
        change = 0.0;
      }
    });
  }

  // Fungsi untuk memeriksa apakah uang yang dibayar cukup
  bool isAmountPaidValid() {
    double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
    return amountPaid >= totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView( // Membungkus body dengan SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input untuk Nama Pelanggan
            TextField(
              controller: customerNameController,
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan',
                hintText: 'Masukkan nama pelanggan',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (text) {
                setState(() {}); // Memperbarui tampilan setiap kali ada perubahan pada nama pelanggan
              },
            ),
            SizedBox(height: 20),

            // Menampilkan nama pelanggan
            Text(
              'Nama Pelanggan: ${customerNameController.text.isEmpty ? 'Belum diisi' : customerNameController.text}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),

            // Menampilkan total harga
            Text('Total yang harus dibayar:', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 5),
            Text('Rp ${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            SizedBox(height: 20),

            // Rincian produk yang dipesan
            Text('Rincian Produk:', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Column(
                children: widget.orderMenu.map((item) {
                  return ListTile(
                    title: Text('${item['name']} (x${item['quantity']})'),
                    subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),

            // Input nominal uang yang dibayar
            TextField(
              controller: amountPaidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Masukkan Uang yang Dibayar',
                hintText: 'Masukkan jumlah uang',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                calculateChange();
              },
            ),
            SizedBox(height: 20),

            // Menampilkan pengembalian
            Text('Pengembalian: Rp ${change.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            SizedBox(height: 20),

            // Dropdown untuk memilih metode pembayaran
            DropdownButton<String>(
              value: paymentMethod,
              onChanged: (String? newValue) {
                setState(() {
                  paymentMethod = newValue!;
                });
              },
              items: <String>['Cash', 'Transfer BCA', 'Transfer BRI', 'Transfer Mandiri']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Tombol Nota
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Menampilkan notifikasi jika uang yang dibayar belum dimasukkan
                  if (amountPaidController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan nominal uang terlebih dahulu')));
                  }
                  // Jika uang tidak cukup
                  else if (!isAmountPaidValid()) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang tidak cukup')));
                  }
                  // Jika semua valid, lanjutkan ke NotaScreen
                  else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotaScreen(
                          orderMenu: widget.orderMenu,
                          totalAmount: totalAmount,
                          change: change,
                          paymentMethod: paymentMethod,  // Kirim metode pembayaran ke NotaScreen
                        ),
                      ),
                    );
                  }
                },
                child: Text('Nota'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

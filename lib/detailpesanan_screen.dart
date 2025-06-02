import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailPesananScreen extends StatelessWidget {
  final String orderId;

  // Constructor untuk menerima ID pesanan
  DetailPesananScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('pesanan').doc(orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pesananData = snapshot.data!.data() as Map<String, dynamic>;
          final customerName = pesananData['customerName'] ?? 'Tidak ada nama';
          final orderMenu = pesananData['orderDetails'] as List<dynamic>;
          final totalCharge = pesananData['total'] ?? 0.0;
          final timestamp = pesananData['timestamp']?.toDate() ?? DateTime.now();

          // Format waktu dengan tanggal, jam dan menit
          String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelanggan: $customerName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Pesanan pada $formattedTime',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                // Menampilkan daftar produk yang dipesan
                Column(
                  children: orderMenu.map((item) {
                    return ListTile(
                      title: Text('${item['name']} (x${item['quantity']})'),
                      subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                // Menampilkan total harga
                Text(
                  'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

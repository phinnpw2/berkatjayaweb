import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Mengimpor intl untuk format tanggal

class PesananScreen extends StatefulWidget {
  @override
  _PesananScreenState createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  // Fungsi untuk menghapus pesanan dan mengembalikan stok produk
  void deleteOrder(String orderId, List<dynamic> orderMenu) async {
    try {
      // Menghapus pesanan dari Firestore
      await FirebaseFirestore.instance.collection('pesanan').doc(orderId).delete();

      // Mengembalikan stok produk yang telah dipesan
      for (var item in orderMenu) {
        final docRef = FirebaseFirestore.instance.collection('produk').doc(item['id']);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final currentStock = docSnapshot.data()?['stok'] ?? 0;
          await docRef.update({'stok': currentStock + item['quantity']}); // Menambah stok sesuai dengan quantity yang dibeli
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dihapus dan stok dikembalikan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus pesanan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pesanan')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pesananDocs = snapshot.data!.docs;

          if (pesananDocs.isEmpty) {
            return Center(child: Text('Belum ada pesanan'));
          }

          return ListView.builder(
            itemCount: pesananDocs.length,
            itemBuilder: (context, index) {
              final pesananData = pesananDocs[index].data() as Map<String, dynamic>;
              final customerName = pesananData['customerName'] ?? 'Tidak ada nama'; // Mengambil nama pelanggan
              final timestamp = pesananData['timestamp']?.toDate() ?? DateTime.now();
              final orderMenu = pesananData['orderDetails'] as List<dynamic>;
              final totalCharge = pesananData['total'] ?? 0.0;
              final orderId = pesananDocs[index].id; // Mendapatkan ID pesanan

              // Format waktu dengan tanggal, jam dan menit
              String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);

              return Card(
                elevation: 5,
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menampilkan nama pelanggan dan waktu dengan format tanggal, jam dan menit
                      Text(
                        '$customerName - Pesanan pada $formattedTime',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Menampilkan total harga
                      Text(
                        'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Tombol untuk melihat detail pesanan
                      TextButton(
                        onPressed: () {
                          // Navigasi ke halaman detail pesanan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPesananScreen(orderId: orderId),
                            ),
                          );
                        },
                        child: Text('Lihat Detail Pesanan'),
                      ),
                      // Tombol Hapus Pesanan
                      ElevatedButton(
                        onPressed: () => deleteOrder(orderId, orderMenu),
                        child: Text('Hapus Pesanan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent, // Tombol merah untuk hapus
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context); // Kembali ke layar kasir
        },
        child: Icon(Icons.arrow_back),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }
}

class DetailPesananScreen extends StatelessWidget {
  final String orderId;

  DetailPesananScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pesanan').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pesananData = snapshot.data!.data() as Map<String, dynamic>;
          final orderMenu = pesananData['orderDetails'] as List<dynamic>;
          final totalCharge = pesananData['total'] ?? 0.0;

          return Column(
            children: [
              // Daftar produk pesanan
              Expanded(
                child: ListView.builder(
                  itemCount: orderMenu.length,
                  itemBuilder: (context, index) {
                    final item = orderMenu[index];
                    return ListTile(
                      title: Text('${item['name']} (x${item['quantity']})'),
                      subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              // Menampilkan total harga
              Text(
                'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatusNotaTempoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Nota Tempo'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('statusnotatempo').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pesananDocs = snapshot.data!.docs;

          if (pesananDocs.isEmpty) {
            return Center(child: Text('Belum ada pesanan nota tempo.'));
          }

          return ListView.builder(
            itemCount: pesananDocs.length,
            itemBuilder: (context, index) {
              final pesananData = pesananDocs[index].data() as Map<String, dynamic>;
              final customerName = pesananData['customerName'] ?? 'Tidak ada nama';
              final orderDetails = pesananData['orderDetails'] as List<dynamic>;
              final totalAmount = pesananData['total'] ?? 0.0;
              final paymentMethod = pesananData['paymentMethod'] ?? 'Tidak Diketahui';
              final status = pesananData['status'] ?? 'Belum Diketahui';
              final orderId = pesananDocs[index].id;

              return GestureDetector(
                onTap: () {
                  // Menampilkan rincian produk ketika grid diklik
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Rincian Produk'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pelanggan: $customerName'),
                          SizedBox(height: 10),
                          Text('Status: $status'),
                          SizedBox(height: 10),
                          Text('Metode Pembayaran: $paymentMethod'),
                          SizedBox(height: 10),
                          Text('Total: Rp ${totalAmount.toStringAsFixed(2)}'),
                          SizedBox(height: 10),
                          Text('Rincian Produk:'),  // Menampilkan rincian produk
                          SizedBox(height: 10),
                          if (orderDetails.isNotEmpty)
                            Column(
                              children: List.generate(orderDetails.length, (i) {
                                var product = orderDetails[i];
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
                                          product['name'],
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
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$customerName - Pesanan pada ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('Total: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.green)),
                        SizedBox(height: 10),
                        // Menampilkan Status sesuai dengan data yang ada
                        Text(
                          'Status: $status',
                          style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        // Menambahkan tombol untuk mengubah status menjadi 'Lunas'
                        if (status == 'Belum Diketahui')
                          ElevatedButton(
                            onPressed: () async {
                              // Update status pesanan menjadi "Lunas"
                              await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).update({
                                'status': 'Lunas',
                              });

                              // Pindahkan pesanan yang telah lunas ke riwayat transaksi
                              await FirebaseFirestore.instance.collection('riwayattransaksi').add({
                                'customerName': customerName,
                                'orderDetails': orderDetails,
                                'total': totalAmount,
                                'paymentMethod': paymentMethod,
                                'status': 'Lunas',
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              // Menghapus pesanan dari status nota tempo setelah dipindahkan
                              await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).delete();

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dilunasi dan dipindahkan ke riwayat transaksi')));
                            },
                            child: Text('Tandai sebagai Lunas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

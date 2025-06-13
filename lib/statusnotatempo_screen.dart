import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusNotaTempoScreen extends StatefulWidget {
  @override
  _StatusNotaTempoScreenState createState() => _StatusNotaTempoScreenState();
}

class _StatusNotaTempoScreenState extends State<StatusNotaTempoScreen> {
  bool _isLoading = false; // Flag untuk menampilkan loading spinner

  // Fungsi untuk menghapus data pesanan setelah dipindahkan ke riwayat transaksi
  Future<void> deletePesanan(String orderId) async {
    try {
      // Menghapus pesanan dari status nota tempo setelah dipindahkan
      await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).delete();
      print('Pesanan dengan ID $orderId berhasil dihapus.');
    } catch (e) {
      print('Terjadi kesalahan saat menghapus pesanan: $e');
      throw e; // Lempar error agar bisa ditangani lebih lanjut
    }
  }

  // Fungsi untuk menangani konfirmasi pembayaran
  Future<void> konfirmasiPembayaran(String orderId, Map<String, dynamic> pesananData) async {
    try {
      setState(() {
        _isLoading = true; // Tampilkan loading spinner
      });

      double totalAmount = pesananData['total'] ?? 0.0;
      double amountPaid = totalAmount;  // Simulasi pembayaran
      String customerName = pesananData['customerName'] ?? 'Tidak ada nama';
      String paymentMethod = pesananData['paymentMethod'] ?? 'Tidak Diketahui';
      List<dynamic> orderDetails = pesananData['orderDetails'] ?? [];

      // Verifikasi pembayaran
      if (amountPaid >= totalAmount) {
        // Update status pesanan menjadi "Lunas"
        await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).update({
          'status': 'Lunas',
        });

        // Pindahkan pesanan yang telah lunas ke riwayat transaksi
        await FirebaseFirestore.instance.collection('riwayattransaksi').add({
          'customerName': customerName,
          'orderDetails': orderDetails,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          'status': 'Lunas',
          'timestamp': FieldValue.serverTimestamp(),
          'keterangan': 'notatempo',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()), // Menambahkan tanggal transaksi
          'change': amountPaid - totalAmount,  // Menghitung pengembalian
        });

        // Panggil fungsi untuk menghapus pesanan
        await deletePesanan(orderId);

        // Menyimpan data ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final transactionData = {
          'customerName': customerName,
          'orderDetails': orderDetails,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          'status': 'Lunas',
          'keterangan': 'notatempo',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        };

        List<String> transactions = prefs.getStringList('transactions') ?? [];
        transactions.add(json.encode(transactionData));
        await prefs.setStringList('transactions', transactions);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dipindahkan ke riwayat transaksi')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah pembayaran tidak mencukupi')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan loading spinner setelah proses selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Nota Tempo'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Menampilkan indikator loading jika sedang memproses
          : StreamBuilder<QuerySnapshot>(
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
                                Text('Rincian Produk:'),
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
                              Text(
                                'Status: $status',
                                style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              // Tombol Konfirmasi Pembayaran
                              ElevatedButton(
                                onPressed: () async {
                                  await konfirmasiPembayaran(orderId, pesananData);
                                },
                                child: Text('Konfirmasi Pembayaran'),
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

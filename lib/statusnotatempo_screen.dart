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
  bool _isLoading = false;

  Future<void> deletePesanan(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).delete();
      print('Pesanan dengan ID $orderId berhasil dihapus.');
    } catch (e) {
      print('Terjadi kesalahan saat menghapus pesanan: $e');
      throw e;
    }
  }

  Future<void> konfirmasiPembayaran(String orderId, Map<String, dynamic> pesananData) async {
    try {
      setState(() {
        _isLoading = true;
      });

      double totalAmount = pesananData['total'] ?? 0.0;
      double amountPaid = totalAmount;
      String customerName = pesananData['customerName'] ?? 'Tidak ada nama';
      String paymentMethod = pesananData['paymentMethod'] ?? 'Tidak Diketahui';
      List<dynamic> orderDetails = pesananData['orderDetails'] ?? [];
      String invoiceNumber = pesananData['invoiceNumber'] ?? 'No Invoice'; // Reference the existing invoice number

      if (amountPaid >= totalAmount) {
        await FirebaseFirestore.instance.collection('statusnotatempo').doc(orderId).update({
          'status': 'Lunas',
          'invoiceNumber': invoiceNumber, // Use the existing invoice number
        }).then((_) async {
          print('Status berhasil diperbarui menjadi Lunas dengan Invoice Number: $invoiceNumber.');

          await FirebaseFirestore.instance.collection('riwayattransaksi').add({
            'customerName': customerName,
            'orderDetails': orderDetails,
            'totalAmount': totalAmount,
            'paymentMethod': paymentMethod,
            'status': 'Lunas',
            'timestamp': FieldValue.serverTimestamp(),           
            'invoiceNumber': invoiceNumber,
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'change': amountPaid - totalAmount,
          }).then((_) async {
            await saveTransactionLocally(customerName, orderDetails, totalAmount, paymentMethod, invoiceNumber);
            await deletePesanan(orderId);

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dipindahkan ke riwayat transaksi dengan nomor nota $invoiceNumber')));
          }).catchError((e) {
            print('Error saat memindahkan pesanan ke riwayat transaksi: $e');
          });
        }).catchError((e) {
          print('Error saat memperbarui status: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status, coba lagi')));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah pembayaran tidak mencukupi')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveTransactionLocally(String customerName, List<dynamic> orderDetails, double totalAmount, String paymentMethod, String invoiceNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactions = prefs.getStringList('transactions') ?? [];

      Map<String, dynamic> transaction = {
        'customerName': customerName,
        'orderDetails': orderDetails,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': 'Lunas',
        'invoiceNumber': invoiceNumber,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'change': totalAmount - totalAmount,
      };

      transactions.add(json.encode(transaction));
      await prefs.setStringList('transactions', transactions);

      print("Transaksi berhasil disimpan di SharedPreferences");
    } catch (e) {
      print("Error saving transaction locally: $e");
    }
  }

  Future<void> showPaymentMethodDialog(String orderId, Map<String, dynamic> pesananData) async {
    String selectedPaymentMethod = 'Tidak Diketahui';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Metode Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tunai'),
              onTap: () {
                selectedPaymentMethod = 'Tunai';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Transfer BCA'),
              onTap: () {
                selectedPaymentMethod = 'Transfer BCA';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Transfer BRI'),
              onTap: () {
                selectedPaymentMethod = 'Transfer BRI';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Transfer Mandiri'),
              onTap: () {
                selectedPaymentMethod = 'Transfer Mandiri';
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Batal'),
          ),
        ],
      ),
    );
    // Update the payment method before proceeding with confirmation
    pesananData['paymentMethod'] = selectedPaymentMethod;
    await konfirmasiPembayaran(orderId, pesananData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Nota Tempo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                              Text('Total: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text(
                                'Status: $status',
                                style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),                                                       
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  await showPaymentMethodDialog(orderId, pesananData);
                                },
                                child: Text('Konfirmasi Pembayaran'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF003f7f),
                                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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

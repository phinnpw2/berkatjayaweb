import 'dart:convert'; // Menambahkan impor untuk json.decode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences untuk mengambil riwayat transaksi

class RiwayatTransaksiScreen extends StatefulWidget {
  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // Fungsi untuk mengambil riwayat transaksi dari SharedPreferences
  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    List<Map<String, dynamic>> loadedTransactions = transactionStrings.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();

    setState(() {
      transactions = loadedTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: transactions.isEmpty
          ? Center(child: Text('Tidak ada riwayat transaksi'))
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                var transaction = transactions[index];
                return Card(
                  child: ListTile(
                    title: Text('Pelanggan: ${transaction['customerName']}'),
                    subtitle: Text('Tanggal: ${transaction['date']}'),
                    trailing: Icon(Icons.history),
                    onTap: () {
                      // Tampilkan detail transaksi
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Detail Transaksi'),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nama: ${transaction['customerName']}'),
                              Text('Metode Pembayaran: ${transaction['paymentMethod']}'),
                              Text('Total: Rp ${transaction['totalAmount']}'),
                              Text('Pengembalian: Rp ${transaction['change']}'),
                              Text('Rincian Produk:'),
                              ...List.generate(transaction['orderDetails'].length, (index) {
                                var item = transaction['orderDetails'][index];
                                return Text('${item['name']} x${item['quantity']} - Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}');
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

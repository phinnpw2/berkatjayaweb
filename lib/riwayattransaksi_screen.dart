import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> transactions = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = false; // Untuk menampilkan spinner saat menghapus transaksi

  Future<void> loadTransactionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];

      // Ambil transaksi dari Firestore
      final snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi').get();
      List<Map<String, dynamic>> loadedTransactions = transactionStrings
          .map((e) => Map<String, dynamic>.from(json.decode(e)))
          .toList();

      snapshot.docs.forEach((doc) {
        Map<String, dynamic> transactionData = doc.data() as Map<String, dynamic>;

        if (transactionData['keterangan'] == 'notatempo') {
          bool isDuplicate = loadedTransactions.any((existingTransaction) =>
              existingTransaction['invoiceNumber'] == transactionData['invoiceNumber'] &&
              existingTransaction['customerName'] == transactionData['customerName'] &&
              existingTransaction['keterangan'] != 'notatempo');
          if (!isDuplicate) {
            loadedTransactions.add(transactionData);
          }
        } else {
          loadedTransactions.add(transactionData);
        }
      });

      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  Future<void> deleteTransaction(int index) async {
    setState(() {
      _isLoading = true; // Tampilkan spinner saat menghapus
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      String deletedTransactionJson = transactionStrings.removeAt(index); // Menghapus transaksi dari daftar

      // Update SharedPreferences setelah menghapus transaksi
      await prefs.setStringList('transactions', transactionStrings);

      // Parse data transaksi yang dihapus
      Map<String, dynamic> deletedTransaction = json.decode(deletedTransactionJson);

      // Mendapatkan nama pelanggan dari transaksi yang dihapus
      String customerName = deletedTransaction['customerName'] ?? ''; // Pastikan ada nama pelanggan

      if (customerName.isNotEmpty) {
        // Hapus transaksi dari Firestore berdasarkan customerName
        var snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi')
            .where('customerName', isEqualTo: customerName)
            .get();

        if (snapshot.docs.isEmpty) {
          print("Tidak ada transaksi untuk pelanggan $customerName.");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak ada transaksi untuk pelanggan ini')));
        } else {
          // Menghapus transaksi berdasarkan customerName
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
            print("Transaksi dengan pelanggan $customerName berhasil dihapus.");
          }
        }
      }

      // Reload transaksi setelah penghapusan
      loadTransactionsFromPrefs();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil dihapus')));
    } catch (e) {
      print("Error deleting transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus transaksi')));
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan spinner setelah proses selesai
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadTransactionsFromPrefs();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f), // Updated to your color
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query.toLowerCase();
                      });
                    },
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Cari Nama Pelanggan',
                      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => selectStartDate(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF003f7f),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        startDate == null ? 'Pilih Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => selectEndDate(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF003f7f),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        endDate == null ? 'Pilih Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      var transaction = transactions[index];

                      if (!transaction['customerName']
                          .toLowerCase()
                          .contains(searchQuery)) {
                        return Container();
                      }

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Rincian Produk'),
                              content: Container(
                                height: 250,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Metode Pembayaran: ${transaction['paymentMethod']}'),
                                      SizedBox(height: 10),
                                      Text("Total Harga : ${transaction['totalAmount'] ?? 'Tidak ada total'}"),
                                      SizedBox(height: 10),
                                      Text('Rincian Produk:'),
                                      SizedBox(height: 10),
                                      if (transaction['orderDetails'] != null && transaction['orderDetails'].isNotEmpty)
                                        Column(
                                          children: List.generate(transaction['orderDetails'].length, (i) {
                                            var product = transaction['orderDetails'][i];
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
                                ),
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
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Card(
                            elevation: 5,
                            color: Colors.blueGrey.shade50,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nomor Nota: ${transaction['invoiceNumber'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text('Pelanggan: ${transaction['customerName']}'),
                                  SizedBox(height: 5),
                                  Text('Tanggal: ${transaction['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date'])) : 'Tidak ada tanggal'}'),
                                  SizedBox(height: 5),
                                  Text('Total: Rp ${transaction['totalAmount'] ?? '0.0'}'),
                                  SizedBox(height: 5),
                                  Text('Pengembalian: Rp ${transaction['change'] ?? '0.0'}'),
                                  SizedBox(height: 5),
                                  if (transaction['keterangan'] != null && transaction['keterangan'] == 'notatempo')
                                    Text(
                                      'Keterangan: Nota Tempo',
                                      style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
                                    ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Hapus Transaksi'),
                                              content: Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    deleteTransaction(index); // Menghapus transaksi berdasarkan indeks
                                                  },
                                                  child: Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }
}

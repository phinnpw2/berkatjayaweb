import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> loadTransactionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      List<Map<String, dynamic>> loadedTransactions = transactionStrings
          .map((e) => Map<String, dynamic>.from(json.decode(e)))
          .toList();
      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  Future<void> deleteTransaction(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    transactionStrings.removeAt(index);
    await prefs.setStringList('transactions', transactionStrings);
    loadTransactionsFromPrefs();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil dihapus')));
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0), // Reduce padding for search field
                child: TextField(
                  controller: searchController,
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query.toLowerCase();
                    });
                  },
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Cari Nama Pelanggan',
                    labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.deepPurpleAccent),
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
                      backgroundColor: Colors.deepPurpleAccent,
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
                      backgroundColor: Colors.deepPurpleAccent,
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

                    // Filter berdasarkan nama pelanggan dan tanggal
                    if (!transaction['customerName']
                        .toLowerCase()
                        .contains(searchQuery)) {
                      return Container();
                    }

                    return GestureDetector(
                      onTap: () {
                        // Menampilkan rincian produk ketika transaksi diklik
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Rincian Produk'),
                            content: Container(
                              height: 250, // Batas tinggi kotak kecil
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Metode Pembayaran: ${transaction['paymentMethod']}'),
                                    SizedBox(height: 10),
                                    Text("Total Harga : ${transaction['totalAmount']}"),
                                    SizedBox(height: 10),
                                    Text('Rincian Produk:'),
                                    SizedBox(height: 10),

                                    // Menampilkan rincian produk dengan kotak kecil
                                    if (transaction['orderDetails'] != null && transaction['orderDetails'].isNotEmpty)
                                      Column(
                                        children: List.generate(transaction['orderDetails'].length, (i) {
                                          var product = transaction['orderDetails'][i];
                                          // Harga dihitung berdasarkan quantity
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
                                                  Text('Total: Rp ${totalPrice}'), // Harga dihitung berdasarkan quantity
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
                        alignment: Alignment.topRight, // Move to the top-right
                        child: Card(
                          elevation: 5,
                          color: Colors.blueGrey.shade50,
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0), // Reduced padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pelanggan: ${transaction['customerName']}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text('Tanggal: ${transaction['date']}'),
                                SizedBox(height: 5),
                                Text('Total: Rp ${transaction['totalAmount']}'),
                                SizedBox(height: 5),
                                Text('Pengembalian: Rp ${transaction['change']}'),
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
                                                  deleteTransaction(index);
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

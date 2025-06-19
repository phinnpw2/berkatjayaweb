import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berkatjaya_web/cetaknota_screen.dart';

class PembayaranScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderMenu;

  PembayaranScreen({required this.orderMenu}); // Menghapus invoiceNumber dari konstruktor

  @override
  _PembayaranScreenState createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  late double totalAmount;
  late String invoiceNumber = "Loading..."; // Memberikan nilai default untuk invoiceNumber
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  double change = 0.0;
  String paymentMethod = 'Cash';

  late SharedPreferences prefs;
  int? previousCounter;

  @override
  void initState() {
    super.initState();
    totalAmount = widget.orderMenu.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    _initializeInvoiceNumber();
  }

  Future<void> _initializeInvoiceNumber() async {
    prefs = await SharedPreferences.getInstance();
    // Ambil counter dari Firestore untuk menghasilkan nomor invoice
    _getInvoiceCounter();
  }

  // Fungsi untuk menghasilkan nomor invoice berdasarkan counter
  String _generateInvoiceNumber(int counter) {
    return 'INV${counter.toString().padLeft(3, '0')}'; // Format invoice dengan 3 digit counter
  }

  // Ambil counter dari Firestore untuk membuat nomor invoice yang baru
  Future<void> _getInvoiceCounter() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').get();
      if (doc.exists) {
        int counter = doc['counter']; // Ambil counter terakhir
        previousCounter = counter; // Simpan counter sebelumnya untuk rollback jika diperlukan
        setState(() {
          invoiceNumber = _generateInvoiceNumber(counter + 1); // Generate nomor nota baru berdasarkan counter
        });
        _updateInvoiceCounter(counter + 1);  // Update counter di Firestore
      }
    } catch (e) {
      print("Error fetching counter: $e");
    }
  }

  // Update nilai counter di Firestore setelah transaksi selesai
  Future<void> _updateInvoiceCounter(int newCounter) async {
    try {
      await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').update({'counter': newCounter});
    } catch (e) {
      print("Error updating counter: $e");
    }
  }

  // Mengembalikan nilai counter Firestore jika transaksi dibatalkan
  Future<void> _rollbackInvoiceCounter() async {
    if (previousCounter != null) {
      try {
        await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').update({'counter': previousCounter});
        print("Counter rollback to: $previousCounter");
      } catch (e) {
        print("Error rolling back counter: $e");
      }
    }
  }

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

  bool isAmountPaidValid() {
    double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
    return amountPaid >= totalAmount;
  }

  // Fungsi untuk menyimpan transaksi ke Firestore
  Future<void> saveTransactionToFirestore() async {
    // Pastikan pembayaran valid sebelum melanjutkan
    if (!isAmountPaidValid()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang yang dibayar tidak cukup')));
      return;  // Jangan lanjutkan jika uang yang dibayar tidak cukup
    }

    Map<String, dynamic> transaction = {
      'customerName': customerNameController.text,
      'orderDetails': widget.orderMenu,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod, // Menyimpan metode pembayaran
      'change': change,
      'status_transaksi': 'selesai', // Menandakan bahwa transaksi telah selesai
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'invoiceNumber': invoiceNumber, // Menyimpan nomor invoice
    };

    try {
      // Simpan transaksi ke Firestore
      await FirebaseFirestore.instance.collection('riwayattransaksi').add(transaction);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan di Firestore!')));

      // Setelah transaksi berhasil disimpan, update nomor invoice di preferences
      await _updateInvoiceNumberInPreferences(invoiceNumber);

      // Pindah ke halaman cetak nota setelah transaksi selesai
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CetakNotaScreen(
            orderMenu: widget.orderMenu, 
            totalAmount: totalAmount,
            change: change,
            paymentMethod: paymentMethod,
            customerName: customerNameController.text,
            invoiceNumber: invoiceNumber, // Pastikan nomor nota yang terbaru dikirim
          ),
        ),
      );
    } catch (e) {
      print("Error saving transaction to Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi di Firestore!')));
    }
  }

  // Fungsi untuk memperbarui nomor invoice di SharedPreferences
  Future<void> _updateInvoiceNumberInPreferences(String newInvoiceNumber) async {
    await prefs.setString('invoiceNumber', newInvoiceNumber);
    setState(() {
      invoiceNumber = newInvoiceNumber; // Memperbarui invoiceNumber di UI
    });
  }

  // Icon untuk metode pembayaran
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Tunai':
        return Icons.payments;
      case 'Transfer BCA':
        return Icons.account_balance;
      case 'Transfer BRI':
        return Icons.account_balance;
      case 'Transfer Mandiri':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Color(0xFF003f7f),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Mengembalikan counter ke nilai semula jika transaksi dibatalkan
            _rollbackInvoiceCounter();
            Navigator.pop(context);  // Kembali ke halaman sebelumnya
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003f7f), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EAF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 450,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF003f7f).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan icon
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003f7f), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Nomor Nota: $invoiceNumber',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Input nama pelanggan dengan icon
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: customerNameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person, color: Color(0xFF003f7f)),
                          hintText: 'Masukkan nama pelanggan',
                          labelText: 'Nama Pelanggan',
                          labelStyle: TextStyle(color: Color(0xFF003f7f)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Rincian Produk dengan icon
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003f7f), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, color: Color(0xFF003f7f), size: 20),
                                SizedBox(width: 8),
                                Text('Rincian Produk:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                              ],
                            ),
                            SizedBox(height: 12),
                            ...widget.orderMenu.map((item) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.fastfood, color: Color(0xFF003f7f), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${item['name']} (x${item['quantity']})', 
                                            style: TextStyle(fontWeight: FontWeight.w600)),
                                          Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                            style: TextStyle(color: Color(0xFF003f7f), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Input uang dibayar dengan icon
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: amountPaidController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.attach_money, color: Color(0xFF003f7f)),
                          labelText: 'Masukkan Uang yang Dibayar',
                          labelStyle: TextStyle(color: Color(0xFF003f7f)),
                          hintText: 'Masukkan jumlah uang',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          calculateChange();
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Total dan kembalian dengan styling bagus
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF003f7f).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate, color: Color(0xFF003f7f)),
                              SizedBox(width: 8),
                              Text('Total yang harus dibayar:', style: TextStyle(fontSize: 16, color: Color(0xFF003f7f))),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF003f7f), Color(0xFF1565C0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Rp ${totalAmount.toStringAsFixed(2)}', 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.change_circle, color: Colors.green.shade600),
                              SizedBox(width: 8),
                              Text('Pengembalian: ', style: TextStyle(fontSize: 16, color: Colors.green.shade600)),
                              Text('Rp ${change.toStringAsFixed(2)}', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Pilihan metode pembayaran dengan icon
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment, color: Color(0xFF003f7f)),
                              SizedBox(width: 8),
                              Text('Metode Pembayaran:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFF003f7f).withOpacity(0.3)),
                            ),
                            child: DropdownButton<String>(
                              value: paymentMethod,
                              isExpanded: true,
                              underline: SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF003f7f)),
                              onChanged: (String? newValue) {
                                setState(() {
                                  paymentMethod = newValue!;
                                });
                              },
                              items: <String>['Cash', 'Transfer BCA', 'Transfer BRI', 'Transfer Mandiri']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(_getPaymentIcon(value), color: Color(0xFF003f7f), size: 20),
                                      SizedBox(width: 8),
                                      Text(value, style: TextStyle(color: Color(0xFF003f7f))),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Tombol cetak nota dengan styling menarik
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF003f7f), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF003f7f).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountPaidController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Masukkan nominal uang terlebih dahulu'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange,
                                )
                              );
                            } else if (!isAmountPaidValid()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Uang tidak cukup'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                )
                              );
                            } else {
                              // Menyimpan transaksi dan memperbarui nomor nota
                              saveTransactionToFirestore();
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.print, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Cetak Nota', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
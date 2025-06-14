import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:berkatjaya_web/cetaknota_screen.dart';

class PembayaranScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderMenu;
  final String invoiceNumber; // Menerima parameter invoiceNumber

  PembayaranScreen({required this.orderMenu, required this.invoiceNumber}); // Constructor menerima invoiceNumber

  @override
  _PembayaranScreenState createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  late double totalAmount;
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  double change = 0.0;
  String paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    totalAmount = widget.orderMenu.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
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

  Future<void> saveTransactionToSharedPreferences() async {
    Map<String, dynamic> transaction = {
      'customerName': customerNameController.text,
      'orderDetails': widget.orderMenu,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'change': change,
      'status_transaksi': 'selesai',
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'invoiceNumber': widget.invoiceNumber, // Menyimpan nomor invoice
    };

    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    transactionStrings.add(json.encode(transaction)); 
    await prefs.setStringList('transactions', transactionStrings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text('Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
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
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 450,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.red, Colors.yellow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text('Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: customerNameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama pelanggan',
                          labelText: 'Nama Pelanggan',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('Rincian Produk:', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.white24, Colors.white10],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                      Text('Total yang harus dibayar:', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 5),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.green, Colors.yellow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text('Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      SizedBox(height: 20),
                      Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(height: 20),
                      Text('Pembayaran:', style: TextStyle(fontSize: 18)),
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
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountPaidController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan nominal uang terlebih dahulu')));
                            } else if (!isAmountPaidValid()) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang tidak cukup')));
                            } else {
                              saveTransactionToSharedPreferences().then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pembayaran Berhasil!')));
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CetakNotaScreen(
                                    orderMenu: widget.orderMenu, 
                                    totalAmount: totalAmount,
                                    change: change,
                                    paymentMethod: paymentMethod,
                                    customerName: customerNameController.text,
                                    invoiceNumber: widget.invoiceNumber, // Pastikan invoiceNumber dikirimkan ke CetakNotaScreen
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text('Nota'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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
        ],
      ),
    );
  }
}

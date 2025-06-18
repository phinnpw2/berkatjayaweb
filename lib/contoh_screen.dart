// oke bisa jelaskan pada saya dibagian sini apa saja yang anda tambahkan logikanya? import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:berkatjaya_web/cetaknota_screen.dart';

// class PembayaranScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> orderMenu;

//   PembayaranScreen({required this.orderMenu}); // Menghapus invoiceNumber dari konstruktor

//   @override
//   _PembayaranScreenState createState() => _PembayaranScreenState();
// }

// class _PembayaranScreenState extends State<PembayaranScreen> {
//   late double totalAmount;
//   late String invoiceNumber; // Deklarasikan invoiceNumber di sini
//   TextEditingController amountPaidController = TextEditingController();
//   TextEditingController customerNameController = TextEditingController();
//   double change = 0.0;
//   String paymentMethod = 'Cash';

//   late SharedPreferences prefs;
//   int? previousCounter;

//   @override
//   void initState() {
//     super.initState();
//     totalAmount = widget.orderMenu.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
//     _initializeInvoiceNumber();
//   }

//   Future<void> _initializeInvoiceNumber() async {
//     prefs = await SharedPreferences.getInstance();
//     // Ambil counter dari Firestore untuk menghasilkan nomor invoice
//     _getInvoiceCounter();
//   }

//   // Fungsi untuk menghasilkan nomor invoice berdasarkan counter
//   String _generateInvoiceNumber(int counter) {
//     return 'INV-${counter.toString().padLeft(3, '0')}'; // Format invoice dengan 3 digit counter
//   }

//   // Ambil counter dari Firestore untuk membuat nomor invoice yang baru
//   Future<void> _getInvoiceCounter() async {
//     try {
//       DocumentSnapshot doc = await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').get();
//       if (doc.exists) {
//         int counter = doc['counter']; // Ambil counter terakhir
//         previousCounter = counter; // Simpan counter sebelumnya untuk rollback jika diperlukan
//         setState(() {
//           invoiceNumber = _generateInvoiceNumber(counter + 1); // Generate nomor nota baru berdasarkan counter
//         });
//         _updateInvoiceCounter(counter + 1);  // Update counter di Firestore
//       }
//     } catch (e) {
//       print("Error fetching counter: $e");
//     }
//   }

//   // Update nilai counter di Firestore setelah transaksi selesai
//   Future<void> _updateInvoiceCounter(int newCounter) async {
//     try {
//       await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').update({'counter': newCounter});
//     } catch (e) {
//       print("Error updating counter: $e");
//     }
//   }

//   // Mengembalikan nilai counter Firestore jika transaksi dibatalkan
//   Future<void> _rollbackInvoiceCounter() async {
//     if (previousCounter != null) {
//       try {
//         await FirebaseFirestore.instance.collection('invoiceCounter').doc('counter').update({'counter': previousCounter});
//         print("Counter rollback to: $previousCounter");
//       } catch (e) {
//         print("Error rolling back counter: $e");
//       }
//     }
//   }

//   void calculateChange() {
//     double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
//     setState(() {
//       if (amountPaid >= totalAmount) {
//         change = amountPaid - totalAmount;
//       } else {
//         change = 0.0;
//       }
//     });
//   }

//   bool isAmountPaidValid() {
//     double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
//     return amountPaid >= totalAmount;
//   }

//   // Fungsi untuk menyimpan transaksi ke Firestore
//   Future<void> saveTransactionToFirestore() async {
//     // Pastikan pembayaran valid sebelum melanjutkan
//     if (!isAmountPaidValid()) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang yang dibayar tidak cukup')));
//       return;  // Jangan lanjutkan jika uang yang dibayar tidak cukup
//     }

//     Map<String, dynamic> transaction = {
//       'customerName': customerNameController.text,
//       'orderDetails': widget.orderMenu,
//       'totalAmount': totalAmount,
//       'paymentMethod': paymentMethod, // Menyimpan metode pembayaran
//       'change': change,
//       'status_transaksi': 'selesai', // Menandakan bahwa transaksi telah selesai
//       'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
//       'invoiceNumber': invoiceNumber, // Menyimpan nomor invoice
//     };

//     try {
//       // Simpan transaksi ke Firestore
//       await FirebaseFirestore.instance.collection('riwayattransaksi').add(transaction);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan di Firestore!')));

//       // Setelah transaksi berhasil disimpan, update nomor invoice di preferences
//       await _updateInvoiceNumberInPreferences(invoiceNumber);

//       // Pindah ke halaman cetak nota setelah transaksi selesai
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CetakNotaScreen(
//             orderMenu: widget.orderMenu, 
//             totalAmount: totalAmount,
//             change: change,
//             paymentMethod: paymentMethod,
//             customerName: customerNameController.text,
//             invoiceNumber: invoiceNumber, // Pastikan nomor nota yang terbaru dikirim
//           ),
//         ),
//       );
//     } catch (e) {
//       print("Error saving transaction to Firestore: $e");
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi di Firestore!')));
//     }
//   }

//   // Fungsi untuk memperbarui nomor invoice di SharedPreferences
//   Future<void> _updateInvoiceNumberInPreferences(String newInvoiceNumber) async {
//     await prefs.setString('invoiceNumber', newInvoiceNumber);
//     setState(() {
//       invoiceNumber = newInvoiceNumber; // Memperbarui invoiceNumber di UI
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         backgroundColor: Color(0xFF003f7f),
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           color: Colors.white,
//           onPressed: () {
//             // Mengembalikan counter ke nilai semula jika transaksi dibatalkan
//             _rollbackInvoiceCounter();
//             Navigator.pop(context);  // Kembali ke halaman sebelumnya
//           },
//         ),
//       ),
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//               ),
//             ),
//           ),
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Container(
//                 width: 450,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.2),
//                       blurRadius: 15,
//                       spreadRadius: 5,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Nomor Nota: $invoiceNumber',  // Nomor nota akan diperbarui secara otomatis
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 20),
//                       TextField(
//                         controller: customerNameController,
//                         decoration: InputDecoration(
//                           hintText: 'Masukkan nama pelanggan',
//                           labelText: 'Nama Pelanggan',
//                           border: OutlineInputBorder(),
//                           filled: true,
//                           fillColor: Colors.grey.shade100,
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       Text('Rincian Produk:', style: TextStyle(fontSize: 18)),
//                       SizedBox(height: 10),
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(8),
//                           gradient: LinearGradient(
//                             colors: [Colors.white24, Colors.white10],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                         ),
//                         child: Column(
//                           children: widget.orderMenu.map((item) {
//                             return ListTile(
//                               title: Text('${item['name']} (x${item['quantity']})'),
//                               subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       TextField(
//                         controller: amountPaidController,
//                         keyboardType: TextInputType.number,
//                         decoration: InputDecoration(
//                           labelText: 'Masukkan Uang yang Dibayar',
//                           hintText: 'Masukkan jumlah uang',
//                           border: OutlineInputBorder(),
//                           filled: true,
//                           fillColor: Colors.grey.shade100,
//                         ),
//                         onChanged: (value) {
//                           calculateChange();
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       Text('Total yang harus dibayar:', style: TextStyle(fontSize: 18)),
//                       SizedBox(height: 5),
//                       ShaderMask(
//                         shaderCallback: (bounds) => LinearGradient(
//                           colors: [Colors.green, Colors.yellow],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ).createShader(bounds),
//                         child: Text('Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
//                       ),
//                       SizedBox(height: 20),
//                       Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
//                       SizedBox(height: 20),
//                       Text('Pembayaran:', style: TextStyle(fontSize: 18)),
//                       DropdownButton<String>(
//                         value: paymentMethod,
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             paymentMethod = newValue!;
//                           });
//                         },
//                         items: <String>['Cash', 'Transfer BCA', 'Transfer BRI', 'Transfer Mandiri']
//                             .map<DropdownMenuItem<String>>((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(value),
//                           );
//                         }).toList(),
//                       ),
//                       SizedBox(height: 20),
//                       Center(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (amountPaidController.text.isEmpty) {
//                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan nominal uang terlebih dahulu')));
//                             } else if (!isAmountPaidValid()) {
//                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang tidak cukup')));
//                             } else {
//                               // Menyimpan transaksi dan memperbarui nomor nota
//                               saveTransactionToFirestore();
//                             }
//                           },
//                           child: Text('Nota'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white12,
//                             padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
//                             textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

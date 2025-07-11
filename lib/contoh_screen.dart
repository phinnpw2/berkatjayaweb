// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'kasir_screen.dart';
// import 'notatempo_screen.dart';

// class CetakNotaScreen extends StatelessWidget {
//   final String customerName;
//   final List<Map<String, dynamic>> orderMenu;
//   final double totalAmount;
//   final double change;
//   final String paymentMethod;
//   final String invoiceNumber;
//   final Timestamp? originalTimestamp;

//   CetakNotaScreen({
//     required this.customerName,
//     required this.orderMenu,
//     required this.totalAmount,
//     required this.change,
//     required this.paymentMethod,
//     required this.invoiceNumber,
//     this.originalTimestamp,
//   });

//   Future<void> _printPdf(BuildContext context) async {
//   final pdf = pw.Document();
//   final orderDate = originalTimestamp?.toDate() ?? DateTime.now();

//   // Hitung tinggi konten berdasarkan jumlah item
//   final baseHeight = 180.0; // untuk header, footer, dan total
//   final itemHeight = 12.0; // tinggi per item
//   final contentHeight = baseHeight + (orderMenu.length * itemHeight);
//   final pageHeight = contentHeight < 250 ? 250.0 : contentHeight;

//   pdf.addPage(
//   pw.Page(
//     pageFormat: PdfPageFormat.roll80.copyWith(height: pageHeight),
//       build: (pw.Context ctx) {
//         return pw.Container(
//           padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Center(child: pw.Text('TOKO BERKAT JAYA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
//               pw.Center(child: pw.Text('Jl. Slamet Riady', style: pw.TextStyle(fontSize: 9))),
//               pw.SizedBox(height: 8),
//               pw.Text('Nota: $invoiceNumber', style: pw.TextStyle(fontSize: 8)),
//               pw.Text('Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(orderDate)}', style: pw.TextStyle(fontSize: 8)),
//               pw.Text('Kasir: Evy', style: pw.TextStyle(fontSize: 8)),
//               pw.Divider(thickness: 0.5),
//               ...orderMenu.map((item) => pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Expanded(child: pw.Text('${item['name']} x${item['quantity']}', style: pw.TextStyle(fontSize: 8))),
//                   pw.Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8)),
//                 ],
//               )),
//               pw.Divider(thickness: 0.5),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text('Total:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//                   pw.Text('Rp ${totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//                 ],
//               ),
//               pw.SizedBox(height: 4),
//               pw.Text('Pelanggan: $customerName', style: pw.TextStyle(fontSize: 8)),
//               pw.Text('Pembayaran: $paymentMethod', style: pw.TextStyle(fontSize: 8)),
//               pw.Text('Kembalian: Rp ${change.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8)),
//               pw.SizedBox(height: 8),
//               pw.Center(child: pw.Text('Terima Kasih', style: pw.TextStyle(fontSize: 9))),
//             ],
//           ),
//         );
//       },
//     ),
//   );

//   final bytes = await pdf.save();

//   await Printing.layoutPdf(
//     name: 'Nota_$invoiceNumber.pdf',
//     format: PdfPageFormat(80 * PdfPageFormat.mm, pageHeight),
//     onLayout: (PdfPageFormat format) async => bytes,
//   );
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         backgroundColor: Color(0xFF003f7f),
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF003f7f).withOpacity(0.1), Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.check_circle, color: Color(0xFF003f7f), size: 50),
//                     SizedBox(height: 10),
//                     Text('Pesanan Berhasil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
//                     SizedBox(height: 5),
//                     Text('Nota #$invoiceNumber', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
//                     Text('${DateFormat('dd MMMM yyyy, HH:mm').format(originalTimestamp?.toDate() ?? DateTime.now())}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
//                     SizedBox(height: 15),
//                     ...orderMenu.map((item) => Padding(
//                       padding: EdgeInsets.only(bottom: 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text('${item['name']} x${item['quantity']}', style: TextStyle(fontSize: 14)),
//                           ),
//                           Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//                         ],
//                       ),
//                     )).toList(),
//                     Divider(color: Colors.grey[300]),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         Text('Rp ${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Informasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
//                     SizedBox(height: 15),
//                     _buildInfoRow('Pelanggan', customerName),
//                     _buildInfoRow('Pembayaran', paymentMethod),
//                     _buildInfoRow('Kembalian', 'Rp ${change.toStringAsFixed(0)}'),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 30),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _printPdf(context),
//                       icon: Icon(Icons.print, color: Colors.white),
//                       label: Text('Cetak Nota', style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF003f7f),
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 15),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.pushAndRemoveUntil(
//                         context,
//                         MaterialPageRoute(builder: (context) => KasirScreen()),
//                         (route) => false,
//                       ),
//                       icon: Icon(Icons.add, color: Colors.white),
//                       label: Text('Transaksi Baru', style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => NotaTempoScreen()),
//                       ),
//                       icon: Icon(Icons.schedule, color: Colors.white),
//                       label: Text('Nota Tempo', style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
//           Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }

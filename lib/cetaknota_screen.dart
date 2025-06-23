import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'kasir_screen.dart';
import 'notatempo_screen.dart';

class CetakNotaScreen extends StatelessWidget {
  final String customerName;
  final List<Map<String, dynamic>> orderMenu;
  final double totalAmount;
  final double change;
  final String paymentMethod;
  final String invoiceNumber;
  final Timestamp? originalTimestamp;

  CetakNotaScreen({
    required this.customerName,
    required this.orderMenu,
    required this.totalAmount,
    required this.change,
    required this.paymentMethod,
    required this.invoiceNumber,
    this.originalTimestamp,
  });

  Future<void> _printPdf(BuildContext context) async {
    print('👉 _printPdf terpanggil...');
    final pdf = pw.Document();

    final orderDate = originalTimestamp?.toDate() ?? DateTime.now();
    final printDate = DateTime.now();

    pdf.addPage(
  pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (pw.Context ctx) {
      return pw.Center(
        child: pw.Container(
          width: 350,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              pw.Center(
                child: pw.Text(
                  'LOGO TOKO',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              // Alamat
              pw.Center(
                child: pw.Text(
                  'Toko Berkat Jaya\nJl. Slamet Riady',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              // Tanggal
              if (originalTimestamp != null)
                pw.Text(
                  'Tanggal Nota Dibuat: ${DateFormat('yyyy-MM-dd').format(orderDate)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Text(
                'Tanggal Cetak: ${DateFormat('yyyy-MM-dd').format(printDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              // Info Nota dan Kasir
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nomor Nota: $invoiceNumber', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Kasir: Evy', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Divider(),
              // Detail Pembelian
              pw.Text(
                'Detail Pembelian:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              // Tabel
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Produk',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Subtotal', style: pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  ...orderMenu.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item['name'],
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'x${item['quantity']}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Rp ${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Informasi lain
              pw.Text('Nama Pelanggan: $customerName', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Total Harga: Rp ${totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Pengembalian: Rp ${change.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Metode Pembayaran: $paymentMethod', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    },
  ),
);


    final bytes = await pdf.save();
    print('📄 PDF selesai dibuat (${bytes.length} bytes), memanggil Printing.layoutPdf...');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );
    print('✅ layoutPdf selesai dieksekusi.');
  }

  @override
  Widget build(BuildContext context) {
    DateTime orderDate = originalTimestamp?.toDate() ?? DateTime.now();
    DateTime printDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Nota', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'LOGO TOKO',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Toko Berkat Jaya\nJl. Slamet Riady',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (originalTimestamp != null)
                      Text('Tanggal Nota Dibuat: ${DateFormat('yyyy-MM-dd').format(orderDate)}'),
                    Text('Tanggal Cetak: ${DateFormat('yyyy-MM-dd').format(printDate)}'),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nomor Nota: $invoiceNumber'),
                        const Text('Kasir: Evy'),
                      ],
                    ),
                    const Divider(),
                    const Text('Detail Pembelian:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...orderMenu.map((item) {
                      return ListTile(
                        title: Text('${item['name']} (x${item['quantity']})'),
                        subtitle: Text(
                            'Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    const Divider(),
                    Text('Nama Pelanggan: $customerName'),
                    Text('Total Harga: Rp ${totalAmount.toStringAsFixed(0)}'),
                    Text('Pengembalian: Rp ${change.toStringAsFixed(0)}'),
                    Text('Metode Pembayaran : $paymentMethod'),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => KasirScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Transaksi Baru'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotaTempoScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Nota Tempo'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _printPdf(context); // panggil print
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Cetak Nota'),
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

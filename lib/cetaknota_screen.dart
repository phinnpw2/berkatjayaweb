import 'package:berkatjaya_web/kasir_screen.dart';
import 'package:berkatjaya_web/notatempo_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CetakNotaScreen extends StatelessWidget {
  final String customerName;
  final List<Map<String, dynamic>> orderMenu;
  final double totalAmount;
  final double change;
  final String paymentMethod;
  final String invoiceNumber;
  final Timestamp? originalTimestamp;
  final bool blockBackButton;  // Parameter baru untuk mengatur apakah tombol back diblokir

  // Memberikan nilai default false untuk blockBackButton
  CetakNotaScreen({
    required this.customerName,
    required this.orderMenu,
    required this.totalAmount,
    required this.change,
    required this.paymentMethod,
    required this.invoiceNumber,
    this.originalTimestamp,
    this.blockBackButton = false,  // Default false jika tidak diberikan
  });

  Future<void> _printPdf(BuildContext context) async {
    final pdf = pw.Document();
    final orderDate = originalTimestamp?.toDate() ?? DateTime.now();

    // Menyesuaikan ukuran halaman menjadi 47mm untuk lebar dan panjang otomatis sesuai isi
    final itemHeight = 10.0; // Tentukan tinggi setiap item yang lebih besar
    final baseHeight = 70.0; // Untuk header dan informasi dasar lainnya
    final pageHeight = baseHeight + (orderMenu.length * itemHeight);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(47 * PdfPageFormat.mm, pageHeight * PdfPageFormat.mm), // Ukuran kertas 47mm x panjang dinamis
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Teks judul dan alamat
              pw.Center(
                child: pw.Text(
                  'TOKO BERKAT JAYA',
                  style: pw.TextStyle(
                    fontSize: 10, // Memperbesar font
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Jl. Slamet Riady',
                  style: pw.TextStyle(fontSize: 8), // Memperbesar sedikit
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '11 Ilir Palembang',
                  style: pw.TextStyle(fontSize: 8), // Memperbesar sedikit
                ),
              ),
              pw.SizedBox(height: 5),
              // Nota, Tanggal dan Kasir
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Nota: $invoiceNumber',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Tanggal: ${DateFormat('dd/MM/yyyy').format(orderDate)}',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Kasir: Evy',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Waktu   : ${DateFormat('HH:mm').format(orderDate)}',
                      style: pw.TextStyle(fontSize: 6), // Menambahkan waktu di sebelah kanan
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              // Bagian Pesanan: produk, jumlah, dan harga per produk
              ...orderMenu.map((item) => pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 5), // Menambah jarak antar produk
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${item['name']} x${item['quantity']}',
                            style: pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Rp. ${_formatCurrency(item['price'] * item['quantity'])}',
                            style: pw.TextStyle(fontSize: 7),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Rp. ${_formatCurrency(item['price'])}',
                      style: pw.TextStyle(fontSize: 6), // Menampilkan harga per item
                    ),
                  ],
                ),
              )),

              pw.Divider(thickness: 0.5),
              // Total dan informasi pembayaran
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Total:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Rp. ${_formatCurrency(totalAmount)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right, // Membuat total lebih ke kanan
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pelanggan: $customerName',
                style: pw.TextStyle(fontSize: 6),
              ),
              pw.SizedBox(height: 2), // Jarak antar informasi
              pw.Text(
                'Pembayaran: $paymentMethod',
                style: pw.TextStyle(fontSize: 6),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Kembalian: Rp. ${_formatCurrency(change)}',
                style: pw.TextStyle(fontSize: 6),
              ),
              pw.SizedBox(height: 5),
              // Bagian Terima Kasih
              pw.Center(
                child: pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(fontSize: 6),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Menampilkan preview print langsung
    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes, // Menyediakan byte array PDF
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(amount);
  }

   @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (blockBackButton) {
          // Jika flag true (transaksi selesai), blokir tombol back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaksi sudah selesai, tidak bisa kembali'),
              backgroundColor: Colors.orange,
            ),
          );
          return false;  // Blokir aksi kembali
        }
        return true;  // Izinkan kembali jika flag false
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003f7f).withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF003f7f), size: 50),
                    SizedBox(height: 10),
                    Text('Pesanan Berhasil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                    SizedBox(height: 5),
                    Text('Nota #$invoiceNumber', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    Text('${DateFormat('dd MMMM yyyy, HH:mm').format(originalTimestamp?.toDate() ?? DateTime.now())}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                    SizedBox(height: 15),
                    ...orderMenu.map((item) => Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item['name']} x${item['quantity']}', style: TextStyle(fontSize: 14)),
                              ),
                              Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )),
                    Divider(color: Colors.grey[300]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Rp ${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                    SizedBox(height: 15),
                    _buildInfoRow('Pelanggan', customerName),
                    _buildInfoRow('Pembayaran', paymentMethod),
                    _buildInfoRow('Kembalian', 'Rp ${change.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printPdf(context),
                      icon: Icon(Icons.print, color: Colors.white),
                      label: Text('Cetak Nota', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF003f7f),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => KasirScreen()),
                        (route) => false,
                      ),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Transaksi Baru', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotaTempoScreen()),
                      ),
                      icon: Icon(Icons.schedule, color: Colors.white),
                      label: Text('Nota Tempo', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:berkatjaya_web/notatempo_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Mengimpor intl untuk format tanggal
import 'package:berkatjaya_web/cetaknota_screen.dart'; // Mengimpor CetakNotaScreen
import 'package:berkatjaya_web/statusnotatempo_screen.dart'; // Mengimpor StatusNotaTempoScreen

class PesananScreen extends StatefulWidget {
  @override
  _PesananScreenState createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  String searchQuery = ""; // Variabel untuk pencarian nama pelanggan
  DateTime? startDate;
  DateTime? endDate;

  // Fungsi untuk memilih tanggal mulai
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked; // Menyimpan tanggal yang dipilih
      });
    }
  }

  // Fungsi untuk memilih tanggal akhir
  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked; // Menyimpan tanggal yang dipilih
      });
    }
  }

  // Fungsi untuk menghapus pesanan dan mengembalikan stok produk
  void deleteOrder(String orderId, List<dynamic> orderMenu) async {
    try {
      // Menghapus pesanan dari Firestore
      await FirebaseFirestore.instance.collection('pesanan').doc(orderId).delete();

      // Mengembalikan stok produk yang telah dipesan
      for (var item in orderMenu) {
        final docRef = FirebaseFirestore.instance.collection('produk').doc(item['id']);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final currentStock = docSnapshot.data()?['stok'] ?? 0;
          await docRef.update({'stok': currentStock + item['quantity']}); // Menambah stok sesuai dengan quantity yang dibeli
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dihapus dan stok dikembalikan')));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus pesanan: $e')));
    }
  }

  // Fungsi untuk menghasilkan nomor invoice
  Future<String> generateInvoiceNumber() async {
    try {
      DocumentReference invoiceRef = FirebaseFirestore.instance.collection('invoiceCounter').doc('counter');
      DocumentSnapshot snapshot = await invoiceRef.get();

      int invoiceNumber = 1;

      if (snapshot.exists) {
        invoiceNumber = snapshot['counter'] ?? 1;  // Mengambil nomor invoice dari Firestore
      }

      // Update nomor invoice
      await invoiceRef.set({
        'counter': invoiceNumber + 1,  // Increment nomor invoice
      }, SetOptions(merge: true));

      return 'INV${invoiceNumber.toString().padLeft(3, '0')}';  // Format INV001, INV002, dst.
    } catch (e) {
      print("Error generating invoice number: $e");
      return 'INV001';  // Kembalikan default jika terjadi error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF003f7f), // AppBar color matching RiwayatTransaksi screen
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => NotaTempoScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase(); // Mengubah pencarian menjadi lowercase
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Nama Pelanggan',
                labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Ensure text is visible
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF003f7f)),
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF003f7f)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => selectStartDate(context),
                child: Text(
                  startDate == null ? 'Pilih Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White bold text for buttons
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF003f7f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => selectEndDate(context),
                child: Text(
                  endDate == null ? 'Pilih Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White bold text for buttons
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF003f7f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final pesananDocs = snapshot.data!.docs;
                if (pesananDocs.isEmpty) {
                  return Center(child: Text('Belum ada pesanan'));
                }

                final filteredDocs = pesananDocs.where((doc) {
                  final pesananData = doc.data() as Map<String, dynamic>;
                  final customerName = pesananData['customerName'] ?? '';
                  final timestamp = pesananData['timestamp']?.toDate();
                  bool isInDateRange = true;

                  if (startDate != null && timestamp != null) {
                    isInDateRange = timestamp.isAfter(startDate!);
                  }
                  if (endDate != null && timestamp != null) {
                    isInDateRange = isInDateRange && timestamp.isBefore(endDate!.add(Duration(days: 1)));
                  }

                  return customerName.toLowerCase().contains(searchQuery) && isInDateRange;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final pesananData = filteredDocs[index].data() as Map<String, dynamic>;
                    final customerName = pesananData['customerName'] ?? 'Tidak ada nama';
                    final orderMenu = pesananData['orderDetails'] as List<dynamic>;
                    final orderId = filteredDocs[index].id;
                    final timestamp = pesananData['timestamp']?.toDate() ?? DateTime.now();
                    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
                    final invoiceNumber = pesananData['invoiceNumber'];

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
                                    Text('Pelanggan: $customerName', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Nomor Nota: $invoiceNumber', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Text('Rincian Produk:'),
                                    SizedBox(height: 10),
                                    Column(
                                      children: List.generate(orderMenu.length, (i) {
                                        var product = orderMenu[i];
                                        double totalPrice = product['price'] * product['quantity'];
                                        return Card(
                                          margin: EdgeInsets.only(bottom: 10),
                                          elevation: 5,
                                          color: Colors.grey.shade300,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                                                SizedBox(height: 5),
                                                Text('Jumlah: ${product['quantity']}'),
                                                Text('Harga per Unit: Rp ${product['price']}'),
                                                Text('Total: Rp ${totalPrice}'),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
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
                      child: Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.grey.shade300,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$customerName - Pesanan pada $formattedTime', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                              SizedBox(height: 10),
                              Text('Nomor Nota: $invoiceNumber', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text('Total: Rp ${(pesananData['total'] ?? 0.0).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  double totalAmount = pesananData['total'] ?? 0.0;
                                  double change = pesananData['change'] ?? 0.0;
                                  String paymentMethod = pesananData['paymentMethod'] ?? 'Tidak Diketahui';

                                  List<Map<String, dynamic>> formattedOrderMenu = List<Map<String, dynamic>>.from(orderMenu);

                                  String invoiceNumber = await generateInvoiceNumber();

                                  await FirebaseFirestore.instance.collection('pesanan').doc(orderId).update({
                                    'status': 'Belum Lunas',
                                    'invoiceNumber': invoiceNumber,
                                  });

                                  await FirebaseFirestore.instance.collection('pesanan').doc(orderId).delete();

                                  await FirebaseFirestore.instance.collection('statusnotatempo').add({
                                    'customerName': customerName,
                                    'orderDetails': formattedOrderMenu,
                                    'total': totalAmount,
                                    'change': change,
                                    'paymentMethod': paymentMethod,
                                    'status': 'Belum Lunas',
                                    'invoiceNumber': invoiceNumber,
                                  });

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CetakNotaScreen(
                                        customerName: customerName,
                                        orderMenu: formattedOrderMenu,
                                        totalAmount: totalAmount,
                                        change: change,
                                        paymentMethod: paymentMethod,
                                        invoiceNumber: invoiceNumber,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
    'Cetak Nota',
    style: TextStyle(
      color: Colors.white, // White text color
      fontWeight: FontWeight.bold, // Bold text
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF003f7f), 
    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
),
                              SizedBox(height: 1),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.blueGrey),
                                  onPressed: () => deleteOrder(orderId, orderMenu),
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
          ),
        ],
      ),
    );
  }
}

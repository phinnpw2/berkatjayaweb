import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Mengimpor intl untuk format tanggal
import 'package:berkatjaya_web/detailpesanan_screen.dart'; // Pastikan file ini ada dan sesuai

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
      fieldLabelText: 'Pilih Tanggal Mulai', // Ganti label dengan Bahasa Indonesia
      initialDatePickerMode: DatePickerMode.day, // Memulai dengan mode hari
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
      fieldLabelText: 'Pilih Tanggal Akhir', // Ganti label dengan Bahasa Indonesia
      initialDatePickerMode: DatePickerMode.day, // Memulai dengan mode hari
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase(); // Mengubah pencarian menjadi lowercase untuk memudahkan pencarian
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Nama Pelanggan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Pilih Tanggal Mulai
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => selectStartDate(context),
                child: Text(
                    startDate == null ? 'Pilih Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!)), // Format tanggal Indonesia
              ),
              SizedBox(width: 10),
              // Pilih Tanggal Akhir
              ElevatedButton(
                onPressed: () => selectEndDate(context),
                child: Text(
                    endDate == null ? 'Pilih Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!)), // Format tanggal Indonesia
              ),
            ],
          ),
          // StreamBuilder untuk menampilkan data pesanan
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

                // Menyaring pesanan berdasarkan nama pelanggan yang sesuai dengan pencarian
                final filteredDocs = pesananDocs.where((doc) {
                  final pesananData = doc.data() as Map<String, dynamic>;
                  final customerName = pesananData['customerName'] ?? '';
                  final timestamp = pesananData['timestamp']?.toDate();
                  bool isInDateRange = true;

                  // Filter berdasarkan rentang tanggal
                  if (startDate != null && timestamp != null) {
                    isInDateRange = timestamp.isAfter(startDate!);
                  }
                  if (endDate != null && timestamp != null) {
                    isInDateRange = isInDateRange && timestamp.isBefore(endDate!.add(Duration(days: 1)));
                  }

                  return customerName.toLowerCase().contains(searchQuery) && isInDateRange; // Memeriksa kecocokan nama pelanggan
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final pesananData = filteredDocs[index].data() as Map<String, dynamic>;
                    final customerName = pesananData['customerName'] ?? 'Tidak ada nama'; // Mengambil nama pelanggan
                    final timestamp = pesananData['timestamp']?.toDate() ?? DateTime.now();
                    final orderMenu = pesananData['orderDetails'] as List<dynamic>;
                    final totalCharge = pesananData['total'] ?? 0.0;
                    final orderId = filteredDocs[index].id; // Mendapatkan ID pesanan

                    // Format waktu dengan tanggal, jam dan menit
                    String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);

                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$customerName - Pesanan pada $formattedTime',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPesananScreen(orderId: orderId),
                                  ),
                                );
                              },
                              child: Text('Lihat Detail Pesanan'),
                            ),
                            ElevatedButton(
                              onPressed: () => deleteOrder(orderId, orderMenu),
                              child: Text('Hapus Pesanan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context); // Kembali ke layar kasir
        },
        child: Icon(Icons.arrow_back),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }
}

class DetailPesananScreen extends StatelessWidget {
  final String orderId;

  DetailPesananScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pesanan').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pesananData = snapshot.data!.data() as Map<String, dynamic>;
          final orderMenu = pesananData['orderDetails'] as List<dynamic>;
          final totalCharge = pesananData['total'] ?? 0.0;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: orderMenu.length,
                  itemBuilder: (context, index) {
                    final item = orderMenu[index];
                    return ListTile(
                      title: Text('${item['name']} (x${item['quantity']})'),
                      subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              Text(
                'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }
}

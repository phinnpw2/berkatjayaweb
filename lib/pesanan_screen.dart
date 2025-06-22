import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:berkatjaya_web/cetaknota_screen.dart';

class PesananScreen extends StatefulWidget {
  @override
  _PesananScreenState createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> with SingleTickerProviderStateMixin {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tab
  }

  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> showPaymentMethodDialog(String orderId, Map<String, dynamic> pesananData) async {
  String selectedPaymentMethod = 'Tidak Diketahui';
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Pilih Metode Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Tunai'),
            onTap: () {
              selectedPaymentMethod = 'Tunai';
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Transfer BCA'),
            onTap: () {
              selectedPaymentMethod = 'Transfer BCA';
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Transfer BRI'),
            onTap: () {
              selectedPaymentMethod = 'Transfer BRI';
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Transfer Mandiri'),
            onTap: () {
              selectedPaymentMethod = 'Transfer Mandiri';
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
      ],
    ),
  );

  if (selectedPaymentMethod != 'Tidak Diketahui') {
    final customerName = pesananData['customerName'];
    final orderDetails = pesananData['orderDetails'];
    final totalAmount = pesananData['total'];
    final invoiceNumber = pesananData['invoiceNumber'];

    // 1️⃣ Tambahkan data ke riwayattransaksi
    await FirebaseFirestore.instance.collection('riwayattransaksi').add({
      'customerName': customerName,
      'orderDetails': orderDetails,
      'totalAmount': totalAmount,
      'paymentMethod': selectedPaymentMethod,
      'status': 'Lunas',
      'invoiceNumber': invoiceNumber,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Hapus dokumen pesanan
    await FirebaseFirestore.instance.collection('pesanan').doc(orderId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran berhasil dikonfirmasi dan pesanan dipindahkan ke riwayat.'),
      ),
    );

    setState(() {});
  }
}

  Widget buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final customerName = data['customerName'] ?? '';
    final orderMenu = data['orderDetails'] as List<dynamic>;
    final rawTimestamp = data['timestamp'];
    DateTime timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    } else {
      timestamp = DateTime.now();
    }
    final invoiceNumber = data['invoiceNumber'];
    final totalAmount = data['total'] ?? 0.0;
    final statusNota = data['statusNota'] ?? 'belum dicetak';
    final statusPembayaran = data['statusPembayaran'] ?? 'belum lunas';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Rincian Produk'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pelanggan: $customerName', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Nomor Nota: $invoiceNumber', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Column(
                    children: orderMenu.map((product) {
                      double totalPrice = product['price'] * product['quantity'];
                      return Card(
                        color: Colors.grey.shade300,
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Jumlah: ${product['quantity']}'),
                              Text('Harga per Unit: Rp ${product['price']}'),
                              Text('Total: Rp $totalPrice'),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
        );
      },
      child: Card(
        color: Colors.grey.shade300,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$customerName - ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Nomor Nota: $invoiceNumber'),
              Text('Total: Rp ${totalAmount.toStringAsFixed(2)}'),
              SizedBox(height: 8),
              Text(
                'Status Nota: $statusNota',
                style: TextStyle(
                  color: statusNota == 'sudah dicetak' ? Colors.green : Colors.red,
                ),
              ),
              Text(
                'Status Pembayaran: $statusPembayaran',
                style: TextStyle(
                  color: statusPembayaran == 'lunas' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              if (statusNota == 'belum dicetak')
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('pesanan').doc(doc.id).update(
                      {
                        'statusNota': 'sudah dicetak',
                      },
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CetakNotaScreen(
                          customerName: customerName,
                          orderMenu: List<Map<String, dynamic>>.from(orderMenu),
                          totalAmount: totalAmount,
                          change: data['change'] ?? 0.0,
                          paymentMethod: data['paymentMethod'] ?? '',
                          invoiceNumber: invoiceNumber,
                          originalTimestamp: rawTimestamp as Timestamp,
                        ),
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nota berhasil dicetak dan status diperbarui'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003f7f),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Cetak Nota',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              if (statusNota == 'sudah dicetak' && statusPembayaran == 'belum lunas')
                ElevatedButton(
                  onPressed: () async {
                    await showPaymentMethodDialog(doc.id, data);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPesananList(String statusNota) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pesanan').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final customerName = data['customerName'] ?? '';
          final rawTimestamp = data['timestamp'];
          DateTime timestamp;
          if (rawTimestamp is Timestamp) {
            timestamp = rawTimestamp.toDate();
          } else {
            timestamp = DateTime.now();
          }

          final pesananStatusNota = data['statusNota'] ?? 'belum dicetak';
          bool inRange = true;

          if (startDate != null) inRange = timestamp.isAfter(startDate!);
          if (endDate != null) inRange &= timestamp.isBefore(endDate!.add(Duration(days: 1)));

          return pesananStatusNota == statusNota &&
              customerName.toLowerCase().contains(searchQuery) &&
              inRange;
        }).toList();

        if (docs.isEmpty) return Center(child: Text('Belum ada pesanan'));
        return ListView(
          children: docs.map((doc) => buildOrderCard(doc)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pesanan & Status Pesanan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF003f7f),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Pesanan'),
            Tab(text: 'Status Pesanan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari Nama Pelanggan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF003f7f)),
              ),
              onChanged: (query) => setState(() => searchQuery = query.toLowerCase()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => selectStartDate(context),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF003f7f)),
                child: Text(
                  startDate == null ? 'Tanggal Mulai' : DateFormat('dd-MM-yyyy').format(startDate!),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => selectEndDate(context),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF003f7f)),
                child: Text(
                  endDate == null ? 'Tanggal Akhir' : DateFormat('dd-MM-yyyy').format(endDate!),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildPesananList('belum dicetak'),
                buildPesananList('sudah dicetak'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

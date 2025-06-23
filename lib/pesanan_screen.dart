import 'package:berkatjaya_web/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:berkatjaya_web/cetaknota_screen.dart';

class PesananScreen extends StatefulWidget {
  @override
  _PesananScreenState createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;

  static const Color _primaryColor = Color(0xFF003f7f);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _cardColor = Color(0xFFF8FAFE);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _showPaymentDialog(String orderId, Map<String, dynamic> data) async {
    String? selectedMethod;
    final methods = ['Tunai', 'Transfer BCA', 'Transfer BRI', 'Transfer Mandiri'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pilih Metode Pembayaran', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) => 
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    selectedMethod = method;
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Text(method, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            )
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (selectedMethod != null) {
      await _processPayment(orderId, data, selectedMethod!);
    }
  }

  Future<void> _processPayment(String orderId, Map<String, dynamic> data, String paymentMethod) async {
    try {
      await FirebaseFirestore.instance.collection('riwayattransaksi').add({
        'customerName': data['customerName'],
        'orderDetails': data['orderDetails'],
        'totalAmount': data['total'],
        'paymentMethod': paymentMethod,
        'status': 'Lunas',
        'invoiceNumber': data['invoiceNumber'],
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('pesanan').doc(orderId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran berhasil dikonfirmasi'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final customerName = data['customerName'] ?? '';
  final orderMenu = data['orderDetails'] as List<dynamic>;
  final invoiceNumber = data['invoiceNumber'];
  final totalAmount = data['total'] ?? 0.0;
  final statusNota = data['statusNota'] ?? 'belum dicetak';
  final statusPembayaran = data['statusPembayaran'] ?? 'belum lunas';

  DateTime timestamp = DateTime.now();
  final rawTimestamp = data['timestamp'];
  if (rawTimestamp is Timestamp) {
    timestamp = rawTimestamp.toDate();
  }

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showOrderDetails(customerName, invoiceNumber, orderMenu),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: _primaryColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusNota == 'sudah dicetak'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusNota == 'sudah dicetak' ? 'Dicetak' : 'Belum Cetak',
                    style: TextStyle(
                      color: statusNota == 'sudah dicetak'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // ✅ Status pembayaran hanya tampil saat sudah dicetak
            if (statusNota == 'sudah dicetak') ...[
              Row(
                children: [
                  Icon(
                    statusPembayaran == 'lunas' ? Icons.check_circle : Icons.error_outline,
                    color: statusPembayaran == 'lunas' ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    statusPembayaran == 'lunas' ? 'Sudah Dibayar' : 'Belum Dibayar',
                    style: TextStyle(
                      color: statusPembayaran == 'lunas' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],

            Row(
              children: [
                Icon(Icons.receipt, color: Colors.grey, size: 16),
                SizedBox(width: 6),
                Text(
                  invoiceNumber,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Spacer(),
                Text(
                  DateFormat('dd/MM/yy HH:mm').format(timestamp),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Rp ${NumberFormat('#,###').format(totalAmount)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            SizedBox(height: 16),

            // Bagian tombol aksi (Cetak nota, Konfirmasi pembayaran, dll)
            _buildActionButtons(doc, data, statusNota, statusPembayaran),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildActionButtons(DocumentSnapshot doc, Map<String, dynamic> data, String statusNota, String statusPembayaran) {
    return Row(
      children: [
        if (statusNota == 'belum dicetak')
          Align(
  alignment: Alignment.centerLeft, // untuk membuatnya di sebelah kiri
  child: ElevatedButton.icon(
    onPressed: () => _printInvoice(doc, data, true),
    icon: Icon(Icons.print, size: 16),
    label: Text(
      'Cetak Nota',
      style: TextStyle(fontSize: 12),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          )
        else ...[
          Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Cetak Ulang
    OutlinedButton.icon(
      onPressed: () => _printInvoice(doc, data, false),
      icon: Icon(Icons.refresh, size: 16),
      label: Text(
        'Cetak Ulang',
        style: TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    if (statusPembayaran == 'belum lunas') ...[
      SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () => _showPaymentDialog(doc.id, data),
        icon: Icon(Icons.payment, size: 16),
        label: Text(
          'Konfirmasi',
          style: TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
          ),
        ],
      ],
    );
  }

  void _printInvoice(DocumentSnapshot doc, Map<String, dynamic> data, bool isFirstPrint) async {
    if (isFirstPrint) {
      await FirebaseFirestore.instance.collection('pesanan').doc(doc.id).update({'statusNota': 'sudah dicetak'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status nota diperbarui'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CetakNotaScreen(
          customerName: data['customerName'],
          orderMenu: List<Map<String, dynamic>>.from(data['orderDetails']),
          totalAmount: data['total'],
          change: data['change'] ?? 0.0,
          paymentMethod: data['paymentMethod'] ?? '',
          invoiceNumber: data['invoiceNumber'],
          originalTimestamp: data['timestamp'] as Timestamp,
        ),
      ),
    );
  }

  void _showOrderDetails(String customerName, String invoiceNumber, List<dynamic> orderMenu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Detail Pesanan', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pelanggan: $customerName', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Nota: $invoiceNumber', style: TextStyle(color: Colors.grey.shade600)),
              SizedBox(height: 16),
              ...orderMenu.map((product) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${product['quantity']} x Rp ${NumberFormat('#,###').format(product['price'])}'),
                    Text('Total: Rp ${NumberFormat('#,###').format(product['price'] * product['quantity'])}',
                         style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananList(String statusNota) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pesanan').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final customerName = data['customerName'] ?? '';
          final pesananStatusNota = data['statusNota'] ?? 'belum dicetak';
          
          DateTime timestamp = DateTime.now();
          final rawTimestamp = data['timestamp'];
          if (rawTimestamp is Timestamp) {
            timestamp = rawTimestamp.toDate();
          }

          bool matchesSearch = customerName.toLowerCase().contains(_searchQuery);
          bool matchesStatus = pesananStatusNota == statusNota;
          bool inDateRange = true;

          if (_startDate != null) inDateRange = timestamp.isAfter(_startDate!);
          if (_endDate != null) inDateRange &= timestamp.isBefore(_endDate!.add(Duration(days: 1)));

          return matchesSearch && matchesStatus && inDateRange;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text('Belum ada pesanan', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) => _buildOrderCard(filteredDocs[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text('Pesanan & Status Nota', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Belum Cetak', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Sudah Cetak', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan...',
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (query) => setState(() => _searchQuery = query.toLowerCase()),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(_startDate == null ? 'Tanggal Mulai' : DateFormat('dd/MM/yy').format(_startDate!)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(_endDate == null ? 'Tanggal Akhir' : DateFormat('dd/MM/yy').format(_endDate!)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPesananList('belum dicetak'),
                _buildPesananList('sudah dicetak'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
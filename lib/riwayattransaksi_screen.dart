import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> transactions = [];
  TextEditingController searchController = TextEditingController();

  // Color scheme
  static const Color primaryColor = Color(0xFF003f7f);
  static const Color accentColor = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color cardColor = Color(0xFFF8FBFF);

  Future<void> loadTransactionsFromFirestore() async {
  try {
    var snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi').get();
    List<Map<String, dynamic>> loadedTransactions = [];

    snapshot.docs.forEach((doc) {
      Map<String, dynamic> transaction = doc.data();
      loadedTransactions.add(transaction);
    });

    // Mengurutkan transaksi berdasarkan nomor nota secara menurun
    loadedTransactions.sort((a, b) {
      String invoiceA = a['invoiceNumber'] ?? '';
      String invoiceB = b['invoiceNumber'] ?? '';

      // Mengambil bagian angka dari nomor nota (menghilangkan 'INV' dan mengonversi menjadi angka)
      int numberA = int.tryParse(invoiceA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numberB = int.tryParse(invoiceB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      return numberB.compareTo(numberA);  // Mengurutkan secara menurun
    });

    setState(() {
      transactions = loadedTransactions;
    });
  } catch (e) {
    print("Error loading transactions from Firestore: $e");
  }
}

  // Fungsi untuk menyimpan transaksi ke SharedPreferences
  Future<void> saveTransactionToSharedPreferences(Map<String, dynamic> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
    String transactionString = json.encode(transaction);
    transactionStrings.add(transactionString);

    await prefs.setStringList('transactions', transactionStrings);
  }

  // Fungsi untuk menghapus transaksi dari Firestore
  Future<void> deleteTransactionFromFirestore(String invoiceNumber) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('riwayattransaksi')
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Transaksi berhasil dihapus!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print("Error deleting transaction from Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal menghapus transaksi!'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Fungsi untuk menghapus transaksi dari SharedPreferences
  Future<void> deleteTransaction(String invoiceNumber) async {
    setState(() {});

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactionStrings = prefs.getStringList('transactions') ?? [];
      transactionStrings.removeWhere((transactionJson) {
        final transaction = json.decode(transactionJson);
        return transaction['invoiceNumber'] == invoiceNumber;
      });
      await prefs.setStringList('transactions', transactionStrings);

      await deleteTransactionFromFirestore(invoiceNumber);
      loadTransactionsFromFirestore();
    } catch (e) {
      print("Error deleting transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal menghapus transaksi'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadTransactionsFromFirestore();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        title: Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,    
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transactions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildSearchAndFilterSection(),
                _buildTransactionList(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada transaksi untuk ditampilkan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Transaksi Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama pelanggan...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchQuery = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Date Filters
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: startDate == null
                        ? 'Tanggal Mulai'
                        : DateFormat('dd MMM yyyy').format(startDate!),
                    onPressed: () => selectStartDate(context),
                    icon: Icons.calendar_today,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    label: endDate == null
                        ? 'Tanggal Akhir'
                        : DateFormat('dd MMM yyyy').format(endDate!),
                    onPressed: () => selectEndDate(context),
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            if (startDate != null || endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                    });
                  },
                  icon: Icon(Icons.clear, color: Colors.red),
                  label: Text('Hapus Filter', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildTransactionList() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          var transaction = transactions[index];

          // Filter berdasarkan pencarian
          if (!transaction['customerName']
              .toLowerCase()
              .contains(searchQuery)) {
            return Container();
          }

          // Filter berdasarkan tanggal
          if (startDate != null || endDate != null) {
            DateTime transactionDate = DateTime.parse(transaction['date']);
            if (startDate != null && transactionDate.isBefore(startDate!)) {
              return Container();
            }
            if (endDate != null && transactionDate.isAfter(endDate!)) {
              return Container();
            }
          }

          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${transaction['invoiceNumber']?.toString() ?? 'N/A'}',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            transaction['customerName']?.toString() ?? 'Tidak Ada Nama',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                      onPressed: () => _showDeleteConfirmation(transaction),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Details
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      transaction['date'] != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(transaction['date']))
                          : 'Tidak ada tanggal',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      transaction['paymentMethod']?.toString() ?? 'Tidak ada metode',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Amount
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###').format(double.parse(transaction['totalAmount']?.toString() ?? '0'))}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (double.parse(transaction['change']?.toString() ?? '0') > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Kembalian',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###').format(double.parse(transaction['change']?.toString() ?? '0'))}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(                              
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // Mengubah background menjadi putih
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      _buildDetailRow('Nomor Nota', transaction['invoiceNumber']?.toString() ?? 'N/A'),
                      _buildDetailRow('Tanggal', transaction['date'] != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(transaction['date']))
                          : 'Tidak ada tanggal'),
                      _buildDetailRow('Pelanggan', transaction['customerName']?.toString() ?? 'Tidak Ada Nama'),
                      _buildDetailRow('Metode Pembayaran', transaction['paymentMethod']?.toString() ?? 'Tidak ada metode'),
                      _buildDetailRow('Total Harga', 'Rp ${NumberFormat('#,###').format(double.parse(transaction['totalAmount']?.toString() ?? '0'))}'),
                      _buildDetailRow('Kembalian', 'Rp ${NumberFormat('#,###').format(double.parse(transaction['change']?.toString() ?? '0'))}'),
                      SizedBox(height: 20),
                      Text(
                        'Rincian Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      if (transaction['orderDetails'] != null && transaction['orderDetails'].isNotEmpty)
                        ...List.generate(transaction['orderDetails'].length, (i) {
                          var product = transaction['orderDetails'][i];
                          double totalPrice = product['price'] * product['quantity'];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name']?.toString() ?? 'Nama Produk Tidak Tersedia',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Jumlah: ${product['quantity']}'),
                                    Text('Rp ${NumberFormat('#,###').format(product['price'])} per unit'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total:'),
                                    Text(
                                      'Rp ${NumberFormat('#,###').format(totalPrice)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Tidak ada produk untuk transaksi ini',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                    ],
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(': ', style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi #${transaction['invoiceNumber']}?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTransaction(transaction['invoiceNumber']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanScreen extends StatefulWidget {
  @override
  _LaporanScreenState createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with TickerProviderStateMixin {
  double totalTransactionValue = 0;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  List<MapEntry<String, int>> filteredProductSales = [];
  Map<String, int> productSales = {};
  
  TextEditingController searchController = TextEditingController();
  TextEditingController productSearchController = TextEditingController();
  
  String selectedReport = 'Laporan Transaksi';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    loadTransactionsFromFirestore();
    searchController.addListener(filterTransactions);
    productSearchController.addListener(filterProductSales);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    productSearchController.dispose();
    super.dispose();
  }

  Future<void> loadTransactionsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('riwayattransaksi').get();
      List<Map<String, dynamic>> loadedTransactions = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> transactionData = doc.data();
        bool isDuplicate = loadedTransactions.any((existing) =>
            existing['invoiceNumber'] == transactionData['invoiceNumber']);
        
        if (!isDuplicate) {
          loadedTransactions.add(transactionData);
        }
      }

      loadedTransactions.sort((a, b) {
        int numberA = int.parse(a['invoiceNumber'].replaceAll('INV', '').trim());
        int numberB = int.parse(b['invoiceNumber'].replaceAll('INV', '').trim());
        return numberA.compareTo(numberB);
      });

      setState(() {
        transactions = loadedTransactions;
        filteredTransactions = loadedTransactions;
      });
      
      generateReport();
      filterTransactions();
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  void generateReport() {
    double total = 0;
    productSales.clear();

    for (var transaction in transactions) {
      total += transaction['totalAmount'] ?? 0.0;

      if (transaction['orderDetails'] != null) {
        for (var product in transaction['orderDetails']) {
          String productName = product['name'] ?? 'Unknown Product';
          int quantity = product['quantity'] ?? 0;
          productSales[productName] = (productSales[productName] ?? 0) + quantity;
        }
      }
    }

    setState(() {
      totalTransactionValue = total;
      filteredProductSales = productSales.entries.toList();
    });
  }

  void filterTransactions() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        String customerName = (transaction['customerName'] ?? '').toLowerCase();
        bool matchesName = customerName.contains(query);
        
        if (selectedStartDate != null) {
          DateTime transactionDate = DateTime.parse(transaction['date']);
          bool matchesDate = transactionDate.isAfter(selectedStartDate!);
          if (selectedEndDate != null) {
            matchesDate = matchesDate && transactionDate.isBefore(selectedEndDate!.add(Duration(days: 1)));
          }
          return matchesName && matchesDate;
        }
        
        return matchesName;
      }).toList();
    });
  }

  void filterProductSales() {
    String query = productSearchController.text.toLowerCase();
    setState(() {
      filteredProductSales = productSales.entries
          .where((entry) => entry.key.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? selectedStartDate : selectedEndDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF003f7f),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
        } else {
          selectedEndDate = picked;
        }
        filterTransactions();
      });
    }
  }

  void resetFilters() {
    setState(() {
      selectedStartDate = null;
      selectedEndDate = null;
      searchController.clear();
      productSearchController.clear();
      filteredTransactions = transactions;
      filteredProductSales = productSales.entries.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportSelector(),
                    SizedBox(height: 20),
                    if (selectedReport == 'Laporan Transaksi') ...[
                      _buildSearchAndFilters(),
                      SizedBox(height: 20),
                      _buildTransactionReport(),
                    ] else
                      _buildProductReport(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Laporan',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Color(0xFF003f7f),
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF003f7f),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 0, 4),
        child: Column(
          children: [
            
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jenis Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003f7f),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _buildReportOption('Laporan Transaksi', Icons.receipt_long),
                SizedBox(width: 10),
                _buildReportOption('Laporan Produk', Icons.inventory),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String title, IconData icon) {
    bool isSelected = selectedReport == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedReport = title;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF003f7f) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Color(0xFF003f7f) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Pencarian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003f7f),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cari Nama Pelanggan',
                prefixIcon: Icon(Icons.search, color: Color(0xFF003f7f)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF003f7f)),
                ),
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildDateButton('Dari', selectedStartDate, true)),
                SizedBox(width: 10),
                Expanded(child: _buildDateButton('Sampai', selectedEndDate, false)),
              ],
            ),
            if (selectedStartDate != null || selectedEndDate != null || searchController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Center(
                  child: TextButton.icon(
                    onPressed: resetFilters,
                    icon: Icon(Icons.clear, color: Colors.red),
                    label: Text('Reset Filter', style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStartDate) {
    return ElevatedButton.icon(
      onPressed: () => _selectDate(context, isStartDate),
      icon: Icon(Icons.calendar_today, size: 16),
      label: Text(
        date == null ? label : DateFormat('dd/MM/yyyy').format(date),
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: date == null ? Colors.grey[200] : Color(0xFF003f7f),
        foregroundColor: date == null ? Colors.grey[600] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildTransactionReport() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menambahkan total transaksi di bagian atas
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Transaksi:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003f7f),
                ),
              ),
              Text(
                'Rp ${NumberFormat('#,###').format(totalTransactionValue)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003f7f),
                ),
              ),
            ],
          ),
        ),
        // Header Laporan Transaksi
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF003f7f),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Rincian Transaksi (${filteredTransactions.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (filteredTransactions.isEmpty)
          Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 10),
                  Text(
                    'Tidak ada transaksi ditemukan',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredTransactions.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return _buildTransactionCard(transaction, index + 1);
            },
          ),
      ],
    ),
  );
}



  Widget _buildTransactionCard(Map<String, dynamic> transaction, int number) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(
        backgroundColor: Color(0xFF003f7f).withOpacity(0.1),
        child: Text(
          number.toString(),
          style: TextStyle(
            color: Color(0xFF003f7f),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        transaction['customerName'] ?? 'N/A',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice: ${transaction['invoiceNumber'] ?? 'N/A'}'),
          Text('Tanggal: ${_formatDate(transaction['date'])}'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Rp ${NumberFormat('#,###').format(transaction['totalAmount'] ?? 0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF003f7f),
            ),
          ),
          TextButton(
            onPressed: () => _showProductDetails(transaction['orderDetails']),
            child: Text('Detail', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductReport() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF003f7f),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Laporan Penjualan Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: productSearchController,
              decoration: InputDecoration(
                labelText: 'Cari Nama Produk',
                prefixIcon: Icon(Icons.search, color: Color(0xFF003f7f)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF003f7f)),
                ),
              ),
            ),
          ),
          if (filteredProductSales.isEmpty)
            Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 60, color: Colors.grey[400]),
                    SizedBox(height: 10),
                    Text(
                      'Tidak ada data produk',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredProductSales.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final product = filteredProductSales[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFF003f7f).withOpacity(0.1),
                    child: Icon(
                      Icons.shopping_bag,
                      color: Color(0xFF003f7f),
                    ),
                  ),
                  title: Text(
                    product.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF003f7f),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${product.value} pcs',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showProductDetails(List<dynamic>? orderDetails) {
    if (orderDetails == null || orderDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada detail produk')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: Color(0xFF003f7f)),
              SizedBox(width: 10),
              Text('Detail Produk'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: orderDetails.map<Widget>((product) {
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF003f7f).withOpacity(0.1),
                      child: Text(
                        '${product['quantity'] ?? 0}',
                        style: TextStyle(
                          color: Color(0xFF003f7f),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(product['name'] ?? 'Unknown Product'),
                    subtitle: Text('Rp ${NumberFormat('#,###').format(product['price'] ?? 0)}'),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: TextStyle(color: Color(0xFF003f7f))),
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:berkatjaya_web/cetaknota_screen.dart';

class PembayaranScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderMenu;
  PembayaranScreen({required this.orderMenu});

  @override
  _PembayaranScreenState createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  late double totalAmount;
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  double change = 0.0;
  String paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    totalAmount = widget.orderMenu.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  void calculateChange() {
    double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
    setState(() {
      if (amountPaid >= totalAmount) {
        change = amountPaid - totalAmount;
      } else {
        change = 0.0;
      }
    });
  }

  bool isAmountPaidValid() {
    double amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
    return amountPaid >= totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade200, Colors.grey.shade300],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                ),
                SizedBox(height: 20),

                // Input untuk Nama Pelanggan
                TextField(
                  controller: customerNameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama pelanggan',
                    labelText: 'Nama Pelanggan',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (text) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 20),

                // Rincian produk yang dipesan
                Text('Rincian Produk:', style: TextStyle(fontSize: 18, color: Colors.black)),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    children: widget.orderMenu.map((item) {
                      return ListTile(
                        title: Text('${item['name']} (x${item['quantity']})', style: TextStyle(fontSize: 16, color: Colors.black)),
                        subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.black)),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),

                // Input nominal uang yang dibayar
                TextField(
                  controller: amountPaidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Masukkan Uang yang Dibayar',
                    hintText: 'Masukkan jumlah uang',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    calculateChange();
                  },
                ),
                SizedBox(height: 20),

                // Menampilkan total harga di atas pengembalian
                Text('Total yang harus dibayar:', style: TextStyle(fontSize: 18, color: Colors.black)),
                SizedBox(height: 5),
                Text('Rp ${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                SizedBox(height: 20),

                // Menampilkan pengembalian
                Text('Pengembalian: Rp ${change.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                SizedBox(height: 20),

                // Menampilkan metode pembayaran
                Text('Pembayaran:', style: TextStyle(fontSize: 18, color: Colors.black)),
                DropdownButton<String>(
                  value: paymentMethod,
                  onChanged: (String? newValue) {
                    setState(() {
                      paymentMethod = newValue!;
                    });
                  },
                  items: <String>['Cash', 'Transfer BCA', 'Transfer BRI', 'Transfer Mandiri']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),

                // Tombol Nota
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (amountPaidController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan nominal uang terlebih dahulu')));
                      }
                      else if (!isAmountPaidValid()) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang tidak cukup')));
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CetakNotaScreen(
                              orderMenu: widget.orderMenu,
                              totalAmount: totalAmount,
                              change: change,
                              paymentMethod: paymentMethod,
                              customerName: customerNameController.text,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

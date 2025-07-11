import 'dart:convert';
import 'dart:ui'; // Menambahkan impor untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Mengimpor intl untuk format tanggal
import 'pesanan_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(MaterialApp(
    home: NotaTempoScreen(),
    theme: ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class NotaTempoScreen extends StatefulWidget {
  @override
  _NotaTempoScreenState createState() => _NotaTempoScreenState();
}

class _NotaTempoScreenState extends State<NotaTempoScreen> {
  String selectedCategory = "All"; // Default kategori All
  String searchQuery = ""; // Untuk menyimpan kata pencarian
  bool isDropdownVisible = false; // Status dropdown
  final List<Map<String, dynamic>> orderMenu = [];
  String? selectedProductId;  // Tambahkan ini untuk mendeklarasikan variabel selectedProductId

  // Fungsi untuk menambah produk ke dalam order menu
  void addToOrder(String id, String name, double price, int stock) async {
  if (stock > 0) {
    setState(() {
      bool itemExists = false;
      for (var item in orderMenu) {
        if (item['id'] == id) {
          item['quantity']++;
          item['totalPrice'] = item['price'] * item['quantity']; // Update totalPrice sesuai quantity
          itemExists = true;
          break;
        }
      }
      if (!itemExists) {
        orderMenu.add({
          'id': id,
          'name': name,
          'price': price,
          'quantity': 1,
          'totalPrice': price, // Set totalPrice saat pertama kali ditambahkan
        });
      }
    });

    // Update stok di Firestore
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      if (currentStock > 0) {
        docRef.update({'stok': currentStock - 1});
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok tidak cukup!')));
  }
}
  // Fungsi untuk mengedit jumlah produk dalam order menu
  void editItemQuantity(String id, String name, double price, int currentQuantity, int stock) async {
    int availableStock = stock + currentQuantity; // Stok yang tersedia adalah stok saat ini ditambah dengan jumlah yang sudah ada di order menu

    int newQuantity = currentQuantity; // Inisialisasi jumlah produk saat ini
    TextEditingController quantityController = TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Jumlah $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Jumlah'),
              ),
              SizedBox(height: 10),
              Text('Stok tersedia: $availableStock'), // Menampilkan stok yang tersedia
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                int updatedQuantity = int.tryParse(quantityController.text) ?? currentQuantity;
                if (updatedQuantity <= availableStock) {
                  setState(() {
                    for (var item in orderMenu) {
                      if (item['id'] == id) {
                        item['quantity'] = updatedQuantity;
                        break;
                      }
                    }
                  });

                  // Update stok di Firestore
                  final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
                  try {
                    final docSnapshot = await docRef.get();
                    if (docSnapshot.exists) {
                      final currentStock = docSnapshot.data()?['stok'] ?? 0;
                      await docRef.update({'stok': currentStock - (updatedQuantity - currentQuantity)});
                      Navigator.of(context).pop();  // Menutup dialog setelah update
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk tidak ditemukan!')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok tidak cukup!')));
                }
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk mengurangi produk dalam order menu
  void removeOneItem(String id, double price) async {
    setState(() {
      for (var item in orderMenu) {
        if (item['id'] == id && item['quantity'] > 1) {
          item['quantity']--;
          break;
        }
      }
    });

    // Update stok di Firestore
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      docRef.update({'stok': currentStock + 1});
    }
  }

  // Fungsi untuk menghapus produk dari order menu
  void removeItemFromOrder(String id, int quantity) async {
    setState(() {
      orderMenu.removeWhere((item) => item['id'] == id);
    });

    // Update stok di Firestore
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      docRef.update({'stok': currentStock + quantity});
    }
  }

  // Menghitung total harga dari produk yang ada di order menu
  double get totalCharge {
    double total = 0;
    for (var item in orderMenu) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  // Fungsi untuk mendapatkan nomor invoice
  Future<String> generateInvoiceNumber() async {
    DocumentReference invoiceRef = FirebaseFirestore.instance.collection('invoiceCounter').doc('counter');
    DocumentSnapshot invoiceSnapshot = await invoiceRef.get();
    int invoiceNumber = 1;

    if (invoiceSnapshot.exists) {
      invoiceNumber = invoiceSnapshot['counter'] ?? 1;
    }

    // Update nomor invoice yang ada di Firestore
    await invoiceRef.set({'counter': invoiceNumber + 1}, SetOptions(merge: true));

    return 'INV${invoiceNumber.toString().padLeft(3, '0')}';
  }

  // Fungsi untuk menyimpan pesanan ke daftar pesanan
  // Fungsi untuk menyimpan pesanan ke daftar pesanan
void saveOrder() async {
  if (orderMenu.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak ada pesanan')),
    );
  } else {
    String customerName = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: Text("Masukkan Nama Pelanggan"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "Nama Pelanggan"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Batal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Simpan"),
              onPressed: () {
                setState(() {
                  customerName = nameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama pelanggan harus diisi')),
      );
      return;
    }

    // Siapkan timestamp lokal
    final Timestamp nowTimestamp = Timestamp.now();

    // Dapatkan nomor invoice
    String invoiceNumber = await generateInvoiceNumber();

    // Simpan ke Firestore
    final orderRef = FirebaseFirestore.instance.collection('pesanan').doc();
    await orderRef.set({
      'orderDetails': orderMenu,
      'total': totalCharge,
      'timestamp': nowTimestamp, // langsung simpan Timestamp.now()
      'customerName': customerName,
      'statusNota': 'belum dicetak',
      'statusPembayaran': 'belum lunas',
      'invoiceNumber': invoiceNumber,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pesanan berhasil disimpan!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PesananScreen()),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nota Tempo', style: 
        TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold),), 
        backgroundColor: Color(0xFF003f7f),
        elevation: 0,
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    color: Colors.white, // Ikon panah untuk kembali
    onPressed: () {
      // Fungsi untuk kembali ke HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()), // Sesuaikan dengan data Anda
      );
    },
  ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PesananScreen()), // Navigasi ke PesananScreen
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Grid Produk di sebelah kiri
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = 'All';
                                isDropdownVisible = !isDropdownVisible;
                              });
                            },
                            child: Row(
                              children: [
                                CategoryButton(
                                  label: selectedCategory == 'All' ? 'All' : selectedCategory,
                                  isSelected: selectedCategory == 'All',
                                  onPressed: () {
                                    setState(() {
                                      selectedCategory = 'All';
                                      isDropdownVisible = !isDropdownVisible;
                                    });
                                  },
                                ),
                                Icon(
                                  isDropdownVisible
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                          if (isDropdownVisible) ...[ 
                            CategoryButton(
                              label: 'Makanan',
                              isSelected: selectedCategory == 'makanan',
                              onPressed: () {
                                setState(() {
                                  selectedCategory = 'makanan';
                                  isDropdownVisible = false;
                                });
                              },
                            ),
                            CategoryButton(
                              label: 'Minuman',
                              isSelected: selectedCategory == 'minuman',
                              onPressed: () {
                                setState(() {
                                  selectedCategory = 'minuman';
                                  isDropdownVisible = false;
                                });
                              },
                            ),
                          ],
                          // Search bar untuk produk
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: TextField(
                                onChanged: (query) {
                                  setState(() {
                                    searchQuery = query;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Cari Produk...",
                                  hintStyle: TextStyle(color: Colors.blueGrey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>( 
                        stream: FirebaseFirestore.instance
                            .collection('produk')
                            .where('kategori', isEqualTo: selectedCategory == 'All' ? null : selectedCategory)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(child: Text('Belum ada produk'));
                          }

                          final filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['nama'] ?? '';
                            return name.toLowerCase().contains(searchQuery.toLowerCase());
                          }).toList();

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final id = doc.id;
                              final name = data['nama'] ?? '';
                              final stock = data['stok'] ?? 0;
                              final price = data['harga'] ?? 0.0;
                              final base64Image = data['gambar'] ?? '';

                              return GestureDetector(
  onTap: () {
    setState(() {
      selectedProductId = id; 
    });
  },
  child: Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: Colors.black, width: 2), // Menambahkan border hitam
    ),
    color: selectedProductId == id ? Colors.deepPurple[200] : Colors.white, 
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        base64Image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(base64Image),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.fastfood, size: 50),
        Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Stok: $stock', style: TextStyle(fontSize: 16)),
        IconButton(
          icon: Icon(Icons.add, size: 30, color: Colors.deepPurple),
          onPressed: () {
            addToOrder(id, name, price, stock);
          },
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
              ),
              // Order Menu di sebelah kanan
             Expanded(
  flex: 1,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8), // Warna latar belakang dengan opasitas
      borderRadius: BorderRadius.circular(15), // Membulatkan sudut
      border: Border.all(color: Colors.black, width: 2), // Menambahkan border hitam
    ),
    padding: EdgeInsets.all(8),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10, left: 20),
          child: Row(
            children: [
              Text("Order Menu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.history, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PesananScreen()),
                  );
                },
              ),
            ],
          ),
        ),
                      Expanded(
  child: ListView.builder(
    itemCount: orderMenu.length,
    itemBuilder: (context, index) {
      final item = orderMenu[index];
      return Padding(
        padding: const EdgeInsets.all(8.0), // Menambahkan padding untuk memastikan border terlihat
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2), // Menambahkan border hitam
            borderRadius: BorderRadius.circular(30),
          ),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              // Tidak perlu border di sini lagi, karena kita menggunakan Container untuk border
            ),
            child: ListTile(
              title: Text('${item['name']} (x${item['quantity']})'),
              subtitle: Text('Rp ${item['totalPrice']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      final item = orderMenu[index];
                      final id = item['id'];
                      final name = item['name'];
                      final currentQuantity = item['quantity'];
                      final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
                      final docSnapshot = await docRef.get();
                      if (docSnapshot.exists) {
                        final stock = docSnapshot.data()?['stok'] ?? 0;
                        editItemQuantity(id, name, item['price'], currentQuantity, stock);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: () {
                      if (item['quantity'] > 1) {
                        removeOneItem(item['id'], item['price']);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20),
                    onPressed: () {
                      removeItemFromOrder(item['id'], item['quantity']);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: ElevatedButton(
                                onPressed: saveOrder,
                                child: Text('Simpan Pesanan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF003f7f),
                                  padding: EdgeInsets.symmetric(horizontal: 140, vertical: 20),
                                  textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Kategori button
class CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  CategoryButton({required this.label, this.isSelected = false, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepPurpleAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

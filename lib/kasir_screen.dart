import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pembayaran_screen.dart';  // Pastikan untuk mengimpor PembayaranScreen di sini

void main() {
  runApp(MaterialApp(
    home: KasirScreen(),
  ));
}

class KasirScreen extends StatefulWidget {
  @override
  _KasirScreenState createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String selectedCategory = "makanan";  // Default kategori makanan
  final List<Map<String, dynamic>> orderMenu = [];

  // Fungsi untuk menambah produk ke dalam order menu
  void addToOrder(String id, String name, double price, int stock) async {
    if (stock > 0) {
      setState(() {
        bool itemExists = false;
        for (var item in orderMenu) {
          if (item['id'] == id) {
            item['quantity']++;
            itemExists = true;
            break;
          }
        }
        if (!itemExists) {
          orderMenu.add({'id': id, 'name': name, 'price': price, 'quantity': 1});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir App'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Row(
        children: [
          // Grid Produk di sebelah kiri
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Kategori Buttons (Makanan dan Minuman)
                Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // Tombol kiri
                    children: [
                      CategoryButton(
                        label: 'Makanan',
                        isSelected: selectedCategory == 'makanan',
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'makanan';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      CategoryButton(
                        label: 'Minuman',
                        isSelected: selectedCategory == 'minuman',
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'minuman';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Grid Produk berdasarkan kategori yang dipilih
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('produk')
                        .where('kategori', isEqualTo: selectedCategory)
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

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final id = doc.id;
                          final name = data['nama'] ?? '';
                          final stock = data['stok'] ?? 0;
                          final price = data['harga'] ?? 0.0;
                          final base64Image = data['gambar'] ?? '';

                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
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
                                Text(name, style: TextStyle(fontSize: 16)),
                                Text('Stok: $stock', style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.add, size: 30),
                                  onPressed: () {
                                    addToOrder(id, name, price, stock);
                                  },
                                ),
                              ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Menu Title
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Order Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),

                // Order items grid
                Expanded(
                  child: ListView.builder(
                    itemCount: orderMenu.length,
                    itemBuilder: (context, index) {
                      final item = orderMenu[index];

                      return Card(
                        elevation: 5,
                        child: ListTile(
                          title: Text('${item['name']} (x${item['quantity']})'),
                          subtitle: Text('Rp ${item['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tombol Edit
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () async {
                                  // Fungsi untuk mengedit jumlah produk
                                },
                              ),

                              // Tombol pengurangan produk
                              IconButton(
                                icon: Icon(Icons.remove, size: 20),
                                onPressed: () {
                                  if (item['quantity'] > 1) {
                                    removeOneItem(item['id'], item['price']);
                                  }
                                },
                              ),
                              
                              // Tombol Hapus produk
                              IconButton(
                                icon: Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  removeItemFromOrder(item['id'], item['quantity']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total charge di bagian bawah order menu
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        'Total: Rp ${totalCharge.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      // Tombol Pembayaran di bawah total charge
Padding(
  padding: const EdgeInsets.symmetric(vertical: 20),
  child: ElevatedButton(
    onPressed: () {
      // Navigasi ke PembayaranScreen dan kirim orderMenu sebagai parameter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PembayaranScreen(orderMenu: orderMenu),  // Kirim orderMenu ke PembayaranScreen
        ),
      );
    },
    child: Text('Pembayaran'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black12,
      padding: EdgeInsets.symmetric(horizontal: 170, vertical: 10),
      textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  ),
),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          color: isSelected ? Colors.yellow : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepPurpleAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.deepPurpleAccent : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

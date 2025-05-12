import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<Map<String, dynamic>> orderMenu = [];
  String selectedCategory = "All";  // Default category

  double get totalCharge {
    double total = 0;
    for (var item in orderMenu) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  // Fungsi untuk menambah produk ke dalam pesanan
  void addToOrder(String id, String name, double price) async {
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

    // Update stok produk di Firestore
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      if (currentStock > 0) {
        docRef.update({'stok': currentStock - 1});
      }
    }
  }

  // Fungsi untuk menambah atau mengurangi jumlah produk dalam pesanan
  Future<void> _updateProductQuantity(String id, bool increase) async {
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      final orderItem = orderMenu.firstWhere((item) => item['id'] == id);

      setState(() {
        if (increase) {
          if (currentStock > 0) {
            orderItem['quantity']++;
            docRef.update({'stok': currentStock - 1}); // Update stok Firestore
          }
        } else {
          if (orderItem['quantity'] > 1) {
            orderItem['quantity']--;
            docRef.update({'stok': currentStock + 1}); // Kembalikan stok
          }
        }
      });
    }
  }

  // Fungsi untuk menghapus produk dari order
  Future<void> _removeProduct(String id) async {
    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      final orderItem = orderMenu.firstWhere((item) => item['id'] == id);

      setState(() {
        orderMenu.removeWhere((item) => item['id'] == id); // Remove item from order
        docRef.update({'stok': currentStock + orderItem['quantity']}); // Add back to stock
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir App'),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Order Summary'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: orderMenu.map((item) {
                        return ListTile(
                          title: Text('${item['name']} (x${item['quantity']})'),
                          subtitle: Text('\$${item['price']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeProduct(item['id']),
                          ),
                        );
                      }).toList(),
                    ),
                    actions: [
                      Text('Subtotal: \$${totalCharge.toStringAsFixed(2)}'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.deepPurpleAccent),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Charge \$${totalCharge.toStringAsFixed(2)}'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Grid Produk di sebelah kiri
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Category buttons
                Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CategoryButton(label: 'All', isSelected: selectedCategory == 'All', onPressed: () {
                        setState(() {
                          selectedCategory = 'All';
                        });
                      }),
                      CategoryButton(label: 'Makanan', isSelected: selectedCategory == 'Makanan', onPressed: () {
                        setState(() {
                          selectedCategory = 'Makanan';
                        });
                      }),
                      CategoryButton(label: 'Minuman', isSelected: selectedCategory == 'Minuman', onPressed: () {
                        setState(() {
                          selectedCategory = 'Minuman';
                        });
                      }),
                    ],
                  ),
                ),

                // Grid Produk berdasarkan kategori
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
                          final price = data['harga'] ?? 0.0;
                          final stock = data['stok'] ?? 0;
                          final base64Image = data['gambar'] ?? '';  // Mendapatkan gambar base64

                          return GestureDetector(
                            onTap: stock > 0 ? () => addToOrder(id, name, price) : null,
                            child: Card(
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: stock > 0 ? () => _updateProductQuantity(id, true) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => _updateProductQuantity(id, false),
                                      ),
                                    ],
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 4,
                    ),
                    itemCount: orderMenu.length,
                    itemBuilder: (context, index) {
                      final item = orderMenu[index];
                      return Card(
                        elevation: 5,
                        child: ListTile(
                          title: Text('${item['name']} (x${item['quantity']})'),
                          subtitle: Text('\$${item['price']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeProduct(item['id']),
                          ),
                        ),
                      );
                    },
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

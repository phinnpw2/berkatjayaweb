import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'pembayaran_screen.dart';
import 'riwayattransaksi_screen.dart';

void main() {
  runApp(MaterialApp(
    home: KasirScreen(),
    theme: ThemeData(
      primarySwatch: Colors.deepPurple,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class KasirScreen extends StatefulWidget {
  @override
  _KasirScreenState createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String selectedCategory = "All";
  String searchQuery = "";
  bool isDropdownVisible = false;
  final List<Map<String, dynamic>> orderMenu = [];
  String? selectedProductId;

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

  void removeOneItem(String id, double price) async {
    setState(() {
      for (var item in orderMenu) {
        if (item['id'] == id && item['quantity'] > 1) {
          item['quantity']--;
          break;
        }
      }
    });

    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      docRef.update({'stok': currentStock + 1});
    }
  }

  void removeItemFromOrder(String id, int quantity) async {
    setState(() {
      orderMenu.removeWhere((item) => item['id'] == id);
    });

    final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final currentStock = docSnapshot.data()?['stok'] ?? 0;
      docRef.update({'stok': currentStock + quantity});
    }
  }

  double get totalCharge {
    double total = 0;
    for (var item in orderMenu) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  void editItemQuantity(String id, String name, double price, int currentQuantity, int stock) async {
    int availableStock = stock + currentQuantity; 

    int newQuantity = currentQuantity; 
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
              Text('Stok tersedia: $availableStock'),
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

                  final docRef = FirebaseFirestore.instance.collection('produk').doc(id);
                  try {
                    final docSnapshot = await docRef.get();
                    if (docSnapshot.exists) {
                      final currentStock = docSnapshot.data()?['stok'] ?? 0;
                      await docRef.update({'stok': currentStock - (updatedQuantity - currentQuantity)});
                      Navigator.of(context).pop();
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

  void handlePayment() {
    if (orderMenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak ada transaksi')));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PembayaranScreen(orderMenu: orderMenu),
        ),
      );
    }
  }

  void startNewTransaction() {
    setState(() {
      orderMenu.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir App', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Row(
            children: [
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
                            const SizedBox(width: 10),
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
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), 
                    borderRadius: BorderRadius.circular(15),
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
                                Navigator.push(context,
                                MaterialPageRoute(builder: (context) => RiwayatTransaksiScreen()),
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
                            return Card(
                              elevation: 5,
                              child: ListTile(
                                title: Text('${item['name']} (x${item['quantity']})'),
                                subtitle: Text('Rp ${item['price']}'),
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
                                onPressed: handlePayment,
                                child: Text('Pembayaran'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
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
              ),
            ],
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

import 'package:berkatjaya_web/pesanan_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotaTempoScreen extends StatefulWidget {
  @override
  _NotaTempoScreenState createState() => _NotaTempoScreenState();
}

class _NotaTempoScreenState extends State<NotaTempoScreen> {
  String selectedCategory = "All"; // Default kategori All, menampilkan semua produk
  String searchQuery = ""; // Variabel untuk menyimpan kata pencarian
  bool isDropdownVisible = false; // Menyimpan status dropdown
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

  // Fungsi untuk menyimpan nota
  void saveNota() async {
    if (orderMenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak ada pesanan untuk disimpan')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('nota_temp').add({
        'orderMenu': orderMenu,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        orderMenu.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nota berhasil disimpan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan nota: $e')));
    }
  }

  // Fungsi untuk melihat riwayat nota
  void viewNotaHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PesananScreen()),
    );
  }

  double getTotalCharge() {
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
        title: Text('Nota Tempo'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Row(
        children: [
          // Grid Produk di sebelah kiri
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Kategori Buttons (All, Makanan, Minuman)
                Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = 'All';
                            isDropdownVisible = !isDropdownVisible; // Toggle dropdown
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
                      if (isDropdownVisible) ...[ // Dropdown Makanan & Minuman
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
                      // Menambahkan search bar untuk filter produk
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

                // Grid Produk berdasarkan kategori yang dipilih
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
                      final filteredDocs = docs.where((doc) {
                        final name = doc['nama'].toString().toLowerCase();
                        return name.contains(searchQuery.toLowerCase());
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(child: Text('Produk tidak ditemukan'));
                      }

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

                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fastfood, size: 50),
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Order Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                icon: Icon(Icons.remove, size: 20),
                                onPressed: () {
                                  // Fungsi untuk mengurangi jumlah item
                                  if (item['quantity'] > 1) {
                                    setState(() {
                                      item['quantity']--;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  // Fungsi untuk menghapus item dari daftar pesanan
                                  setState(() {
                                    orderMenu.removeAt(index);
                                  });
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
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: saveNota,  // Panggil fungsi untuk menyimpan nota
                    child: Text('Simpan Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: EdgeInsets.symmetric(horizontal: 190, vertical: 10),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: viewNotaHistory,  // Tampilkan riwayat nota
                    child: Text('Riwayat Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: EdgeInsets.symmetric(horizontal: 174, vertical: 10),
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

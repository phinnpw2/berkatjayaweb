import 'package:flutter/material.dart';
import 'produk_page.dart';
import 'kasir_screen.dart';
import 'notatempo_screen.dart';  // Impor NotaTempoScreen
import 'riwayattransaksi_screen.dart';
import 'statusnotatempo_screen.dart'; // Impor RiwayatTransaksiScreen
import 'pengaturan_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final String role;
  final String userDocId;

  const HomeScreen({
    Key? key,
    required this.username,
    required this.role,
    required this.userDocId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/profile_pic.png'),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $username 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Role: $role',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 20),
          Icon(Icons.notifications, color: Colors.black),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/back1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selamat Datang Sahabatku',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Membuat Grid dengan kotak yang lebih kecil dan lebih terstruktur
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Menggunakan 3 kolom untuk grid
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: screenWidth > 600 ? 1.0 : 1.2,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        title: categories[index]['title'],
                        imagePath: categories[index]['imagePath'],
                        onTap: () {
                          final title = categories[index]['title'];

                          if (title == 'Kasir') {
                            // Pilih antara Kasir langsung atau Nota Tempo
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Pilih Mode Kasir'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text('Kasir Langsung'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => KasirScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: Text('Nota Tempo'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NotaTempoScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else if (title == 'Status Nota Tempo') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatusNotaTempoScreen(),
                              ),
                            );
                          } else if (title == 'Riwayat Transaksi') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RiwayatTransaksiScreen(),
                              ),
                            );
                          } else if (title == 'Stok Produk') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProdukPage()),
                            );
                          } else if (title == 'Pengaturan') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PengaturanScreen(
                                  username: username,
                                  role: role,
                                  userDocId: userDocId,
                                ),
                              ),
                            );
                          } else if (title == 'Laporan') {
                            // Anda dapat menambahkan kode navigasi untuk Laporan di sini
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 50, width: 50),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> categories = [
  {'title': 'Kasir', 'imagePath': 'assets/kasirlogo.png'},
  {'title': 'Stok Produk', 'imagePath': 'assets/stoklogo.png'},
  {'title': 'Laporan', 'imagePath': 'assets/laporanlogo.png'}, // Laporan tetap ada
  {'title': 'Pengaturan', 'imagePath': 'assets/pengaturanlogo.png'},
  {'title': 'Status Nota Tempo', 'imagePath': 'assets/notatemologo.png'}, // Tambahkan Status Nota Tempo
  {'title': 'Riwayat Transaksi', 'imagePath': 'assets/riwayatlogo.png'}, // Tambahkan Riwayat Transaksi
];

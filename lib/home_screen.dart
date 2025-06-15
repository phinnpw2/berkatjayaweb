import 'package:flutter/material.dart';
import 'produk_page.dart';
import 'kasir_screen.dart';
import 'notatempo_screen.dart';  // Impor NotaTempoScreen
import 'riwayattransaksi_screen.dart';
import 'statusnotatempo_screen.dart'; // Impor RiwayatTransaksiScreen
import 'pengaturan_screen.dart';
import 'laporan_screen.dart';

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
                  // Improved "Selamat Datang Sahabatku" section
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selamat Datang, $username',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5, // Adding letter spacing for a more refined look
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
                  // Grid of categories with smaller cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 columns for grid
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: screenWidth > 600 ? 1.1 : 1.2, // Adjusted aspect ratio to better fit the layout
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        title: categories[index]['title'],
                        imagePath: categories[index]['imagePath'],
                        onTap: () {
                          final title = categories[index]['title'];

                          if (title == 'Kasir') {
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
                          } else if (title == 'Laporan') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LaporanScreen(),
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
              colors: [Color(0xFF003f7f), Color(0xFF003f7f)], // Blue gradient
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
              Image.asset(imagePath, height: 40, width: 40), // Reduced icon size for smaller cards
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14, // Smaller text size for the category
                  color: Colors.white, // White text color for contrast
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

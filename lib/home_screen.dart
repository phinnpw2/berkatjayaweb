import 'package:flutter/material.dart';
import 'produk_page.dart';
import 'kasir_screen.dart';
import 'notatempo_screen.dart';
import 'riwayattransaksi_screen.dart';
import 'statusnotatempo_screen.dart';
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
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selamat Datang, $username',
                      style: TextStyle(
                        fontSize: 24,
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
                  SizedBox(height: 16),

                  // ✅ GridView FIXED
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: 1.8,
                      children: categories.map((category) {
                        return CategoryCard(
                          title: category['title'],
                          imagePath: category['imagePath'],
                          onTap: () {
                            final title = category['title'];

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
                                                  builder: (context) =>
                                                      KasirScreen()),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          title: Text('Nota Tempo'),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      NotaTempoScreen()),
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
                                  builder: (context) =>
                                      StatusNotaTempoScreen(),
                                ),
                              );
                            } else if (title == 'Riwayat Transaksi') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RiwayatTransaksiScreen(),
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
                                MaterialPageRoute(
                                  builder: (context) => ProdukPage(),
                                ),
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
                      }).toList(),
                    ),
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
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Color(0xFF003f7f),
          ),
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 60, width: 60),
              SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
  {'title': 'Laporan', 'imagePath': 'assets/laporanlogo.png'},
  {'title': 'Pengaturan', 'imagePath': 'assets/pengaturanlogo.png'},
  {'title': 'Status Nota Tempo', 'imagePath': 'assets/notatemologo.png'},
  {'title': 'Riwayat Transaksi', 'imagePath': 'assets/riwayatlogo.png'},
];

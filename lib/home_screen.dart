import 'package:flutter/material.dart';
import 'produk_page.dart';
import 'kasir_screen.dart';
import 'notatempo_screen.dart';
import 'riwayattransaksi_screen.dart';
import 'statusnotatempo_screen.dart';
import 'pengaturan_screen.dart';
import 'laporan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



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
    final allowedCategories = {
      'Owner': [
        'Kasir',
        'Stok Produk',
        'Laporan',
        'Pengaturan',
        'Status Nota Tempo',
        'Riwayat Transaksi',
      ],
      'Kasir': [
        'Kasir',
        'Status Nota Tempo',
        'Riwayat Transaksi',
        'Pengaturan',
      ],
      'Kepala Gudang': [
        'Stok Produk',
        'Pengaturan',
      ],
      'Sales': [
        'Stok Produk',
        'Status Nota Tempo',
        'Pengaturan',
      ],
    }[role] ?? [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF003f7f).withOpacity(0.8),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/profile_pic.png'),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $username 👋',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Role: $role',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF003f7f).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Selamat Datang $username',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 460, vertical: 16),
                    child: Text(
                      'TOKO BERKAT JAYA',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 56,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: 1.7,
                      children: categories.map((category) {
                        final title = category['title'];
                        final isAllowed = allowedCategories.contains(title);

                        return CategoryCard(
                          title: title,
                          imagePath: category['imagePath'],
                          onTap: () async {
                            if (!isAllowed) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Akses Ditolak'),
                                  content: Text('Role $role tidak memiliki akses ke menu "$title".'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                    

                            if (title == 'Kasir') {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text('Pilih Mode Kasir'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.payment, color: Color(0xFF003f7f)),
                                          title: Text('Kasir Langsung'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => KasirScreen()));
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.receipt_long, color: Color(0xFF003f7f)),
                                          title: Text('Nota Tempo'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => NotaTempoScreen()));
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else if (title == 'Status Nota Tempo') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => StatusNotaTempoScreen()));
                            } else if (title == 'Riwayat Transaksi') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatTransaksiScreen()));
                            } else if (title == 'Laporan') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanScreen()));
                            } else if (title == 'Stok Produk') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukPage()));
                            } else if (title == 'Pengaturan') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PengaturanScreen(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 140,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFF003f7f).withOpacity(0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blueAccent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                height: 50,
                width: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 28,
                    color: Color(0xFF003f7f),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
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

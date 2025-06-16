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
                  // Container Selamat Datang
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

                  // Text TOKO BERKAT JAYA
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

                  // GridView dengan penyesuaian lebar kartu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16, // Atur jarak antar kolom
                      mainAxisSpacing: 56,  // Atur jarak antar baris
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: 1.7, // Kecilkan rasio aspek
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text(
                                      'Pilih Mode Kasir',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.payment, color: Color(0xFF003f7f)),
                                          title: Text('Kasir Langsung'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => KasirScreen()),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.receipt_long, color: Color(0xFF003f7f)),
                                          title: Text('Nota Tempo'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => NotaTempoScreen()),
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
                  SizedBox(height: 20), // Spasi tambahan di bawah
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
        width: 120, // Ukuran kartu lebih kecil
        height: 140, // Sesuaikan tinggi kartu
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFF003f7f).withOpacity(0.88), // Latar belakang kotak kategori
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blueAccent, // Warna border
            width: 2, // Lebar border
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
            // Kotak abu-abu di sekitar logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3), // Efek transparan pada logo
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                height: 50, // Ukuran ikon lebih besar
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
            // Judul dengan ukuran font disesuaikan
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Ukuran font judul lebih kecil dan terang
                color: Colors.white, // Ubah warna teks jadi putih
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

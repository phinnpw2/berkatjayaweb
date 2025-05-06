import 'package:flutter/material.dart';
import 'produk_page.dart';  // Mengimpor halaman produk_page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,  // Transparan agar background tetap terlihat
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/profile_pic.png'), // Gambar profil
            ),
            SizedBox(width: 10),
            Text(
              'Hi Julia 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
          // Menambahkan background gambar
          Positioned.fill(
            child: Image.asset(
              'assets/back1.jpg', // Ganti dengan nama file gambar yang sesuai
              fit: BoxFit.cover,  // Mengatur gambar agar menutupi seluruh layar
            ),
          ),
          SingleChildScrollView(  // Membuat konten bisa di-scroll
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  // Menyesuaikan jumlah kolom berdasarkan lebar layar
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),  // Menghindari scroll ganda
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (screenWidth > 600) ? 2 : 2,  // 3 kolom untuk layar besar, 2 kolom untuk layar kecil
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: screenWidth > 600 ? 1.3 : 1, // Menyesuaikan ukuran untuk layar kecil
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        title: categories[index]['title'],
                        imagePath: categories[index]['imagePath'],
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

  const CategoryCard({
    Key? key,
    required this.title,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),  // Membuat sudut lebih melengkung
      ),
      elevation: 8,  // Memberikan bayangan lebih dalam
      child: InkWell(
        onTap: () {
          // Navigasi ke halaman terkait kategori
          if (title == 'Stok Produk') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProdukPage()),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),  // Membuat sudut lebih melengkung
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(  // Memberikan efek bayangan di luar tombol
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 40, width: 40), // Menampilkan gambar sesuai path
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,  // Mengurangi ukuran teks
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
  {'title': 'Kasir', 'imagePath': 'assets/kasirlogo.png'},  // Ganti dengan path gambar Anda
  {'title': 'Stok Produk', 'imagePath': 'assets/stoklogo.png'},  // Ganti dengan path gambar Anda
  {'title': 'Laporan', 'imagePath': 'assets/laporanlogo.png'},  // Ganti dengan path gambar Anda
  {'title': 'Pengaturan', 'imagePath': 'assets/pengaturanlogo.png'},  // Ganti dengan path gambar Anda
];

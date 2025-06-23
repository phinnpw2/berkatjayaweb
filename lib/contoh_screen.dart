// // import 'dart:convert';
// // import 'package:berkatjaya_web/kasir_screen.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart'; // Mengimpor intl package
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'notatempo_screen.dart'; // Impor NotaTempoScreen

// // class CetakNotaScreen extends StatelessWidget {
// //   final String customerName; 
// //   final List<Map<String, dynamic>> orderMenu;
// //   final double totalAmount;
// //   final double change;
// //   final String paymentMethod;
// //   final String invoiceNumber;  // Menerima parameter invoiceNumber
// //   final Timestamp? originalTimestamp;  // Menyimpan timestamp asli, opsional

// //   CetakNotaScreen({
// //     required this.customerName,
// //     required this.orderMenu,
// //     required this.totalAmount,
// //     required this.change,
// //     required this.paymentMethod,
// //     required this.invoiceNumber,  // Menerima parameter invoiceNumber
// //     this.originalTimestamp,  // Menambahkan timestamp asli sebagai opsional
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     // Jika originalTimestamp ada, gunakan tanggal tersebut, jika tidak gunakan DateTime.now()
// //     DateTime orderDate = originalTimestamp?.toDate() ?? DateTime.now();  // Jika originalTimestamp tidak ada, gunakan waktu saat ini
// //     DateTime printDate = DateTime.now();  // Waktu nota dicetak (waktu sekarang)

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Cetak Nota', style: TextStyle(fontWeight: FontWeight.bold)),
// //         backgroundColor: Colors.deepPurpleAccent,
// //         elevation: 5,
// //       ),
// //       body: SingleChildScrollView( 
// //         child: Container(
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [Colors.purple.shade100, Colors.blue.shade200], 
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //             ),
// //           ),
// //           child: Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: Center(
// //               child: Container(
// //                 width: 350,
// //                 padding: EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   border: Border.all(color: Colors.grey.shade300),
// //                   borderRadius: BorderRadius.circular(10),
// //                   color: Colors.white,
// //                 ),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // Logo Toko
// //                     Container(
// //                       alignment: Alignment.center,
// //                       child: Text(
// //                         'LOGO TOKO', 
// //                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
// //                       ),
// //                     ),
// //                     SizedBox(height: 10),
// //                     // Nama Toko dan Alamat
// //                     Text(
// //                       'Toko Berkat Jaya\nJl. Slamet Riady', 
// //                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                     SizedBox(height: 10),
// //                     // Tanggal dan Waktu
// //                     Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           originalTimestamp != null ? 'Tanggal Nota Dibuat: ${DateFormat('yyyy-MM-dd').format(orderDate)}' : '', 
// //                           style: TextStyle(fontSize: 14, color: Colors.black),
// //                         ), 
// //                         SizedBox(height: 5),
// //                         Text(
// //                            'Tanggal Cetak: ${DateFormat('yyyy-MM-dd').format(printDate)}',
// //                           style: TextStyle(fontSize: 14, color: Colors.black),
// //                         ),                     
// //                       ],
// //                     ),
// //                     SizedBox(height: 15),
// //                     // Nomor Nota dan Kasir ditempatkan di atas garis
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text('Nomor Nota: ${invoiceNumber}', style: TextStyle(fontSize: 14, color: Colors.black)),
// //                         Text('Kasir: Evy', style: TextStyle(fontSize: 14, color: Colors.black)), // Kasir lebih kecil dan abu-abu
// //                       ],
// //                     ),
// //                     SizedBox(height: 10),
// //                     // Garis Pemisah
// //                     SizedBox(height: 15),
// //                     Divider(color: Colors.black),
// //                     SizedBox(height: 10),
                    
// //                     // Rincian Produk
// //                     Text('Detail Pembelian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
// //                     SizedBox(height: 10),
// //                     Container(
// //                       decoration: BoxDecoration(
// //                         border: Border.all(color: Colors.grey.shade300),
// //                         borderRadius: BorderRadius.circular(8),
// //                         color: Colors.grey.shade100,
// //                       ),
// //                       child: Column(
// //                         children: orderMenu.map((item) {
// //                           return ListTile(
// //                             title: Text('${item['name']} (x${item['quantity']})', style: TextStyle(fontSize: 14, color: Colors.black)),
// //                             subtitle: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.black)),
// //                           );
// //                         }).toList(),
// //                       ),
// //                     ),
// //                     SizedBox(height: 10),
// //                     Divider(color: Colors.black),
// //                     Text('Nama Pelanggan: $customerName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
// //                     SizedBox(height: 10),
// //                     Text('Total Harga: Rp ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
// //                     SizedBox(height: 10),
// //                     Text('Pengembalian: Rp ${change.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
// //                     SizedBox(height: 15),
// //                     Text('Metode Pembayaran : $paymentMethod', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
// //                     SizedBox(height: 20),
// //                     // Tombol Transaksi Baru
// //                     Center(
// //                       child: ElevatedButton(
// //                         onPressed: () async {
// //                           // Arahkan ke KasirScreen untuk transaksi baru
// //                           Navigator.pushAndRemoveUntil(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => KasirScreen()), 
// //                             (Route<dynamic> route) => false, 
// //                           );
// //                         },
// //                         child: Text('Transaksi Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.green,  // Mengubah warna tombol menjadi hijau
// //                           padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(30), // Rounded corners
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(height: 20),
// //                     // Tombol Nota Tempo
// //                     Center(
// //                       child: ElevatedButton(
// //                         onPressed: () async {
// //                           // Arahkan ke NotaTempoScreen
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => NotaTempoScreen()),
// //                           );
// //                         },
// //                         child: Text('Nota Tempo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.orange,  // Mengubah warna tombol menjadi oranye
// //                           padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(30), // Rounded corners
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // cetaknota

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:berkatjaya_web/pesanan_screen.dart';
// import 'produk_page.dart';
// import 'kasir_screen.dart';
// import 'notatempo_screen.dart';
// import 'riwayattransaksi_screen.dart';
// import 'pengaturan_screen.dart';
// import 'laporan_screen.dart';
// import 'dart:ui';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String username = '';
//   String role = '';
//   String userDocId = '';
//   bool isLoading = true;

//   List<String> get allowedCategories {
//     const rolePermissions = {
//       'Owner': ['Kasir', 'Stok Produk', 'Laporan', 'Pengaturan', 'Pesanan & Status', 'Riwayat Transaksi'],
//       'Kasir': ['Kasir', 'Pesanan & Status', 'Riwayat Transaksi', 'Pengaturan'],
//       'Kepala Gudang': ['Stok Produk', 'Pengaturan'],
//       'Sales': ['Stok Produk', 'Pengaturan'],
//     };
//     return rolePermissions[role] ?? [];
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       username = prefs.getString('username') ?? '';
//       role = prefs.getString('role') ?? '';
//       userDocId = prefs.getString('userDocId') ?? '';
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(25),
//             border: Border.all(color: Colors.white.withOpacity(0.3)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Text(
//             'Role: $role',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Container(
//               decoration: const BoxDecoration(
          //       image: DecorationImage(
          //         image: AssetImage('assets/backgroundhome.jpg'),
          //         fit: BoxFit.cover,
          //       ),
          //     ),
          //     child: BackdropFilter(
          //       filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          //       child: Container(),
          //     ),
          //   ),
          // ),
//           SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   _buildWelcomeSection(),
//                   const SizedBox(height: 40),
//                   _buildStoreTitle(),
//                   const SizedBox(height: 40),
//                   _buildMenuGrid(context),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWelcomeSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(
//               Icons.person_outline,
//               color: Colors.white,
//               size: 32,
//             ),
//           ),
//           const SizedBox(width: 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Selamat Datang',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white.withOpacity(0.8),
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   username,
//                   style: const TextStyle(
//                     fontSize: 24,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStoreTitle() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 20),
//       child: Column(
//         children: [
//           Text(
//             'TOKO BERKAT JAYA',
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               letterSpacing: 3,
//               shadows: [
//                 Shadow(
//                   offset: const Offset(0, 4),
//                   color: Colors.black.withOpacity(0.5),
//                   blurRadius: 8,
//                 ),
//               ],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Container(
//             height: 3,
//             width: 80,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.8),
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuGrid(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         int crossAxisCount;
//         if (constraints.maxWidth > 1200) {
//           crossAxisCount = 3;
//         } else if (constraints.maxWidth > 800) {
//           crossAxisCount = 2;
//         } else {
//           crossAxisCount = 1;
//         }

//         return GridView.builder(
//           physics: const NeverScrollableScrollPhysics(),
//           shrinkWrap: true,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: crossAxisCount,
//             crossAxisSpacing: 20,
//             mainAxisSpacing: 20,
//             childAspectRatio: 1.4,
//           ),
//           itemCount: categories.length,
//           itemBuilder: (context, index) {
//             final category = categories[index];
//             final isAllowed = allowedCategories.contains(category['title']);
//             return _buildMenuCard(context, category, isAllowed);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildMenuCard(BuildContext context, Map<String, dynamic> category, bool isAllowed) {
//     return GestureDetector(
//       onTap: () => _handleMenuTap(context, category['title'], isAllowed),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: isAllowed
//                 ? [const Color(0xFF003f7f), const Color(0xFF0056b3)]
//                 : [Colors.grey.shade600, Colors.grey.shade700],
//           ),
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: isAllowed ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.25),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Image.asset(
//                   category['imagePath'],
//                   height: 48,
//                   width: 48,
//                   color: Colors.white,
//                   errorBuilder: (context, error, stackTrace) {
//                     return const Icon(
//                       Icons.apps_rounded,
//                       size: 48,
//                       color: Colors.white,
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 category['title'],
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   height: 1.2,
//                   shadows: [
//                     Shadow(
//                       offset: Offset(0, 2),
//                       color: Colors.black26,
//                       blurRadius: 4,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleMenuTap(BuildContext context, String title, bool isAllowed) {
//     if (!isAllowed) {
//       _showDialog(
//         context,
//         'Akses Ditolak',
//         'Role $role tidak memiliki akses ke menu "$title".',
//         Icons.lock_outline,
//         Colors.red,
//       );
//       return;
//     }

//     switch (title) {
//       case 'Kasir':
//         _showKasirDialog(context);
//         break;
//       case 'Pesanan & Status':
//         Navigator.push(context, MaterialPageRoute(builder: (_) => PesananScreen()));
//         break;
//       case 'Riwayat Transaksi':
//         Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatTransaksiScreen()));
//         break;
//       case 'Laporan':
//         Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanScreen()));
//         break;
//       case 'Stok Produk':
//         Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukPage()));
//         break;
//       case 'Pengaturan':
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PengaturanScreen(
//               username: username,
//               role: role,
//               userDocId: userDocId,
//             ),
//           ),
//         );
//         break;
//     }
//   }

//   void _showKasirDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         backgroundColor: Colors.white,
//         title: Row(
//           children: const [
//             Icon(Icons.payment, color: Color(0xFF003f7f)),
//             SizedBox(width: 12),
//             Text('Pilih Mode Kasir'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildKasirOption(
//               context,
//               'Kasir Langsung',
//               Icons.point_of_sale,
//               () {
//                 Navigator.pop(context);
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => KasirScreen()));
//               },
//             ),
//             const SizedBox(height: 12),
//             _buildKasirOption(
//               context,
//               'Nota Tempo',
//               Icons.receipt_long,
//               () {
//                 Navigator.pop(context);
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => NotaTempoScreen()));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKasirOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFF003f7f).withOpacity(0.05),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: const Color(0xFF003f7f).withOpacity(0.2),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: const Color(0xFF003f7f), size: 24),
//             const SizedBox(width: 16),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDialog(BuildContext context, String title, String content, IconData icon, Color iconColor) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(icon, color: iconColor),
//             const SizedBox(width: 8),
//             Text(title),
//           ],
//         ),
//         content: Text(content),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// final List<Map<String, dynamic>> categories = [
//   {'title': 'Kasir', 'imagePath': 'assets/kasirlogo.png'},
//   {'title': 'Stok Produk', 'imagePath': 'assets/stoklogo.png'},
//   {'title': 'Laporan', 'imagePath': 'assets/laporanlogo.png'},
//   {'title': 'Pengaturan', 'imagePath': 'assets/pengaturanlogo.png'},
//   {'title': 'Pesanan & Status', 'imagePath': 'assets/pesananlogo.png'},
//   {'title': 'Riwayat Transaksi', 'imagePath': 'assets/riwayatlogo.png'},
// ];

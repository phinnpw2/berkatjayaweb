// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'package:path_provider/path_provider.dart';

// class RiwayatOrderScreen extends StatefulWidget {
//   @override
//   _RiwayatOrderScreenState createState() => _RiwayatOrderScreenState();
// }

// class _RiwayatOrderScreenState extends State<RiwayatOrderScreen> {
//   List<Map<String, dynamic>> orders = [];

//   // Fungsi untuk membaca riwayat transaksi dari file
//   Future<void> loadOrders() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final path = '${directory.path}/riwayattransaksi_screen.txt';
//     final file = File(path);

//     if (await file.exists()) {
//       final fileContents = await file.readAsString();
//       final List<String> orderStrings = fileContents.split('\n');
//       List<Map<String, dynamic>> loadedOrders = [];

//       for (var orderString in orderStrings) {
//         if (orderString.isNotEmpty) {
//           Map<String, dynamic> order = jsonDecode(orderString);
//           loadedOrders.add(order);
//         }
//       }

//       setState(() {
//         orders = loadedOrders;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     loadOrders();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Riwayat Order'),
//         backgroundColor: Colors.deepPurpleAccent,
//       ),
//       body: orders.isEmpty
//           ? Center(child: Text('Tidak ada transaksi yang disimpan.'))
//           : ListView.builder(
//               itemCount: orders.length,
//               itemBuilder: (context, index) {
//                 var order = orders[index];
//                 return Card(
//                   margin: EdgeInsets.all(10),
//                   child: ListTile(
//                     title: Text(order['customerName']),
//                     subtitle: Text('Total: Rp ${order['totalAmount']}'),
//                     trailing: Text(order['date']),
//                     onTap: () {
//                       // Aksi yang ingin dilakukan ketika item di-tap, misalnya tampilkan detail
//                     },
//                   ),
//                 );
//               // }
//             ),
//     );
//   }
// }

// import 'package:shared_preferences/shared_preferences.dart';

// class RiwayatTransaksi {
//   final String customerName;
//   final List<Map<String, dynamic>> orderDetails;
//   final double totalAmount;
//   final String paymentMethod;
//   final double change;
//   final String date;

//   RiwayatTransaksi({
//     required this.customerName,
//     required this.orderDetails,
//     required this.totalAmount,
//     required this.paymentMethod,
//     required this.change,
//     required this.date,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'customerName': customerName,
//       'orderDetails': orderDetails,
//       'totalAmount': totalAmount,
//       'paymentMethod': paymentMethod,
//       'change': change,
//       'date': date,
//     };
//   }

//   static RiwayatTransaksi fromMap(Map<String, dynamic> map) {
//     return RiwayatTransaksi(
//       customerName: map['customerName'],
//       orderDetails: List<Map<String, dynamic>>.from(map['orderDetails']),
//       totalAmount: map['totalAmount'],
//       paymentMethod: map['paymentMethod'],
//       change: map['change'],
//       date: map['date'],
//     );
//   }
// }

// Future<void> saveTransaction(RiwayatTransaksi transaksi) async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> transactions = prefs.getStringList('transactions') ?? [];

//   // Convert RiwayatTransaksi to Map and then to String
//   String transaksiString = transaksi.toMap().toString();
//   transactions.add(transaksiString);
  
//   // Save updated transactions list to SharedPreferences
//   await prefs.setStringList('transactions', transactions);
// }

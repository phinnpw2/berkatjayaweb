import 'package:berkatjaya_web/kasir_screen.dart';
import 'package:berkatjaya_web/laporan_screen.dart';
import 'package:berkatjaya_web/login_screen.dart';
import 'package:berkatjaya_web/notatempo_screen.dart';
import 'package:berkatjaya_web/pembayaran_screen.dart';
import 'package:berkatjaya_web/produk_page.dart';
import 'package:berkatjaya_web/riwayattransaksi_screen.dart';
import 'package:berkatjaya_web/statusnotatempo_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screen.dart';  // HomeScreen baru yang akan ditampilkan pertama kali

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Produk App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  LoginPage(), // Menampilkan HomeScreen pertama kali
    );
  }
}

 
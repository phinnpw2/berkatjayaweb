import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'produk_page.dart';  // ProdukPage yang akan dituju setelah login
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
      home:  HomeScreen(), // Menampilkan HomeScreen pertama kali
    );
  }
}

 
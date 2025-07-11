import 'package:berkatjaya_web/home_screen.dart';
import 'package:berkatjaya_web/login_screen.dart';
import 'package:berkatjaya_web/pesanan_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      home: LoginPage(), //ww
    );
  }
}

 
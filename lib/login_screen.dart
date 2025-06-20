import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'logger.dart'; 
import 'user_list_screen.dart'; 
import 'user_session.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Username dan password tidak boleh kosong"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('user')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final userData = doc.data();
        final userDocId = doc.id;

        final role = userData['role'] ?? 'Unknown';
        final namaUser = userData['username'] ?? 'User';
        
        UserSession.userDocId = userDocId;
        UserSession.username = namaUser;
        UserSession.role = role;

        await logActivity(
          userId: userDocId,
          username: namaUser,
          activity: 'Login ke sistem',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: namaUser,
              role: role,
              userDocId: userDocId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Username atau password salah"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Terjadi kesalahan, coba lagi"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgroundlogin.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(top: 100),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Toko Berkat Jaya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003f7f),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Color(0xFF003f7f)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Color(0xFF003f7f)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF003f7f)),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.symmetric(vertical: 15, horizontal: 40)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
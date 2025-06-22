import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class PengaturanScreen extends StatefulWidget {
  final String username;
  final String role;
  final String userDocId;

  const PengaturanScreen({
    Key? key,
    required this.username,
    required this.role,
    required this.userDocId,
  }) : super(key: key);

  @override
  _PengaturanScreenState createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _editUsernameController = TextEditingController();
  final _editPasswordController = TextEditingController();
  final _editRoleController = TextEditingController();

  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _newRole = 'Kasir';

  bool _isLoading = false;
  final _availableRoles = ['Owner', 'Kasir', 'Kepala Gudang', 'Sales'];

  @override
  void initState() {
    super.initState();
    _editUsernameController.text = widget.username;
    _editRoleController.text = widget.role;
    _editPasswordController.text = '';
  }

  void _editAkun() async {
    final username = _editUsernameController.text.trim();
    final password = _editPasswordController.text.trim();
    final role = _editRoleController.text.trim();

    if (username.isEmpty || password.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.userDocId)
        .update({
      'username': username,
      'password': password,
      'role': role,
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun berhasil diperbarui')),
    );
  }

  void _tambahAkunBaru() async {
    final username = _newUsernameController.text.trim();
    final password = _newPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || _newRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua data harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('user').add({
      'username': username,
      'password': password,
      'role': _newRole,
    });

    setState(() {
      _newUsernameController.clear();
      _newPasswordController.clear();
      _newRole = 'Kasir';
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun baru berhasil ditambahkan')),
    );
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role.toLowerCase() == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Akun Anda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _editUsernameController,
              decoration: InputDecoration(labelText: 'Username'),
              readOnly: !isOwner,
            ),
            TextField(
              controller: _editPasswordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              readOnly: !isOwner,
            ),
            TextField(
              controller: _editRoleController,
              decoration: InputDecoration(labelText: 'Role'),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            if (isOwner)
              ElevatedButton(
                onPressed: _isLoading ? null : _editAkun,
                child: Text('Simpan Perubahan'),
              ),

            const SizedBox(height: 32),

            if (isOwner) ...[
              Text('➕ Tambah Akun Baru', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _newUsernameController,
                decoration: InputDecoration(labelText: 'Username Baru'),
              ),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _newRole,
                decoration: InputDecoration(labelText: 'Role'),
                onChanged: (val) {
                  if (val != null) setState(() => _newRole = val);
                },
                items: _availableRoles.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _tambahAkunBaru,
                child: Text('Buat Akun Baru'),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: Icon(Icons.list),
                label: Text('Lihat Semua Akun Terdaftar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                onPressed: () {
              
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}

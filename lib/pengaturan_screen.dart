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
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _newRole = 'Kasir';
  bool _isLoading = false;
  final _availableRoles = ['Owner', 'Kasir', 'Kepala Gudang', 'Sales'];

  @override
  void initState() {
    super.initState();
    _editUsernameController.text = widget.username;
  }

  Future<List<Map<String, dynamic>>> _getAllUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('user').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void _editAkun() async {
    if (_editUsernameController.text.trim().isEmpty || _editPasswordController.text.trim().isEmpty) {
      _showSnackBar('Semua kolom harus diisi');
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('user').doc(widget.userDocId).update({
      'username': _editUsernameController.text.trim(),
      'password': _editPasswordController.text.trim(),
    });
    setState(() => _isLoading = false);
    _showSnackBar('Akun berhasil diperbarui');
  }

  void _tambahAkunBaru() async {
    if (_newUsernameController.text.trim().isEmpty || _newPasswordController.text.trim().isEmpty) {
      _showSnackBar('Semua data harus diisi');
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('user').add({
      'username': _newUsernameController.text.trim(),
      'password': _newPasswordController.text.trim(),
      'role': _newRole,
    });
    setState(() {
      _newUsernameController.clear();
      _newPasswordController.clear();
      _newRole = 'Kasir';
      _isLoading = false;
    });
    _showSnackBar('Akun baru berhasil ditambahkan');
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF003f7f)),
            child: Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF003f7f)),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false, bool readOnly = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF003f7f), width: 2),
          ),
        ),
        obscureText: obscureText,
        readOnly: readOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role.toLowerCase() == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
        backgroundColor: Color(0xFF003f7f),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: 'Akun Anda',
              child: Column(
                children: [
                  _buildTextField(_editUsernameController, 'Username', readOnly: !isOwner),
                  _buildTextField(_editPasswordController, 'Password', obscureText: true, readOnly: !isOwner),
                  _buildTextField(TextEditingController(text: widget.role), 'Role', readOnly: true),
                  if (isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _editAkun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF003f7f),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Simpan Perubahan', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            if (isOwner) ...[
              _buildCard(
                title: 'Tambah Akun Baru',
                child: Column(
                  children: [
                    _buildTextField(_newUsernameController, 'Username Baru'),
                    _buildTextField(_newPasswordController, 'Password Baru', obscureText: true),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _newRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF003f7f), width: 2),
                          ),
                        ),
                        onChanged: (val) => setState(() => _newRole = val!),
                        items: _availableRoles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _tambahAkunBaru,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF003f7f),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Buat Akun Baru', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.list, color: Colors.white),
                  label: Text('Lihat Semua Akun Terdaftar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003f7f).withOpacity(0.8),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final users = await _getAllUsers();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.7,
                        maxChildSize: 0.95,
                        minChildSize: 0.4,
                        builder: (context, scrollController) {
                          return Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('Daftar Semua Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003f7f))),
                                SizedBox(height: 12),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(
                                          leading: Icon(Icons.person, color: Color(0xFF003f7f)),
                                          title: Text(user['username'] ?? 'Tanpa Username'),
                                          subtitle: Text('Role: ${user['role'] ?? 'Tidak Diketahui'}'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

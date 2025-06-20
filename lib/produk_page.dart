// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:berkatjaya_web/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'logger.dart';
import 'user_session.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  String _kategoriAktif = 'makanan';
  String _filterStok = 'semua';
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _tambahProduk() async {
    final nama = _namaController.text.trim();
    final stok = int.tryParse(_stokController.text) ?? -1;
    final harga = int.tryParse(_hargaController.text) ?? -1;

    if (nama.isEmpty || stok < 0 || harga < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi data dengan benar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('produk').add({
        'nama': nama,
        'stok': stok,
        'harga': harga,
        'kategori': _kategoriAktif,
        'gambar': _base64Image ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _namaController.clear();
      _stokController.clear();
      _hargaController.clear();
      setState(() {
        _base64Image = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi!')),
      );
    }
  }

  Future<void> _editProduk(String id, String nama, int stok, int harga) async {
    _namaController.text = nama;
    _stokController.text = stok.toString();
    _hargaController.text = harga.toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Edit Produk", style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final newNama = _namaController.text.trim();
                final newStok = int.tryParse(_stokController.text) ?? -1;
                final newHarga = int.tryParse(_hargaController.text) ?? -1;

                if (newNama.isEmpty || newStok < 0 || newHarga < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mohon isi data dengan benar')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('produk').doc(id).update({
                  'nama': newNama,
                  'stok': newStok,
                  'harga': newHarga,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk berhasil diperbarui!')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusProduk(String id, String nama) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('produk').doc(id).delete();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/back2.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.white.withOpacity(0.6)),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: const Text("Stok Produk", style: TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFF003366),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            username: UserSession.username,
                            role: UserSession.role,
                            userDocId: UserSession.userDocId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            hintText: 'Cari produk...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ToggleButtons(
                                isSelected: [
                                  _kategoriAktif == 'makanan',
                                  _kategoriAktif == 'minuman',
                                ],
                                onPressed: (index) {
                                  setState(() {
                                    _kategoriAktif = index == 0 ? 'makanan' : 'minuman';
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                fillColor: Colors.white,
                                selectedColor: const Color(0xFF003366),
                                color: Colors.white,
                                borderColor: Colors.transparent,
                                constraints: const BoxConstraints(minHeight: 40),
                                children: const [
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Makanan")),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Minuman")),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: const Color(0xFF003366),
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                value: _filterStok,
                                onChanged: (val) => setState(() => _filterStok = val!),
                                items: const [
                                  DropdownMenuItem(value: 'semua', child: Text('Semua')),
                                  DropdownMenuItem(value: 'stok_terbanyak', child: Text('Stok Terbanyak')),
                                  DropdownMenuItem(value: 'stok_tersedikit', child: Text('Stok Tersedikit')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildProdukList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTambahProdukBottomSheet(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
      ),
    );
  }

  Widget _buildProdukList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produk')
          .where('kategori', isEqualTo: _kategoriAktif)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;
        List<QueryDocumentSnapshot> docs = allDocs.where((doc) {
          final nama = (doc['nama'] ?? '').toString().toLowerCase();
          return nama.contains(_searchText);
        }).toList();

        if (_filterStok == 'stok_terbanyak') {
          docs.sort((a, b) => (b['stok'] ?? 0).compareTo(a['stok'] ?? 0));
        } else if (_filterStok == 'stok_tersedikit') {
          docs.sort((a, b) => (a['stok'] ?? 0).compareTo(b['stok'] ?? 0));
        }

        if (docs.isEmpty) return const Center(child: Text('Belum ada produk'));

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final nama = data['nama'] ?? 'tidak tersedia';
            final stok = data['stok'] ?? 0;
            final harga = data['harga'] ?? 0;
            final img = data['gambar'] ?? '';

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: img.isNotEmpty
                          ? Image.memory(base64Decode(img), height: 70, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported, size: 70, color: Colors.grey),
                    ),
                    Text(nama, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    Text('Stok: $stok', style: const TextStyle(fontSize: 12)),
                    Text('Rp ${NumberFormat('#,###').format(harga)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _editProduk(docs[index].id, nama, stok, harga),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => _hapusProduk(docs[index].id, nama),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTambahProdukBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Tambah Produk", style: Theme.of(context).textTheme.titleLarge),
              TextField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Produk')),
              TextField(controller: _stokController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
              TextField(controller: _hargaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
              DropdownButtonFormField<String>(
                value: _kategoriAktif,
                onChanged: (val) => setState(() => _kategoriAktif = val!),
                items: ['makanan', 'minuman']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
              ),
              if (_base64Image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.memory(base64Decode(_base64Image!), width: 100, height: 100),
                ),
              const SizedBox(height: 12),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        await _tambahProduk();
                        Navigator.pop(context);
                      },
                      child: const Text('Simpan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

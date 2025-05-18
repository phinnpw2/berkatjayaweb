import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  String _kategoriAktif = 'makanan';
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
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
    final nama = _namaController.text;
    final stok = int.tryParse(_stokController.text) ?? 0;
    final harga = int.tryParse(_hargaController.text) ?? 0;

    if (nama.isEmpty) return;

    setState(() => _isLoading = true);

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
  }

  Future<void> _editProduk(String id, String nama, int stok) async {
    _namaController.text = nama;
    _stokController.text = stok.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _namaController.clear();
              _stokController.clear();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final newNama = _namaController.text;
              final newStok = int.tryParse(_stokController.text) ?? 0;

              await FirebaseFirestore.instance.collection('produk').doc(id).update({
                'nama': newNama,
                'stok': newStok,
              });

              Navigator.pop(context);
              _namaController.clear();
              _stokController.clear();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusProduk(String id) async {
    await FirebaseFirestore.instance.collection('produk').doc(id).delete();
  }

  void _showTambahProdukDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Kategori: '),
                    DropdownButton<String>(
                      value: _kategoriAktif,
                      onChanged: (String? newValue) {
                        setState(() {
                          _kategoriAktif = newValue!;
                        });
                      },
                      items: <String>['makanan', 'minuman'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ],
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
                    child: Image.memory(
                      base64Decode(_base64Image!),
                      width: 80,
                      height: 80,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () async {
                      await _tambahProduk();
                      Navigator.pop(context);
                    },
                    child: const Text('Simpan'),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildRoundedButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTabButton(String label, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildArrowLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/back2.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRoundedButton('Stok Produk'),
                      _buildRoundedButton('Filter'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('Makanan', isActive: _kategoriAktif == 'makanan', onTap: () {
                          setState(() => _kategoriAktif = 'makanan');
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTabButton('Minuman', isActive: _kategoriAktif == 'minuman', onTap: () {
                          setState(() => _kategoriAktif = 'minuman');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildArrowLabel('Daftar Produk'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('produk')
                          .where('kategori', isEqualTo: _kategoriAktif)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('Belum ada produk'));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final nama = data['nama'] ?? '';
                            final stok = data['stok'] ?? 0;
                            final harga = data['harga'] ?? 0;
                            final base64Image = data['gambar'] ?? '';

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D3B2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (base64Image.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(base64Image),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.image_not_supported, size: 70, color: Colors.grey),
                                  Text(
                                    '$nama\nStok: $stok\nHarga: Rp $harga',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.black),
                                        onPressed: () => _editProduk(doc.id, nama, stok),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.black),
                                        onPressed: () {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi Hapus'),
      content: Text('Apakah Anda yakin ingin menghapus "$nama"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // batal
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // tutup dialog dulu
            await _hapusProduk(doc.id); // baru hapus
          },
          child: const Text(
            'Hapus',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
},

                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showTambahProdukDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

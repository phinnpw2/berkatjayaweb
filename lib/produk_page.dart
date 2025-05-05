import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  // Fungsi untuk tambah produk
  Future<void> _tambahProduk() async {
    final nama = _namaController.text;
    final stok = int.tryParse(_stokController.text) ?? 0;
    final harga = int.tryParse(_hargaController.text) ?? 0;

    if (nama.isEmpty) return;

    await FirebaseFirestore.instance.collection('produk').add({
      'nama': nama,
      'stok': stok,
      'harga': harga,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _namaController.clear();
    _stokController.clear();
    _hargaController.clear();
  }

  // Fungsi untuk hapus produk
  Future<void> _hapusProduk(String docId) async {
    await FirebaseFirestore.instance.collection('produk').doc(docId).delete();
  }

  // Fungsi untuk edit produk
  Future<void> _editProduk(String docId) async {
    final nama = _namaController.text;
    final stok = int.tryParse(_stokController.text) ?? 0;
    final harga = int.tryParse(_hargaController.text) ?? 0;

    if (nama.isEmpty) return;

    await FirebaseFirestore.instance.collection('produk').doc(docId).update({
      'nama': nama,
      'stok': stok,
      'harga': harga,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _namaController.clear();
    _stokController.clear();
    _hargaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            ElevatedButton(
              onPressed: _tambahProduk,
              child: const Text('Tambah Produk'),
            ),
            const SizedBox(height: 20),
            const Text('Daftar Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('produk')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      return ListTile(
                        title: Text(data['nama']),
                        subtitle: Text('Stok: ${data['stok']} | Harga: Rp${data['harga']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _namaController.text = data['nama'];
                                _stokController.text = data['stok'].toString();
                                _hargaController.text = data['harga'].toString();
                                _editProduk(docId); // Panggil fungsi edit
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _hapusProduk(docId); // Panggil fungsi hapus
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

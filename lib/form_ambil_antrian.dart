import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormAmbilAntrian extends StatefulWidget {
  const FormAmbilAntrian({super.key});

  @override
  State<FormAmbilAntrian> createState() => _FormAmbilAntrianState();
}

class _FormAmbilAntrianState extends State<FormAmbilAntrian> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> ambilAntrian() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = 'User tidak ditemukan. Harap login ulang.';
        });
        return;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Cek apakah user sudah ambil antrian hari ini
      final existing = await FirebaseFirestore.instance
          .collection('antrian')
          .where('uid', isEqualTo: user.uid)
          .where(
            'waktu',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _message = 'Kamu sudah ambil antrian hari ini.';
        });
        return;
      }

      // Simpan antrian
      await FirebaseFirestore.instance.collection('antrian').add({
        'uid': user.uid,
        'nama': namaController.text.trim(),
        'waktu': FieldValue.serverTimestamp(),
        'status': 'menunggu',
      });

      setState(() {
        _message = 'Antrian berhasil diambil!';
      });
    } catch (e) {
      setState(() {
        _message = 'Terjadi kesalahan saat mengambil antrian.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Antrian')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Silakan isi nama untuk mengambil antrian:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: ambilAntrian,
                      child: const Text('Ambil Antrian'),
                    ),
              const SizedBox(height: 16),
              if (_message != null)
                Center(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('berhasil')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

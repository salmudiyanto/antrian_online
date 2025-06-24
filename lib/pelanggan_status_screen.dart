import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PelangganStatusScreen extends StatefulWidget {
  const PelangganStatusScreen({super.key});

  @override
  State<PelangganStatusScreen> createState() => _PelangganStatusScreenState();
}

class _PelangganStatusScreenState extends State<PelangganStatusScreen> {
  User? user;
  String? docId;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Stream<DocumentSnapshot>? getUserAntrianStream() {
    if (user == null) return null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Cari dokumen antrian milik user hari ini
    return FirebaseFirestore.instance
        .collection('antrian')
        .where('uid', isEqualTo: user!.uid)
        .where('waktu', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null,
        )
        .where((doc) => doc != null)
        .cast<DocumentSnapshot>();
  }

  Future<int> getNomorAntrian(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection('antrian')
        .doc(docId)
        .get();
    final waktuSaya = (doc.data()?['waktu'] as Timestamp).toDate();

    final snapshot = await FirebaseFirestore.instance
        .collection('antrian')
        .where('waktu', isLessThanOrEqualTo: Timestamp.fromDate(waktuSaya))
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final stream = getUserAntrianStream();

    if (stream == null) {
      return const Scaffold(
        body: Center(child: Text('Harap login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Status Antrian Anda')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Kamu belum ambil antrian hari ini.'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'menunggu';
          final waktu = (data['waktu'] as Timestamp).toDate();
          final id = snapshot.data!.id;

          return FutureBuilder<int>(
            future: getNomorAntrian(id),
            builder: (context, nomorSnapshot) {
              final nomor = nomorSnapshot.data;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Nomor Antrian Kamu:',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nomor != null ? nomor.toString() : '...',
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Status: $status',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Waktu Daftar: ${waktu.hour}:${waktu.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final DateFormat formatter = DateFormat('HH:mm:ss');

  Stream<QuerySnapshot> getTodayAntrian() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('antrian')
        .where('waktu', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('waktu')
        .snapshots();
  }

  Future<void> updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('antrian').doc(docId).update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getTodayAntrian(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada antrian hari ini'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              final nama = data['nama'] ?? 'Tanpa Nama';
              final status = data['status'] ?? 'menunggu';
              final waktu = data['waktu'] != null
                  ? formatter.format((data['waktu'] as Timestamp).toDate())
                  : '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(nama),
                  subtitle: Text('Status: $status\nWaktu: $waktu'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      if (status == 'menunggu')
                        ElevatedButton(
                          onPressed: () => updateStatus(id, 'dipanggil'),
                          child: const Text('Panggil'),
                        ),
                      if (status == 'dipanggil')
                        ElevatedButton(
                          onPressed: () => updateStatus(id, 'selesai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Selesai'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

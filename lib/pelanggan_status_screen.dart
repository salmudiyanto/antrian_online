import 'package:antrian_online/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PelangganStatusScreen extends StatefulWidget {
  const PelangganStatusScreen({super.key});

  @override
  State<PelangganStatusScreen> createState() => _PelangganStatusScreenState();
}

class _PelangganStatusScreenState extends State<PelangganStatusScreen> {
  User? user;
  String? docId;

  Future<void> showAntrianDipanggilNotification(String nama) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'antrian_channel', 'Notifikasi Antrian',
      channelDescription: 'Notifikasi saat antrian dipanggil',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Nomor Antrian Dipanggil',
      'Halo $nama, giliran kamu sekarang!',
      notificationDetails,
    );
  }

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
          final nama = data['nama'] ?? 'Pelanggan';

          // Notifikasi saat status dipanggil
          if (status == 'dipanggil') {
            // hanya tampilkan 1 kali
            Future.microtask(() {
              showAntrianDipanggilNotification(nama);
            });
          }

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

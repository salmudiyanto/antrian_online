import 'package:flutter/material.dart';
import 'form_ambil_antrian.dart';
import 'pelanggan_status_screen.dart'; // pastikan ini diimpor

class PelangganHomeScreen extends StatelessWidget {
  const PelangganHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Ambil Antrian'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormAmbilAntrian()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Lihat Status Antrian'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PelangganStatusScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PelangganHomeScreen extends StatelessWidget {
  const PelangganHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      body: const Center(child: Text('Halo Pelanggan!')),
    );
  }
}

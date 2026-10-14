// lib/home/home_screen.dart
// صفحه اصلی موقت — بعداً UI واقعی را جایگزین کن
import 'package:flutter/material.dart';
import 'package:helsa/setting/storage/profile_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.profile;
    final name = [
      profile?['firstName']?.toString() ?? '',
      profile?['lastName']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name.isEmpty ? 'Helsa' : name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Home',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

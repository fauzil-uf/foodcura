import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModelSQL user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<UserModelSQL>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = DBHelper().getAllUsers();
  }

  void _refresh() {
    setState(() => _usersFuture = DBHelper().getAllUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Selamat Datang, ${widget.user.name}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daftar Pengguna Terdaftar:', style: AppTextStyles.label),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<UserModelSQL>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'),
                    );
                  }
                  final daftarPengguna = snapshot.data ?? [];
                  if (daftarPengguna.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada data pengguna.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: daftarPengguna.length,
                    itemBuilder: (context, index) {
                      final user = daftarPengguna[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.iconCircleBg,
                            child: Icon(Icons.person, color: AppColors.primary),
                          ),
                          title: Text(
                            user.name,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(user.email),
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
    );
  }
}

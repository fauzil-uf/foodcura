import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DBHelper _db = DBHelper();

  List<NotificationModel> _notifications = [];
  int _selectedFilter = 0;
  bool _loading = true;

  final List<String> _filters = ['Semua', 'Belum Dibaca', 'Kadaluwarsa', 'FoodCura'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Generate expiry and nutrition excess notifications first
    await _db.checkExpiryAndCreateNotifications();
    await _db.checkNutritionExcess();

    String? filter;
    switch (_selectedFilter) {
      case 1:
        filter = 'unread';
        break;
      case 2:
        filter = 'expiry';
        break;
      case 3:
        filter = 'foodcura';
        break;
    }

    final notifs = await _db.getNotifications(filter: filter);

    if (mounted) {
      setState(() {
        _notifications = notifs;
        _loading = false;
      });
    }
  }

  void _onFilterChanged(int index) {
    setState(() => _selectedFilter = index);
    _loadData();
  }

  Future<void> _markAllRead() async {
    await _db.markAllNotificationsRead();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi ditandai dibaca')),
      );
    }
  }

  Future<void> _markRead(NotificationModel notif) async {
    if (notif.id != null && !notif.isRead) {
      await _db.markNotificationRead(notif.id!);
      _loadData();
    }
  }

  // Group notifications into Today and Earlier
  Map<String, List<NotificationModel>> get _groupedNotifications {
    final today = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (var notif in _notifications) {
      if (notif.isToday) {
        today.add(notif);
      } else {
        earlier.add(notif);
      }
    }

    return {'today': today, 'earlier': earlier};
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F3),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                toolbarHeight: 64,
                automaticallyImplyLeading: false,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassSurface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.ecoGreen,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Text(
                                'Notifikasi',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepForest,
                                ),
                              ),
                              // Mark all read
                              GestureDetector(
                                onTap: _markAllRead,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.done_all,
                                    color: AppColors.ecoGreen,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => _onFilterChanged(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppColors.surfaceDim),
                            ),
                            child: Center(
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textGray,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.ecoGreen)),
                )
              else if (_notifications.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today section
                        if (grouped['today']!.isNotEmpty) ...[
                          _buildSectionLabel('Hari Ini'),
                          const SizedBox(height: 10),
                          ...grouped['today']!.map((n) => _buildNotificationCard(n, false)),
                        ],

                        // Earlier section
                        if (grouped['earlier']!.isNotEmpty) ...[
                          if (grouped['today']!.isNotEmpty)
                            const SizedBox(height: 24),
                          _buildSectionLabel('Sebelumnya'),
                          const SizedBox(height: 10),
                          ...grouped['earlier']!.map((n) => _buildNotificationCard(n, true)),
                        ],

                        const SizedBox(height: 16),

                        // Info tip
                        _buildInfoTip(),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ecoGreen,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, bool isEarlier) {
    IconData iconData;
    Color accentColor;
    Color iconBgColor;
    String categoryTag;

    switch (notif.type) {
      case 'expiry_warning':
        categoryTag = 'Pantry & Expiry';
        accentColor = AppColors.urgent;
        iconData = Icons.warning_amber_rounded;
        iconBgColor = AppColors.warningBg;
        break;
      case 'nutrition_excess':
        categoryTag = 'Tracker Nutrisi';
        accentColor = AppColors.segera;
        iconData = Icons.analytics_rounded;
        iconBgColor = const Color(0xFFFFF4ED);
        break;
      case 'tips':
        categoryTag = 'Tips Food Rescue';
        accentColor = AppColors.ecoGreen;
        iconData = notif.iconType == 'restaurant'
            ? Icons.restaurant_rounded
            : Icons.lightbulb_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case 'system':
      default:
        categoryTag = 'System & Info';
        accentColor = const Color(0xFF2563EB); // Blue
        iconData = notif.iconType == 'eco'
            ? Icons.eco_rounded
            : Icons.system_update_rounded;
        iconBgColor = const Color(0xFFEFF6FF);
        break;
    }

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? AppColors.surfaceDim
                : accentColor.withValues(alpha: 0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2C1B).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent border strip
                Container(
                  width: 5,
                  color: notif.isRead
                      ? accentColor.withValues(alpha: 0.4)
                      : accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Opacity(
                      opacity: isEarlier ? 0.85 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Main Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Category tag + Unread dot
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        categoryTag,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Title
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    fontWeight: notif.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),

                                // Message
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // Time ago
                                Text(
                                  notif.timeAgo,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active, color: AppColors.ecoGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kami hanya mengirim notifikasi penting terkait bahan makananmu dan pengingat yang kamu atur.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.mintTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 40,
                color: AppColors.ecoGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada notifikasi saat ini.\nKami akan memberitahumu jika ada hal penting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

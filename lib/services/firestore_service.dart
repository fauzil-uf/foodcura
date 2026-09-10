import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/article_model.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import '../models/pantry_item_model.dart';

/// Service utama untuk interaksi dengan Cloud Firestore di FoodCura.
/// Dirancang modular, offline-friendly, dan toleran terhadap kegagalan jaringan.
class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  factory FirestoreService() => instance;
  FirestoreService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[FirestoreService] FirebaseFirestore belum terinisialisasi: $e');
      return null;
    }
  }

  // Nama koleksi Firestore
  static const String colFoods = 'foods';
  static const String colUsers = 'users';
  static const String colPantryItems = 'pantry_items';
  static const String colFoodLogs = 'food_logs';
  static const String colNotifications = 'notifications';
  static const String colArticles = 'articles';

  /// Cek ketersediaan Firestore
  bool get isAvailable => _firestore != null;

  // ===========================================================================
  // 1. MASTER FOODS CATALOG
  // ===========================================================================

  /// Mengambil semua data katalog makanan dari Firestore
  Future<List<FoodItemModel>> getFoods() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colFoods)
          .orderBy('name')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FoodItemModel.fromMap({
          ...data,
          'id': data['id'] ?? doc.id.hashCode.abs(),
        });
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil katalog foods: $e');
      return [];
    }
  }

  /// Batch upload / seeding katalog makanan lokal ke Firestore (Fase 2)
  Future<void> seedFoods(List<FoodItemModel> foods) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final batch = firestore.batch();
      final collection = firestore.collection(colFoods);

      for (final food in foods) {
        final docRef = collection.doc('food_${food.id ?? food.name.hashCode.abs()}');
        batch.set(docRef, {
          'id': food.id,
          'name': food.name,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'cholesterol': food.cholesterol,
          'category': food.category,
          'image_path': food.imagePath,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[FirestoreService] Berhasil seeding ${foods.length} makanan ke Firestore');
    } catch (e) {
      debugPrint('[FirestoreService] Gagal seeding foods ke Firestore: $e');
    }
  }

  // ===========================================================================
  // 2. USER PROFILE & ECO POINTS
  // ===========================================================================

  /// Menyimpan atau memperbarui profil user di Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String name,
    int? ecoPoints,
    int? streakCount,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final docRef = firestore.collection(colUsers).doc(uid);
      await docRef.set({
        'uid': uid,
        'email': email,
        'name': name,
        'eco_points': ?ecoPoints,
        'streak_count': ?streakCount,
        'last_active_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menyimpan user profile ($uid): $e');
    }
  }

  /// Mengambil data profil user dari Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection(colUsers).doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil profil user ($uid): $e');
      return null;
    }
  }

  /// Stream realtime untuk profil user (nama, eco_points, streak, dll.)
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    return firestore
        .collection(colUsers)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Memperbarui Eco Points dan streak user di Firestore
  Future<void> updateEcoPoints({
    required String uid,
    int? ecoPoints,
    int? streakCount,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final Map<String, dynamic> data = {
        'last_active_at': FieldValue.serverTimestamp(),
      };
      if (ecoPoints != null) data['eco_points'] = ecoPoints;
      if (streakCount != null) data['streak_count'] = streakCount;

      await firestore.collection(colUsers).doc(uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[FirestoreService] Gagal memperbarui eco points ($uid): $e');
    }
  }

  // ===========================================================================
  // 3. PANTRY ITEMS (SUBCOLLECTION: users/{uid}/pantry_items)
  // ===========================================================================

  /// Menambahkan item ke inventaris pantry di Firestore
  Future<String?> addPantryItem(String uid, PantryItemModel item) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final docId = item.id != null ? 'pantry_${item.id}' : null;
      final collection = firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colPantryItems);
      final docRef = docId != null ? collection.doc(docId) : collection.doc();

      await docRef.set({
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'storage': item.storage,
        'expiry_date': item.expiryDate.toIso8601String(),
        'image_url': item.imageUrl ?? '',
        'is_used': item.isUsed,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menambahkan pantry item: $e');
      return null;
    }
  }

  /// Memperbarui status atau data item pantry di Firestore
  Future<void> updatePantryItem(String uid, String firestoreId, PantryItemModel item) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colPantryItems)
          .doc(firestoreId)
          .set({
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'storage': item.storage,
        'expiry_date': item.expiryDate.toIso8601String(),
        'image_url': item.imageUrl ?? '',
        'is_used': item.isUsed,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] Gagal memperbarui pantry item ($firestoreId): $e');
    }
  }

  /// Menghapus item pantry dari Firestore
  Future<void> deletePantryItem(String uid, String firestoreId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colPantryItems)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menghapus pantry item ($firestoreId): $e');
    }
  }

  /// Helper normalisasi lokasi penyimpanan ke kategori resmi aplikasi
  static String _normalizeStorage(dynamic val) {
    final s = val?.toString().toLowerCase().trim() ?? '';
    if (s.contains('freezer') || s.contains('beku')) return 'Freezer';
    if (s.contains('kulkas') || s.contains('chiller') || s.contains('fridge') || s.contains('refrigerator')) return 'Kulkas';
    if (s.contains('lemari') || s.contains('kering') || s.contains('dry')) return 'Lemari Kering';
    if (s.contains('ruang') || s.contains('room')) return 'Suhu Ruang';
    return 'Kulkas';
  }

  /// Helper toleran untuk parse tanggal (String ISO, Firestore Timestamp, int millis)
  static DateTime _parseDateTime(dynamic val, [DateTime? fallback]) {
    if (val == null) return fallback ?? DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return dt;
    }
    return fallback ?? DateTime.now();
  }

  /// Helper toleran untuk konversi angka kuantitas
  static double _parseDouble(dynamic val, [double fallback = 1.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      final d = double.tryParse(val);
      if (d != null) return d;
    }
    return fallback;
  }

  /// Helper toleran untuk boolean
  static bool _parseBool(dynamic val, [bool fallback = false]) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is int) return val == 1;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return fallback;
  }

  /// Mengambil semua item pantry user dari Firestore
  Future<List<PantryItemModel>> getPantryItems(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colPantryItems)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawId = (data['id'] as num?)?.toInt() ??
            (doc.id.startsWith('pantry_')
                ? int.tryParse(doc.id.replaceFirst('pantry_', ''))
                : null);
        return PantryItemModel(
          firestoreId: doc.id,
          id: rawId,
          name: data['name']?.toString() ?? data['nama']?.toString() ?? '',
          quantity: _parseDouble(data['quantity'] ?? data['jumlah'], 1.0),
          unit: data['unit']?.toString() ?? data['satuan']?.toString() ?? 'buah',
          storage: _normalizeStorage(data['storage'] ?? data['penyimpanan']),
          expiryDate: _parseDateTime(
            data['expiry_date'] ?? data['expiryDate'] ?? data['kadaluwarsa'] ?? data['kedaluwarsa'],
            DateTime.now().add(const Duration(days: 7)),
          ),
          imageUrl: (data['image_url'] as String?)?.isEmpty == true ? null : data['image_url'] as String?,
          isUsed: _parseBool(data['is_used'] ?? data['isUsed'], false),
          createdAt: _parseDateTime(
            data['created_at'] ?? data['createdAt'],
            DateTime.now(),
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil data pantry: $e');
      return [];
    }
  }

  /// Stream realtime untuk item pantry user
  Stream<List<PantryItemModel>> streamPantryItems(String uid) {
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    return firestore
        .collection(colUsers)
        .doc(uid)
        .collection(colPantryItems)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawId = (data['id'] as num?)?.toInt() ??
            (doc.id.startsWith('pantry_')
                ? int.tryParse(doc.id.replaceFirst('pantry_', ''))
                : null);
        return PantryItemModel(
          firestoreId: doc.id,
          id: rawId,
          name: data['name']?.toString() ?? data['nama']?.toString() ?? '',
          quantity: _parseDouble(data['quantity'] ?? data['jumlah'], 1.0),
          unit: data['unit']?.toString() ?? data['satuan']?.toString() ?? 'buah',
          storage: _normalizeStorage(data['storage'] ?? data['penyimpanan']),
          expiryDate: _parseDateTime(
            data['expiry_date'] ?? data['expiryDate'] ?? data['kadaluwarsa'] ?? data['kedaluwarsa'],
            DateTime.now().add(const Duration(days: 7)),
          ),
          imageUrl: (data['image_url'] as String?)?.isEmpty == true ? null : data['image_url'] as String?,
          isUsed: _parseBool(data['is_used'] ?? data['isUsed'], false),
          createdAt: _parseDateTime(
            data['created_at'] ?? data['createdAt'],
            DateTime.now(),
          ),
        );
      }).toList();
    });
  }

  // ===========================================================================
  // 4. FOOD CONSUMPTION LOGS (SUBCOLLECTION: users/{uid}/food_logs)
  // ===========================================================================

  /// Menambahkan riwayat makanan harian ke Firestore
  Future<String?> addFoodLog(String uid, FoodLogModel log) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final docId = log.id != null ? 'foodlog_${log.id}' : null;
      final collection = firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colFoodLogs);
      final docRef = docId != null ? collection.doc(docId) : collection.doc();

      await docRef.set({
        'id': log.id,
        'food_name': log.foodName,
        'meal_type': log.mealType,
        'calories': log.calories,
        'protein': log.protein,
        'carbs': log.carbs,
        'fat': log.fat,
        'cholesterol': log.cholesterol,
        'image_path': log.imagePath,
        'time': log.time,
        'date': log.date,
        'note': log.note ?? '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menambahkan food log: $e');
      return null;
    }
  }

  /// Menghapus catatan makan dari Firestore
  Future<void> deleteFoodLog(String uid, String firestoreId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colFoodLogs)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menghapus food log ($firestoreId): $e');
    }
  }

  /// Mengambil log makanan pada tanggal tertentu (format: YYYY-MM-DD)
  Future<List<FoodLogModel>> getFoodLogsByDate(String uid, String date) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colFoodLogs)
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FoodLogModel(
          foodName: data['food_name'] as String? ?? '',
          mealType: data['meal_type'] as String? ?? '',
          calories: (data['calories'] as num?)?.toInt() ?? 0,
          protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
          carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
          fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
          cholesterol: (data['cholesterol'] as num?)?.toDouble() ?? 0.0,
          imagePath: data['image_path'] as String? ?? '',
          time: data['time'] as String? ?? '',
          date: data['date'] as String? ?? date,
          note: data['note'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil food logs untuk $date: $e');
      return [];
    }
  }

  /// Mengambil semua log makanan user dari Firestore
  Future<List<FoodLogModel>> getFoodLogs(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colFoodLogs)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawId = (data['id'] as num?)?.toInt() ??
            (doc.id.startsWith('foodlog_')
                ? int.tryParse(doc.id.replaceFirst('foodlog_', ''))
                : null);
        return FoodLogModel(
          id: rawId,
          firestoreId: doc.id,
          foodName: data['food_name']?.toString() ?? data['foodName']?.toString() ?? data['nama']?.toString() ?? '',
          mealType: data['meal_type']?.toString() ?? data['mealType']?.toString() ?? data['kategori']?.toString() ?? 'Lainnya',
          calories: (data['calories'] ?? data['kalori'] as num?)?.toInt() ?? _parseDouble(data['calories'] ?? data['kalori'], 0.0).toInt(),
          protein: _parseDouble(data['protein'], 0.0),
          carbs: _parseDouble(data['carbs'] ?? data['karbo'] ?? data['karbohidrat'], 0.0),
          fat: _parseDouble(data['fat'] ?? data['lemak'], 0.0),
          cholesterol: _parseDouble(data['cholesterol'] ?? data['kolesterol'], 0.0),
          imagePath: data['image_path']?.toString() ?? data['imagePath']?.toString() ?? '',
          time: data['time']?.toString() ?? data['waktu']?.toString() ?? data['jam']?.toString() ?? '',
          date: data['date']?.toString() ?? data['tanggal']?.toString() ?? '',
          note: data['note']?.toString() ?? data['catatan']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil semua food logs: $e');
      return [];
    }
  }

  /// Stream realtime untuk log makanan user
  Stream<List<FoodLogModel>> streamFoodLogs(String uid) {
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    return firestore
        .collection(colUsers)
        .doc(uid)
        .collection(colFoodLogs)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawId = (data['id'] as num?)?.toInt() ??
            (doc.id.startsWith('foodlog_')
                ? int.tryParse(doc.id.replaceFirst('foodlog_', ''))
                : null);
        return FoodLogModel(
          id: rawId,
          firestoreId: doc.id,
          foodName: data['food_name']?.toString() ?? data['foodName']?.toString() ?? data['nama']?.toString() ?? '',
          mealType: data['meal_type']?.toString() ?? data['mealType']?.toString() ?? data['kategori']?.toString() ?? 'Lainnya',
          calories: (data['calories'] ?? data['kalori'] as num?)?.toInt() ?? _parseDouble(data['calories'] ?? data['kalori'], 0.0).toInt(),
          protein: _parseDouble(data['protein'], 0.0),
          carbs: _parseDouble(data['carbs'] ?? data['karbo'] ?? data['karbohidrat'], 0.0),
          fat: _parseDouble(data['fat'] ?? data['lemak'], 0.0),
          cholesterol: _parseDouble(data['cholesterol'] ?? data['kolesterol'], 0.0),
          imagePath: data['image_path']?.toString() ?? data['imagePath']?.toString() ?? '',
          time: data['time']?.toString() ?? data['waktu']?.toString() ?? data['jam']?.toString() ?? '',
          date: data['date']?.toString() ?? data['tanggal']?.toString() ?? '',
          note: data['note']?.toString() ?? data['catatan']?.toString(),
        );
      }).toList();
    });
  }

  // ===========================================================================
  // 5. NOTIFICATIONS (SUBCOLLECTION: users/{uid}/notifications)
  // ===========================================================================

  /// Menambahkan atau memperbarui notifikasi ke Firestore
  Future<String?> addNotification(String uid, NotificationModel notif) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final docId = notif.id != null ? 'notif_${notif.id}' : null;
      final collection = firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colNotifications);
      final docRef = docId != null ? collection.doc(docId) : collection.doc();

      await docRef.set({
        ...notif.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menambahkan notifikasi ke Firestore: $e');
      return null;
    }
  }

  /// Menandai satu notifikasi sudah dibaca di Firestore
  Future<void> markNotificationRead(String uid, String notifDocId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colNotifications)
          .doc(notifDocId)
          .set({
        'is_read': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menandai notif dibaca ($notifDocId): $e');
    }
  }

  /// Menandai semua notifikasi sudah dibaca di Firestore
  Future<void> markAllNotificationsRead(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colNotifications)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menandai semua notif dibaca: $e');
    }
  }

  /// Menghapus satu notifikasi dari Firestore
  Future<void> deleteNotification(String uid, String notifDocId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colNotifications)
          .doc(notifDocId)
          .delete();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menghapus notif ($notifDocId): $e');
    }
  }

  /// Menghapus sejumlah notifikasi secara batch dari Firestore
  Future<void> deleteNotificationsBatch(String uid, List<String> notifDocIds) async {
    final firestore = _firestore;
    if (firestore == null || notifDocIds.isEmpty) return;

    try {
      final batch = firestore.batch();
      for (final docId in notifDocIds) {
        final ref = firestore
            .collection(colUsers)
            .doc(uid)
            .collection(colNotifications)
            .doc(docId);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal batch delete notifikasi: $e');
    }
  }

  /// Mengambil semua daftar notifikasi dari Firestore
  Future<List<NotificationModel>> getNotifications(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colUsers)
          .doc(uid)
          .collection(colNotifications)
          .get();

      return snapshot.docs.map((doc) {
        final d = doc.data();
        final rawId = (d['id'] as num?)?.toInt() ??
            int.tryParse(doc.id) ??
            (doc.id.startsWith('notif_')
                ? int.tryParse(doc.id.replaceFirst('notif_', ''))
                : null);
        return NotificationModel(
          id: rawId,
          firestoreId: doc.id,
          title: (d['title'] ?? d['judul'] ?? d['name'] ?? '').toString(),
          message: (d['message'] ?? d['pesan'] ?? d['body'] ?? d['deskripsi'] ?? d['isi'] ?? '').toString(),
          type: (d['type'] ?? d['tipe'] ?? d['kategori'] ?? 'system').toString(),
          iconType: (d['icon_type'] ?? d['iconType'] ?? d['icon'] ?? 'info').toString(),
          isRead: d['is_read'] == true || d['isRead'] == true || d['dibaca'] == true || d['read'] == true,
          relatedPantryId: ((d['related_pantry_id'] ?? d['relatedPantryId']) as num?)?.toInt(),
          createdAt: _parseDateTime(d['created_at'] ?? d['createdAt'] ?? d['tanggal'], DateTime.now()),
        );
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil notifikasi dari cloud: $e');
      return [];
    }
  }

  /// Stream realtime untuk notifikasi user
  Stream<List<NotificationModel>> streamNotifications(String uid) {
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    return firestore
        .collection(colUsers)
        .doc(uid)
        .collection(colNotifications)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final rawId = (d['id'] as num?)?.toInt() ??
            int.tryParse(doc.id) ??
            (doc.id.startsWith('notif_')
                ? int.tryParse(doc.id.replaceFirst('notif_', ''))
                : null);
        return NotificationModel(
          id: rawId,
          firestoreId: doc.id,
          title: (d['title'] ?? d['judul'] ?? d['name'] ?? '').toString(),
          message: (d['message'] ?? d['pesan'] ?? d['body'] ?? d['deskripsi'] ?? d['isi'] ?? '').toString(),
          type: (d['type'] ?? d['tipe'] ?? d['kategori'] ?? 'system').toString(),
          iconType: (d['icon_type'] ?? d['iconType'] ?? d['icon'] ?? 'info').toString(),
          isRead: d['is_read'] == true || d['isRead'] == true || d['dibaca'] == true || d['read'] == true,
          relatedPantryId: ((d['related_pantry_id'] ?? d['relatedPantryId']) as num?)?.toInt(),
          createdAt: _parseDateTime(d['created_at'] ?? d['createdAt'] ?? d['tanggal'], DateTime.now()),
        );
      }).toList();
    });
  }

  // ===========================================================================
  // 6. ARTICLES (GLOBAL COLLECTION: articles)
  // ===========================================================================

  /// Mengambil artikel edukasi gizi dan food waste dari Firestore
  Future<List<ArticleModel>> getArticles() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection(colArticles)
          .orderBy('id')
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final d = doc.data();
        return ArticleModel(
          id: (d['id'] as num?)?.toInt() ?? doc.id.hashCode.abs(),
          title: d['title'] as String? ?? '',
          category: d['category'] as String? ?? 'GIZI',
          readTime: d['read_time'] as String? ?? '3 menit',
          date: d['date'] as String? ?? '',
          summary: d['summary'] as String? ?? '',
          imageUrl: d['image_url'] as String? ?? '',
          content: d['content'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil artikel: $e');
      return [];
    }
  }

  /// Batch upload artikel edukasi lokal ke Firestore (seeding cloud)
  Future<void> seedArticles(List<ArticleModel> articles) async {
    final firestore = _firestore;
    if (firestore == null || articles.isEmpty) return;

    try {
      final batch = firestore.batch();
      final collection = firestore.collection(colArticles);

      for (final a in articles) {
        final docRef = collection.doc('article_${a.id}');
        batch.set(docRef, {
          'id': a.id,
          'title': a.title,
          'category': a.category,
          'read_time': a.readTime,
          'date': a.date,
          'summary': a.summary,
          'image_url': a.imageUrl,
          'content': a.content,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[FirestoreService] Berhasil seeding ${articles.length} artikel ke Firestore');
    } catch (e) {
      debugPrint('[FirestoreService] Gagal seeding artikel ke Firestore: $e');
    }
  }

  // ===========================================================================
  // 7. USER PREFERENCES (Jam Makan & Alert Switches)
  // ===========================================================================

  /// Menyimpan preferensi pengguna (jam makan, toggle alert) ke Firestore
  Future<void> saveUserPreferences(String uid, Map<String, dynamic> preferences) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection(colUsers).doc(uid).set({
        'preferences': preferences,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] Gagal menyimpan preferensi user: $e');
    }
  }

  /// Mengambil preferensi pengguna dari Firestore
  Future<Map<String, dynamic>?> getUserPreferences(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection(colUsers).doc(uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('preferences')) {
        return Map<String, dynamic>.from(data['preferences'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[FirestoreService] Gagal mengambil preferensi user: $e');
      return null;
    }
  }
}

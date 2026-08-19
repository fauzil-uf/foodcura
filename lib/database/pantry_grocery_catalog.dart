import '../models/pantry_ingredient_model.dart';

/// Katalog bahan baku mentah, produk olahan, sembako, kaleng & bumbu dapur (Pantry).
/// Berisi gambar visual online HD, perkiraan masa simpan standar, dan lokasi simpan.
class PantryGroceryCatalog {
  static const List<PantryIngredientModel> ingredients = [
    // ─── 1. SUSU, TELUR & OLAHAN DAIRY ──────────────────────────────────────
    PantryIngredientModel(
      name: 'Susu UHT Plain',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 7,
      defaultUnit: 'ml',
      imageUrl:
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Susu UHT Cokelat',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 7,
      defaultUnit: 'ml',
      imageUrl:
          'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Telur Ayam Ras',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 21,
      defaultUnit: 'butir',
      imageUrl:
          'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Telur Bebek',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 28,
      defaultUnit: 'butir',
      imageUrl:
          'https://images.unsplash.com/photo-1569288052389-dac9b01c9c05?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Keju Cheddar Block',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 30,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Keju Mozzarella',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 14,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1559561853-08451507cbe7?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Yogurt Plain / Greek',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 14,
      defaultUnit: 'ml',
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Mentega / Butter',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 60,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Margarin Serbaguna',
      category: 'Susu & Olahan',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 120,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Susu Kental Manis',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 30,
      defaultUnit: 'kaleng',
      imageUrl:
          'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Santan Kelapa Cair',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 4,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Tahu Putih / Sutra',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 4,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1588165171080-c89acfa5a259?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Tempe Kedelai Segar',
      category: 'Susu & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 4,
      defaultUnit: 'papan',
      imageUrl:
          'https://images.unsplash.com/photo-1584278860047-22db9ff82bed?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 2. MAKANAN KALENG, FROZEN & SIAP MASAK ─────────────────────────────
    PantryIngredientModel(
      name: 'Sarden Saus Tomat Kaleng',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'kaleng',
      imageUrl:
          'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Tuna Kaleng in Oil',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'kaleng',
      imageUrl:
          'https://images.unsplash.com/photo-1535400255456-984241443b29?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Kornet Daging Sapi',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'kaleng',
      imageUrl:
          'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Nugget Ayam Frozen',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 90,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1562967914-608f82629710?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Sosis Sapi / Ayam',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 21,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Bakso Sapi Segar',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 60,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Jagung Manis Pipil Kaleng',
      category: 'Kaleng & Olahan',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'kaleng',
      imageUrl:
          'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 3. SAYURAN & JAMUR ──────────────────────────────────────────────────
    PantryIngredientModel(
      name: 'Bayam Segar',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 3,
      defaultUnit: 'ikat',
      imageUrl:
          'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Kangkung Segar',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 3,
      defaultUnit: 'ikat',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Brokoli Hijau',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 5,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Wortel Segar',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 10,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Tomat Merah',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 7,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Sawi Hijau / Caisim',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 4,
      defaultUnit: 'ikat',
      imageUrl:
          'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Kubis / Kol Putih',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 14,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Buncis Muda',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 6,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Timun Segar',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 7,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Jamur Tiram',
      category: 'Sayuran',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 4,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1504544750208-dc0358e63f7f?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Kentang Segar',
      category: 'Sayuran',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 30,
      defaultUnit: 'kg',
      imageUrl:
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 4. BUAH-BUAHAN ──────────────────────────────────────────────────────
    PantryIngredientModel(
      name: 'Apel Fuji',
      category: 'Buah',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 21,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Pisang Cavendish',
      category: 'Buah',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 5,
      defaultUnit: 'sisir',
      imageUrl:
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Jeruk Manis',
      category: 'Buah',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 14,
      defaultUnit: 'kg',
      imageUrl:
          'https://images.unsplash.com/photo-1582979512210-99b6a53386f9?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Alpukat Mentega',
      category: 'Buah',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 4,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Pepaya Matang',
      category: 'Buah',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 5,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1517282009859-f000ec3b26fe?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Semangka Merah',
      category: 'Buah',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 6,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Lemon Segar',
      category: 'Buah',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 21,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 5. DAGING, UNGGAS & SEAFOOD ─────────────────────────────────────────
    PantryIngredientModel(
      name: 'Dada Ayam Fillet',
      category: 'Daging & Ikan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 60,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Daging Sapi Segar',
      category: 'Daging & Ikan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 90,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Ikan Salmon Fillet',
      category: 'Daging & Ikan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 30,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Udang Segar',
      category: 'Daging & Ikan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 30,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Fillet Ikan Gurame',
      category: 'Daging & Ikan',
      defaultStorage: 'Freezer',
      defaultShelfLifeDays: 30,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 6. BAHAN POKOK, PASTA & SEREAL ──────────────────────────────────────
    PantryIngredientModel(
      name: 'Beras Putih Pandan Wangi',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'kg',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Pasta Spaghetti',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3d5d6281691?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Pasta Macaroni',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1551462147-37885acc36f1?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Mie Telur Kering',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'pack',
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Rolled Oat / Oatmeal',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Roti Tawar Gandum',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 5,
      defaultUnit: 'bungkus',
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Tepung Terigu Segitiga',
      category: 'Bahan Pokok',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 90,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1574484284002-952d92456975?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 7. BUMBU, SAUS & MINYAK ─────────────────────────────────────────────
    PantryIngredientModel(
      name: 'Bawang Merah',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 30,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Bawang Putih',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 45,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1588615419957-c33a9ceeeeb1?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Bawang Bombay',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 30,
      defaultUnit: 'pcs',
      imageUrl:
          'https://images.unsplash.com/photo-1508747703725-719777637510?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Cabai Rawit Merah',
      category: 'Bumbu & Saus',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 10,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Jahe Segar',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 21,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Minyak Goreng Sawit',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'L',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Minyak Zaitun / Olive Oil',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'ml',
      imageUrl:
          'https://images.unsplash.com/photo-1541256942802-7b299b483057?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Kecap Manis Botol',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'botol',
      imageUrl:
          'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Saus Tiram Botol',
      category: 'Bumbu & Saus',
      defaultStorage: 'Kulkas',
      defaultShelfLifeDays: 90,
      defaultUnit: 'botol',
      imageUrl:
          'https://images.unsplash.com/photo-1514733670139-4d87a1941d55?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Saus Sambal Botol',
      category: 'Bumbu & Saus',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'botol',
      imageUrl:
          'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500&auto=format&fit=crop&q=80',
    ),

    // ─── 8. SELAI, MADU & MINUMAN PANTRY ─────────────────────────────────────
    PantryIngredientModel(
      name: 'Madu Murni Asli',
      category: 'Selai & Minuman',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 730,
      defaultUnit: 'botol',
      imageUrl:
          'https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Selai Cokelat Hazelnut',
      category: 'Selai & Minuman',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'jar',
      imageUrl:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Selai Kacang / Peanut Butter',
      category: 'Selai & Minuman',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'jar',
      imageUrl:
          'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Biji / Bubuk Kopi Robusta',
      category: 'Selai & Minuman',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 180,
      defaultUnit: 'g',
      imageUrl:
          'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=500&auto=format&fit=crop&q=80',
    ),
    PantryIngredientModel(
      name: 'Teh Celup Melati / Hijau',
      category: 'Selai & Minuman',
      defaultStorage: 'Suhu Ruang',
      defaultShelfLifeDays: 365,
      defaultUnit: 'box',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=80',
    ),
  ];

  /// Cari bahan dapur mentah berdasarkan kata kunci
  static List<PantryIngredientModel> search(String query) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.trim().toLowerCase();
    return ingredients
        .where(
          (item) =>
              item.name.toLowerCase().contains(cleanQuery) ||
              item.category.toLowerCase().contains(cleanQuery),
        )
        .toList();
  }

  /// Dapatkan gambar otomatis berdasarkan nama bahan (pencocokan parsial)
  static String? getImageFor(String itemName) {
    if (itemName.trim().isEmpty) return null;
    final cleanName = itemName.trim().toLowerCase();
    for (final ing in ingredients) {
      final ingName = ing.name.toLowerCase();
      if (ingName.contains(cleanName) ||
          cleanName.contains(ingName.split(' ').first)) {
        return ing.imageUrl;
      }
    }
    return null;
  }
}

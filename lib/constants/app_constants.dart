/// String/angka konstan terpusat — nama app, nama & versi database, dsb.
class AppConstants {
  AppConstants._();

  static const appName = 'FoodCura';

  // Database (SQFLite)
  static const dbName = 'foodcura.db';
  static const tableUsers = 'users';

  // SharedPreferences keys
  static const keyLoggedInUserId = 'logged_in_user_id';
  static const keyStreakCount = 'user_streak_count';
  static const keyStreakLastDate = 'user_streak_last_date';

  // Notification preference keys
  static const keyNotifExpiryAlert = 'notif_expiry_alert';
  static const keyNotifNutritionExcess = 'notif_nutrition_excess';
  static const keyNotifDailyMealLog = 'notif_daily_meal_log';
  static const keyNotifEcoTips = 'notif_eco_tips';

  // Meal reminder preference keys
  static const keyNotifBreakfastEnabled = 'notif_breakfast_enabled';
  static const keyNotifBreakfastTime = 'notif_breakfast_time';
  static const keyNotifLunchEnabled = 'notif_lunch_enabled';
  static const keyNotifLunchTime = 'notif_lunch_time';
  static const keyNotifDinnerEnabled = 'notif_dinner_enabled';
  static const keyNotifDinnerTime = 'notif_dinner_time';
}

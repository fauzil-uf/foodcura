/// Konstanta konfigurasi global aplikasi, database SQLite, dan kunci SharedPreferences.
class AppConstants {
  AppConstants._();

  static const appName = 'FoodCura';
  static const appVersion = '2.3.1';
  static const appBuildNumber = '13';
  static const appVersionDisplay = 'v2.3.1';

  // Database (SQFLite)
  static const dbName = 'foodcura.db';
  static const dbVersion = 1;
  static const tableUsers = 'users';

  // SharedPreferences keys
  static const keyLoggedInUserId = 'logged_in_user_id';

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

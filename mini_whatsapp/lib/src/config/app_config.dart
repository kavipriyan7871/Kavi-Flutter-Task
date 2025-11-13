// lib/config/app_config.dart

class AppConfig {
  // --------------------- ZEGO CLOUD ---------------------
  static const int zegoAppID = 294033442;

  // ❗ PASTE YOUR REAL ZEGO APPSIGN HERE
  static const String zegoAppSign =
      "910d7105cab0923adbf60f12c760e10f177935b3834e56d11ef007d988f1f106"; // Example: "fa6bc91b6044cd2...."

  // --------------------- CLOUDINARY ---------------------
  static const String cloudName = "dhe0pkz7a";
  static const String apiKey = "571361735266774";
  static const String apiSecret = "Lji13W2tXXzayh0gpBaLT0w22WE";
  static const String uploadPreset = "flutter_unsigned";

  // --------------------- LOCAL SERVER -------------------
  static const String tokenServerBaseUrl = "http://10.0.2.2:3000";
}

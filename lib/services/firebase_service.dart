import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }
  
  static bool isInitialized = false;
  
  static Future<void> checkConnection() async {
    try {
      await Firebase.initializeApp();
      isInitialized = true;
      print('✅ Firebase connected successfully!');
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      isInitialized = false;
    }
  }
} 
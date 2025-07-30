import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pizza_app_vs_010/firebase_options.dart';
import 'package:pizza_app_vs_010/pages/onboard.dart';
import 'package:pizza_app_vs_010/pages/login.dart';
import 'package:pizza_app_vs_010/pages/signup.dart';
import 'package:pizza_app_vs_010/pages/home.dart';
import 'package:pizza_app_vs_010/pages/details.dart';
import 'package:pizza_app_vs_010/pages/order.dart';
import 'package:pizza_app_vs_010/pages/checkout.dart';
import 'package:pizza_app_vs_010/pages/order_status.dart';
import 'package:pizza_app_vs_010/pages/profile.dart';
import 'package:pizza_app_vs_010/pages/wallet.dart';
import 'package:pizza_app_vs_010/pages/forgotpassword.dart';
import 'package:pizza_app_vs_010/pages/bottomnav.dart';
import 'package:pizza_app_vs_010/admin/admin_login.dart';
import 'package:pizza_app_vs_010/admin/home_admin.dart';
import 'package:pizza_app_vs_010/admin/category_management.dart';
import 'package:pizza_app_vs_010/admin/food_management.dart';
import 'package:pizza_app_vs_010/admin/order_management.dart';
import 'package:pizza_app_vs_010/admin/user_management.dart';
import 'package:pizza_app_vs_010/admin/promo_management.dart';
import 'package:pizza_app_vs_010/admin/review_management.dart';
import 'package:pizza_app_vs_010/pages/settings.dart';
import 'package:pizza_app_vs_010/pages/theme_demo.dart';
import 'package:pizza_app_vs_010/services/cart_provider.dart';
import 'package:pizza_app_vs_010/services/theme_service.dart';
import 'package:pizza_app_vs_010/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'FoodGo',
            debugShowCheckedModeBanner: false,
            themeMode: themeService.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: '/onboard',
            routes: {
              '/onboard': (context) => const Onboard(),
              '/login': (context) => const LogIn(),
              '/signup': (context) => const SignUp(),
              '/home': (context) => const Home(),
              '/details': (context) =>
                  Details(id: '', name: '', price: '', image: '', detail: ''),
              '/order': (context) => Order(),
              '/checkout': (context) => const CheckoutPage(),
              '/order_status': (context) => OrderStatusPage(),
              '/profile': (context) => Profile(),
              '/wallet': (context) => const Wallet(),
              '/forgotpassword': (context) => const ForgotPassword(),
              '/bottomnav': (context) => const BottomNav(),
              '/admin_login': (context) => const AdminLogin(),
              '/home_admin': (context) => const HomeAdmin(),
              '/category_management': (context) => const CategoryManagement(),
              '/food_management': (context) => const FoodManagement(),
              '/order_management': (context) => OrderManagement(),
              '/user_management': (context) => const UserManagement(),
              '/promo_management': (context) => const PromoManagement(),
              '/review_management': (context) => const ReviewManagement(),
              '/settings': (context) => const SettingsPage(),
              '/theme_demo': (context) => const ThemeDemo(),
            },
          );
        },
      ),
    );
  }
}

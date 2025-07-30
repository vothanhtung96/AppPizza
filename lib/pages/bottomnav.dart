import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/pages/home.dart';
import 'package:pizza_app_vs_010/pages/order.dart';
import 'package:pizza_app_vs_010/pages/profile.dart';
import 'package:pizza_app_vs_010/pages/wallet.dart';
import 'package:pizza_app_vs_010/pages/order_status.dart';
import 'package:pizza_app_vs_010/pages/settings.dart';
import 'package:pizza_app_vs_010/widget/cart_badge.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Widget currentPage;
  late Home homepage;
  late Profile profile;
  late Order order;
  late Wallet wallet;
  late OrderStatusPage orderStatus;
  late SettingsPage settings;

  @override
  void initState() {
    homepage = Home();
    order = Order();
    profile = Profile();
    wallet = Wallet();
    orderStatus = OrderStatusPage();
    settings = SettingsPage();
    pages = [homepage, order, orderStatus, wallet, profile, settings];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(Icons.home_outlined, color: Colors.white),
          CartBadge(
            child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
          ),
          Icon(FontAwesomeIcons.receipt, color: Colors.white),
          Icon(Icons.wallet_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
          Icon(Icons.settings, color: Colors.white),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}

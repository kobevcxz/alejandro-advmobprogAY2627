import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  static HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<HomeScreenState>();
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final Color _accentBlue = Colors.lightBlue.shade600;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cartProvider = context.read<CartProvider>();

      final cartUserId = widget.user.isDummyJson && widget.user.id > 0
          ? widget.user.id
          : 2;

      cartProvider.setUserId(cartUserId);
      cartProvider.loadCart();
    });
  }

  void switchToTab(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const CartScreen();
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const SettingsScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _selectedIndex != 1;
    final bool showCartButton = _selectedIndex != 1;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          title: _selectedIndex == 0
              ? Image.asset('assets/images/nudexchange_logo.png', scale: 11.sp)
              : CustomText(
                  text: _selectedIndex == 1
                      ? 'Chats'
                      : _selectedIndex == 2
                      ? 'Profile'
                      : 'Home',
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                ),
          actions: [
            if (showCartButton)
              IconButton(
                tooltip: 'Cart',
                icon: Icon(Icons.shopping_cart_outlined, size: 24.sp),
                color: theme.colorScheme.onSurface,
                onPressed: _openCart,
              ),
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                tooltip: 'Settings',
                icon: Icon(Icons.settings_outlined, size: 24.sp),
                color: theme.colorScheme.onSurface,
                onPressed: _openSettings,
              ),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: <Widget>[
            const ProductScreen(),
            const ChatScreen(),
            ProfileScreen(user: widget.user),
          ],
        ),
        floatingActionButton: showFab
            ? FloatingActionButton(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                onPressed: () {
                  switchToTab(1);
                },
                child: const Icon(Icons.chat_bubble_outline),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            selectedItemColor: _accentBlue,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onTappedBar,
            currentIndex: _selectedIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shop_2_outlined),
                activeIcon: Icon(Icons.shop_2),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    switchToTab(value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'cart_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, this.username = ''});

  static HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeScreenState>();

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Custom light blue palette accents matching your theme
  final Color _accentBlue = Colors.lightBlue.shade600;
  final Color _lightBlueBg = Colors.lightBlue.shade50;

  // Public method to switch tabs dynamically (e.g., jump to Cart tab index 1)
  void switchToTab(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _selectedIndex != 1;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0, // Clean flat AppBar look
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
                      ? 'Cart'
                      : _selectedIndex == 2
                      ? 'Profile'
                      : 'Home',
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(Icons.settings_outlined, size: 24.sp),
                color: theme.colorScheme.onSurface,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            Center(child: Text('Profile')),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Chat opened'),
                      backgroundColor: _accentBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shop_2_outlined),
                activeIcon: Icon(Icons.shop_2),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
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

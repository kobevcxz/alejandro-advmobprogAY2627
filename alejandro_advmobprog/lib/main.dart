// Packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// Models
import 'models/user.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');

    runApp(const RolesAdvMobProg());
  });
}

class RolesAdvMobProg extends StatelessWidget {
  const RolesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Enhancement 3:
        // The user ID will be assigned after successful authentication.
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NUBD Exchange',
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,

            // Enhancement 1:
            // Always open the splash screen first to check authentication.
            initialRoute: '/splash',

            routes: {
              '/splash': (context) => const SplashScreen(),
              '/signin': (context) => const SignInScreen(),
              '/settings': (context) => const SettingsScreen(),

              // Enhancement 2 and 3:
              // Receive the authenticated user from sign-in or splash.
              '/home': (context) {
                final user = ModalRoute.of(context)!.settings.arguments as User;

                return HomeScreen(user: user);
              },
            },
          );
        },
      ),
    );
  }
}

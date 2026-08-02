import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style for light theme
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ScanShieldApp());
}

class ScanShieldApp extends StatelessWidget {
  const ScanShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
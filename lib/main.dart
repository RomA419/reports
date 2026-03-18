import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Твои экраны (убедись, что названия файлов в папке screens именно такие)
import 'package:car_care/screens/home_screen.dart';
import 'package:car_care/screens/detail_screen.dart';
import 'package:car_care/screens/my_car_screen.dart';
import 'package:car_care/screens/posts_screen.dart';
import 'package:car_care/screens/auth_screen.dart';
import 'package:car_care/screens/chat_screen.dart';
import 'package:car_care/screens/qr_screen.dart';
import 'package:car_care/screens/qr_scan_screen.dart';
import 'package:car_care/models/car_model.dart';

void main() async {
  // Гарантируем работу системных плагинов (SharedPreferences) до старта дизайна
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarCareApp());
}

class CarCareApp extends StatelessWidget {
  const CarCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AUTO CORE',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1D), // Твой основной темный фон
      ),
      // Стартовая точка всегда Splash
      home: const SplashScreen(), 
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/detail': (context) => const DetailScreen(),
        '/my_car': (context) => const MyCarScreen(),
        '/posts': (context) => const PostsScreen(),
        '/chat': (context) {
          final car = ModalRoute.of(context)!.settings.arguments as Car?;
          return ChatScreen(car: car);
        },
        '/qr': (context) {
          final car = ModalRoute.of(context)!.settings.arguments as Car?;
          return QrScreen(car: car);
        },
        '/qr_scan': (context) => const QrScanScreen(),
      },
    );
  }
}

// ЭКРАН ЗАГРУЗКИ (Splash)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Небольшая пауза для красоты (логотип)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Инициализируем память
    final prefs = await SharedPreferences.getInstance();
    
    // 3. Достаем флаг входа. Если null — значит пользователь еще не входил.
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // Залогинен -> в главное меню
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Не залогинен -> на авторизацию
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1D), Color(0xFF000000)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированный или просто красивый логотип
            const Icon(
              Icons.directions_car_filled, 
              size: 100, 
              color: Color(0xFF00ADB5)
            ),
            const SizedBox(height: 20),
            const Text(
              "AUTO CORE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 50),
            // Кастомный индикатор загрузки
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ADB5)),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
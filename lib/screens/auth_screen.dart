import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_care/configs/car_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // --- КОНТРОЛЛЕРЫ ДЛЯ ВСЕХ ПОЛЕЙ ---
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true; // Переключатель Вход/Регистрация
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Автозаполнение при старте
  }

  // --- ЗАГРУЗКА СОХРАНЕННЫХ ДАННЫХ (REMEMBER ME) ---
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _loginController.text = prefs.getString('saved_login') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  // Шифрование пароля
  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  // --- ПОЛНАЯ ФУНКЦИЯ РЕГИСТРАЦИИ ---
  Future<void> _register() async {
    final login = _loginController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final age = _ageController.text.trim();
    final name = _nameController.text.trim();

    // Полная валидация
    if (login.isEmpty || password.isEmpty || email.isEmpty || age.isEmpty || name.isEmpty) {
      _showMessage("Заполните абсолютно все поля профиля", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Проверка на уникальность логина
      if (prefs.containsKey('user_$login')) {
        _showMessage("Этот логин уже занят другим водителем", isError: true);
        return;
      }

      // Создаем объект пользователя
      Map<String, dynamic> userData = {
        'login': login,
        'passwordHash': _hashPassword(password),
        'email': email,
        'age': age,
        'name': name,
        'regDate': DateTime.now().toIso8601String(),
      };

      // Сохраняем в память (имитация базы данных пользователей)
      await prefs.setString('user_$login', jsonEncode(userData));
      
      _showMessage("Аккаунт для $name успешно создан!", isError: false);
      
      // После регистрации перекидываем на вход
      setState(() {
        _isLoginMode = true;
      });
    } catch (e) {
      _showMessage("Произошла критическая ошибка регистрации", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ПОЛНАЯ ФУНКЦИЯ ВХОДА ---
  Future<void> _login() async {
    final login = _loginController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      _showMessage("Введите логин и пароль для авторизации", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userRaw = prefs.getString('user_$login');

      if (userRaw == null) {
        _showMessage("Пользователь с таким логином не существует", isError: true);
        return;
      }

      Map<String, dynamic> user = jsonDecode(userRaw);

      // Сверяем хэши паролей
      if (user['passwordHash'] == _hashPassword(password)) {
        
        // --- СОХРАНЯЕМ СЕССИЮ ВХОДА ---
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('current_user', login);
        await prefs.setString('current_user_name', user['name']);

        // Логика "Запомнить меня"
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_login', login);
          await prefs.setString('saved_password', password);
        } else {
          await prefs.remove('saved_login');
          await prefs.remove('saved_password');
        }

        if (mounted) {
          // ПЕРЕХОД НА ГЛАВНЫЙ САЙТ/ЭКРАН
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showMessage("Введен неверный пароль", isError: true);
      }
    } catch (e) {
      _showMessage("Ошибка подключения к данным", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : CarConfig.accentNeon,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarConfig.primaryDark,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CarConfig.primaryDark,
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            children: [
              // Логотип
              const Icon(Icons.speed_rounded, size: 90, color: CarConfig.accentBlue),
              const SizedBox(height: 10),
              const Text(
                "AUTO CORE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),
              
              // Основная форма
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      _isLoginMode ? "АВТОРИЗАЦИЯ" : "РЕГИСТРАЦИЯ",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Поле Логина (всегда)
                    _buildField(_loginController, "Ваш логин", Icons.person_outline),
                    const SizedBox(height: 15),

                    // Поля только для регистрации
                    if (!_isLoginMode) ...[
                      _buildField(_nameController, "Имя водителя", Icons.badge_outlined),
                      const SizedBox(height: 15),
                      _buildField(_emailController, "Электронная почта", Icons.email_outlined, type: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _buildField(_ageController, "Возраст", Icons.calendar_today_outlined, type: TextInputType.number),
                      const SizedBox(height: 15),
                    ],
                    
                    // Поле Пароля (всегда)
                    _buildField(_passwordController, "Пароль", Icons.lock_open_rounded, isPass: true),
                    
                    const SizedBox(height: 10),

                    // Чекбокс "Запомнить" только в режиме входа
                    if (_isLoginMode)
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: CarConfig.accentBlue,
                              side: const BorderSide(color: Colors.white24),
                              onChanged: (v) => setState(() => _rememberMe = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text("Запомнить пароль", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    
                    const SizedBox(height: 30),
                    _buildBtn(),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Кнопка переключения режима
              TextButton(
                onPressed: () => setState(() {
                  _isLoginMode = !_isLoginMode;
                  _isLoading = false;
                }),
                child: Text(
                  _isLoginMode ? "СОЗДАТЬ НОВЫЙ АККАУНТ" : "УЖЕ ЕСТЬ ПРОФИЛЬ? ВОЙТИ",
                  style: const TextStyle(color: CarConfig.accentBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Универсальный виджет поля ввода
  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass ? _obscurePassword : false,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: CarConfig.accentBlue, size: 22),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white24),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: CarConfig.accentBlue, width: 2),
        ),
      ),
    );
  }

  // Кнопка действия
  Widget _buildBtn() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: CarConfig.accentBlue,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: CarConfig.accentBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : (_isLoginMode ? _login : _register),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(
              _isLoginMode ? "ВОЙТИ В СИСТЕМУ" : "ЗАРЕГИСТРИРОВАТЬСЯ", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
            ),
      ),
    );
  }
}
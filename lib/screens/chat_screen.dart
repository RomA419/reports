import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_care/models/car_model.dart';

class ChatScreen extends StatefulWidget {
  final Car? car;
  const ChatScreen({super.key, this.car});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final Random _random = Random();

  String _openAiKey = '';
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _loadOpenAiKey();
    _addSystemMessage();
  }

  Future<void> _loadOpenAiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openAiKey = prefs.getString('openai_api_key') ?? '';
    });
  }

  void _addSystemMessage() {
    final carName = widget.car?.name ?? 'вашего авто';
    _messages.add(_ChatMessage(
      text: 'Привет! Я ИИ-механик вашего сервиса. Спрашивайте про $carName, ТО, расходы и советы.',
      isUser: false,
    ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isThinking = true;
    });

    _messageController.clear();

    if (_openAiKey.isNotEmpty) {
      _getAiReply(text.trim()).then((reply) {
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
          _isThinking = false;
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        final reply = _generateReply(text);
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
          _isThinking = false;
        });
      });
    }
  }

  Future<String> _getAiReply(String prompt) async {
    // Сейчас используется локальный генератор ответов.
    // Если потребуется подключить внешнее API (например OpenAI), сюда можно добавить его вызов.
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateReply(prompt);
  }

  String _generateReply(String question) {
    final query = question.toLowerCase();

    if (query.contains('масло')) {
      return 'Рекомендуется менять масло каждые 8 000 км. Проверьте, когда вы меняли его в последний раз.';
    }
    if (query.contains('шины') || query.contains('колес')) {
      return 'Проверьте давление и протектор. В Караганде рекомендую 2.2–2.4 бара для легковых авто.';
    }
    if (query.contains('цепь') || query.contains('грм')) {
      return 'Цепь ГРМ стоит проверять каждые 60 000 км. Если слышите постукивание — пора на диагностику.';
    }
    if (query.contains('датчик') || query.contains('ошибка')) {
      return 'Проверьте код ошибки в диагностике. Часто помогает сброс через OBD и повторная проверка.';
    }

    final fallbacks = [
      'Расскажите подробнее о проблеме, и я помогу подобрать решение.',
      'Попробуйте уточнить, когда в последний раз делали техобслуживание.',
      'Для точного совета мне нужна информация о пробеге и последних работах.',
      'Если хотите, я могу подсчитать примерную стоимость ТО.',
    ];

    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('ИИ Механик', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))),
                          SizedBox(width: 12),
                          Text('ИИ формирует ответ...', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blueAccent.withOpacity(0.9) : Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.black12.withOpacity(0.05)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Задайте вопрос механику...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white70),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

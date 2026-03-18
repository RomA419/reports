import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:car_care/models/car_model.dart';

class QrScreen extends StatefulWidget {
  final Car? car;
  const QrScreen({super.key, this.car});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final TextEditingController _scanController = TextEditingController();
  String _scanResult = '';

  String get _generatedCode {
    final car = widget.car;
    if (car == null) return 'CAR:unknown';
    return 'CAR:${car.name}|MILEAGE:${car.mileage}';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Код скопирован')));
  }

  void _handleScan() {
    final input = _scanController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _scanResult = input;
    });

    final parts = input.split('|');
    final namePart = parts.firstWhere((p) => p.startsWith('CAR:'), orElse: () => '');
    if (namePart.isNotEmpty) {
      final carName = namePart.replaceFirst('CAR:', '');
      try {
        final found = myGarage.firstWhere((c) => c.name == carName);
        Navigator.pushNamed(context, '/my_car', arguments: found);
        return;
      } catch (_) {
        // Не удалось найти
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось найти автомобиль по коду')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('QR Генератор', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сгенерированный код для вашего автомобиля', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            Center(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white12, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                padding: const EdgeInsets.all(18),
                child: QrImageView(
                  data: _generatedCode,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('Код: $_generatedCode', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, color: Colors.white54),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text('Сканировать код (вставьте сюда то, что просканировали)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scanController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Вставьте QR-код из сканера',
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  onPressed: _handleScan,
                  child: const Text('ОТКРЫТЬ', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_scanResult.isNotEmpty)
              Text('Результат: $_scanResult', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

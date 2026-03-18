import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:car_care/models/car_model.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? lastScan;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;
      _isProcessing = true;

      final code = scanData.code;
      if (code == null) {
        _isProcessing = false;
        return;
      }

      if (code == lastScan) {
        _isProcessing = false;
        return;
      }
      lastScan = code;

      final parts = code.split('|');
      final namePart = parts.firstWhere((p) => p.startsWith('CAR:'), orElse: () => '');
      if (namePart.isNotEmpty) {
        final carName = namePart.replaceFirst('CAR:', '');
        Navigator.pop(context, carName);
        return;
      }

      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('Сканирование QR', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.cyanAccent,
                borderRadius: 16,
                borderLength: 28,
                borderWidth: 6,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF121212),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Держите камеру на QR коде автомобиля.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  if (lastScan != null)
                    Text('Последнее: $lastScan', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        label: const Text('Фонарик', style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          await controller?.toggleFlash();
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Перезапуск', style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          await controller?.resumeCamera();
                          setState(() {
                            lastScan = null;
                            _isProcessing = false;
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

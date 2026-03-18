import 'package:flutter/material.dart';

class CarConfig {
  static const primaryDark = Color(0xFF1A1A1D);
  static const accentNeon = Color(0xFF4ECCA3);
  static const accentBlue = Color(0xFF00ADB5);
  static const cardDark = Color(0xFF25252B);

  static BoxDecoration premiumCard = BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white10),
    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
  );
}
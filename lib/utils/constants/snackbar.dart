import 'package:flutter/material.dart';

class AppSnackBar {
  static const _backgroundColor =Colors.black54;
  static const _behavior = SnackBarBehavior.floating;
  static const _margin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static SnackBar success(String message) {
    return SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: _backgroundColor,
      behavior: _behavior,
      margin: _margin,
      shape: _shape,
      duration: Duration(seconds: 2),
    );
  }

}
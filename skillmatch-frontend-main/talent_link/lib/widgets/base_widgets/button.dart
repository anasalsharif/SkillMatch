import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color buttonColor;
  const BaseButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonColor = const Color(
      0xFF0C9E91,
    ), // Default color if no color is passed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
        child: Text(text),
      ),
    );
  }
}

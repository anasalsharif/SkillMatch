import 'package:flutter/material.dart';

class MyTextFieled extends StatelessWidget {
  final String textHint, textLable;
  final TextEditingController controller;
  final bool obscureText;
  final void Function(String)? onChanged; // <-- added this line

  const MyTextFieled({
    super.key,
    required this.textHint,
    required this.textLable,
    required this.controller,
    required this.obscureText,
    this.onChanged, // <-- added this line
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        obscureText: obscureText,
        onChanged: onChanged, // <-- added this line
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          hintText: textHint,
          fillColor: Colors.white,
          label: Text(textLable),
          labelStyle: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

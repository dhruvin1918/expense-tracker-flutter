import 'package:flutter/material.dart';

class Switchbutton extends StatefulWidget {
  const Switchbutton({super.key});

  @override
  State<Switchbutton> createState() => _SwitchbuttonState();
}

class _SwitchbuttonState extends State<Switchbutton> {
  bool isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isSwitched,
      onChanged: (value) {
        setState(() {
          isSwitched = value;
        });
      },
      activeColor: Colors.green, // Color when ON
      inactiveThumbColor: Colors.grey, // Knob color when OFF
      inactiveTrackColor: Colors.grey.shade400, // Track color when OFF
    );
  }
}

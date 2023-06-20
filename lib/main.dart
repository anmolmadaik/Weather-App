import 'package:flutter/material.dart';
import 'home.dart';
import 'location.dart';

void main() {
  runApp(MaterialApp(
    themeMode: ThemeMode.system,
    theme: ThemeData(
      brightness: Brightness.light,
      dividerColor: Colors.transparent
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      cardTheme: CardTheme(
        color: Colors.grey[900],
        shadowColor: Colors.white38
      )
    ),
    routes: {
      "/" : (context) => Home(),
      "/location" : (context) => Location(),
    }
  ));
}



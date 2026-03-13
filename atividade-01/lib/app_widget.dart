import 'package:flutter/material.dart';
import 'package:primeiro/home_page.dart';

class AppWidget extends StatelessWidget { 

 final String title;

  const AppWidget({super.key, required this.title});
  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: HomeScreen(),
    );
  }
}


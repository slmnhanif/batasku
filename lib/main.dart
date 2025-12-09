import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import '/db/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DBHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/omori_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReincarnatedAsParentsApp());
}

class ReincarnatedAsParentsApp extends StatelessWidget {
  const ReincarnatedAsParentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Time I Got Reincarnated As My Parents',
      debugShowCheckedModeBanner: false,
      theme: OmoriTheme.build(),
      home: const HomeScreen(),
    );
  }
}

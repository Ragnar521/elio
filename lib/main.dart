import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/storage_service.dart';
import 'theme/elio_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const ElioApp());
}

class ElioApp extends StatelessWidget {
  const ElioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elio',
      theme: ElioTheme.light(),
      darkTheme: ElioTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}

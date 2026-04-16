import 'package:flutter/material.dart';

import 'pages/tool_shell_page.dart';

class MyToolsApp extends StatelessWidget {
  const MyToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6F8),
        useMaterial3: true,
      ),
      home: const ToolShellPage(),
    );
  }
}

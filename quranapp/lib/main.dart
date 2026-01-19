import 'package:flutter/material.dart';
import 'package:quranapp/app.dart';
import 'package:quranapp/core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Service Locator
  await di.init();

  runApp(const QuranApp());
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/dark_theme.dart';
import 'screens/location_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fuerza orientación vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado transparente con iconos claros
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const GeoTrackerApp());
}

class GeoTrackerApp extends StatelessWidget {
  const GeoTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEO TRACKER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const LocationScreen(),
    );
  }
}

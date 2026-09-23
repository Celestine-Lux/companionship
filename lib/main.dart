import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/activity_service.dart';
import 'services/permission_service.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityService(databaseService)),
        Provider(create: (_) => PermissionService()),
        Provider.value(value: databaseService),
      ],
      child: const CompanionshipApp(),
    ),
  );
}

class CompanionshipApp extends StatelessWidget {
  const CompanionshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Companionship',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

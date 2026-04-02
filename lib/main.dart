import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/providers/menu_provider.dart';
import 'core/providers/dashboard_provider.dart'; // Import provider mới
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load cấu hình từ file .env trước khi chạy app
  await dotenv.load(fileName: "assets/.env");
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()), // Đăng ký DashboardProvider
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Daklak Agent Admin',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
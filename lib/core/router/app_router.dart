import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/user_management/screens/user_list_screen.dart';
import '../../features/content_management/screens/disease_manager_screen.dart';
import '../../features/content_management/screens/banner_manager_screen.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../widgets/admin_layout.dart'; // Import layout


class AppRouter {
  static final router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final bool isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // SỬ DỤNG SHELL_ROUTE CHO CÁC TRANG QUẢN TRỊ
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child); // Bọc nội dung bằng Layout có Sidebar
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          // Thêm các route khác ở đây (chúng sẽ tự động nằm trong AdminLayout)
          // GoRoute(path: '/users', builder: (context, state) => const UserScreen()),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UserListScreen(),
          ),
          GoRoute(
            path: '/diseases',
            builder: (context, state) => const DiseaseManagerScreen(),
          ),
          GoRoute(
            path: '/banners',
            builder: (context, state) => const BannerManagerScreen(),
          ),
        ],
      ),
    ],
  );
}
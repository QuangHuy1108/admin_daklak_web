import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/logic/user_provider.dart';
import '../../features/user_management/screens/user_list_screen.dart';
import '../../features/content_management/screens/disease_manager_screen.dart';
import '../../features/content_management/screens/banner_manager_screen.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../widgets/admin_layout.dart'; // Import layout
import '../../features/expert_management/screens/admin_appointments_screen.dart';
import '../../features/logs/screens/ai_logs_screen.dart';
import '../../features/price_management/screens/agricultural_price.dart';
import '../../features/sales_management/screens/hub_dashboard_screen.dart';
import '../../features/order_management/screens/order_list_screen.dart';
import '../../features/product_warehouse/screens/product_list_screen.dart';
import '../../features/promotions/screens/voucher_management_screen.dart';
import '../../features/finance/screens/finance_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/settings/presentation/screens/settings_main_screen.dart';
import '../../features/logs/screens/audit_logs_screen.dart';
import '../../features/expert_management/screens/expert_verification_screen.dart';
import '../../features/system_logs/screens/system_log_screen.dart';
import '../../features/profile/screens/admin_profile_screen.dart';

class AppRouter {
  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: userProvider,
      redirect: (context, state) {
        final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
        final bool isGoingToLogin = state.matchedLocation == '/login';

        if (!isLoggedIn && !isGoingToLogin) return '/login';
        if (isLoggedIn && isGoingToLogin) return '/dashboard';

        // RBAC Check for Settings
        if (state.matchedLocation == '/settings') {
          // If still loading role from Firestore, don't redirect yet
          if (userProvider.isLoading) return null;

          if (!userProvider.isSuperAdmin) {
            debugPrint('AppRouter: Access denied to /settings. Role detected: ${userProvider.role}');
            return '/dashboard'; // Redirect to dashboard if not super_admin
          }
        }

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
            GoRoute(
              path: '/profile',
              builder: (context, state) => const AdminProfileScreen(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UserManagementScreen(),
            ),
            GoRoute(
              path: '/diseases',
              builder: (context, state) => const DiseaseManagerScreen(),
            ),
            GoRoute(
              path: '/banners',
              builder: (context, state) => const BannerManagerScreen(),
            ),
            GoRoute(
              path: '/appointments',
              builder: (context, state) => const AdminAppointmentsScreen(),
            ),
            GoRoute(
              path: '/ai-logs',
              builder: (context, state) => const AiLogsScreen(),
            ),
            GoRoute(
              path: '/prices',
              builder: (context, state) => const AgriculturalPriceDashboard(),
            ),
            GoRoute(
              path: '/sales',
              builder: (context, state) => const HubDashboardScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrderListScreen(),
            ),
            GoRoute(
              path: '/orders/detail/:id',
              builder: (context, state) => const OrderListScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductListScreen(),
            ),
            GoRoute(
              path: '/promotions',
              builder: (context, state) => const VoucherManagementScreen(),
            ),
            GoRoute(
              path: '/finance',
              builder: (context, state) => const FinanceScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsMainScreen(),
            ),
            GoRoute(
              path: '/audit-logs',
              builder: (context, state) => const AuditLogsScreen(),
            ),
            GoRoute(
              path: '/expert-verifications',
              builder: (context, state) => const ExpertVerificationScreen(),
            ),
            GoRoute(
              path: '/system-logs',
              builder: (context, state) => const SystemLogScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
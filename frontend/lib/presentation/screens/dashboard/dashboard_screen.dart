import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:frontend/src/providers/auth_provider.dart';
import 'package:frontend/src/providers/dashboard_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/dashboard/dashboard_content.dart';
import 'package:frontend/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:frontend/presentation/widgets/globals/sidebar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dashboardProvider = context.read<DashboardProvider>();
        final authProvider = context.read<AuthProvider>();

        // ✅ Redirect MANAGER away from dashboard to Projects (index 1)
        if (authProvider.currentUser?.role == 'MANAGER' &&
            (dashboardProvider.selectedMenuIndex == 0 || dashboardProvider.selectedMenuIndex == 27)) {
          dashboardProvider.selectMenu(1);
        }

        dashboardProvider.setInstance(); // Set global instance
        dashboardProvider.initialize();

        // ✅ Add listener to handle auto-logout/unauthenticated state
        authProvider.addListener(_handleAuthStateChange);
      }
    });
  }

  void _handleAuthStateChange() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.state == AuthState.unauthenticated) {
      // ✅ Stop all dashboard polling before redirect
      context.read<DashboardProvider>().stopPolling();
      
      // Auto redirect to login if we lose authentication
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  void dispose() {
    // Clean up listener
    context.read<AuthProvider>().removeListener(_handleAuthStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.creamWhite,
        body: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            return Row(
              children: [
                // Sidebar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: dashboardProvider.isSidebarExpanded ? 28.w : 8.w,
                  child: PremiumSidebar(
                    isExpanded: dashboardProvider.isSidebarExpanded,
                    selectedIndex: dashboardProvider.selectedMenuIndex,
                    onMenuSelected: (index) {
                      dashboardProvider.selectMenu(index);
                    },
                    onToggle: () {
                      dashboardProvider.toggleSidebar();
                    },
                  ),
                ),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      // DashboardHeader(
                      //   title: dashboardProvider.currentPageTitle,
                      //   onNotificationTap: () {
                      //     // Handle notifications
                      //   },
                      //   onProfileTap: () {
                      //     // Handle profile
                      //   },
                      // ),

                      // Content
                      Expanded(
                        child: DashboardContent(
                          selectedIndex: dashboardProvider.selectedMenuIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
  }
}

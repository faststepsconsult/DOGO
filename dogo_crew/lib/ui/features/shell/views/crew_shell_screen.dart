import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../driver/view_models/driver_view_model.dart';

class CrewShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CrewShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final driverVm = context.watch<DriverViewModel>();
    final isDriverBusy = driverVm.isBusy && navigationShell.currentIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: navigationShell,
      bottomNavigationBar: isDriverBusy
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Color(0xFF12151E),
                border: Border(
                  top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: const Color(0xFF12151E),
                  indicatorColor: const Color(0x2610B981),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 22,
                      color: selected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 64,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.navigation_outlined),
                      selectedIcon: Icon(Icons.navigation_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Earnings',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

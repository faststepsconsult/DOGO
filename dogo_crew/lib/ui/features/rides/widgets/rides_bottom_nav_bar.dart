import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RidesBottomNavBar extends StatelessWidget {
  final String activeRoute;

  const RidesBottomNavBar({
    super.key,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF10131B),
        border: Border(
          top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                route: '/rides',
                isActive: activeRoute == '/rides',
              ),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Trips',
                route: '/rides/my-trips',
                isActive: activeRoute == '/rides/my-trips',
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Account',
                route: '/account',
                isActive: activeRoute == '/account' ||
                    activeRoute == '/rides/account' ||
                    activeRoute == '/verify' ||
                    activeRoute == '/rides/help',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    final color = isActive ? Colors.white : const Color(0xFF8E95A5);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            context.go(route);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


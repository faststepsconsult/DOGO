import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/features/auth/view_models/auth_view_model.dart';
import '../../ui/features/auth/views/auth_screen.dart';
import '../../ui/features/board/views/board_screen.dart';
import '../../ui/features/driver/views/driver_clearance_screen.dart';
import '../../ui/features/driver/views/driver_earnings_screen.dart';
import '../../ui/features/driver/views/driver_home_screen.dart';
import '../../ui/features/driver/views/driver_profile_screen.dart';
import '../../ui/features/shell/views/crew_shell_screen.dart';
import '../../ui/features/team/views/team_screen.dart';
import '../../ui/features/trip_detail/views/trip_detail_screen.dart';
import '../../ui/features/verification/views/verification_screen.dart';
import '../../ui/features/rides/views/rides_home_screen.dart';
import '../../ui/features/rides/views/my_rides_screen.dart';
import '../../ui/features/rides/views/trip_track_screen.dart';
import '../../ui/features/rides/views/account_screen.dart';
import '../../ui/features/rides/views/help_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authVm) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/rides',
      refreshListenable: authVm,
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        // Rides Aspect Routes (Default Customer Experience)
        GoRoute(
          path: '/rides',
          builder: (context, state) => const RidesHomeScreen(),
        ),
        GoRoute(
          path: '/rides/my-trips',
          builder: (context, state) => const MyRidesScreen(),
        ),
        GoRoute(
          path: '/rides/track/:code',
          builder: (context, state) {
            final code = state.pathParameters['code'] ?? 'DG-4821HK';
            return TripTrackScreen(tripCode: code);
          },
        ),
        GoRoute(
          path: '/rides/help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
        GoRoute(
          path: '/rides/account',
          builder: (context, state) => const AccountScreen(),
        ),
        GoRoute(
          path: '/verify',
          builder: (context, state) => const VerificationScreen(),
        ),
        GoRoute(
          path: '/crew-verify',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const VerificationScreen(),
        ),
        GoRoute(
          path: '/driver-clearance',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DriverClearanceScreen(),
        ),
        GoRoute(
          path: '/board-dispatch',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const BoardScreen(),
        ),
        GoRoute(
          path: '/team',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TeamScreen(),
        ),

        // Crew Console / Driver Stateful Shell (3 tabs: Home, Earnings, Profile)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return CrewShellScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/board',
                  builder: (context, state) => const DriverHomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/crew-earnings',
                  builder: (context, state) => const DriverEarningsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/crew-profile',
                  builder: (context, state) => const DriverProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/trips/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final tripId = state.pathParameters['id']!;
            return TripDetailScreen(tripId: tripId);
          },
        ),
      ],
    );
  }
}

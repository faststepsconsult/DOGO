import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/crew_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/repositories/verification_repository.dart';
import 'data/services/supabase_service.dart';
import 'data/repositories/rides_repository.dart';
import 'ui/features/rides/view_models/rides_view_model.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/board/view_models/board_view_model.dart';
import 'ui/features/driver/view_models/driver_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend safely
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const DogoCrewApp());
}

class DogoCrewApp extends StatefulWidget {
  const DogoCrewApp({super.key});

  @override
  State<DogoCrewApp> createState() => _DogoCrewAppState();
}

class _DogoCrewAppState extends State<DogoCrewApp> {
  late final AuthRepository _authRepo;
  late final TripRepository _tripRepo;
  late final ChatRepository _chatRepo;
  late final VerificationRepository _verifRepo;
  late final CrewRepository _crewRepo;
  late final RidesRepository _ridesRepo;

  late final AuthViewModel _authViewModel;
  late final BoardViewModel _boardViewModel;
  late final RidesViewModel _ridesViewModel;
  late final DriverViewModel _driverViewModel;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository();
    _tripRepo = TripRepository();
    _chatRepo = ChatRepository();
    _verifRepo = VerificationRepository();
    _crewRepo = CrewRepository();
    _ridesRepo = RidesRepository();

    _authViewModel = AuthViewModel(authRepo: _authRepo);
    _boardViewModel = BoardViewModel(tripRepo: _tripRepo);
    _ridesViewModel = RidesViewModel(ridesRepo: _ridesRepo);
    _driverViewModel = DriverViewModel();
    _router = AppRouter.createRouter(_authViewModel);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _boardViewModel.dispose();
    _ridesViewModel.dispose();
    _driverViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepo),
        Provider<TripRepository>.value(value: _tripRepo),
        Provider<ChatRepository>.value(value: _chatRepo),
        Provider<VerificationRepository>.value(value: _verifRepo),
        Provider<CrewRepository>.value(value: _crewRepo),
        Provider<RidesRepository>.value(value: _ridesRepo),
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
        ChangeNotifierProvider<BoardViewModel>.value(value: _boardViewModel),
        ChangeNotifierProvider<RidesViewModel>.value(value: _ridesViewModel),
        ChangeNotifierProvider<DriverViewModel>.value(value: _driverViewModel),
      ],
      child: MaterialApp.router(
        title: 'DOGO Crew',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}

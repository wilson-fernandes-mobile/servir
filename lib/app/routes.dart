import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/churches/presentation/pages/church_setup_page.dart';
import '../features/home/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // ValueNotifier keeps the latest auth state and acts as a Listenable
  // for GoRouter — this avoids recreating the entire router on auth changes.
  final authNotifier = ValueNotifier<AsyncValue<UserEntity?>>(
    ref.read(authStateChangesProvider),
  );

  ref.onDispose(authNotifier.dispose);

  // Whenever auth state changes, update the notifier → GoRouter re-evaluates
  // the redirect WITHOUT creating a new GoRouter instance.
  ref.listen<AsyncValue<UserEntity?>>(
    authStateChangesProvider,
    (_, next) => authNotifier.value = next,
  );

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;

      // While the auth stream is still loading, stay on the current page
      if (authState.isLoading) return null;

      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final hasChurch = user?.churchId != null;

      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == AppRoutes.login || loc == AppRoutes.register;
      final isChurchSetup = loc == AppRoutes.churchSetup;

      // Not logged in → always go to login
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // Logged in but on auth screens
      if (isLoggedIn && isAuthRoute) {
        return hasChurch ? AppRoutes.home : AppRoutes.churchSetup;
      }

      // Logged in but has no church → must complete setup first
      if (isLoggedIn && !hasChurch && !isChurchSetup) {
        return AppRoutes.churchSetup;
      }

      // Already has a church but is on the setup page → go home
      if (isLoggedIn && hasChurch && isChurchSetup) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.churchSetup,
        name: 'church-setup',
        builder: (context, state) => const ChurchSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página não encontrada: ${state.error}')),
    ),
  );
});

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String churchSetup = '/church-setup';
  static const String home = '/';
  static const String members = '/members';
  static const String ministries = '/ministries';
  static const String events = '/events';
  static const String schedules = '/schedules';
}


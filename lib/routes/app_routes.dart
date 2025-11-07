// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/create_new_password_screen.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/email_confirmation_screen/email_confirmation_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/nutrition_screen/nutrition_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/progress_screen/progress_screen.dart';
import '../presentation/sign_up_screen/sign_up_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/workouts_screen/workouts_screen.dart';
import '../presentation/wait_for_confirmation_screen.dart';

// BLDR CLUB
import '../presentation/bldr_club/bldr_club_screen.dart';
import '../presentation/bldr_club/ranking_screen.dart'
    show RankingScreen, loadRankingFromClub, rankingStreamFromClub; // ✅ loaders novos
import '../presentation/bldr_club/club_workout_screen.dart';
import '../presentation/bldr_club/esportes_screen.dart';
import '../presentation/bldr_club/comunidade_screen.dart';
import '../presentation/bldr_club/club_types.dart';

class AppRoutes {
  // Route constants
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String signUpScreen = '/sign-up-screen';
  static const String emailConfirmationScreen = '/email-confirmation-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String dashboard = '/dashboard';
  static const String workoutsScreen = '/workouts-screen';
  static const String nutritionScreen = '/nutrition-screen';
  static const String progressScreen = '/progress-screen';
  static const String checkoutScreen = '/checkout-screen';
  static const String waitForConfirmationScreen = '/wait-for-confirmation';
  static const String createNewPasswordScreen = '/create-new-password';

  // BLDR CLUB
  static const String bldrClubScreen = '/bldr-club';
  static const String rankingScreen = '/bldr-club/ranking';
  static const String treinosScreen = '/bldr-club/treinos';
  static const String esportesScreen = '/bldr-club/esportes';
  static const String comunidadeScreen = '/bldr-club/comunidade';

  // Route map
  static Map<String, WidgetBuilder> get routes {
    return {
      splashScreen: (context) => const SplashScreen(),
      loginScreen: (context) => const LoginScreen(),
      signUpScreen: (context) => const SignUpScreen(),
      emailConfirmationScreen: (context) => const EmailConfirmationScreen(),
      onboardingFlow: (context) => const OnboardingFlow(),
      dashboard: (context) => const Dashboard(),
      workoutsScreen: (context) => const WorkoutsScreen(),
      nutritionScreen: (context) => const NutritionScreen(),
      progressScreen: (context) => const ProgressScreen(),
      checkoutScreen: (context) => const CheckoutScreen(),
      waitForConfirmationScreen: (context) => const WaitForConfirmationScreen(),
      createNewPasswordScreen: (context) => const CreateNewPasswordScreen(),

      // BLDR CLUB
      bldrClubScreen: (context) => const BldrClubScreen(),

      // ✅ usa loaders novos (select + stream). Se "club_ranking" for VIEW, o stream retornará null sem quebrar.
      rankingScreen: (context) => RankingScreen(
        loadRanking: () => loadRankingFromClub(limit: 100),
        rankingStream: rankingStreamFromClub(limit: 100),
      ),

      treinosScreen: (context) => const ClubWorkoutsScreen(),
      esportesScreen: (context) => const EsportesScreen(),
      comunidadeScreen: (context) => const ComunidadeScreen(),
    };
  }
}

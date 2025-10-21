import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// Certifique-se de que os caminhos de importação estão corretos para seu projeto
import './services/supabase_service.dart';
import './services/profile_notifier.dart';
import 'core/app_export.dart';

late final Map<String, dynamic> appConfig;

void main() async {
  // Garante que o Flutter esteja pronto para código assíncrono antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final configString = await rootBundle.loadString('dart_defines.dev.json');
  appConfig = json.decode(configString);

  try {
    // 1. Inicializa o Supabase.
    await SupabaseService.initialize();

    // 2. Inicializa a Stripe AQUI.
    // A chave publicável é pega do ambiente.
    Stripe.publishableKey = appConfig['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();

  runApp(
  ChangeNotifierProvider(
  create: (context) => ProfileNotifier(),
  child: const MyApp(),
  ),
  );

  } catch (e) {
  if (kDebugMode) {
  print('Falha crítica na inicialização do App: $e');
  }
  runApp(MaterialApp(
  home: Scaffold(
  body: Center(
  child: Text('Erro ao iniciar o aplicativo. Detalhes: $e'),
  ),
  ),
  ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'BLDR App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
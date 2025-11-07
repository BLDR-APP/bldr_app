import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './services/notification_service.dart';

// --- (MODIFICAÇÃO 1 de 3) ---
// Importa as opções geradas pelo FlutterFire
import 'firebase_options.dart';

// Certifique-se de que os caminhos de importação estão corretos para seu projeto
import './services/supabase_service.dart';
import './services/profile_notifier.dart';
import 'core/app_export.dart';

const FirebaseOptions firebaseOptionsAlimentos = FirebaseOptions(
    apiKey: "AIzaSyCJ8Esde8OkYLvjFfHCi8f5Et6se0GX_oE",
    authDomain: "database-alimentos-c68e2.firebaseapp.com",
    projectId: "database-alimentos-c68e2",
    storageBucket: "database-alimentos-c68e2.firebasestorage.app",
    messagingSenderId: "515368188667",
    appId: "1:515368188667:web:69317de12fb2176e300e5e",
    measurementId: "G-W67FDGEMMT"
);



late final Map<String, dynamic> appConfig;

void main() async {
  // Garante que o Flutter esteja pronto para código assíncrono antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // --- (MODIFICAÇÃO 2 de 3) ---
  // O bloco try AGORA envolve TODA a inicialização.
  try {
    // Inicializa o Firebase (AGORA da forma correta)
    //await Firebase.initializeApp(
      //options: DefaultFirebaseOptions.currentPlatform, // (MODIFICAÇÃO 3 de 3)
    //);

    if (Firebase.apps.where((app) => app.name == 'alimentosDB').isEmpty) {
      await Firebase.initializeApp(
        name: 'alimentosDB',
        options: firebaseOptionsAlimentos,
      );
    }

    // Carrega a configuração (AGORA dentro do try)
    final configString = await rootBundle.loadString('dart_defines.dev.json');
    appConfig = json.decode(configString);

    // 1. Inicializa o Supabase.
    await SupabaseService.initialize();

    // 2. Inicializa a Stripe AQUI.
    // A chave publicável é pega do ambiente.
    Stripe.publishableKey = appConfig['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();

    await NotificationService().initialize();

    // Roda o app principal
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
    // Roda um app de erro se qualquer coisa acima falhar
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro ao iniciar o aplicativo. Detalhes: $e'),
        ),
      ),
    ));
  }
}

// --- NENHUMA ALTERAÇÃO ABAIXO ---

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
          // Define o idioma padrão do app como Português (Brasil)
          locale: const Locale('pt', 'BR'),

          // Informa ao Flutter quais são os "tradutores"
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Lista os idiomas que seu app suporta
          supportedLocales: const [
            Locale('pt', 'BR'), // Português (Brasil)
            Locale('en', 'US'), // Inglês (como reserva, caso necessário)
          ],
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
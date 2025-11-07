// Salve em: lib/services/notification_service.dart
// (VERSÃO CORRIGIDA)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // O ID da nossa notificação de descanso. Usamos um ID fixo (0)
  // para que possamos cancelá-la facilmente se o utilizador ficar no app.

  // ===================================
  // CORREÇÃO 1: 'private const' removido
  // ===================================
  final int _restNotificationId = 0;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Usa o ícone do seu app

    // Configurações para iOS (necessita de permissão no AppDelegate)
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Pedir permissão de notificação no Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Agenda a notificação de "Descanso Concluído"
  Future<void> scheduleRestNotification(int seconds) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'rest_timer_channel', // ID do Canal
      'Timers de Descanso', // Nome do Canal
      channelDescription: 'Notificações para quando o descanso do treino acabar',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
    DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // Agenda a notificação
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _restNotificationId, // ID fixo
      'Descanso Concluído!',
      'O seu descanso acabou. Vamos para a próxima série!',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // ===================================
      // CORREÇÃO 2: Linhas obsoletas removidas
      // ===================================
      // uiLocalNotificationDateInterpretation: (REMOVIDO)
      //     UILocalNotificationDateInterpretation.absoluteTime, (REMOVIDO)
    );

    print("NOTIFICAÇÃO: Agendada para daqui a $seconds segundos.");
  }

  /// Cancela a notificação de descanso (se o utilizador ficar no app)
  Future<void> cancelRestNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_restNotificationId);
    print("NOTIFICAÇÃO: Notificação de descanso pendente foi cancelada.");
  }
}
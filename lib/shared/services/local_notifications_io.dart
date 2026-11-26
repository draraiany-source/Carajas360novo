import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotificationsPlugin(
  void Function(String title, String body) onMessage,
) async {
  const a = AndroidInitializationSettings('@mipmap/ic_launcher');
  const i = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true);
  await _plugin.initialize(
      settings: const InitializationSettings(android: a, iOS: i));
}

Future<void> showLocalNotification({
  required int id,
  required String title,
  required String body,
}) async {
  const a = AndroidNotificationDetails('sc_main', 'ServiçoConecta',
      channelDescription: 'Notificações',
      importance: Importance.high,
      priority: Priority.high);
  const i = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true);
  await _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: a, iOS: i),
  );
}

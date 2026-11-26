/// Stub Web: notificações locais não usam o plugin nativo.
Future<void> initLocalNotificationsPlugin(
  void Function(String title, String body) onMessage,
) async {}

Future<void> showLocalNotification({
  required int id,
  required String title,
  required String body,
}) async {}

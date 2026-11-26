import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/modules/platform_modules.dart';
import '../services/firebase_service.dart';

/// Evita que a UI quebre quando o Firebase ainda não foi configurado.
Stream<T> c360Stream<T>(Stream<T> Function() create) {
  try {
    return create().transform(
      StreamTransformer.fromHandlers(
        handleError: (Object _, StackTrace __, EventSink<T> sink) {
          sink.close();
        },
      ),
    );
  } catch (_) {
    return const Stream.empty();
  }
}

String? c360Uid() {
  try {
    return AuthService.uid;
  } catch (_) {
    return null;
  }
}

/// Destinos da navegação principal (sidebar / barra inferior).
enum C360Dest {
  home,
  explore,
  professionals,
  orders,
  messages,
  favorites,
  account,
  tia,
  agenda,
}

/// Como a busca de profissionais é apresentada.
enum SearchMode { explore, professionals }

/// Navegação compartilhada entre o shell e as telas embutidas.
class C360Nav extends InheritedWidget {
  final C360Dest current;
  final ValueChanged<C360Dest> go;
  final ValueChanged<Widget> push;
  final VoidCallback pop;
  final bool canPop;

  const C360Nav({
    super.key,
    required this.current,
    required this.go,
    required this.push,
    required this.pop,
    required this.canPop,
    required super.child,
  });

  static C360Nav? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<C360Nav>();

  @override
  bool updateShouldNotify(C360Nav oldWidget) =>
      current != oldWidget.current || canPop != oldWidget.canPop;
}

/// Abre uma tela dentro do shell quando ele existe; senão, via rota nomeada.
void c360Open(
  BuildContext context, {
  required Widget page,
  required String route,
  Object? arguments,
}) {
  final nav = C360Nav.maybeOf(context);
  if (nav != null) {
    nav.push(page);
    return;
  }
  Navigator.pushNamed(context, route, arguments: arguments);
}

void c360Pop(BuildContext context) {
  final nav = C360Nav.maybeOf(context);
  if (nav != null && nav.canPop) {
    nav.pop();
    return;
  }
  Navigator.maybePop(context);
}

void c360Go(BuildContext context, C360Dest dest, String fallbackRoute) {
  final nav = C360Nav.maybeOf(context);
  if (nav != null) {
    nav.go(dest);
    return;
  }
  Navigator.pushNamed(context, fallbackRoute);
}

/// Cidade selecionada na região (persistida no perfil quando há sessão).
class RegionController {
  RegionController._();
  static final instance = RegionController._();

  final ValueNotifier<String> city =
      ValueNotifier<String>(RegionCities.defaultCity);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final user = await FS.userStream(uid).first;
      final value = user?.city?.trim();
      if (value != null && value.isNotEmpty) city.value = value;
    } catch (_) {}
  }

  Future<void> setCity(String value) async {
    city.value = value;
    try {
      if (AuthService.uid != null) {
        await FS.updateUser({'city': value});
      }
    } catch (_) {}
  }
}

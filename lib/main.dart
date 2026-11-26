import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'shared/widgets/micro_interactions.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/runtime_config.dart';
import 'core/utils/firebase_bootstrap.dart';
import 'shared/services/firebase_service.dart';

import 'package:servico_conecta/features/auth/auth_screen.dart';
import 'package:servico_conecta/features/home/home_screen.dart'
    show SearchScreen, ServicesHubScreen;
import 'package:servico_conecta/features/resolve/resolve_screen.dart';
import 'package:servico_conecta/features/chat/chat_screen.dart';
import 'package:servico_conecta/features/chat/chat_inbox_screen.dart';
import 'package:servico_conecta/features/gps/gps_screen.dart';
import 'package:servico_conecta/features/wallet/wallet_screen.dart';
import 'package:servico_conecta/features/health/health_screen.dart';
import 'package:servico_conecta/features/marketplace/marketplace_screen.dart';
import 'package:servico_conecta/features/marketplace/store_screen.dart';
import 'package:servico_conecta/features/rental/rental_screen.dart';
import 'package:servico_conecta/features/profile/profile_screens.dart';
import 'package:servico_conecta/features/support/support_screens.dart';
import 'package:servico_conecta/features/tia/tia_request_screen.dart';
import 'package:servico_conecta/features/tia/tia_schedule_screen.dart';
import 'package:servico_conecta/features/tia/tia_screen.dart';
import 'package:servico_conecta/features/admin/admin_screen.dart';
import 'package:servico_conecta/features/company/company_screen.dart';
import 'package:servico_conecta/features/orders/orders_screen.dart';
import 'package:servico_conecta/features/provider/provider_home_screen.dart';
import 'package:servico_conecta/features/home/provider_profile_screen.dart';
import 'package:servico_conecta/core/auth/access_control.dart';
import 'package:servico_conecta/shared/widgets/c360_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // setPreferredOrientations é no-op seguro no Web.
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {}
  await ThemeController.instance.load();

  bool firebaseOk = false;
  try {
    await FirebaseBootstrap.initialize();
    // FCM/Analytics podem falhar nos emuladores — nao bloqueiam auth.
    try {
      await PushSvc.init();
    } catch (e) {
      debugPrint('PushSvc.init: $e');
    }
    // Crashlytics nao e suportado no Web — usa handlers locais nesse caso.
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught: $error\n$stack');
        return true;
      };
    }
    firebaseOk = true;
  } catch (e) {
    debugPrint('Firebase nao configurado — modo demonstracao: $e');
  }

  RuntimeConfig.firebaseReady = firebaseOk;
  runApp(ServicoConectaApp(firebaseOk: firebaseOk));
}

class ServicoConectaApp extends StatelessWidget {
  final bool firebaseOk;
  const ServicoConectaApp({super.key, this.firebaseOk = false});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance.mode,
        builder: (context, themeMode, _) => MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          navigatorObservers: firebaseOk
              ? [
                  FirebaseAnalyticsObserver(
                      analytics: FirebaseAnalytics.instance)
                ]
              : const <NavigatorObserver>[],
          initialRoute: Routes.splash,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case Routes.splash:
                return _route(SplashScreen(firebaseReady: firebaseOk));
              case Routes.onboarding:
                return _route(const OnboardingScreen());
              case Routes.login:
                return _route(const LoginScreen());
              case Routes.register:
                return _route(const RegisterScreen());
              case Routes.main:
                return _route(const MainNav());
              case Routes.search:
                final sa = settings.arguments as Map<String, dynamic>?;
                return _route(
                    SearchScreen(initialCategory: sa?['category'] as String?));
              case Routes.chat:
                final a = settings.arguments as Map<String, dynamic>?;
                return _route(ChatScreen(
                  roomId: a?['roomId'] ?? a?['id'] ?? 'demo',
                  otherName: a?['name'] ?? 'Profissional',
                  otherPhoto: a?['photo'],
                ));
              case Routes.gps:
                final a = settings.arguments as Map<String, dynamic>?;
                return _route(GpsScreen(
                    ctxKey: a?['ctx'] ?? 'servico',
                    deliveryId: a?['deliveryId'],
                    orderId: a?['orderId']));
              case Routes.wallet:
                return _route(const RequireAuth(title: 'Carteira', child: WalletScreen()));
              case Routes.admin:
                return _route(const AdminGate(child: AdminScreen()));
              case Routes.health:
                return _route(const HealthScreen());
              case Routes.marketplace:
                return _route(const MarketplaceScreen());
              case Routes.store:
                return _route(const StoreScreen());
              case Routes.rental:
                final ra = settings.arguments as Map<String, dynamic>?;
                return _route(
                    RentalScreen(initialTab: (ra?['tab'] as int?) ?? 0));
              case Routes.bookings:
                return _route(const MyBookingsScreen());
              case Routes.stores:
                return _route(const StoresListScreen());
              case Routes.delivery:
                return _route(const DeliveryScreen());
              case Routes.profile:
                return _route(const ProfileScreen());
              case Routes.notifications:
                return _route(const NotificationsScreen());
              case Routes.reviews:
                final a = settings.arguments as Map<String, dynamic>?;
                return _route(ReviewScreen(
                    orderId: a?['orderId'] ?? 'demo',
                    providerId: a?['providerId'],
                    providerName: a?['providerName']));
              case Routes.support:
                return _route(const RequireAuth(title: 'Suporte', child: SupportScreen()));
              case Routes.coupons:
                return _route(const CouponsScreen());
              case Routes.aiAssistant:
                return _route(const TiaCentralScreen());
              case Routes.tiaRequest:
                final rq = settings.arguments as Map<String, dynamic>?;
                return _route(RequireAuth(
                  title: 'Solicitar serviço',
                  child: TiaRequestScreen(
                    providerId: rq?['providerId'] as String?,
                    providerName: rq?['providerName'] as String?,
                    category: rq?['category'] as String?,
                  ),
                ));
              case Routes.tiaSchedule:
                final sq = settings.arguments as Map<String, dynamic>?;
                return _route(RequireAuth(
                  title: 'Agendamento',
                  child: TiaScheduleScreen(
                    category: sq?['category'] as String?,
                    specialty: sq?['specialty'] as String?,
                    providerId: sq?['providerId'] as String?,
                  ),
                ));
              case Routes.companyProfile:
                return _route(const RequireAuth(title: 'Empresa', child: CompanyProfileScreen()));
              case Routes.favorites:
                return _route(const FavoritesScreen());
              case Routes.myOrders:
                return _route(const MyOrdersScreen());
              case Routes.requestService:
                final a = settings.arguments as Map<String, dynamic>?;
                return _route(RequestServiceScreen(
                  providerId: a?['providerId'] ?? '',
                  providerName: a?['providerName'] ?? 'Profissional',
                  category: a?['category'] ?? '',
                  providerColor: a?['providerColor'] ?? AppColors.primary,
                ));
              case Routes.providerHome:
                return _route(const C360Shell(singlePage: ProviderHomeScreen()));
              case Routes.providerProfile:
                final pa = settings.arguments as Map<String, dynamic>?;
                return _route(C360Shell(
                  singlePage: ProviderProfileScreen(
                    providerId: pa?['providerId'] ?? '',
                    providerName: pa?['providerName'] ?? 'Profissional',
                    category: pa?['category'] ?? '',
                    style: pa?['style'] == 'service'
                        ? ProviderDetailStyle.service
                        : ProviderDetailStyle.profile,
                  ),
                ));
              case Routes.providerOnboarding:
                return _route(const ProviderOnboardingScreen());
              case Routes.servicesHub:
                return _route(const ServicesHubScreen());
              case Routes.resolve:
                return _route(const ResolveScreen());
              case Routes.resolveDetail:
                final a = settings.arguments as Map<String, dynamic>?;
                final rid = a?['id'] as String? ?? '';
                if (rid.isEmpty) {
                  return _route(const MyResolveScreen());
                }
                return _route(ResolveDetailScreen(requestId: rid));
              case Routes.resolveOpportunities:
                return _route(const ResolveOpportunitiesScreen());
              case Routes.myResolve:
                return _route(const MyResolveScreen());
              case Routes.chatInbox:
                return _route(const ChatInboxScreen());
              default:
                // Rota desconhecida: volta ao app principal (evita splash “presa”).
                return _route(const MainNav());
            }
          },
        ),
      );

  PageRoute _route(Widget page) => FadeSlidePageRoute(page: page);
}

// ─────────────────────────────────────────────────────────────
// MAIN NAVIGATION — Bottom NavBar
// ─────────────────────────────────────────────────────────────
class MainNav extends StatelessWidget {
  const MainNav({super.key});

  @override
  Widget build(BuildContext context) => const C360Shell();
}

// ─────────────────────────────────────────────────────────────
// SPLASH SCREEN wrapper (imported from auth_screen.dart)
// ─────────────────────────────────────────────────────────────

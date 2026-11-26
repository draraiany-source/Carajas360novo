export 'service_category.dart';
export '../catalog/service_catalog.dart' show Categories;

abstract class AppInfo {
  static const name = 'Carajás 360';
  static const slogan = 'Tudo que você precisa na região, em um só lugar.';
  static const version = '1.0.0';
  /// Nome legado do núcleo de serviços (módulo Serviços).
  static const servicesModuleName = 'Serviços';
  static const servicesModuleLegacy = 'Serviço Conecta';
}

abstract class AppConst {
  static const double commission = 0.15;
  static const int otpTimeoutSeconds = 60;
  static const int xpPerReview = 30;
}

abstract class Col {
  static const users = 'users';
  static const providers = 'providers';
  static const companies = 'companies';
  static const orders = 'orders';
  static const wallets = 'wallets';
  static const transactions = 'transactions';
  static const reviews = 'reviews';
  static const chatRooms = 'chatRooms';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const coupons = 'coupons';
  static const deliveries = 'deliveries';
  static const appointments = 'appointments';
  static const contracts = 'contracts';
  static const support = 'support';
  static const auditLogs = 'auditLogs';
  static const banners = 'banners';
  static const categories = 'categories';
  static const favorites = 'favorites';
  static const reports = 'reports';
  static const employees = 'employees';
  static const branches = 'branches';
  static const stores = 'stores';
  static const products = 'products';
  static const rentals = 'rentals';
  static const bookings = 'bookings';
  /// Resolve Carajás — solicitações abertas e propostas.
  static const resolveRequests = 'resolveRequests';
  static const resolveProposals = 'resolveProposals';
  static const financialAudits = 'financialAudits';
  static const rateLimits = 'rateLimits';
}

abstract class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const search = '/search';
  static const chat = '/chat';
  static const wallet = '/wallet';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const reviews = '/reviews';
  static const health = '/health';
  static const delivery = '/delivery';
  static const marketplace = '/marketplace';
  static const store = '/store';
  static const rental = '/rental';
  static const bookings = '/bookings';
  static const stores = '/stores';
  static const admin = '/admin';
  static const gps = '/gps';
  static const support = '/support';
  static const coupons = '/coupons';
  static const aiAssistant = '/ai';
  static const tiaRequest = '/tia-request';
  static const tiaSchedule = '/tia-schedule';
  static const companyProfile = '/company';
  static const favorites = '/favorites';
  static const myOrders = '/my-orders';
  static const requestService = '/request-service';
  static const providerHome = '/provider-home';
  static const providerOnboarding = '/provider-onboarding';
  static const servicesHub = '/services-hub';
  static const resolve = '/resolve';
  static const resolveDetail = '/resolve-detail';
  static const resolveOpportunities = '/resolve-opportunities';
  static const chatInbox = '/chat-inbox';
  static const myResolve = '/my-resolve';
  static const providerProfile = '/provider-profile';
}


String xpLevel(int xp) {
  if (xp >= 4000) return '💎 Diamante';
  if (xp >= 2000) return '🥇 Ouro';
  if (xp >= 1000) return '🥈 Prata';
  if (xp >= 500) return '🥉 Bronze';
  return '⭐ Iniciante';
}

int nextLevelXp(int xp) {
  if (xp < 500) return 500 - xp;
  if (xp < 1000) return 1000 - xp;
  if (xp < 2000) return 2000 - xp;
  if (xp < 4000) return 4000 - xp;
  return 0;
}

double xpProgress(int xp) {
  if (xp < 500) return xp / 500;
  if (xp < 1000) return (xp - 500) / 500;
  if (xp < 2000) return (xp - 1000) / 1000;
  if (xp < 4000) return (xp - 2000) / 2000;
  return 1.0;
}

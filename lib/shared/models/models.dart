import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/security/order_lifecycle.dart';

enum UserType { client, provider, deliverer, company, admin }

enum AdminRole { master, financial, support, moderator, marketing }

class UserModel {
  final String id, name, email, phone;
  final UserType type;
  final String? photoUrl, cpf, city, state, address, fcmToken;
  final double? lat, lng;
  final int xp;
  final String status;
  final bool verified, termsAccepted;
  final AdminRole? adminRole;
  final PlanTier plan;
  final DateTime createdAt;
  /// Perfis habilitados na mesma conta (ex.: client, provider, company).
  /// Mantém [type] como perfil ativo; não quebra documentos legados.
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    this.photoUrl,
    this.cpf,
    this.city,
    this.state,
    this.address,
    this.fcmToken,
    this.lat,
    this.lng,
    this.xp = 0,
    this.status = 'active',
    this.verified = false,
    this.termsAccepted = false,
    this.adminRole,
    this.plan = PlanTier.free,
    required this.createdAt,
    this.roles = const [],
  });

  String get levelName => xpLevelOf(xp);
  String get firstName => name.isEmpty ? '' : name.split(' ').first;

  factory UserModel.fromMap(String id, Map<String, dynamic> m) => UserModel(
        id: id,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        type: UserType.values.firstWhere(
            (t) => t.name == (m['type'] ?? 'client'),
            orElse: () => UserType.client),
        photoUrl: m['photoUrl'],
        cpf: m['cpf'],
        city: m['city'],
        state: m['state'],
        address: m['address'],
        fcmToken: m['fcmToken'],
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        status: m['status'] ?? 'active',
        verified: m['verified'] ?? false,
        termsAccepted: m['termsAccepted'] ?? false,
        adminRole: m['adminRole'] != null
            ? AdminRole.values.firstWhere((r) => r.name == m['adminRole'],
                orElse: () => AdminRole.support)
            : null,
        plan: PlanTier.values.firstWhere((p) => p.name == (m['plan'] ?? 'free'),
            orElse: () => PlanTier.free),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        roles: List<String>.from(m['roles'] ?? const []),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'type': type.name,
        'photoUrl': photoUrl,
        'cpf': cpf,
        'city': city,
        'state': state,
        'address': address,
        'fcmToken': fcmToken,
        'lat': lat,
        'lng': lng,
        'xp': xp,
        'status': status,
        'verified': verified,
        'termsAccepted': termsAccepted,
        if (adminRole != null) 'adminRole': adminRole!.name,
        'plan': plan.name,
        if (roles.isNotEmpty) 'roles': roles,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ── Company (Vol.5: coleção companies) ─────────────────────────
enum PlanTier { free, professional, premium, corporate }

class CompanyModel {
  final String id, ownerId, name, cnpj;
  final String? logoUrl, phone, email, address, city, state;
  final List<String> categories;
  final PlanTier plan;
  final bool verified, active;
  final int teamSize;
  final DateTime createdAt;

  const CompanyModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.cnpj,
    this.logoUrl,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.categories = const [],
    this.plan = PlanTier.free,
    this.verified = false,
    this.active = true,
    this.teamSize = 1,
    required this.createdAt,
  });

  String get planLabel {
    switch (plan) {
      case PlanTier.free:
        return 'Grátis';
      case PlanTier.professional:
        return 'Profissional';
      case PlanTier.premium:
        return 'Premium';
      case PlanTier.corporate:
        return 'Corporativo';
    }
  }

  factory CompanyModel.fromMap(String id, Map<String, dynamic> m) =>
      CompanyModel(
        id: id,
        ownerId: m['ownerId'] ?? '',
        name: m['name'] ?? '',
        cnpj: m['cnpj'] ?? '',
        logoUrl: m['logoUrl'],
        phone: m['phone'],
        email: m['email'],
        address: m['address'],
        city: m['city'],
        state: m['state'],
        categories: List<String>.from(m['categories'] ?? []),
        plan: PlanTier.values.firstWhere((p) => p.name == (m['plan'] ?? 'free'),
            orElse: () => PlanTier.free),
        verified: m['verified'] ?? false,
        active: m['active'] ?? true,
        teamSize: (m['teamSize'] as num?)?.toInt() ?? 1,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'cnpj': cnpj,
        'logoUrl': logoUrl,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'categories': categories,
        'plan': plan.name,
        'verified': verified,
        'active': active,
        'teamSize': teamSize,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ── Banner (Vol.6: marketing) ────────────────────────────────
class BannerModel {
  final String id, imageUrl, title;
  final String? link, category;
  final bool active;
  final int order;
  final DateTime? expiresAt;

  const BannerModel(
      {required this.id,
      required this.imageUrl,
      required this.title,
      this.link,
      this.category,
      this.active = true,
      this.order = 0,
      this.expiresAt});

  factory BannerModel.fromMap(String id, Map<String, dynamic> m) => BannerModel(
        id: id,
        imageUrl: m['imageUrl'] ?? '',
        title: m['title'] ?? '',
        link: m['link'],
        category: m['category'],
        active: m['active'] ?? true,
        order: (m['order'] as num?)?.toInt() ?? 0,
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      );
}

// ── Support Ticket (Vol.6: atendimento) ──────────────────────
enum TicketStatus { open, inProgress, resolved, closed }

class TicketModel {
  final String id, userId, userName, subject, message;
  final TicketStatus status;
  final String priority;
  final DateTime createdAt;
  final List<String> attachments;

  const TicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.message,
    this.status = TicketStatus.open,
    this.priority = 'normal',
    required this.createdAt,
    this.attachments = const [],
  });

  String get statusLabel {
    switch (status) {
      case TicketStatus.open:
        return '🟡 Aberto';
      case TicketStatus.inProgress:
        return '🔵 Em atendimento';
      case TicketStatus.resolved:
        return '🟢 Resolvido';
      case TicketStatus.closed:
        return '⚪ Fechado';
    }
  }

  factory TicketModel.fromMap(String id, Map<String, dynamic> m) => TicketModel(
        id: id,
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? 'Usuário',
        subject: m['subject'] ?? '',
        message: m['message'] ?? '',
        status: TicketStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'open'),
            orElse: () => TicketStatus.open),
        priority: m['priority'] ?? 'normal',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        attachments: List<String>.from(m['attachments'] ?? []),
      );
}

// ── Audit Log (Vol.6: todas as ações críticas registradas) ───
class AuditLogModel {
  final String id, adminId, adminName, action, target;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const AuditLogModel(
      {required this.id,
      required this.adminId,
      required this.adminName,
      required this.action,
      required this.target,
      required this.timestamp,
      this.details});

  factory AuditLogModel.fromMap(String id, Map<String, dynamic> m) =>
      AuditLogModel(
        id: id,
        adminId: m['adminId'] ?? '',
        adminName: m['adminName'] ?? 'Admin',
        action: m['action'] ?? '',
        target: m['target'] ?? '',
        timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        details: m['details'] as Map<String, dynamic>?,
      );
}

String xpLevelOf(int xp) {
  if (xp >= 4000) return '💎 Diamante';
  if (xp >= 2000) return '🥇 Ouro';
  if (xp >= 1000) return '🥈 Prata';
  if (xp >= 500) return '🥉 Bronze';
  return '⭐ Iniciante';
}

class ProviderModel {
  final String id, userId, name;
  final String? photoUrl, bio, city, documentUrl, selfieUrl;
  final List<String> categories, modalities, certificates, serviceAreas;
  final double rating;
  final int totalReviews;
  final bool active, verified;
  final double? minPrice;
  final String? council;
  final String? registrationNumber;
  final bool registrationVerified;
  final String? phone;
  final List<String> specialties;
  final List<String> availabilitySlots;
  final bool availableToday;
  final DateTime createdAt;

  const ProviderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.bio,
    this.city,
    this.documentUrl,
    this.selfieUrl,
    this.categories = const [],
    this.modalities = const ['presential'],
    this.certificates = const [],
    this.serviceAreas = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.active = true,
    this.verified = false,
    this.minPrice,
    this.council,
    this.registrationNumber,
    this.registrationVerified = false,
    this.phone,
    this.specialties = const [],
    this.availabilitySlots = const [],
    this.availableToday = false,
    required this.createdAt,
  });

  String get badge {
    if (totalReviews >= 500) return '💎 Diamante';
    if (totalReviews >= 200) return '🥇 Ouro';
    if (totalReviews >= 50) return '🥈 Prata';
    return '🥉 Bronze';
  }

  factory ProviderModel.fromMap(String id, Map<String, dynamic> m) =>
      ProviderModel(
        id: id,
        userId: m['userId'] ?? '',
        name: m['name'] ?? '',
        photoUrl: m['photoUrl'],
        bio: m['bio'],
        city: m['city'],
        documentUrl: m['documentUrl'],
        selfieUrl: m['selfieUrl'],
        categories: List<String>.from(m['categories'] ?? []),
        modalities: List<String>.from(m['modalities'] ?? ['presential']),
        certificates: List<String>.from(m['certificates'] ?? []),
        serviceAreas: List<String>.from(m['serviceAreas'] ?? []),
        rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: (m['totalReviews'] as num?)?.toInt() ?? 0,
        active: m['active'] ?? true,
        verified: m['verified'] ?? false,
        minPrice: (m['minPrice'] as num?)?.toDouble(),
        council: m['council'] as String?,
        registrationNumber: m['registrationNumber'] as String?,
        registrationVerified: m['registrationVerified'] == true,
        phone: m['phone'] as String?,
        specialties: List<String>.from(m['specialties'] ?? const []),
        availabilitySlots: List<String>.from(m['availabilitySlots'] ?? const []),
        availableToday: m['availableToday'] == true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

enum OrderStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  disputed
}

class OrderModel {
  final String id, clientId, category, title, description, address;
  final String? providerId;
  final double? price;
  final OrderStatus status;
  final String? lifecycle;
  final bool urgent, reviewed;
  final String? paymentStatus;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.category,
    required this.title,
    required this.description,
    required this.address,
    this.providerId,
    this.price,
    this.status = OrderStatus.pending,
    this.lifecycle,
    this.urgent = false,
    this.reviewed = false,
    this.paymentStatus,
    required this.createdAt,
  });

  String get statusLabel {
    final rich = OrderLifecycle.label(lifecycle);
    if (rich != null) return rich;
    switch (status) {
      case OrderStatus.pending:
        return '⏳ Aguardando';
      case OrderStatus.accepted:
        return '✅ Aceito';
      case OrderStatus.inProgress:
        return '🔄 Em andamento';
      case OrderStatus.completed:
        return '✔️ Concluído';
      case OrderStatus.cancelled:
        return '❌ Cancelado';
      case OrderStatus.disputed:
        return '⚠️ Disputa';
    }
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
        id: id,
        clientId: m['clientId'] ?? '',
        providerId: m['providerId'],
        category: m['category'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        address: m['address'] ?? '',
        price: (m['price'] as num?)?.toDouble(),
        status: OrderStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'pending'),
            orElse: () => OrderStatus.pending),
        lifecycle: m['lifecycle'] as String?,
        urgent: m['urgent'] ?? false,
        reviewed: m['reviewed'] ?? false,
        paymentStatus: m['paymentStatus'] as String?,
        createdAt: m['createdAt'] is Timestamp
            ? (m['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
      );
}

class MessageModel {
  final String id, senderId, senderName, text;
  final bool read;
  final DateTime createdAt;
  final String? mediaUrl;
  final String? replyToText, replyToSender; // mensagem citada
  final bool deleted; // apagada para todos

  const MessageModel(
      {required this.id,
      required this.senderId,
      required this.senderName,
      required this.text,
      this.read = false,
      required this.createdAt,
      this.mediaUrl,
      this.replyToText,
      this.replyToSender,
      this.deleted = false});

  factory MessageModel.fromMap(String id, Map<String, dynamic> m) =>
      MessageModel(
        id: id,
        senderId: m['senderId'] ?? '',
        senderName: m['senderName'] ?? '',
        text: m['text'] ?? '',
        read: m['read'] ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        mediaUrl: m['mediaUrl'],
        replyToText: m['replyToText'],
        replyToSender: m['replyToSender'],
        deleted: m['deleted'] ?? false,
      );
}

class WalletModel {
  final String userId;
  final double balance;
  const WalletModel({required this.userId, required this.balance});
  factory WalletModel.fromMap(Map<String, dynamic> m) => WalletModel(
      userId: m['userId'] ?? '',
      balance: (m['balance'] as num?)?.toDouble() ?? 0.0);
}

class TransactionModel {
  final String id, userId, type, description, icon, status;
  final double amount;
  final DateTime createdAt;

  const TransactionModel(
      {required this.id,
      required this.userId,
      required this.type,
      required this.amount,
      required this.description,
      required this.icon,
      required this.status,
      required this.createdAt});

  bool get isCredit => type == 'credit';

  factory TransactionModel.fromMap(String id, Map<String, dynamic> m) =>
      TransactionModel(
        id: id,
        userId: m['userId'] ?? '',
        type: m['type'] ?? 'debit',
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        description: m['description'] ?? '',
        icon: m['icon'] ?? '💰',
        status: m['status'] ?? 'done',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class ReviewModel {
  final String id, orderId, clientId, clientName, comment;
  final String? clientPhoto, providerId;
  final int stars;
  final List<String> tags;
  final DateTime createdAt;

  const ReviewModel(
      {required this.id,
      required this.orderId,
      required this.clientId,
      required this.clientName,
      required this.comment,
      this.clientPhoto,
      this.providerId,
      required this.stars,
      this.tags = const [],
      required this.createdAt});

  factory ReviewModel.fromMap(String id, Map<String, dynamic> m) => ReviewModel(
        id: id,
        orderId: m['orderId'] ?? '',
        clientId: m['clientId'] ?? '',
        clientName: m['clientName'] ?? 'Cliente',
        clientPhoto: m['clientPhoto'],
        providerId: m['providerId'],
        comment: m['comment'] ?? '',
        stars: (m['stars'] as num?)?.toInt() ?? 5,
        tags: List<String>.from(m['tags'] ?? []),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class NotifModel {
  final String id, userId, title, body, type;
  final bool read;
  final DateTime createdAt;

  const NotifModel(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.type,
      this.read = false,
      required this.createdAt});

  String get icon {
    switch (type) {
      case 'order':
        return '🔧';
      case 'payment':
        return '💳';
      case 'chat':
        return '💬';
      case 'review':
        return '⭐';
      case 'promo':
        return '🎁';
      case 'health':
        return '🏥';
      case 'delivery':
        return '📦';
      default:
        return '🔔';
    }
  }

  factory NotifModel.fromMap(String id, Map<String, dynamic> m) => NotifModel(
        id: id,
        userId: m['userId'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        type: m['type'] ?? 'general',
        read: m['read'] ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class CouponModel {
  final String id, code, description;
  final double discount;
  final bool isPercentage, active;
  final double? minValue;
  final DateTime expiresAt;
  final String? category;

  const CouponModel(
      {required this.id,
      required this.code,
      required this.description,
      required this.discount,
      this.isPercentage = true,
      this.active = true,
      this.minValue,
      required this.expiresAt,
      this.category});

  bool get isValid => active && expiresAt.isAfter(DateTime.now());
  String get label => isPercentage
      ? '${discount.toInt()}% OFF'
      : 'R\$ ${discount.toStringAsFixed(2)}';

  factory CouponModel.fromMap(String id, Map<String, dynamic> m) => CouponModel(
        id: id,
        code: m['code'] ?? '',
        description: m['description'] ?? '',
        discount: (m['discount'] as num?)?.toDouble() ?? 0.0,
        isPercentage: m['isPercentage'] ?? true,
        active: m['active'] ?? true,
        minValue: (m['minValue'] as num?)?.toDouble(),
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        category: m['category'],
      );
}

// ── Denúncias (Vol.20: Administração) ──────────────────────────
enum ReportStatus { pending, reviewing, resolved, dismissed }

class ReportModel {
  final String id,
      reporterId,
      reporterName,
      targetId,
      targetName,
      reason,
      details;
  final ReportStatus status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.reason,
    this.details = '',
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case ReportStatus.pending:
        return '🟡 Pendente';
      case ReportStatus.reviewing:
        return '🔵 Em análise';
      case ReportStatus.resolved:
        return '🟢 Resolvida';
      case ReportStatus.dismissed:
        return '⚪ Arquivada';
    }
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> m) => ReportModel(
        id: id,
        reporterId: m['reporterId'] ?? '',
        reporterName: m['reporterName'] ?? 'Usuário',
        targetId: m['targetId'] ?? '',
        targetName: m['targetName'] ?? 'Usuário',
        reason: m['reason'] ?? '',
        details: m['details'] ?? '',
        status: ReportStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'pending'),
            orElse: () => ReportStatus.pending),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ── Empresas: Equipe, Filiais, Contratos (Vol.15: Empresas) ────
class EmployeeModel {
  final String id, companyId, name, role;
  final String? email, phone, photoUrl;
  final bool active;
  final DateTime createdAt;

  const EmployeeModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.photoUrl,
    this.active = true,
    required this.createdAt,
  });

  factory EmployeeModel.fromMap(String id, Map<String, dynamic> m) =>
      EmployeeModel(
        id: id,
        companyId: m['companyId'] ?? '',
        name: m['name'] ?? '',
        role: m['role'] ?? '',
        email: m['email'],
        phone: m['phone'],
        photoUrl: m['photoUrl'],
        active: m['active'] ?? true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class BranchModel {
  final String id, companyId, name, address, city, state;
  final String? phone;
  final bool active;
  final DateTime createdAt;

  const BranchModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    this.phone,
    this.active = true,
    required this.createdAt,
  });

  factory BranchModel.fromMap(String id, Map<String, dynamic> m) => BranchModel(
        id: id,
        companyId: m['companyId'] ?? '',
        name: m['name'] ?? '',
        address: m['address'] ?? '',
        city: m['city'] ?? '',
        state: m['state'] ?? '',
        phone: m['phone'],
        active: m['active'] ?? true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

enum ContractStatus { draft, active, expired, cancelled }

class ContractModel {
  final String id, companyId, clientName, title, description;
  final double value;
  final ContractStatus status;
  final DateTime startDate, endDate, createdAt;

  const ContractModel({
    required this.id,
    required this.companyId,
    required this.clientName,
    required this.title,
    this.description = '',
    required this.value,
    this.status = ContractStatus.draft,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case ContractStatus.draft:
        return '📝 Rascunho';
      case ContractStatus.active:
        return '✅ Ativo';
      case ContractStatus.expired:
        return '⏰ Expirado';
      case ContractStatus.cancelled:
        return '❌ Cancelado';
    }
  }

  factory ContractModel.fromMap(String id, Map<String, dynamic> m) =>
      ContractModel(
        id: id,
        companyId: m['companyId'] ?? '',
        clientName: m['clientName'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        value: (m['value'] as num?)?.toDouble() ?? 0.0,
        status: ContractStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'draft'),
            orElse: () => ContractStatus.draft),
        startDate: (m['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (m['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// MARKETPLACE — Loja e Produto
// Permite que empresas cadastrem uma loja e anunciem produtos
// (catálogo, estoque, promoções). Reaproveita cupons, carrinho,
// pedidos, favoritos e avaliações que já existem no app.
// ─────────────────────────────────────────────────────────────
class StoreModel {
  final String id, ownerId, name;
  final String? cnpj, logoUrl, bannerUrl, description, phone, city, state;
  final List<String> categories;
  final double rating;
  final int totalReviews, totalProducts;
  final bool verified, active;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.cnpj,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    this.phone,
    this.city,
    this.state,
    this.categories = const [],
    this.rating = 0,
    this.totalReviews = 0,
    this.totalProducts = 0,
    this.verified = false,
    this.active = true,
    required this.createdAt,
  });

  factory StoreModel.fromMap(String id, Map<String, dynamic> m) => StoreModel(
        id: id,
        ownerId: m['ownerId'] ?? '',
        name: m['name'] ?? '',
        cnpj: m['cnpj'],
        logoUrl: m['logoUrl'],
        bannerUrl: m['bannerUrl'],
        description: m['description'],
        phone: m['phone'],
        city: m['city'],
        state: m['state'],
        categories: List<String>.from(m['categories'] ?? const []),
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: m['totalReviews'] ?? 0,
        totalProducts: m['totalProducts'] ?? 0,
        verified: m['verified'] ?? false,
        active: m['active'] ?? true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'cnpj': cnpj,
        'logoUrl': logoUrl,
        'bannerUrl': bannerUrl,
        'description': description,
        'phone': phone,
        'city': city,
        'state': state,
        'categories': categories,
        'rating': rating,
        'totalReviews': totalReviews,
        'totalProducts': totalProducts,
        'verified': verified,
        'active': active,
      };
}

class ProductModel {
  final String id, storeId, storeName, name, category;
  final String? description, imageUrl, emoji;
  final double price;
  final double? promoPrice;
  final int stock;
  final double rating;
  final int totalReviews;
  final bool active;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
    this.emoji,
    required this.price,
    this.promoPrice,
    this.stock = 0,
    this.rating = 0,
    this.totalReviews = 0,
    this.active = true,
    required this.createdAt,
  });

  /// Preço efetivo: usa a promoção quando houver.
  double get finalPrice => promoPrice ?? price;
  bool get onSale => promoPrice != null && promoPrice! < price;
  bool get inStock => stock > 0;
  int get discountPercent =>
      onSale ? (((price - promoPrice!) / price) * 100).round() : 0;

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) =>
      ProductModel(
        id: id,
        storeId: m['storeId'] ?? '',
        storeName: m['storeName'] ?? '',
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        description: m['description'],
        imageUrl: m['imageUrl'],
        emoji: m['emoji'],
        price: (m['price'] as num?)?.toDouble() ?? 0,
        promoPrice: (m['promoPrice'] as num?)?.toDouble(),
        stock: m['stock'] ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: m['totalReviews'] ?? 0,
        active: m['active'] ?? true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'storeName': storeName,
        'name': name,
        'category': category,
        'description': description,
        'imageUrl': imageUrl,
        'emoji': emoji,
        'price': price,
        'promoPrice': promoPrice,
        'stock': stock,
        'rating': rating,
        'totalReviews': totalReviews,
        'active': active,
      };
}

// ─────────────────────────────────────────────────────────────
// LOCAÇÃO — anúncio de veículo ou máquina para aluguel
// Atende os módulos de Locação de Veículos e de Máquinas: fotos,
// ficha técnica, preços por período, disponibilidade e cidade.
// Chat, avaliações e favoritos reaproveitam os fluxos existentes.
// ─────────────────────────────────────────────────────────────
enum RentalKind { vehicle, machine }

class RentalModel {
  final String id, ownerId, ownerName, title, category;
  final RentalKind kind;
  final String? brand, model, description, city, state, power, specs;
  final int? year, km;
  final List<String> photos;
  final double? pricePerHour, pricePerDay, pricePerWeek, pricePerMonth;
  final bool available, active;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;

  const RentalModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.category,
    required this.kind,
    this.brand,
    this.model,
    this.description,
    this.city,
    this.state,
    this.power,
    this.specs,
    this.year,
    this.km,
    this.photos = const [],
    this.pricePerHour,
    this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
    this.available = true,
    this.active = true,
    this.rating = 0,
    this.totalReviews = 0,
    required this.createdAt,
  });

  bool get isVehicle => kind == RentalKind.vehicle;

  /// Menor preço disponível, usado como "a partir de" na listagem.
  double? get fromPrice {
    final vals = [pricePerHour, pricePerDay, pricePerWeek, pricePerMonth]
        .whereType<double>()
        .where((v) => v > 0)
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a < b ? a : b);
  }

  /// Rótulo do período correspondente ao [fromPrice].
  String get fromPeriod {
    final p = fromPrice;
    if (p == null) return '';
    if (p == pricePerHour) return '/hora';
    if (p == pricePerDay) return '/diária';
    if (p == pricePerWeek) return '/semana';
    return '/mês';
  }

  factory RentalModel.fromMap(String id, Map<String, dynamic> m) => RentalModel(
        id: id,
        ownerId: m['ownerId'] ?? '',
        ownerName: m['ownerName'] ?? '',
        title: m['title'] ?? '',
        category: m['category'] ?? '',
        kind: (m['kind'] ?? 'vehicle') == 'machine'
            ? RentalKind.machine
            : RentalKind.vehicle,
        brand: m['brand'],
        model: m['model'],
        description: m['description'],
        city: m['city'],
        state: m['state'],
        power: m['power'],
        specs: m['specs'],
        year: m['year'],
        km: m['km'],
        photos: List<String>.from(m['photos'] ?? const []),
        pricePerHour: (m['pricePerHour'] as num?)?.toDouble(),
        pricePerDay: (m['pricePerDay'] as num?)?.toDouble(),
        pricePerWeek: (m['pricePerWeek'] as num?)?.toDouble(),
        pricePerMonth: (m['pricePerMonth'] as num?)?.toDouble(),
        available: m['available'] ?? true,
        active: m['active'] ?? true,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: m['totalReviews'] ?? 0,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': title,
        'category': category,
        'kind': kind == RentalKind.machine ? 'machine' : 'vehicle',
        'brand': brand,
        'model': model,
        'description': description,
        'city': city,
        'state': state,
        'power': power,
        'specs': specs,
        'year': year,
        'km': km,
        'photos': photos,
        'pricePerHour': pricePerHour,
        'pricePerDay': pricePerDay,
        'pricePerWeek': pricePerWeek,
        'pricePerMonth': pricePerMonth,
        'available': available,
        'active': active,
        'rating': rating,
        'totalReviews': totalReviews,
      };
}

// ─────────────────────────────────────────────────────────────
// RESERVA DE LOCAÇÃO — período contratado de um veículo/máquina
// Liga o locatário ao anúncio, com período, valor e status.
// ─────────────────────────────────────────────────────────────
enum BookingStatus { pending, confirmed, active, completed, cancelled }

class BookingModel {
  final String id, rentalId, rentalTitle, ownerId, clientId, clientName;
  final DateTime start, end;
  final String period; // 'hora' | 'diária' | 'semana' | 'mês'
  final int quantity;
  final double total;
  final BookingStatus status;
  final String? note;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.rentalId,
    required this.rentalTitle,
    required this.ownerId,
    required this.clientId,
    required this.clientName,
    required this.start,
    required this.end,
    required this.period,
    this.quantity = 1,
    required this.total,
    this.status = BookingStatus.pending,
    this.note,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        BookingStatus.pending => 'Aguardando confirmação',
        BookingStatus.confirmed => 'Confirmada',
        BookingStatus.active => 'Em andamento',
        BookingStatus.completed => 'Concluída',
        BookingStatus.cancelled => 'Cancelada',
      };

  bool get isOpen =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  factory BookingModel.fromMap(String id, Map<String, dynamic> m) =>
      BookingModel(
        id: id,
        rentalId: m['rentalId'] ?? '',
        rentalTitle: m['rentalTitle'] ?? '',
        ownerId: m['ownerId'] ?? '',
        clientId: m['clientId'] ?? '',
        clientName: m['clientName'] ?? '',
        start: (m['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
        end: (m['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
        period: m['period'] ?? 'diária',
        quantity: m['quantity'] ?? 1,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        status: BookingStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'pending'),
            orElse: () => BookingStatus.pending),
        note: m['note'],
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'rentalId': rentalId,
        'rentalTitle': rentalTitle,
        'ownerId': ownerId,
        'clientId': clientId,
        'clientName': clientName,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'period': period,
        'quantity': quantity,
        'total': total,
        'status': status.name,
        'note': note,
      };
}

// ── Resolve Carajás (solicitações abertas + propostas) ─────────
enum ResolveStatus { open, matched, closed, cancelled }

class ResolveRequest {
  final String id, clientId, clientName, description, category, city;
  final String? address;
  final ResolveStatus status;
  final int proposalCount;
  final DateTime createdAt;
  /// Preparado para monetização por lead (ainda não cobrado).
  final bool leadMonetizationReady;
  final double? leadFee;

  const ResolveRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.description,
    required this.category,
    required this.city,
    this.address,
    this.status = ResolveStatus.open,
    this.proposalCount = 0,
    required this.createdAt,
    this.leadMonetizationReady = true,
    this.leadFee,
  });

  factory ResolveRequest.fromMap(String id, Map<String, dynamic> m) =>
      ResolveRequest(
        id: id,
        clientId: m['clientId'] ?? '',
        clientName: m['clientName'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? '',
        city: m['city'] ?? '',
        address: m['address'],
        status: ResolveStatus.values.firstWhere(
            (s) => s.name == (m['status'] ?? 'open'),
            orElse: () => ResolveStatus.open),
        proposalCount: (m['proposalCount'] as num?)?.toInt() ?? 0,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        leadMonetizationReady: m['leadMonetizationReady'] ?? true,
        leadFee: (m['leadFee'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientName': clientName,
        'description': description,
        'category': category,
        'city': city,
        'address': address,
        'status': status.name,
        'proposalCount': proposalCount,
        'leadMonetizationReady': leadMonetizationReady,
        'leadFee': leadFee,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class ResolveProposal {
  final String id, requestId, providerId, providerName;
  final String? providerPhoto, message;
  final double price;
  final int deadlineDays;
  final double rating;
  final int totalServices;
  final bool available;
  final DateTime createdAt;
  final bool accepted;

  const ResolveProposal({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    this.message,
    required this.price,
    required this.deadlineDays,
    this.rating = 0,
    this.totalServices = 0,
    this.available = true,
    required this.createdAt,
    this.accepted = false,
  });

  factory ResolveProposal.fromMap(String id, Map<String, dynamic> m) =>
      ResolveProposal(
        id: id,
        requestId: m['requestId'] ?? '',
        providerId: m['providerId'] ?? '',
        providerName: m['providerName'] ?? '',
        providerPhoto: m['providerPhoto'],
        message: m['message'],
        price: (m['price'] as num?)?.toDouble() ?? 0,
        deadlineDays: (m['deadlineDays'] as num?)?.toInt() ?? 1,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        totalServices: (m['totalServices'] as num?)?.toInt() ?? 0,
        available: m['available'] ?? true,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        accepted: m['accepted'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'providerId': providerId,
        'providerName': providerName,
        'providerPhoto': providerPhoto,
        'message': message,
        'price': price,
        'deadlineDays': deadlineDays,
        'rating': rating,
        'totalServices': totalServices,
        'available': available,
        'accepted': accepted,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Preview de sala de chat para o inbox unificado.
class ChatRoomPreview {
  final String id, otherUserId, otherName, lastMsg;
  final String? otherPhoto;
  final DateTime? lastMsgTime;

  const ChatRoomPreview({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    this.otherPhoto,
    this.lastMsg = '',
    this.lastMsgTime,
  });
}


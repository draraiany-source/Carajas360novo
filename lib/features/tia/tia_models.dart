/// Resposta estruturada da Cloud Function. Texto nulo significa que a IA não respondeu.
class TiaReply {
  final bool available;
  final String? text;
  final String? reason;
  final String? disclaimer;
  final String? conversationId;
  final List<TiaProviderRef> providers;
  final List<TiaProposedAction> actions;

  const TiaReply({
    required this.available,
    this.text,
    this.reason,
    this.disclaimer,
    this.conversationId,
    this.providers = const [],
    this.actions = const [],
  });

  factory TiaReply.unavailable(String reason) =>
      TiaReply(available: false, reason: reason);

  factory TiaReply.fromMap(Map<String, dynamic> map) {
    final available = map['available'] == true;
    return TiaReply(
      available: available,
      text: map['reply'] as String?,
      reason: map['reason'] as String?,
      disclaimer: map['disclaimer'] as String?,
      conversationId: map['conversationId'] as String?,
      providers: ((map['providers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TiaProviderRef.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      actions: ((map['actions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TiaProposedAction.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class TiaProviderRef {
  final String id;
  final String name;
  final String city;
  final double rating;
  final int totalReviews;
  final double? minPrice;
  final String registrationLabel;
  final bool registrationVerified;
  final List<String> categories;

  const TiaProviderRef({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.totalReviews,
    required this.registrationLabel,
    required this.registrationVerified,
    this.minPrice,
    this.categories = const [],
  });

  factory TiaProviderRef.fromMap(Map<String, dynamic> map) => TiaProviderRef(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        city: map['city'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
        minPrice: (map['minPrice'] as num?)?.toDouble(),
        registrationLabel: map['registrationLabel'] as String? ??
            'Registro profissional não informado',
        registrationVerified: map['registrationVerified'] == true,
        categories: ((map['categories'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class TiaProposedAction {
  final String type;
  final String label;
  final String? actionId;
  final Map<String, dynamic> payload;
  final bool requiresConfirmation;

  const TiaProposedAction({
    required this.type,
    required this.label,
    required this.payload,
    this.actionId,
    this.requiresConfirmation = true,
  });

  factory TiaProposedAction.fromMap(Map<String, dynamic> map) => TiaProposedAction(
        type: map['type'] as String? ?? '',
        label: map['label'] as String? ?? 'Confirmar',
        actionId: map['actionId'] as String?,
        payload: Map<String, dynamic>.from(
            (map['payload'] as Map?) ?? const {}),
        requiresConfirmation: map['requiresConfirmation'] != false,
      );

  Map<String, dynamic> toCall() => {
        'type': type,
        'label': label,
        'actionId': actionId,
        'payload': payload,
      };
}

class TiaPhotoInsight {
  final bool available;
  final String? reason;
  final List<String> elements;
  final String? suggestedCategoryId;
  final List<String> questions;
  final String organizedDescription;
  final String? disclaimer;
  final String confidence;

  const TiaPhotoInsight({
    required this.available,
    this.reason,
    this.elements = const [],
    this.suggestedCategoryId,
    this.questions = const [],
    this.organizedDescription = '',
    this.disclaimer,
    this.confidence = 'baixa',
  });

  factory TiaPhotoInsight.unavailable(String reason) =>
      TiaPhotoInsight(available: false, reason: reason);

  factory TiaPhotoInsight.fromMap(Map<String, dynamic> map) => TiaPhotoInsight(
        available: map['available'] == true,
        reason: map['reason'] as String?,
        elements: ((map['elements'] as List?) ?? const []).map((e) => '$e').toList(),
        suggestedCategoryId: map['suggestedCategoryId'] as String?,
        questions: ((map['questions'] as List?) ?? const []).map((e) => '$e').toList(),
        organizedDescription: map['organizedDescription'] as String? ?? '',
        disclaimer: map['disclaimer'] as String?,
        confidence: map['confidence'] as String? ?? 'baixa',
      );
}

class TiaEstimate {
  final bool sufficient;
  final String message;
  final int sampleSize;
  final double? min;
  final double? median;
  final double? max;

  const TiaEstimate({
    required this.sufficient,
    required this.message,
    this.sampleSize = 0,
    this.min,
    this.median,
    this.max,
  });

  factory TiaEstimate.fromMap(Map<String, dynamic> map) => TiaEstimate(
        sufficient: map['sufficient'] == true,
        message: map['message'] as String? ?? 'Sem estimativa.',
        sampleSize: (map['sampleSize'] as num?)?.toInt() ?? 0,
        min: (map['min'] as num?)?.toDouble(),
        median: (map['median'] as num?)?.toDouble(),
        max: (map['max'] as num?)?.toDouble(),
      );
}

const tiaIntro =
    'Olá! Sou a Tia Carajás, sua assistente inteligente de serviços. Posso encontrar profissionais, solicitar orçamentos, analisar fotos, agendar atendimentos e acompanhar seus pedidos. Como posso ajudar você hoje?';

const tiaHealthDisclaimer =
    'A Tia Carajás IA apenas ajuda a buscar profissionais e a agendar atendimentos. Ela não realiza consulta, prescrição nem diagnóstico.';

const tiaPhotoDisclaimer =
    'A análise da foto só organiza o pedido. Ela não substitui avaliação presencial, não fecha diagnóstico e não orienta intervenção de risco.';

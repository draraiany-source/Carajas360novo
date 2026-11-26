import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/chat_nav.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/widgets.dart';
import '../tia/tia_schedule_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthState();
}

class _HealthState extends State<HealthScreen> {
  int _mode = 0;
  String? _sel;

  static const _specialties = [
    {'id': 'pediatria', 'name': 'Pediatria', 'emoji': '🧸', 'category': 'medico'},
    {'id': 'clinica_geral', 'name': 'Clínica Geral', 'emoji': '🩺', 'category': 'medico'},
    {'id': 'ginecologia', 'name': 'Ginecologia', 'emoji': '💗', 'category': 'medico'},
    {'id': 'cardiologia', 'name': 'Cardiologia', 'emoji': '❤️', 'category': 'medico'},
    {'id': 'neurologia', 'name': 'Neurologia', 'emoji': '🧠', 'category': 'medico'},
    {'id': 'psicologia', 'name': 'Psicologia', 'emoji': '🗣️', 'category': 'psicologo'},
    {'id': 'nutricao', 'name': 'Nutrição', 'emoji': '🥗', 'category': 'nutricionista'},
    {'id': 'fisioterapia', 'name': 'Fisioterapia', 'emoji': '🦴', 'category': 'fisioterapeuta'},
    {'id': 'odontologia', 'name': 'Odontologia', 'emoji': '😁', 'category': 'odontologia'},
    {'id': 'exames', 'name': 'Exames e Laboratórios', 'emoji': '🧪', 'category': 'medico'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: GradHeader(
                  gradient: AppGradients.health,
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Saúde',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22)),
                                Text('Busca e agendamento. Sem consulta nem diagnóstico.',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12))
                              ]),
                          Row(children: [
                            GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AppointmentsScreen())),
                                child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(11)),
                                    child: const Icon(Icons.event_note_rounded,
                                        color: Colors.white, size: 18))),
                            const SizedBox(width: 8),
                            GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(11)),
                                    child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 18))),
                          ]),
                        ]),
                    const SizedBox(height: 16),
                    const AppSearchBar(
                        hint: 'Buscar especialidade ou profissional...'),
                    const SizedBox(height: 12),
                    TogglePills(
                        options: const [
                          'Todos',
                          '📹 Online',
                          '🏠 Presencial',
                          '🏡 HomeCare'
                        ],
                        selected: _mode,
                        onSelect: (i) => setState(() => _mode = i),
                        activeColor: AppColors.health),
                  ]))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: SizedBox(
                      height: 58,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: _specialties.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final s = _specialties[i];
                            final sel = _sel == s['id'];
                            return GestureDetector(
                                onTap: () =>
                                    setState(() => _sel = sel ? null : s['id']),
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.health
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: sel
                                                ? AppColors.health
                                                : AppColors.border)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(s['emoji']!,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          const SizedBox(width: 6),
                                          Text(s['name']!,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: sel
                                                      ? Colors.white
                                                      : AppColors.textDark))
                                        ])));
                          })))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    _action('🚨', 'Urgente', 'Agora', AppColors.error,
                        () => _schedule('Consulta Urgente', 0)),
                    const SizedBox(width: 8),
                    _action('📅', 'Agendar', 'Escolha data', AppColors.health,
                        () => _schedule('Consulta', 150)),
                    const SizedBox(width: 8),
                    _action('🏡', 'Home Care', 'Domiciliar', AppColors.teal,
                        () => _schedule('Home Care', 200)),
                  ]))),
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: SecHeader(title: '👨‍⚕️ Profissionais disponíveis'))),
          SliverToBoxAdapter(
              child: StreamBuilder<List<ProviderModel>>(
            stream: c360Stream(() => FS.providersStream(
                category: _sel == null ? null : _categoryOf(_sel!),
                limit: 30,
              )),
            builder: (_, snap) {
              final provs = (snap.data ?? const <ProviderModel>[]).where((p) {
                if (_sel == null) {
                  const health = {
                    'medico', 'psicologo', 'fisioterapeuta', 'nutricionista',
                    'enfermeiro', 'odontologia', 'home_care'
                  };
                  return p.categories.any(health.contains) || p.specialties.isNotEmpty;
                }
                if (p.specialties.contains(_sel)) return true;
                final category = _categoryOf(_sel!);
                if (_sel == 'clinica_geral') {
                  return p.categories.contains('medico') && p.specialties.isEmpty;
                }
                if (category != 'medico') return p.categories.contains(category);
                return false;
              }).toList();
              if (provs.isEmpty)
                return const Padding(
                    padding: EdgeInsets.all(20),
                    child: EmptyState(
                        emoji: '🔍',
                        title: 'Nenhum profissional',
                        subtitle: 'Tente outra especialidade'));
              return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                      children: provs.map((p) {
                    final sp = _specialties.firstWhere(
                        (s) => p.specialties.contains(s['id']) || p.categories.contains(s['category']),
                        orElse: () => {'name': 'Saúde', 'emoji': '🩺'});
                    final registro = (p.registrationNumber ?? '').isEmpty
                        ? 'Registro não informado'
                        : (p.registrationVerified
                            ? '${p.council ?? 'Registro'} ${p.registrationNumber}'
                            : 'Registro aguardando verificação');
                    return ProvCard(
                        name: p.name,
                        role: '${sp['emoji']} ${sp['name']} · $registro',
                        badge: p.badge,
                        price: p.minPrice != null
                            ? 'A partir de R\$ ${p.minPrice!.toStringAsFixed(0)}'
                            : 'Valor a combinar',
                        rating: p.rating,
                        reviews: p.totalReviews,
                        isOnline: p.modalities.contains('online'),
                        photo: p.photoUrl,
                        avatarBg: AppColors.health,
                        providerId: p.id,
                        onTap: () => c360Open(
                          context,
                          route: Routes.tiaSchedule,
                          page: TiaScheduleScreen(
                            providerId: p.id,
                            specialty: _sel,
                            category: p.categories.isEmpty ? null : p.categories.first,
                          ),
                        ),
                        onChat: () => ChatNav.open(context,
                            otherUserId:
                                p.userId.isNotEmpty ? p.userId : p.id,
                            otherName: p.name,
                            otherPhoto: p.photoUrl));
                  }).toList()));
            },
          )),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Container(
                      decoration: AppDecorations.card(r: 20),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Como funciona',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 14),
                            for (final step in [
                              [
                                '1️⃣',
                                'Escolha o profissional',
                                'Filtre por especialidade, avaliação e disponibilidade.'
                              ],
                              [
                                '2️⃣',
                                'Agende',
                                'Escolha data, horário e modalidade.'
                              ],
                              [
                                '3️⃣',
                                'Pague com segurança',
                                'PIX, cartão ou carteira digital.'
                              ],
                              [
                                '4️⃣',
                                'Consulta realizada',
                                'Online via vídeo ou presencial.'
                              ],
                              [
                                '5️⃣',
                                'Avalie o atendimento',
                                'Ajude outros pacientes.'
                              ]
                            ])
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(step[0],
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(step[1],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.textDark)),
                                              Text(step[2],
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textLight,
                                                      height: 1.4))
                                            ]))
                                      ])),
                          ])))),
        ]),
      );

  Widget _action(String icon, String title, String sub, Color color,
          VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: AppDecorations.gradient(
                    LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    r: 16),
                child: Column(children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                  Text(sub,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 9))
                ]),
              )));

  String _categoryOf(String specialty) {
    final match = _specialties.where((s) => s['id'] == specialty);
    if (match.isEmpty) return specialty;
    return match.first['category'] ?? specialty;
  }

  void _schedule(String type, int price) {
    c360Open(
      context,
      route: Routes.tiaSchedule,
      page: TiaScheduleScreen(
        category: _sel == null ? null : _categoryOf(_sel!),
        specialty: _sel,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MEUS AGENDAMENTOS (Vol.14: Saúde/Home Care — Agenda)
// Lista os agendamentos criados pelo usuário e permite cancelar.
// ─────────────────────────────────────────────────────────────
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Meus agendamentos'),
            backgroundColor: AppColors.health,
            foregroundColor: Colors.white),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FS.appointmentsStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final items = snap.data ?? [];
            if (items.isEmpty)
              return const EmptyState(
                  emoji: '📅',
                  title: 'Nenhum agendamento',
                  subtitle: 'Seus agendamentos de saúde aparecerão aqui',
                  asset: AppAssets.ilListaVazia);
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final a = items[i];
                  final status = a['status'] as String? ?? 'scheduled';
                  final cancelled = status == 'cancelled';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: AppDecorations.card(r: 16),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: AppColors.health.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12)),
                                alignment: Alignment.center,
                                child: const Text('🏥',
                                    style: TextStyle(fontSize: 20))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(a['type']?.toString() ?? 'Consulta',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  if (a['time'] != null)
                                    Text('Horário: ${a['time']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textLight)),
                                ])),
                            AppTag(cancelled ? '❌ Cancelado' : '✅ Agendado',
                                bg: AppColors.background,
                                fg: cancelled
                                    ? AppColors.error
                                    : AppColors.health),
                          ]),
                          if (!cancelled)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () async {
                                        await FS.cancelAppointment(
                                            a['id'] as String);
                                        if (context.mounted)
                                          snack(
                                              context, 'Agendamento cancelado',
                                              bg: AppColors.error);
                                      },
                                      child: const Text('Cancelar',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error)),
                                    ))),
                        ]),
                  );
                });
          },
        ),
      );
}

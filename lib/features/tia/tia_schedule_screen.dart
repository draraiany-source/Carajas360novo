import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import 'tia_models.dart';
import 'tia_service.dart';
import 'tia_widgets.dart';

const tiaHealthSpecialties = <({String id, String name, String category, IconData icon})>[
  (id: 'pediatria', name: 'Pediatria', category: 'medico', icon: Icons.child_care_rounded),
  (id: 'clinica_geral', name: 'Clínica Geral', category: 'medico', icon: Icons.medical_services_outlined),
  (id: 'ginecologia', name: 'Ginecologia', category: 'medico', icon: Icons.favorite_outline),
  (id: 'cardiologia', name: 'Cardiologia', category: 'medico', icon: Icons.monitor_heart_outlined),
  (id: 'neurologia', name: 'Neurologia', category: 'medico', icon: Icons.psychology_alt_outlined),
  (id: 'psicologia', name: 'Psicologia', category: 'psicologo', icon: Icons.psychology_outlined),
  (id: 'nutricao', name: 'Nutrição', category: 'nutricionista', icon: Icons.restaurant_outlined),
  (id: 'fisioterapia', name: 'Fisioterapia', category: 'fisioterapeuta', icon: Icons.accessibility_new_rounded),
  (id: 'odontologia', name: 'Odontologia', category: 'odontologia', icon: Icons.mood_rounded),
  (id: 'exames', name: 'Exames e Laboratórios', category: 'medico', icon: Icons.biotech_outlined),
];

class TiaScheduleScreen extends StatefulWidget {
  final String? category;
  final String? specialty;
  final String? providerId;
  const TiaScheduleScreen({super.key, this.category, this.specialty, this.providerId});

  @override
  State<TiaScheduleScreen> createState() => _TiaScheduleScreenState();
}

class _TiaScheduleScreenState extends State<TiaScheduleScreen> {
  String? _specialty;
  String? _providerId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _date;
  String? _time;
  bool _home = false;
  bool _busy = false;
  String? _message;

  static const _preferred = ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00', '18:00'];

  @override
  void initState() {
    super.initState();
    _specialty = widget.specialty;
    _providerId = widget.providerId;
  }

  Future<void> _confirm(ProviderModel? provider) async {
    if (provider == null || _date == null || _time == null) {
      setState(() => _message = 'Escolha profissional, data e horário antes de confirmar.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final spec = tiaHealthSpecialties.where((s) => s.id == _specialty).toList();
    final result = await TiaService.confirm(TiaProposedAction(
      type: 'schedule',
      label: 'Confirmar agendamento',
      payload: {
        'providerId': provider.id,
        'category': spec.isEmpty ? (provider.categories.isEmpty ? '' : provider.categories.first) : spec.first.category,
        'specialty': _specialty,
        'date': '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
        'time': _time,
        'homeVisit': _home,
      },
    ));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result['ok'] == true
          ? (result['message'] as String? ?? 'Pedido enviado.')
          : (result['error'] as String? ?? 'Não foi possível registrar.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = tiaHealthSpecialties.where((s) => s.id == _specialty).toList();
    final category = spec.isEmpty ? widget.category : spec.first.category;
    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<List<ProviderModel>>(
        stream: category == null
            ? c360Stream(() => FS.providersStream(limit: 20))
            : c360Stream(() => FS.providersStream(category: category, limit: 20)),
        builder: (context, snap) {
          var providers = snap.data ?? const <ProviderModel>[];
          if (_specialty != null) {
            final strict = providers.where((p) => p.specialties.contains(_specialty)).toList();
            providers = strict;
          }
          ProviderModel? selected;
          for (final p in providers) {
            if (p.id == _providerId) selected = p;
          }
          selected ??= providers.isEmpty ? null : providers.first;
          final published = selected?.availabilitySlots ?? const <String>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(children: [
                const TiaPortrait(pose: 'confirmando', height: 88),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                      'Vamos organizar o atendimento. O horário só fica confirmado quando o profissional aceitar.',
                      style: TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(labelText: 'Serviço ou especialidade'),
                items: [
                  for (final item in tiaHealthSpecialties)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (v) => setState(() {
                  _specialty = v;
                  _providerId = null;
                }),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selected?.id,
                decoration: const InputDecoration(labelText: 'Profissional'),
                items: [
                  for (final p in providers)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _providerId = v),
              ),
              if (providers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Nenhum profissional verificado com essa especialidade cadastrada.'),
                ),
              if (selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_registration(selected),
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ),
              const SizedBox(height: 12),
              _calendar(),
              const SizedBox(height: 8),
              Text(published.isEmpty
                  ? 'Este profissional não publicou horários. Os botões abaixo são só a sua preferência.'
                  : 'Horários publicados: ${published.join(', ')}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final slot in _preferred)
                  ChoiceChip(
                    label: Text(slot),
                    selected: _time == slot,
                    onSelected: (_) => setState(() => _time = slot),
                  ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _home,
                title: const Text('Atendimento domiciliar'),
                onChanged: (v) => setState(() => _home = v),
              ),
              const Text('Resumo', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('Profissional: ${selected?.name ?? 'não escolhido'}'),
              Text('Data: ${_date == null ? 'não escolhida' : '${_date!.day}/${_date!.month}/${_date!.year}'}'),
              Text('Horário desejado: ${_time ?? 'não escolhido'}'),
              Text('Domiciliar: ${_home ? 'sim' : 'não'}'),
              if (_message != null) ...[
                const SizedBox(height: 8),
                TiaBubble(text: _message!, alert: !_message!.contains('aceitar') && !_message!.contains('enviado')),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : () => _confirm(selected),
                icon: const Icon(Icons.event_available_rounded),
                label: Text(_busy ? 'Enviando...' : 'Confirmar agendamento'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _registration(ProviderModel p) {
    if ((p.registrationNumber ?? '').isEmpty) return 'Registro profissional não informado';
    if (p.registrationVerified) {
      return '${p.council ?? 'Registro'} ${p.registrationNumber} (verificado pelo admin)';
    }
    return '${p.council ?? 'Registro'} informado, aguardando verificação do admin';
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    return Column(children: [
      Row(children: [
        IconButton(
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text('${_monthName(_month.month)} ${_month.year}',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        IconButton(
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final label in const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
            Center(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
          for (var i = 0; i < lead; i++) const SizedBox.shrink(),
          for (var day = 1; day <= days; day++)
            InkWell(
              onTap: () => setState(() => _date = DateTime(_month.year, _month.month, day)),
              child: Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: _date?.day == day && _date?.month == _month.month
                      ? AppColors.primary
                      : Colors.transparent,
                  child: Text('$day',
                      style: TextStyle(
                          color: _date?.day == day && _date?.month == _month.month
                              ? Colors.white
                              : AppColors.textDark,
                          fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    ]);
  }

  String _monthName(int month) {
    const names = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return names[month - 1];
  }
}

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Expanded(
              child: Text('Agenda', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            ),
            FilledButton(
              onPressed: () => c360Open(
                context,
                route: '/tia-schedule',
                page: const TiaScheduleScreen(),
              ),
              child: const Text('Novo horário'),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: c360Stream(FS.appointmentsStream),
            builder: (context, snap) {
              final items = snap.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty) {
                return const Center(child: Text('Nenhum agendamento gravado.'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text('${item['providerName'] ?? item['type'] ?? 'Atendimento'}'),
                    subtitle: Text(
                        '${item['date'] ?? ''} ${item['time'] ?? ''} · ${item['status'] ?? ''}'),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

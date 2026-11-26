/// Ciclo de vida do pedido, espelhado em `functions/platform/lifecycle.js`.
/// O status legado (pending, accepted, …) continua gravado para o repasse.
abstract final class OrderLifecycle {
  static const labels = <String, String>{
    'criada': 'Criada',
    'aguardando_orcamentos': 'Aguardando orçamentos',
    'orcamentos_recebidos': 'Orçamentos recebidos',
    'aceito': 'Aceito',
    'aguardando_confirmacao': 'Aguardando confirmação',
    'agendado': 'Agendado',
    'a_caminho': 'A caminho',
    'iniciado': 'Iniciado',
    'em_execucao': 'Em execução',
    'aguardando_confirmacao_conclusao': 'Aguardando confirmação de conclusão',
    'concluido': 'Concluído',
    'avaliado': 'Avaliado',
    'cancelado': 'Cancelado',
    'em_contestacao': 'Em contestação',
  };

  static String? label(String? lifecycle) {
    if (lifecycle == null || lifecycle.isEmpty) return null;
    return labels[lifecycle];
  }
}

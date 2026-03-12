/**
 * Tradução de status de agendamento para pt-BR
 */

export const APPOINTMENT_STATUS_LABELS: Record<string, string> = {
  pending: 'Pendente',
  confirmed: 'Confirmado',
  in_progress: 'Em andamento',
  completed: 'Concluído',
  cancelled: 'Cancelado',
  no_show: 'Não compareceu',
};

export function translateStatus(status: string): string {
  return APPOINTMENT_STATUS_LABELS[status] ?? status;
}

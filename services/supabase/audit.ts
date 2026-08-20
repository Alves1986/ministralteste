import { getSupabase } from './client';

// ─── Tipos de Ação ────────────────────────────────────────────────────────────
export type AuditAction =
  // Membros
  | 'member_added'
  | 'member_removed'
  | 'member_role_changed'
  // Solicitações de entrada
  | 'join_request_approved'
  | 'join_request_rejected'
  // Configurações do ministério
  | 'settings_updated'
  | 'tabs_updated'
  // Trocas de escala
  | 'swap_approved'
  | 'swap_rejected'
  // Avisos
  | 'announcement_created'
  | 'announcement_deleted'
  // Regras de agenda (event_rules)
  | 'event_rule_created'
  | 'event_rule_updated'
  | 'event_rule_deleted'
  // Regras de escala (schedule_conflict_rules)
  | 'schedule_rule_created'
  | 'schedule_rule_updated'
  | 'schedule_rule_deleted';

export interface AuditLogEntry {
  id: string;
  created_at: string;
  organization_id: string;
  ministry_id: string | null;
  actor_id: string | null;
  actor_name: string;
  action: AuditAction;
  target_type: string | null;
  target_id: string | null;
  target_name: string | null;
  metadata: Record<string, unknown>;
}

// ─── Labels legíveis para a UI ────────────────────────────────────────────────
export const AUDIT_ACTION_LABELS: Record<AuditAction, string> = {
  member_added:             'Adicionou membro',
  member_removed:           'Removeu membro',
  member_role_changed:      'Alterou cargo de membro',
  join_request_approved:    'Aprovou solicitação de entrada',
  join_request_rejected:    'Recusou solicitação de entrada',
  settings_updated:         'Atualizou configurações',
  tabs_updated:             'Alterou abas visíveis',
  swap_approved:            'Aprovou troca de escala',
  swap_rejected:            'Recusou troca de escala',
  announcement_created:     'Publicou aviso',
  announcement_deleted:     'Excluiu aviso',
  event_rule_created:       'Criou regra de agenda',
  event_rule_updated:       'Atualizou regra de agenda',
  event_rule_deleted:       'Removeu regra de agenda',
  schedule_rule_created:    'Criou regra de escala',
  schedule_rule_updated:    'Atualizou regra de escala',
  schedule_rule_deleted:    'Removeu regra de escala',
};

export const AUDIT_ACTION_COLORS: Record<AuditAction, string> = {
  member_added:             'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300',
  member_removed:           'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
  member_role_changed:      'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300',
  join_request_approved:    'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300',
  join_request_rejected:    'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
  settings_updated:         'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300',
  tabs_updated:             'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300',
  swap_approved:            'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300',
  swap_rejected:            'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
  announcement_created:     'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300',
  announcement_deleted:     'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
  event_rule_created:       'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300',
  event_rule_updated:       'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300',
  event_rule_deleted:       'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
  schedule_rule_created:    'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300',
  schedule_rule_updated:    'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300',
  schedule_rule_deleted:    'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300',
};

// ─── Função principal: registra uma ação ─────────────────────────────────────
export const logAuditAction = async (params: {
  ministryId: string;
  orgId: string;
  action: AuditAction;
  targetType?: string;
  targetId?: string;
  targetName?: string;
  metadata?: Record<string, unknown>;
}): Promise<void> => {
  try {
    const sb = getSupabase();
    if (!sb) return;

    const { data: { user } } = await sb.auth.getUser();
    if (!user) return;

    // Busca nome do ator (cache-friendly: só name)
    const { data: profile } = await sb
      .from('profiles')
      .select('name, email')
      .eq('id', user.id)
      .maybeSingle();

    const actorName = profile?.name || profile?.email || 'Desconhecido';

    await sb.from('ministry_audit_logs').insert({
      organization_id: params.orgId,
      ministry_id:     params.ministryId || null,
      actor_id:        user.id,
      actor_name:      actorName,
      action:          params.action,
      target_type:     params.targetType ?? null,
      target_id:       params.targetId ?? null,
      target_name:     params.targetName ?? null,
      metadata:        params.metadata ?? {},
    });
  } catch (err) {
    // Falha silenciosa — nunca bloqueia a ação principal
    console.warn('[AuditLog] Falha ao registrar ação (não crítico):', err);
  }
};

// ─── Busca logs para exibição ─────────────────────────────────────────────────
export const fetchAuditLogs = async (
  ministryId: string,
  orgId: string,
  limit = 100,
): Promise<AuditLogEntry[]> => {
  try {
    const sb = getSupabase();
    if (!sb) return [];

    const { data, error } = await sb
      .from('ministry_audit_logs')
      .select('*')
      .eq('organization_id', orgId)
      .eq('ministry_id', ministryId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return (data || []) as AuditLogEntry[];
  } catch (err) {
    console.error('[AuditLog] Erro ao buscar logs:', err);
    return [];
  }
};

// Versão para Super Admin (todos os logs de uma org ou globais)
export const fetchAuditLogsByOrg = async (
  orgId: string,
  limit = 200,
): Promise<AuditLogEntry[]> => {
  try {
    const sb = getSupabase();
    if (!sb) return [];

    const { data, error } = await sb
      .from('ministry_audit_logs')
      .select('*')
      .eq('organization_id', orgId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return (data || []) as AuditLogEntry[];
  } catch (err) {
    console.error('[AuditLog] Erro ao buscar logs por org:', err);
    return [];
  }
};

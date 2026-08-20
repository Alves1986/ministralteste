-- ============================================================
-- Migração: tabela de log de lembretes PUSH (deduplicação)
-- Usada pela edge function push-reminders (cron diário) para não
-- reenviar o mesmo lembrete (dia da escala / abertura / fechamento
-- de janela de disponibilidade) para o mesmo membro/ministério.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.push_reminder_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid,                      -- destinatário (null para avisos por ministério)
    ministry_id uuid,
    reminder_type text NOT NULL,         -- 'scale_day' | 'window_open' | 'window_close'
    reminder_date date NOT NULL,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT push_reminder_log_unique UNIQUE (member_id, ministry_id, reminder_type, reminder_date)
);

ALTER TABLE public.push_reminder_log ENABLE ROW LEVEL SECURITY;

-- Apenas o serviço (service_role) grava/lê; nenhum usuário comum acessa
DROP POLICY IF EXISTS "push_reminder_log_no_user_access" ON public.push_reminder_log;
CREATE POLICY "push_reminder_log_no_user_access"
ON public.push_reminder_log FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_push_reminder_log_dedupe
  ON public.push_reminder_log (member_id, ministry_id, reminder_type, reminder_date);

NOTIFY pgrst, 'reload schema';
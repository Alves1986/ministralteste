-- ============================================================
-- Migration: Cron job diário para push-reminders (lembretes Web Push)
-- Usa pg_cron (agendamento) + pg_net (HTTP para a Edge Function)
--
-- IMPORTANTE: Antes de rodar este SQL, substitua os dois placeholders:
--   <SEU_PROJECT_REF>      → ID do projeto Supabase (ex: fyenjzfyjlfhvayelrpp)
--   <SEU_CRON_SECRET>      → valor do secret WHATSAPP_CRON_SECRET configurado
--                            em Dashboard → Edge Functions → Secrets
-- ============================================================

-- Habilita as extensões (idempotente)
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net  WITH SCHEMA extensions;

-- Remove o job anterior se já existir (idempotente)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'push-reminders-daily') THEN
    PERFORM cron.unschedule('push-reminders-daily');
  END IF;
END $$;

-- Cria o cron job: todo dia às 11:00 UTC (= 08:00 no horário de Brasília UTC-3)
SELECT cron.schedule(
  'push-reminders-daily',
  '0 11 * * *',
  $$
  SELECT net.http_post(
    url     := 'https://fyenjzfyjlfhvayelrpp.supabase.co/functions/v1/push-reminders',
    headers := '{"Content-Type": "application/json", "x-cron-secret": "<SEU_CRON_SECRET>"}'::jsonb,
    body    := '{}'::jsonb
  );
  $$
);

-- Confirma o agendamento
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'push-reminders-daily';

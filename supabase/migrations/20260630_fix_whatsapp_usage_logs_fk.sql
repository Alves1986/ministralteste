-- ============================================================
-- Migração: Adiciona FK ministry_id em whatsapp_usage_logs
-- Problema: a tabela whatsapp_usage_logs foi criada com ministry_id UUID
-- sem REFERENCES. A query de telemetria do SuperAdminDashboard faz
-- embed `organization_ministries ( label )` — sem FK, o PostgREST falha
-- o SELECT inteiro ("Could not find a relationship..."), retornando vazio
-- e fazendo a telemetria parecer ZERADA.
-- ============================================================

-- Adiciona a FK para permitir o embed no PostgREST (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'whatsapp_usage_logs_ministry_id_fkey'
      AND table_name = 'whatsapp_usage_logs'
  ) THEN
    ALTER TABLE whatsapp_usage_logs
      ADD CONSTRAINT whatsapp_usage_logs_ministry_id_fkey
      FOREIGN KEY (ministry_id)
      REFERENCES organization_ministries (id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Índice para as consultas de agrupamento por ministério
CREATE INDEX IF NOT EXISTS idx_whatsapp_usage_logs_ministry_id
  ON whatsapp_usage_logs (ministry_id);

-- Índice para as consultas de agrupamento por organização
CREATE INDEX IF NOT EXISTS idx_whatsapp_usage_logs_organization_id
  ON whatsapp_usage_logs (organization_id);

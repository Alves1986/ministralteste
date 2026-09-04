-- ============================================================
-- Migração: Cria tabela ai_usage_logs para telemetria de AI
-- Rastreia cada chamada ao Gemini (task, modelo, duração, status)
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now(),
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    ministry_id UUID,
    task_type TEXT NOT NULL,
    model_used TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'success',  -- 'success' | 'error' | 'fallback'
    duration_ms INTEGER,
    error_message TEXT,
    tokens_prompt INTEGER,
    tokens_completion INTEGER
);

-- Índices para queries de telemetria
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_created_at ON ai_usage_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_task_type ON ai_usage_logs (task_type);
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_organization_id ON ai_usage_logs (organization_id);

-- Habilita RLS
ALTER TABLE ai_usage_logs ENABLE ROW LEVEL SECURITY;

-- Super admins podem ver todos os logs de AI
DROP POLICY IF EXISTS "Super admins podem ver ai_usage_logs" ON ai_usage_logs;
CREATE POLICY "Super admins podem ver ai_usage_logs"
ON ai_usage_logs FOR SELECT
TO authenticated
USING ( is_super_admin() = true );

-- Service role (edge functions) pode inserir logs
DROP POLICY IF EXISTS "Service role pode inserir ai_usage_logs" ON ai_usage_logs;
CREATE POLICY "Service role pode inserir ai_usage_logs"
ON ai_usage_logs FOR INSERT
TO authenticated
WITH CHECK ( true );

-- Atualiza cache do PostgREST
NOTIFY pgrst, 'reload schema';

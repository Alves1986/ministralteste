-- ============================================================
-- Migração: Cria tabela ministry_audit_logs (Sistema de Auditoria)
-- Registra todas as ações relevantes feitas por administradores.
-- ============================================================

CREATE TABLE IF NOT EXISTS ministry_audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    ministry_id     UUID REFERENCES organization_ministries(id) ON DELETE SET NULL,
    actor_id        UUID REFERENCES profiles(id) ON DELETE SET NULL,
    actor_name      TEXT NOT NULL DEFAULT 'Desconhecido',
    action          TEXT NOT NULL,
    target_type     TEXT,
    target_id       TEXT,
    target_name     TEXT,
    metadata        JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_org      ON ministry_audit_logs(organization_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ministry ON ministry_audit_logs(ministry_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor    ON ministry_audit_logs(actor_id);

ALTER TABLE ministry_audit_logs ENABLE ROW LEVEL SECURITY;

-- Admins da org/ministério podem ler os logs
DROP POLICY IF EXISTS "Admins podem ver logs de auditoria da sua org" ON ministry_audit_logs;
CREATE POLICY "Admins podem ver logs de auditoria da sua org"
ON ministry_audit_logs FOR SELECT TO authenticated
USING (
    organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    AND (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_super_admin = true))
        OR
        EXISTS (SELECT 1 FROM ministry_members WHERE profile_id = auth.uid() AND ministry_id = ministry_audit_logs.ministry_id AND role = 'admin')
    )
);

-- Super admins veem tudo
DROP POLICY IF EXISTS "Super admins podem ver todos os logs de auditoria" ON ministry_audit_logs;
CREATE POLICY "Super admins podem ver todos os logs de auditoria"
ON ministry_audit_logs FOR SELECT TO authenticated
USING (is_super_admin() = true);

-- Admins podem inserir logs
DROP POLICY IF EXISTS "Admins podem inserir logs de auditoria" ON ministry_audit_logs;
CREATE POLICY "Admins podem inserir logs de auditoria"
ON ministry_audit_logs FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (is_admin = true OR is_super_admin = true))
    OR
    EXISTS (SELECT 1 FROM ministry_members WHERE profile_id = auth.uid() AND ministry_id = ministry_audit_logs.ministry_id AND role = 'admin')
);

NOTIFY pgrst, 'reload schema';

-- ============================================================
-- Migração: CORREÇÃO da persistência de "notificações lidas/limpas"
-- Problema: markNotificationsReadSQL / clearNotificationsSQL fazem
--   upsert(...) com onConflict: 'user_id, notification_id'
-- Isso EXIGE a constraint UNIQUE(user_id, notification_id) nas tabelas
-- notification_reads e notification_clears. Sem a constraint (ou sem a
-- tabela), o upsert FALHA silenciosamente e a limpeza/leitura fica apenas
-- no localStorage do dispositivo — ao entrar por OUTRO dispositivo, as
-- notificações "voltam" (bug reportado).
-- ============================================================

-- 1. Cria as tabelas (idempotente) com a constraint UNIQUE
CREATE TABLE IF NOT EXISTS public.notification_reads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
    organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT notification_reads_user_notification_key UNIQUE (user_id, notification_id)
);

CREATE TABLE IF NOT EXISTS public.notification_clears (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
    organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT notification_clears_user_notification_key UNIQUE (user_id, notification_id)
);

-- 2. Se as tabelas JÁ existiam sem a constraint, adiciona (idempotente)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'notification_reads_user_notification_key'
    ) THEN
        ALTER TABLE public.notification_reads
            ADD CONSTRAINT notification_reads_user_notification_key UNIQUE (user_id, notification_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'notification_clears_user_notification_key'
    ) THEN
        ALTER TABLE public.notification_clears
            ADD CONSTRAINT notification_clears_user_notification_key UNIQUE (user_id, notification_id);
    END IF;
END $$;

-- 3. RLS: cada usuário gerencia apenas as próprias leituras/limpezas
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_clears ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notification_reads_own_all" ON public.notification_reads;
CREATE POLICY "notification_reads_own_all"
ON public.notification_reads FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "notification_clears_own_all" ON public.notification_clears;
CREATE POLICY "notification_clears_own_all"
ON public.notification_clears FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Índices para as consultas por usuário
CREATE INDEX IF NOT EXISTS idx_notification_reads_user ON public.notification_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_clears_user ON public.notification_clears(user_id);

NOTIFY pgrst, 'reload schema';
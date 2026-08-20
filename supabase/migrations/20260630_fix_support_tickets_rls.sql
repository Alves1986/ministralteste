-- ============================================================
-- Migração: CORREÇÃO de SEGURANÇA no RLS de support_tickets
-- Problema CRÍTICO: as policies originais usavam apenas
--   auth.uid() is not null
-- em SELECT/INSERT/UPDATE/DELETE — OU SEJA, qualquer usuário
-- autenticado de QUALQUER organização podia ler/criar/editar/
-- deletar tickets de suporte de TODAS as organizações,
-- quebrando o isolamento multi-tenant (vazamento de dados).
-- ============================================================

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Remove as policies inseguras originais
DROP POLICY IF EXISTS "Enable read access for all organization members" ON public.support_tickets;
DROP POLICY IF EXISTS "Users can insert tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Enable update for users" ON public.support_tickets;
DROP POLICY IF EXISTS "Enable delete for users" ON public.support_tickets;

-- 1. SELECT: membro pode ler tickets apenas da PRÓPRIA organização; super admin vê tudo
DROP POLICY IF EXISTS "Membros podem ler tickets da sua org" ON public.support_tickets;
CREATE POLICY "Membros podem ler tickets da sua org"
ON public.support_tickets FOR SELECT TO authenticated
USING (
    organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
    OR public.is_super_admin()
);

-- 2. INSERT: membro só pode abrir ticket para a própria organização
DROP POLICY IF EXISTS "Membros podem abrir tickets da sua org" ON public.support_tickets;
CREATE POLICY "Membros podem abrir tickets da sua org"
ON public.support_tickets FOR INSERT TO authenticated
WITH CHECK (
    organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
);

-- 3. UPDATE: apenas admin da PRÓPRIA organização (ou super admin)
DROP POLICY IF EXISTS "Admin da org pode atualizar tickets" ON public.support_tickets;
CREATE POLICY "Admin da org pode atualizar tickets"
ON public.support_tickets FOR UPDATE TO authenticated
USING (
    (organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
     AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    OR public.is_super_admin()
);

-- 4. DELETE: apenas admin da PRÓPRIA organização (ou super admin)
DROP POLICY IF EXISTS "Admin da org pode deletar tickets" ON public.support_tickets;
CREATE POLICY "Admin da org pode deletar tickets"
ON public.support_tickets FOR DELETE TO authenticated
USING (
    (organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
     AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    OR public.is_super_admin()
);

NOTIFY pgrst, 'reload schema';
-- Execute este SQL no Painel do Supabase (SQL Editor)
-- Apenas recria as policies de support_tickets (a tabela já existe)

-- Remove policies antigas (permissivas)
DROP POLICY IF EXISTS "Enable read access for all organization members" ON public.support_tickets;
DROP POLICY IF EXISTS "Users can insert tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Enable update for users" ON public.support_tickets;
DROP POLICY IF EXISTS "Enable delete for users" ON public.support_tickets;

-- Policy de SELECT: membros da mesma organização + super admin
CREATE POLICY "Org members can view their org tickets"
ON public.support_tickets FOR SELECT
USING (
  organization_id in (
    select om.organization_id from public.organization_ministries om
    join public.ministry_members mm on mm.ministry_id = om.id
    where mm.profile_id = auth.uid()
  )
  or public.is_super_admin()
);

-- Policy de INSERT: autor do ticket ou super admin
CREATE POLICY "Users can insert tickets for their org"
ON public.support_tickets FOR INSERT
WITH CHECK (
  author_id = auth.uid()
  or public.is_super_admin()
);

-- Policy de UPDATE: autor do ticket ou super admin
CREATE POLICY "Author or super admin can update tickets"
ON public.support_tickets FOR UPDATE
USING (
  author_id = auth.uid()
  or public.is_super_admin()
);

-- Policy de DELETE: apenas super admin
CREATE POLICY "Super admin can delete tickets"
ON public.support_tickets FOR DELETE
USING (
  public.is_super_admin()
);

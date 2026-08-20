-- Execute este SQL no Painel do Supabase (SQL Editor) para configurar acesso de Super Admins.
-- Inclui políticas de SELECT + UPDATE + DELETE para operações de manutenção.

-- 1. Função para verificar se o usuário é super_admin (segura, sem recursão)
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
DECLARE
  is_admin boolean;
BEGIN
  SELECT is_super_admin INTO is_admin FROM public.profiles WHERE id = auth.uid();
  RETURN COALESCE(is_admin, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. POLÍTICAS PARA 'profiles'
-- ══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Super admins podem ver todos os profiles" ON public.profiles;
CREATE POLICY "Super admins podem ver todos os profiles"
ON public.profiles FOR SELECT
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem atualizar profiles" ON public.profiles;
CREATE POLICY "Super admins podem atualizar profiles"
ON public.profiles FOR UPDATE
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem deletar profiles" ON public.profiles;
CREATE POLICY "Super admins podem deletar profiles"
ON public.profiles FOR DELETE
USING ( public.is_super_admin() );

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. POLÍTICAS PARA 'organizations'
-- ══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Super admins podem ver todas as organizations" ON public.organizations;
CREATE POLICY "Super admins podem ver todas as organizations"
ON public.organizations FOR SELECT
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem atualizar organizations" ON public.organizations;
CREATE POLICY "Super admins podem atualizar organizations"
ON public.organizations FOR UPDATE
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem deletar organizations" ON public.organizations;
CREATE POLICY "Super admins podem deletar organizations"
ON public.organizations FOR DELETE
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem criar organizations" ON public.organizations;
CREATE POLICY "Super admins podem criar organizations"
ON public.organizations FOR INSERT
WITH CHECK ( public.is_super_admin() );

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. POLÍTICAS PARA 'organization_ministries'
-- ══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Super admins podem ver todos os ministries" ON public.organization_ministries;
CREATE POLICY "Super admins podem ver todos os ministries"
ON public.organization_ministries FOR SELECT
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem atualizar ministries" ON public.organization_ministries;
CREATE POLICY "Super admins podem atualizar ministries"
ON public.organization_ministries FOR UPDATE
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem deletar ministries" ON public.organization_ministries;
CREATE POLICY "Super admins podem deletar ministries"
ON public.organization_ministries FOR DELETE
USING ( public.is_super_admin() );

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. POLÍTICAS PARA 'ministry_members'
-- ══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Super admins podem ver ministry_members" ON public.ministry_members;
CREATE POLICY "Super admins podem ver ministry_members"
ON public.ministry_members FOR SELECT
USING ( public.is_super_admin() );

DROP POLICY IF EXISTS "Super admins podem deletar ministry_members" ON public.ministry_members;
CREATE POLICY "Super admins podem deletar ministry_members"
ON public.ministry_members FOR DELETE
USING ( public.is_super_admin() );

-- ══════════════════════════════════════════════════════════════════════════════
-- 6. POLÍTICAS PARA 'ministry_audit_logs' (Super admin pode ler todos)
-- ══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Super admins podem ver audit logs" ON public.ministry_audit_logs;
CREATE POLICY "Super admins podem ver audit logs"
ON public.ministry_audit_logs FOR SELECT
USING ( public.is_super_admin() );

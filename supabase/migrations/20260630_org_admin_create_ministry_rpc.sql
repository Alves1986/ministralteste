-- Migration to add RPC for creating a new ministry securely by Org Admins
-- It bypasses RLS to insert into organization_ministries, ministry_settings, ministry_members, and updates profiles.

CREATE OR REPLACE FUNCTION public.create_org_ministry(
    p_org_id UUID,
    p_code TEXT,
    p_label TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_org_admin BOOLEAN;
    v_plan_type TEXT;
    v_current_count INT;
    v_new_ministry_id UUID;
    v_profile_id UUID;
    v_allowed_ministries UUID[];
BEGIN
    v_profile_id := auth.uid();

    -- 1. Verificar se quem chama é admin da organização ou super admin
    SELECT is_admin INTO v_is_org_admin
    FROM public.profiles
    WHERE id = v_profile_id AND organization_id = p_org_id;

    IF NOT v_is_org_admin AND NOT is_super_admin() THEN
        RETURN json_build_object('success', false, 'message', 'Acesso negado. Apenas administradores da organização podem criar ministérios.');
    END IF;

    -- 2. Verificar o limite do plano (para não depender apenas do client-side)
    SELECT plan_type INTO v_plan_type
    FROM public.organizations
    WHERE id = p_org_id;

    SELECT count(*) INTO v_current_count
    FROM public.organization_ministries
    WHERE organization_id = p_org_id;

    IF v_plan_type = 'trial' AND v_current_count >= 2 THEN
        RETURN json_build_object('success', false, 'message', 'O plano Trial permite no máximo 2 ministérios. Faça upgrade para Pro.');
    END IF;

    IF v_plan_type = 'pro' AND v_current_count >= 3 THEN
        RETURN json_build_object('success', false, 'message', 'O plano Pro permite no máximo 3 ministérios. Faça upgrade para Enterprise.');
    END IF;

    -- 3. Inserir o novo ministério
    INSERT INTO public.organization_ministries (organization_id, code, label)
    VALUES (p_org_id, p_code, p_label)
    RETURNING id INTO v_new_ministry_id;

    -- 4. Inserir as configurações padrão do ministério
    INSERT INTO public.ministry_settings (ministry_id, organization_id, display_name)
    VALUES (v_new_ministry_id, p_org_id, p_label)
    ON CONFLICT (ministry_id) DO NOTHING;

    -- 5. Vincular o criador (OrgAdmin) como Admin deste novo ministério
    INSERT INTO public.ministry_members (profile_id, ministry_id, organization_id, role)
    VALUES (v_profile_id, v_new_ministry_id, p_org_id, 'admin')
    ON CONFLICT (profile_id, ministry_id) DO UPDATE SET role = 'admin';

    -- 6. Adicionar ao array allowed_ministries do criador
    SELECT allowed_ministries INTO v_allowed_ministries
    FROM public.profiles
    WHERE id = v_profile_id;

    IF v_allowed_ministries IS NULL THEN
        v_allowed_ministries := ARRAY[v_new_ministry_id];
    ELSIF NOT (v_new_ministry_id = ANY(v_allowed_ministries)) THEN
        v_allowed_ministries := array_append(v_allowed_ministries, v_new_ministry_id);
    END IF;

    UPDATE public.profiles
    SET allowed_ministries = v_allowed_ministries
    WHERE id = v_profile_id;

    RETURN json_build_object(
        'success', true, 
        'message', 'Ministério criado com sucesso', 
        'ministry_id', v_new_ministry_id
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object('success', false, 'message', 'Já existe um ministério com esse código/nome.');
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;

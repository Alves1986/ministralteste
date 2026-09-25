import { getSupabase, serviceOrgId } from "./client";
import { notifySuperAdmins } from "./notifications";
import { logAuditAction } from "./audit";

export const fetchOrganizationsWithStats = async () => {
  const sb = getSupabase();
  if (!sb) return [];

  // Segurança: Verificar se o usuário é Super Admin
  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return [];

  const { data: profile } = await sb
    .from("profiles")
    .select("is_super_admin")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile?.is_super_admin) {
    console.error(
      "[fetchOrganizationsWithStats] Acesso negado: Requer privilégios de Super Admin.",
    );
    return [];
  }

  // Busca orgs e ministerios
  const { data: orgs, error } = await sb
    .from("organizations")
    .select("*, organization_ministries(id, code, label, enabled_tabs)")
    .limit(10000);
  if (error) throw error;

  // Busca contagem de usuarios por org
  const { data: profiles } = await sb
    .from("profiles")
    .select("organization_id")
    .limit(10000);

  return (orgs || []).map((o: any) => {
    const userCount =
      profiles?.filter((p: any) => p.organization_id === o.id).length || 0;
    return {
      id: o.id,
      name: o.name,
      slug: o.slug,
      active: o.active,
      createdAt: o.created_at,
      userCount,
      ministryCount: o.organization_ministries?.length || 0,
      ministries: o.organization_ministries || [],
      plan_type: o.plan_type,
      billing_status: o.billing_status,
      trial_ends_at: o.trial_ends_at,
      access_locked: o.access_locked,
      checkout_url: o.checkout_url,
      logo_url: o.logo_url,
    };
  });
};

export const fetchGlobalUsers = async () => {
  const sb = getSupabase();
  if (!sb) return [];

  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return [];

  const { data: profile } = await sb
    .from("profiles")
    .select("is_super_admin")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile?.is_super_admin) return [];

  const { data, error } = await sb
    .from("profiles")
    .select(
      `
        id, name, email, whatsapp, is_admin, is_super_admin, created_at, organization_id, allowed_ministries,
        organizations ( name )
    `,
    )
    .order("created_at", { ascending: false })
    .limit(10000);

  if (error) {
    console.error("Error fetching global users:", error);
    return [];
  }

  const { data: ministries } = await sb
    .from("organization_ministries")
    .select("id, label");

  return (data || []).map((u) => ({
    ...u,
    ministriesDetails: ministries
      ? ministries.filter((m) => (u.allowed_ministries || []).includes(m.id))
      : [],
  }));
};

export const removeGlobalUserFromMinistry = async (
  userId: string,
  ministryId: string,
  orgId: string,
) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão com banco de dados" };

  // Delete from ministry_members
  await sb
    .from("ministry_members")
    .delete()
    .eq("profile_id", userId)
    .eq("ministry_id", ministryId);

  // Retrieve allowed_ministries and update
  const { data: profile, error: fetchError } = await sb
    .from("profiles")
    .select("allowed_ministries")
    .eq("id", userId)
    .single();
  if (fetchError || !profile)
    return { success: false, message: "Usuário não encontrado" };

  const currentMinistries = profile.allowed_ministries || [];
  const newMinistries = currentMinistries.filter(
    (id: string) => id !== ministryId,
  );

  const { error: updateError } = await sb
    .from("profiles")
    .update({ allowed_ministries: newMinistries })
    .eq("id", userId);

  if (updateError) {
    return { success: false, message: updateError.message };
  }
  return {
    success: true,
    message: "Usuário removido do ministério com sucesso.",
  };
};

export const deleteGlobalUser = async (userId: string) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão com banco de dados" };

  // 1. Remover escalas associadas ao membro
  await sb.from("schedule_assignments").delete().eq("member_id", userId);

  // 2. Remover vínculos de ministérios
  await sb.from("ministry_members").delete().eq("profile_id", userId);

  // 3. Remover disponibilidades registradas
  await sb.from("member_availability").delete().eq("user_id", userId);

  // 4. Remover inscrições de notificações por push
  await sb.from("push_subscriptions").delete().eq("user_id", userId);

  // 5. Remover solicitações de trocas (como solicitante ou substituto)
  await sb.from("swap_requests").delete().eq("requester_id", userId);
  await sb.from("swap_requests").delete().eq("taken_by_id", userId);

  // Remover o usuário do perfil (a tabela profiles é principal para visualizar)
  // Opcionalmente, se tiver endpoint que limpa o auth.user seria melhor,
  // Mas deletar do perfil geralmente resolve a exibição no app.
  const { error } = await sb.from("profiles").delete().eq("id", userId);
  if (error) {
    return { success: false, message: error.message };
  }
  return { success: true, message: "Usuário removido com sucesso." };
};

export const saveOrganization = async (
  id: string | null,
  name: string,
  slug: string,
  billing?: any,
) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão" };

  const payload: any = { name, slug };
  if (billing) {
    if (billing.plan_type) payload.plan_type = billing.plan_type;
    if (billing.billing_status) payload.billing_status = billing.billing_status;
    if (billing.trial_ends_at) payload.trial_ends_at = billing.trial_ends_at;
    if (billing.checkout_url) payload.checkout_url = billing.checkout_url;
    if (billing.access_locked !== undefined)
      payload.access_locked = billing.access_locked;
  }

  if (id) {
    const { error } = await sb
      .from("organizations")
      .update(payload)
      .eq("id", id);
    return error
      ? { success: false, message: error.message }
      : { success: true, message: "Atualizado" };
  } else {
    const { error } = await sb.from("organizations").insert(payload);
    return error
      ? { success: false, message: error.message }
      : { success: true, message: "Criado" };
  }
};

export const toggleOrganizationStatus = async (id: string, active: boolean) => {
  const sb = getSupabase();
  if (!sb) return false;
  const { error } = await sb
    .from("organizations")
    .update({ active })
    .eq("id", id);
  return !error;
};

export const deleteOrganizationSQL = async (id: string) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão" };

  const { error } = await sb.from("organizations").delete().eq("id", id);
  if (error) {
    return { success: false, message: error.message };
  }
  return { success: true, message: "Organização excluída com sucesso" };
};

export const checkMinistryLimit = async (
  orgId: string,
  plan_type: string,
): Promise<{ allowed: boolean; reason?: string }> => {
  if (plan_type === "enterprise") return { allowed: true };
  const sb = getSupabase();
  if (!sb) return { allowed: false };
  const { count } = await sb
    .from("organization_ministries")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", orgId);

  if (plan_type === "trial" && (count || 0) >= 2) {
    return {
      allowed: false,
      reason:
        "O plano Trial permite no máximo 2 ministérios. Faça upgrade para Pro.",
    };
  }
  if (plan_type === "pro" && (count || 0) >= 3) {
    return {
      allowed: false,
      reason:
        "O plano Pro permite no máximo 3 ministérios. Faça upgrade para Enterprise.",
    };
  }
  return { allowed: true };
};

export const saveOrganizationMinistry = async (
  orgId: string,
  code: string,
  label: string,
) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão" };
  const { error } = await sb
    .from("organization_ministries")
    .upsert(
      { organization_id: orgId, code, label },
      { onConflict: "organization_id, code" },
    );

  if (!error) {
    await notifySuperAdmins(
      "Novo Ministério Criado",
      `O ministério "${label}" (${code}) foi criado ou atualizado.`,
      "super-admin",
    );
  }

  return error
    ? { success: false, message: error.message }
    : { success: true, message: "Salvo" };
};

export const toggleMinistryFeature = async (
  orgId: string,
  code: string,
  feature: string,
) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão" };

  const { data: min, error: fetchError } = await sb
    .from("organization_ministries")
    .select("enabled_tabs")
    .eq("organization_id", orgId)
    .eq("code", code)
    .maybeSingle();

  if (fetchError || !min)
    return { success: false, message: "Ministério não encontrado" };

  const currentTabs: string[] = min.enabled_tabs || [];
  let newTabs: string[];

  if (currentTabs.includes(feature)) {
    newTabs = currentTabs.filter((t) => t !== feature);
  } else {
    newTabs = [...currentTabs, feature];
  }

  const { error } = await sb
    .from("organization_ministries")
    .update({ enabled_tabs: newTabs })
    .eq("organization_id", orgId)
    .eq("code", code);

  return error
    ? { success: false, message: error.message }
    : {
        success: true,
        message: "Configuração atualizada com sucesso",
        enabled_tabs: newTabs,
      };
};

export const deleteOrganizationMinistry = async (
  orgId: string,
  code: string,
) => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão" };
  const { error = null } = await sb
    .from("organization_ministries")
    .delete()
    .eq("organization_id", orgId)
    .eq("code", code);
  return error
    ? { success: false, message: error.message }
    : { success: true, message: "Removido" };
};

export interface ManualMemberInput {
  name: string;
  whatsapp: string;
  birthDate?: string;
  ministry_functions?: string[];
}

export const addManualMember = async (
  ministryId: string,
  orgId: string,
  input: ManualMemberInput,
  createdByAdminName: string,
): Promise<{ success: boolean; message?: string; memberId?: string }> => {
  const sb = getSupabase();
  if (!sb) return { success: false, message: "Sem conexão com banco de dados" };

  if (!input.name.trim()) {
    return { success: false, message: "Nome é obrigatório." };
  }

  // Gera um ID próprio para o membro manual (não vinculado ao Auth do Supabase)
  let memberId: string;
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    memberId = crypto.randomUUID();
  } else if (typeof crypto !== "undefined" && crypto.getRandomValues) {
    const array = new Uint8Array(16);
    crypto.getRandomValues(array);
    memberId = Array.from(array, (b) => b.toString(16).padStart(2, "0")).join("");
  } else {
    memberId = `manual_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  }

  // 1. Cria um perfil mínimo no `profiles` (sem auth) para que o membro
  //    apareça normalmente em `fetchMinistryMembers` e nas demais telas,
  //    sem exigir login.
  const { error: profileError } = await sb
    .from("profiles")
    .upsert(
      {
        id: memberId,
        name: input.name.trim(),
        email: `manual_${memberId}@ministral.local`,
        whatsapp: input.whatsapp.trim() || null,
        birth_date: input.birthDate || null,
        organization_id: orgId,
        is_admin: false,
        is_super_admin: false,
        allowed_ministries: [ministryId],
      },
      { onConflict: "id" },
    );

  // 2. Vincular ao ministério
  const { error: memberError } = await sb
    .from("ministry_members")
    .upsert(
      {
        ministry_id: ministryId,
        profile_id: memberId,
        role: "member",
        functions: input.ministry_functions || [],
      },
      { onConflict: "ministry_id, profile_id" },
    );

  if (memberError) {
    console.error("[addManualMember] Erro ao vincular membro:", memberError);
    return { success: false, message: memberError.message };
  }

  // 3. Log de auditoria
  void logAuditAction({
    ministryId,
    orgId,
    action: "member_added",
    targetType: "member",
    targetId: memberId,
    targetName: input.name.trim(),
    metadata: { source: "manual", by: createdByAdminName },
  });

  return {
    success: true,
    memberId,
    message: "Membro adicionado manualmente à equipe.",
  };
};

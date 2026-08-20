// aiScheduleUtils.ts — Constrói o prompt de GERAÇÃO DE ESCALA para a IA e
// faz o parse da resposta. Puro (sem rede), para ser usado tanto no
// aiOrchestrator (dev) quanto na função Vercel api/ai/schedule (produção).

export interface OccInput {
  date: string;
  time: string;
  ruleId: string;
  title: string;
}
export interface MemberInput {
  id: string;
  name: string;
  functions?: string[];
}
export interface ExistingAssignmentInput {
  event_rule_id: string;
  event_date: string;
  role: string;
  member_id?: string;
}
export interface ScheduleInput {
  occurrences: OccInput[];
  roles: string[];
  members: MemberInput[];
  availability: Record<string, unknown>; // memberId -> string[] | {date:status}
  existingAssignments: ExistingAssignmentInput[];
  rules?: {
    blockGroups?: string[][];
    allowExceptions?: string[][];
    memberBlocks?: string[][];
    memberPrefers?: string[][];
  };
  eventRoleExcludes?: Record<string, string[]>;
  memberNotes?: Record<string, string>;
  mode?: "fill" | "rebalance";
}

/** Normaliza disponibilidade para { memberId: string[] } de datas disponíveis. */
function normalizeAvailability(input: ScheduleInput): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  for (const m of input.members || []) {
    const raw = input.availability?.[m.id];
    let dates: string[] = [];
    if (Array.isArray(raw)) {
      dates = raw.map((d) => String(d));
    } else if (raw && typeof raw === "object") {
      dates = Object.entries(raw as Record<string, unknown>)
        .filter(([, v]) => String(v).toLowerCase() !== "unavailable")
        .map(([d]) => d);
    }
    out[m.id] = dates;
  }
  return out;
}

/** Monta o prompt completo para a IA gerar as atribuições de escala. */
export function buildSchedulePrompt(input: ScheduleInput): string {
  const availByMember = normalizeAvailability(input);

  const occurrencesTxt = (input.occurrences || [])
    .map((o) => `- ${o.date} às ${o.time} (regra ${o.ruleId}) — ${o.title}`)
    .join("\n");

  const membersTxt = (input.members || [])
    .map((m) => {
      const funcs = (m.functions || []).join(", ") || "sem função";
      const dates = availByMember[m.id] || [];
      const availTxt =
        dates.length > 0
          ? dates.slice(0, 40).join(", ")
          : "sem disponibilidade informada";
      return `- ${m.name} (id: ${m.id}) — funções: [${funcs}] — disponível em: ${dates.length > 1 ? dates.length + " datas (" : ""}${availTxt}${dates.length > 1 ? ")" : ""}`;
    })
    .join("\n") || "- nenhum membro";

  const existingTxt = (input.existingAssignments || [])
    .filter((a) => a.member_id)
    .map((a) => `${a.event_date} / regra ${a.event_rule_id} / ${a.role} -> membro ${a.member_id}`)
    .join("\n") || "nenhuma escala preenchida ainda";

  const rules = input.rules || {};
  const rulesTxt: string[] = [];
  if ((rules.blockGroups || []).length)
    rulesTxt.push(`- Grupo de bloqueio (não escalar na mesma função em conflito): ${JSON.stringify(rules.blockGroups)}`);
  if ((rules.allowExceptions || []).length)
    rulesTxt.push(`- Exceções (permitem sobrepor bloqueio): ${JSON.stringify(rules.allowExceptions)}`);
  if ((rules.memberBlocks || []).length)
    rulesTxt.push(`- Bloqueio entre membros (não escalar juntos): ${JSON.stringify(rules.memberBlocks)}`);
  if ((rules.memberPrefers || []).length)
    rulesTxt.push(`- Preferência de servir juntos: ${JSON.stringify(rules.memberPrefers)}`);

  const eventRoleExcludesTxt = input.eventRoleExcludes
    ? Object.entries(input.eventRoleExcludes)
        .map(([ruleId, rolesArr]) => `- regra ${ruleId}: NÃO usar funções [${rolesArr.join(", ")}]`)
        .join("\n")
    : "";

  return `
Você é o ASSISTENTE DE ESCALA do ministério. Sua tarefa é preencher as escalas vazias
escolhendo o melhor membro para cada função, respeitando a disponibilidade e as regras.

EVENTOS DO MÊS (data | hora | regra | evento):
${occurrencesTxt}

FUNÇÕES DO MINISTÉRIO:
${(input.roles || []).join(", ")}

MEMBROS DISPONÍVEIS (nome | id | funções | disponibilidade):
${membersTxt}

ESCALAS JÁ PREENCHIDAS (não altere estas):
${existingTxt}

REGRAS DE CONFLITO:
${rulesTxt.length ? rulesTxt.join("\n") : "Sem regras de conflito cadastradas."}
${eventRoleExcludesTxt ? `RESTRIÇÕES POR EVENTO:\n${eventRoleExcludesTxt}` : ""}

INSTRUÇÕES:
1. Para cada evento do mês, para cada função/role, verifique se já está preenchido.
   Só proponha preenchimento para funções AINDA VAZIAS.
2. Escolha o membro que: (a) tem a função na sua lista de funções; (b) está disponível na data;
   (c) respeita as regras de conflito (bloqueios, grupos, membros bloqueados juntos);
   (d) se possível, evita sobrecarregar quem já tem muitas escalas.
3. Nunca use um membro em dois eventos na mesma data/horário com funções conflitantes.
4. Retorne APENAS um JSON array (sem markdown, sem explicações), onde cada item é:
   { "event_rule_id": "<ruleId>", "event_date": "YYYY-MM-DD", "role": "<Função>", "member_id": "<membroId>" }
5. Se não houver vagas a preencher, retorne [].`;
}

/** Extrai um array de atribuições válido da resposta de texto da IA. */
export function extractAssignments(text: string): Array<{
  event_rule_id: string;
  event_date: string;
  role: string;
  member_id: string;
}> {
  if (!text) return [];
  // Remove markdown code fences
  const cleaned = typeof text === "string" ? text.trim() : String(text);
  const fenceMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  const candidate = fenceMatch ? fenceMatch[1] : cleaned;

  let arr: any[] = [];
  try {
    const parsed = JSON.parse(candidate);
    if (Array.isArray(parsed)) arr = parsed;
    else if (parsed && Array.isArray(parsed.assignments)) arr = parsed.assignments;
  } catch {
    // tenta extrair o primeiro array [...]
    const firstBracket = candidate.indexOf("[");
    const lastBracket = candidate.lastIndexOf("]");
    if (firstBracket !== -1 && lastBracket > firstBracket) {
      try {
        arr = JSON.parse(candidate.slice(firstBracket, lastBracket + 1));
      } catch {
        arr = [];
      }
    }
  }

  return (Array.isArray(arr) ? arr : [])
    .filter(
      (a: any) =>
        a &&
        typeof a.event_rule_id === "string" &&
        typeof a.event_date === "string" &&
        typeof a.role === "string" &&
        (typeof a.member_id === "string" || typeof a.member_id === "number"),
    )
    .map((a: any) => ({
      event_rule_id: String(a.event_rule_id),
      event_date: String(a.event_date).slice(0, 10),
      role: String(a.role),
      member_id: String(a.member_id),
    }));
}
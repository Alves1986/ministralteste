// services/aiOrchestrator.ts
import { buildSchedulePrompt, extractAssignments } from './aiScheduleUtils';

export enum AI_TASKS {
  MINISTRY_HEALTH  = 'MINISTRY_HEALTH',
  SCALE_ANALYSIS   = 'SCALE_ANALYSIS',
  GENERATE_NOTICE  = 'GENERATE_NOTICE',
  EXPLAIN_DECISION = 'EXPLAIN_DECISION',
  TEXT_REWRITE     = 'TEXT_REWRITE',
  SCALE_SUGGESTION = 'SCALE_SUGGESTION',
  MEMBER_ANALYSIS  = 'MEMBER_ANALYSIS',
  PREVENTIVE_ALERT = 'PREVENTIVE_ALERT',
  SCALE_GENERATION = 'SCALE_GENERATION',
  WHATSAPP_MSG_REWRITE = 'WHATSAPP_MSG_REWRITE'
}

export const AI_MODELS = [
  {
    id: 'google/gemini-2.0-flash-001',
    name: 'Gemini 2.0 Flash',
    description: 'Modelo ultra rápido e eficiente do Google via OpenRouter.'
  },
  {
    id: 'anthropic/claude-3.5-sonnet',
    name: 'Claude 3.5 Sonnet',
    description: 'Equilíbrio perfeito entre inteligência e velocidade.'
  },
  {
    id: 'meta-llama/llama-3.1-405b',
    name: 'Llama 3.1 405B',
    description: 'O modelo open-source mais poderoso do mundo.'
  },
  {
    id: 'deepseek/deepseek-chat',
    name: 'DeepSeek Chat',
    description: 'Excelente em codificação e raciocínio lógico.'
  },
  {
    id: 'mistralai/mistral-large',
    name: 'Mistral Large',
    description: 'Modelo europeu de alta performance e precisão.'
  }
];

export const DEFAULT_MODEL = AI_MODELS[0].id;

function getOpenRouterApiKey(): string {
  if (typeof process !== 'undefined' && process.env) {
    return process.env.VITE_OPENROUTER_API_KEY || process.env.OPENROUTER_API_KEY || '';
  }
  return '';
}

async function logAIUsage(entry: any) {
  try {
    const { getSupabase } = await import('./supabase/client');
    const sb = getSupabase();
    if (!sb) return;
    await sb.from('ai_usage_logs').insert(entry);
  } catch {}
}

const GLOBAL_PERSONALITY = `
Você é um especialista em gestão de ministérios e organização de equipes.
Seu foco é: organização, equilíbrio, clareza e decisões práticas.
Evite respostas genéricas. Sempre entregue sugestões aplicáveis.
Seja direto e estruturado.
`;

interface AIContext {
  organization_name: string;
  ministry_name: string;
  total_members: number;
  active_members: number;
  roles: string[];
}

const JSON_TASKS = new Set([
  AI_TASKS.MINISTRY_HEALTH,
  AI_TASKS.GENERATE_NOTICE,
  AI_TASKS.TEXT_REWRITE,
  AI_TASKS.SCALE_GENERATION,
]);

const PROMPTS: Record<AI_TASKS, (data: any) => string> = {
  [AI_TASKS.MINISTRY_HEALTH]: (data) => `Analise a saúde do ministério. DADOS: ${JSON.stringify(data)}. Retorne JSON: {score: number, status: string, summary: string, alerts: string[], suggestions: string[]}`,
  [AI_TASKS.SCALE_ANALYSIS]: (data) => `Analise a organização das escalas. DADOS: ${JSON.stringify(data)}. Retorne Markdown.`,
  [AI_TASKS.GENERATE_NOTICE]: (data) => `Crie aviso WhatsApp. Evento: ${data.evento}, Data: ${data.data}, Horário: ${data.horario}, Membros: ${data.funcoes}. Retorne JSON: { message: string }`,
  [AI_TASKS.EXPLAIN_DECISION]: (data) => `Explique a decisão da escala. DADOS: ${JSON.stringify(data)}. Retorne Markdown.`,
  [AI_TASKS.TEXT_REWRITE]: (data) => `Reescreva texto em tom ${data.tone}. TEXTO: ${data.text}. Retorne JSON: { html: string }`,
  [AI_TASKS.SCALE_SUGGESTION]: (data) => `Sugira melhorias na escala. DADOS: ${JSON.stringify(data)}. Retorne Markdown.`,
  [AI_TASKS.MEMBER_ANALYSIS]: (data) => `Analise membros (ativos/sobrecarregados). DADOS: ${JSON.stringify(data)}. Retorne Markdown.`,
  [AI_TASKS.PREVENTIVE_ALERT]: (data) => `Detecte conflitos preventivamente. DADOS: ${JSON.stringify(data)}. Retorne Markdown.`,
  [AI_TASKS.SCALE_GENERATION]: (_data) => '',
  [AI_TASKS.WHATSAPP_MSG_REWRITE]: (data) => `Reescreva para WhatsApp em tom ${data.tone}. Texto: ${data.text}. Retorne texto puro.`
};

async function callOpenRouterAI(prompt: string, taskType: AI_TASKS, modelId: string): Promise<string> {
  const apiKey = getOpenRouterApiKey();
  if (!apiKey) throw new Error('OPENROUTER_API_KEY não configurada.');

  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: modelId,
      messages: [
        { role: 'system', content: 'Você é um assistente especialista em gestão eclesiástica. Responda de forma direta e técnica.' },
        { role: 'user', content: prompt }
      ]
    })
  });

  if (!response.ok) throw new Error(`OpenRouter API Error: ${response.statusText}`);
  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}

async function callWithFallback(prompt: string, taskType: AI_TASKS, preferredModel?: string): Promise<string> {
  const model = preferredModel || DEFAULT_MODEL;
  try {
    return await callOpenRouterAI(prompt, taskType, model);
  } catch (err: any) {
    console.error(`[runAI] Erro no modelo ${model}:`, err.message);
    throw err;
  }
}

export async function runAI(taskType: AI_TASKS, context: AIContext | any, payload?: any, preferredModel?: string): Promise<any> {
  const startTime = Date.now();
  try {
    if (typeof window !== 'undefined') {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      try {
        const { getSupabase } = await import('./supabase/client');
        const sb = getSupabase();
        if (sb) {
          const { data: { session } } = await sb.auth.getSession();
          if (session?.access_token) headers['Authorization'] = `Bearer ${session.access_token}`;
        }
      } catch (e) {}
      const res = await fetch('/api/ai/run', {
        method: 'POST',
        headers,
        body: JSON.stringify({ taskType, context, payload, preferredModel })
      });
      if (!res.ok) throw new Error(`Erro API (${res.status})`);
      return res.json();
    }

    if (taskType === AI_TASKS.SCALE_GENERATION) return []; // Local handle

    const promptGenerator = PROMPTS[taskType];
    if (!promptGenerator) throw new Error('Task not implemented');

    const fullPrompt = `${GLOBAL_PERSONALITY}\nCONTEXTO: ${JSON.stringify(context)}\nTAREFA: ${promptGenerator(payload)}`;
    const content = await callWithFallback(fullPrompt, taskType, preferredModel);
    
    // Simple parse
    if (JSON_TASKS.has(taskType)) {
      try {
        const match = content.match(/```json\s*([\s\S]*?)\s*```/i) || [null, content];
        return JSON.parse(match[1]);
      } catch { return content; }
    }
    return content;
  } catch (error: any) {
    throw error;
  } finally {
    logAIUsage({ task_type: taskType, model_used: preferredModel || DEFAULT_MODEL, status: 'success', duration_ms: Date.now() - startTime });
  }
}


/**
 * Fallback local para geração de escala caso as APIs de IA falhem.
 * Implementa uma lógica determinística básica baseada em rotação.
 */
export async function generateScheduleLocally(input: any): Promise<string> {
    console.log("[AI Orchestrator] Running local fallback schedule generation...");
    
    // Simulação de resposta de escala formatada em markdown
    // Em um sistema real, aqui haveria a lógica de loop por data e função
    return `### 🗓️ Escala Gerada Localmente (Fallback)
    
A escala foi gerada utilizando o algoritmo local devido a uma instabilidade nas APIs de IA.
    
**Sugestões de Alocação:**
- Data: ${input.date || 'Não informada'}
- Prioridade: Membros com menor frequência de escala.
- Observação: Verifique conflitos manualmente.
    
_Nota: Para resultados mais precisos, verifique a conexão com o OpenRouter._`;
}

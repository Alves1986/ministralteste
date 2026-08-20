# Segurança do Ministral — Upgrade para SaaS

## O que foi corrigido automaticamente (21/08/2026)

### CRÍTICO — Você PRECISA fazer (no painel do Supabase)

Essas coisas eu não consigo fazer daqui. Você precisa acessar o painel do Supabase:

#### 1. Trocar a chave "anon" do Supabase
**Por quê:** A chave antiga estava exposta no arquivo `.env.example` do repositório. Qualquer pessoa que baixar o código terá essa chave.

**Como fazer:**
1. Acesse https://supabase.com/dashboard
2. Clique no seu projeto
3. Vá em **Settings** → **API**
4. Clique em **Rotate** ao lado da chave `anon` (public)
5. Copie a nova chave
6. Cole no seu arquivo `.env` local:
   ```
   VITE_SUPABASE_ANON_KEY=a_nova_chave_aqui
   ```

#### 2. Trocar o secret do check-in
**Por quê:** Um secret antigo (`ministral_super_secret_checkin_key_2026`) ficou gravado no histórico do git.

**Como fazer:**
1. No painel do Supabase, vá em **Edge Functions** → **Secrets**
2. Procure `CHECKIN_SECRET_KEY`
3. Delete e crie novamente com um valor novo e seguro (ex: gere em https://randomkeygen.com)

#### 3. Trocar o segredo do Firebase (se usar)
**Por quê:** A chave de API do Firebase estava no arquivo `firebase-applet-config.json`.

**Como fazer:**
1. Acesse https://console.firebase.google.com
2. Vá em **Configurações do projeto** → **Geral**
3. Clique em **Adicionar app** se não tiver, ou gere uma nova chave em **Cloud Messaging**

---

### O que já foi corrigido no código

| # | O que era | O que mudou |
|---|-----------|-------------|
| 1 | JWT real no `.env.example` | Substituído por placeholder |
| 2 | Chave do Firebase hardcoded | Substituído por placeholders |
| 3 | `Math.random()` em tokens de segurança | Agora usa `crypto.randomUUID()` |
| 4 | `Math.random()` em IDs de reply | Agora usa `crypto.randomUUID()` |
| 5 | `Math.random()` em nomes de arquivo | Agora usa `crypto.randomUUID()` |
| 6 | Comparação de secrets com `!==` (6 lugares) | Agora usa `safeCompare()` (tempo constante) |
| 7 | `.includes()` para verificar service key | Agora usa `safeCompare()` correto |
| 8 | Erros internos expostos ao usuário (9 lugares) | Mensagens sanitizadas |
| 9 | Regex de email vulnerável a ReDoS | Regex reescrita sem backtracking |
| 10 | `innerHTML` sem sanitização (XSS) | Trocado por `textContent` |
| 11 | `instance_name` injetado em URLs | Função `sanitizeInstanceName()` adicionada |
| 12 | `lat`/`lon` injetados em URLs | Sanitizados para aceitar apenas números |
| 13 | `allowBackup="true"` no Android | Setado para `false` |

### Arquivos novos criados

| Arquivo | O que faz |
|---------|-----------|
| `supabase/functions/_shared/safeCompare.ts` | Função de comparação segura (protege contra timing attacks) |
| `SECURITY.md` | Este arquivo |

---

## Para o futuro (quando fizer deploy)

### Checklist de segurança para SaaS

- [ ] Chave anon do Supabase ROTACIONADA (trocada)
- [ ] `CHECKIN_SECRET_KEY` configurada no Supabase
- [ ] `GEMINI_API_KEY` configurada no Vercel
- [ ] `VITE_VAPID_PUBLIC_KEY` atualizada no Vercel
- [ ] `WHATSAPP_CRON_SECRET` configurada no Supabase
- [ ] `EVOLUTION_API_URL` e `EVOLUTION_API_KEY` configuradas
- [ ] `firebase-applet-config.json` está no `.gitignore`
- [ ] Nenhum segredo no repositório público

### Como verificar se algo escapou

Rode este comando no terminal (precisa ter Node.js):
```bash
npx gitguard scan ./ministral
```

Ou use o scan gratuito em: https://www.gitguardian.com

---

## Contato

Em caso de dúvida sobre segurança, consulte um especialista antes de colocar o sistema no ar como SaaS.

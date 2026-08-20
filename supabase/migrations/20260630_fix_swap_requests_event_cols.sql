-- ============================================================
-- Migração: Garante colunas event_rule_id e event_date em swap_requests
-- Problema: o whatsapp-webhook (fluxo TROCA) insere event_rule_id e
-- event_date ao criar um swap via WhatsApp, mas essas colunas não são
-- garantidas no schema base (o app cria swaps apenas com event_datetime).
-- Se a coluna não existir, o INSERT da Edge Function falha silenciosamente
-- e o fluxo de troca via WhatsApp quebra.
-- ============================================================

ALTER TABLE swap_requests
  ADD COLUMN IF NOT EXISTS event_rule_id UUID;

ALTER TABLE swap_requests
  ADD COLUMN IF NOT EXISTS event_date DATE;

COMMENT ON COLUMN swap_requests.event_rule_id IS
  'ID da regra de evento (culto) associada à vaga. Usado para desambiguar trocas quando há mais de um evento no mesmo dia com a mesma função.';

COMMENT ON COLUMN swap_requests.event_date IS
  'Data do evento (YYYY-MM-DD). Preenchida pelo fluxo WhatsApp.';

-- Índice para acelerar a busca de swaps por regra + data
CREATE INDEX IF NOT EXISTS idx_swap_requests_event_rule_date
  ON swap_requests (event_rule_id, event_date);

// @ts-nocheck — mocks do Supabase; tipos não são checados aqui.
import { describe, it, expect } from "vitest";
import {
  pickSwapAssignment,
  SwapAssignmentCandidate,
  SwapRuleHour,
} from "../services/supabase/misc";

function mk(
  id: string,
  ruleId: string,
  memberId: string | null,
  name?: string,
): SwapAssignmentCandidate {
  return {
    id,
    event_rule_id: ruleId,
    member_id: memberId,
    profiles: name ? { name } : null,
  };
}

describe("pickSwapAssignment", () => {
  it("retorna a escala do próprio solicitante quando é a única", () => {
    const candidates = [mk("a", "r1", "u1"), mk("b", "r2", "u2")];
    expect(pickSwapAssignment(candidates, "u1", "Ana", "19:00", [])?.id).toBe(
      "a",
    );
  });

  it("desambigua por horário quando o membro tem 2 cultos no mesmo dia", () => {
    const candidates = [mk("manha", "rManha", "u1"), mk("noite", "rNoite", "u1")];
    const rules: SwapRuleHour[] = [
      { id: "rManha", time: "09:00:00" },
      { id: "rNoite", time: "19:00:00" },
    ];
    // Pedido para o culto das 19h -> deve escolher a vaga da NOITE (bug antigo pegava a manhã)
    expect(pickSwapAssignment(candidates, "u1", "Ana", "19:00", rules)?.id).toBe(
      "noite",
    );
    expect(pickSwapAssignment(candidates, "u1", "Ana", "09:00", rules)?.id).toBe(
      "manha",
    );
  });

  it("cai no nome quando não acha pelo id (dados inconsistentes)", () => {
    const candidates = [mk("x", "r1", "u2", "Ana")];
    expect(pickSwapAssignment(candidates, "u1", "Ana", "19:00", [])?.id).toBe(
      "x",
    );
  });

  it("usa o candidato único como último recurso", () => {
    const candidates = [mk("unico", "r1", "u2", "Bruno")];
    expect(pickSwapAssignment(candidates, "u1", "Ana", "19:00", [])?.id).toBe(
      "unico",
    );
  });

  it("retorna null quando não há candidatos", () => {
    expect(pickSwapAssignment([], "u1", "Ana", "19:00", [])).toBeNull();
  });

  it("com 2 vítimas do mesmo membro e hora sem correspondência, usa a primeira do membro", () => {
    const candidates = [mk("a", "r1", "u1"), mk("b", "r2", "u1")];
    const rules: SwapRuleHour[] = [
      { id: "r1", time: "09:00:00" },
      { id: "r2", time: "19:00:00" },
    ];
    expect(pickSwapAssignment(candidates, "u1", "Ana", "12:00", rules)?.id).toBe(
      "a",
    );
  });
});
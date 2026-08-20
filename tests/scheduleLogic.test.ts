// @ts-nocheck — lógica pura; runtime não checado pelo tsc.
import { describe, it, expect } from "vitest";
import {
  generateOccurrencesV2,
  EventRuleV2,
} from "../services/scheduleServiceV2";
import {
  getLocalDateISOString,
  adjustMonth,
  generateMonthEvents,
} from "../utils/dateUtils";

describe("generateOccurrencesV2", () => {
  it("gera ocorrências semanais para todos os domingos do mês", () => {
    const rules: EventRuleV2[] = [
      { id: "r1", title: "Culto", type: "weekly", weekday: 0, time: "19:00:00" },
    ];
    // Junho/2026: domingos = 7, 14, 21, 28
    const occs = generateOccurrencesV2(rules, 2026, 6);
    const dates = occs.map((o) => o.date);
    expect(dates).toEqual(["2026-06-07", "2026-06-14", "2026-06-21", "2026-06-28"]);
  });

  it("gera evento único dentro do mês", () => {
    const rules: EventRuleV2[] = [
      { id: "r2", title: "Especial", type: "single", date: "2026-06-15", time: "09:00:00" },
    ];
    const occs = generateOccurrencesV2(rules, 2026, 6);
    expect(occs).toHaveLength(1);
    expect(occs[0].iso).toBe("2026-06-15T09:00:00");
  });

  it("não inclui evento único fora do mês", () => {
    const rules: EventRuleV2[] = [
      { id: "r3", title: "Fora", type: "single", date: "2026-07-01", time: "10:00:00" },
    ];
    expect(generateOccurrencesV2(rules, 2026, 6)).toHaveLength(0);
  });

  it("ordena por data/hora", () => {
    const rules: EventRuleV2[] = [
      { id: "a", title: "A", type: "single", date: "2026-06-20", time: "19:00:00" },
      { id: "b", title: "B", type: "single", date: "2026-06-05", time: "08:00:00" },
    ];
    const occs = generateOccurrencesV2(rules, 2026, 6);
    expect(occs[0].date).toBe("2026-06-05");
    expect(occs[1].date).toBe("2026-06-20");
  });
});

describe("dateUtils", () => {
  it("getLocalDateISOString retorna YYYY-MM-DD válido", () => {
    const s = getLocalDateISOString();
    expect(s).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    const d = new Date();
    expect(s).toBe(
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
        d.getDate(),
      ).padStart(2, "0")}`,
    );
  });

  it("adjustMonth cruza ano (dezembro -> janeiro)", () => {
    expect(adjustMonth("2026-12", 1)).toBe("2027-01");
    expect(adjustMonth("2026-01", -1)).toBe("2025-12");
  });

  it("generateMonthEvents filtra por mês e ordena", () => {
    const events = [
      { id: "1", date: "2026-06-20", time: "19:00", title: "Culto A" },
      { id: "2", date: "2026-05-01", time: "10:00", title: "Fora do mês" },
      { id: "3", date: "2026-06-05", time: "08:00", title: "Culto B" },
    ];
    // month index 5 (0-based) = junho/2026
    const result = generateMonthEvents(2026, 5, events as any);
    expect(result).toHaveLength(2);
    expect(result[0].title).toBe("Culto B"); // 05/06 antes de 20/06
    expect(result[0].dateDisplay).toBe("05/06");
    expect(result[0].iso).toBe("2026-06-05T08:00");
    expect(result[1].title).toBe("Culto A");
  });
});

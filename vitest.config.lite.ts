import { defineConfig } from "vitest/config";

// Config leve para testes de LÓGICA PURA (sem DOM/jest-dom).
// O setup global (tests/setup.ts) importa @testing-library/jest-dom,
// que requer @testing-library/dom (não instalado) — por isso os testes
// de lógica usam este config com environment "node" e sem setup.
export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
});
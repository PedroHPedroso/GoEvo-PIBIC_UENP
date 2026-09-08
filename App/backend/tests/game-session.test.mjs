import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const source = readFileSync(new URL("../../Front/game-session.js", import.meta.url), "utf8");
const storage = (entries = []) => {
  const values = new Map(entries);
  return { getItem: (key) => values.get(key), setItem: (key, value) => values.set(key, value) };
};
function browser({ player = "jogador-a", session = storage(), local = storage(), fetchImpl } = {}) {
  if (player) session.setItem("goevo:jogador", JSON.stringify({ id: player }));
  const calls = [], redirects = [], events = {}, intervals = [];
  const window = { addEventListener: (name, callback) => { events[name] = callback; },
    location: { assign: (url) => redirects.push(url) } };
  vm.runInNewContext(source, {
    window, document: { readyState: "complete", querySelector: () => null },
    sessionStorage: session, localStorage: local, AbortSignal, Error,
    setInterval: (callback) => intervals.push(callback), setTimeout: (callback) => setTimeout(callback, 10),
    fetch: async (url, options) => {
      const call = { url, ...options, payload: JSON.parse(options.body) };
      calls.push(call);
      return fetchImpl ? fetchImpl(call) : { ok: true, json: async () => ({ tempoMs: call.payload.tempoMs }) };
    },
  });
  return { api: window.GoEvoSession, calls, redirects, events, retry: () => intervals[0](), session, local };
}
const settle = async () => { await new Promise(setImmediate); };

test("quatro fases enviam tempos cumulativos para o jogador desta aba", async () => {
  const page = browser();
  for (let fase = 1; fase <= 4; fase++) {
    page.api.savePhase(fase, fase * 1234);
    await settle();
  }
  assert.deepEqual(page.calls.map((call) => call.url), [1, 2, 3, 4].map((fase) => `/api/jogadores/jogador-a/tempos/${fase}`));
  assert.ok(page.calls.every((call) => call.method === "PUT" && call.credentials === "same-origin" && call.keepalive));
  page.api.savePhase(1, 100);
  await settle();
  assert.equal(page.api.getTime(1), 1234);
  assert.equal(page.api.getStatus(), "Tempos salvos.");
});

test("resposta antiga não apaga um tempo mais recente ainda pendente", async () => {
  let resolve;
  const page = browser({ fetchImpl: () => new Promise((done) => { resolve = done; }) });
  page.api.savePhase(1, 1000);
  page.api.savePhase(1, 2500);
  resolve({ ok: true, json: async () => ({ tempoMs: 1000 }) });
  await settle();
  assert.equal(page.api.getTime(1), 2500);
  assert.equal(page.api.getStatus(), "Salvando tempos...");
  page.retry();
  assert.equal(page.calls.at(-1).payload.tempoMs, 2500);
  resolve({ ok: true, json: async () => ({ tempoMs: 2500 }) });
  await settle();
  assert.equal(page.api.getStatus(), "Tempos salvos.");
});

test("Sair abre o menu HTML e a página seguinte reenvia tempos após falha de rede", async () => {
  const page = browser({ fetchImpl: async () => { throw new Error("Sem rede"); } });
  page.api.savePhase(3, 4567);
  await page.api.returnToMenu();
  assert.deepEqual(page.redirects, ["/index.html"]);
  const menu = browser({ session: page.session });
  await settle();
  assert.equal(menu.calls[0].payload.tempoMs, 4567);
  assert.equal(menu.api.getStatus(), "Tempos salvos.");
});

test("cadastros diferentes não compartilham tempos", async () => {
  const first = browser();
  first.api.savePhase(1, 2345);
  await settle();
  const second = browser({ player: "jogador-b", session: first.session });
  assert.equal(second.api.getTime(1), 0);
  second.api.savePhase(1, 99);
  await settle();
  assert.match(second.calls[0].url, /jogador-b/);
  const original = browser({ session: first.session });
  assert.equal(original.api.getTime(1), 2345);
});

test("sem cadastro não grava; fases e tempos inválidos são rejeitados", () => {
  const anonymous = browser({ player: null });
  anonymous.api.savePhase(1, 500);
  assert.equal(anonymous.calls.length, 0);
  const page = browser();
  for (const [fase, tempo] of [[0, 1], [5, 1], [1, -1], [1, 1.2], [1, NaN]]) page.api.savePhase(fase, tempo);
  assert.equal(page.calls.length, 0);
});

test("volume é compartilhado com o portal; saída captura o último intervalo", async () => {
  const page = browser();
  page.api.setVolume(25);
  assert.equal(browser({ local: page.local }).api.getVolume(), 25);
  page.api.setVolume(200);
  assert.equal(page.api.getVolume(), 100);
  page.api.setBeforeLeave(() => page.api.savePhase(4, 9876));
  page.events.pagehide();
  await settle();
  assert.equal(page.calls.at(-1).payload.tempoMs, 9876);
});

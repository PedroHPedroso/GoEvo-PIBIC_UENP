// Testes locais opcionais: Node 22+, API em localhost:5286 e PostgreSQL do Compose ativos.
import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const baseUrl = "http://localhost:5286";
const compose = fileURLToPath(new URL("../docker-compose.yml", import.meta.url));
const sql = (query) => execFileSync("docker", ["compose", "-f", compose, "exec", "-T", "postgres",
  "psql", "-U", "goevo", "-d", "goevo", "-v", "ON_ERROR_STOP=1", "-tA", "-c", query], { encoding: "utf8" }).trim();
const post = (payload) => fetch(`${baseUrl}/api/jogadores`, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
});

test("cadastro HTTP persiste no PostgreSQL, valida dados e evita duplicações", async (t) => {
  const submissionId = randomUUID();
  const concurrentId = randomUUID();
  const invalidId = randomUUID();
  const payload = { nome: "  Ana   Júlia  ", idade: 15, instituicao: "  Escola D'Ávila  ", nivel: "medio", submissionId };
  try {
    await t.test("front e health disponíveis, código do backend não é público", async () => {
      assert.equal((await fetch(`${baseUrl}/api/health`)).status, 200);
      const page = await fetch(`${baseUrl}/cadastro.html`);
      assert.equal(page.status, 200);
      assert.match(await page.text(), /cadastro.js/);
      assert.equal((await fetch(`${baseUrl}/`)).status, 200);
      assert.equal((await fetch(`${baseUrl}/appsettings.json`)).status, 404);
      assert.equal((await fetch(`${baseUrl}/api/jogadores`)).status, 405);
    });
    let jogador;
    await t.test("201 e todos os campos gravados e normalizados", async () => {
      const response = await post(payload);
      assert.equal(response.status, 201);
      assert.equal(response.headers.get("cache-control"), "no-store");
      jogador = (await response.json()).jogador;
      assert.equal(jogador.nome, "Ana Júlia");
      assert.equal(jogador.idade, undefined);
      const stored = JSON.parse(sql(`SELECT row_to_json(j) FROM jogadores j WHERE submission_id = '${submissionId}'`));
      assert.equal(stored.id, jogador.id);
      assert.equal(stored.idade, 15);
      assert.equal(stored.instituicao, "Escola D'Ávila");
      assert.equal(stored.nivel, "medio");
      assert.ok(stored.created_at);
    });
    await t.test("reenvio retorna o original sem alterar nem duplicar", async () => {
      const response = await post({ ...payload, nome: "Outro Nome" });
      assert.equal(response.status, 200);
      assert.deepEqual((await response.json()).jogador, jogador);
      assert.equal(sql(`SELECT COUNT(*) FROM jogadores WHERE submission_id = '${submissionId}'`), "1");
    });
    await t.test("oito envios simultâneos criam somente uma linha", async () => {
      const responses = await Promise.all(Array.from({ length: 8 }, () => post({ ...payload, submissionId: concurrentId })));
      assert.equal(responses.filter((response) => response.status === 201).length, 1);
      assert.equal(responses.filter((response) => response.status === 200).length, 7);
      const bodies = await Promise.all(responses.map((response) => response.json()));
      assert.equal(new Set(bodies.map((body) => body.jogador.id)).size, 1);
      assert.equal(sql(`SELECT COUNT(*) FROM jogadores WHERE submission_id = '${concurrentId}'`), "1");
    });
    await t.test("campos inválidos e JSON incorreto não gravam", async () => {
      for (const change of [{ nome: " " }, { idade: 0 }, { idade: 101 }, { instituicao: "ab" },
        { nivel: "invalido" }, { submissionId: "invalido" }, { instituicao: "Escola\u0000teste" }]) {
        assert.equal((await post({ ...payload, submissionId: invalidId, ...change })).status, 422);
      }
      for (const invalid of [null, [], { ...payload, idade: 1.5 }, { ...payload, nome: 123 }]) {
        assert.equal((await post(invalid)).status, 400);
      }
      const malformed = await fetch(`${baseUrl}/api/jogadores`, {
        method: "POST", headers: { "Content-Type": "application/json" }, body: "{",
      });
      assert.equal(malformed.status, 400);
      assert.equal((await fetch(`${baseUrl}/api/jogadores`, { method: "POST", body: "texto" })).status, 415);
      assert.equal(sql(`SELECT COUNT(*) FROM jogadores WHERE submission_id = '${invalidId}'`), "0");
    });
  } finally {
    // Somente os UUIDs gerados por este teste são removidos.
    sql(`DELETE FROM jogadores WHERE submission_id IN ('${submissionId}', '${concurrentId}', '${invalidId}')`);
  }
});

const frontendSource = readFileSync(new URL("../../Front/cadastro.js", import.meta.url), "utf8");
function browser(fetchImpl, blockedStorage = false) {
  let handler;
  const redirects = [];
  const store = new Map();
  const form = {
    elements: Object.fromEntries(Object.entries({ nome: "Ana Júlia", idade: "15", instituicao: "Escola Mendel", nivel: "medio" })
      .map(([key, value]) => [key, { value }])),
    checkValidity: () => true, reportValidity() {}, addEventListener: (_, callback) => { handler = callback; },
  };
  const button = { setAttribute() {}, removeAttribute() {} };
  const status = { dataset: {} };
  vm.runInNewContext(frontendSource, {
    document: { querySelector: (selector) => ({ "#form-cadastro": form, "#btn-finalizar": button, "#cadastro-status": status })[selector] },
    crypto: { randomUUID }, AbortSignal, Error, fetch: fetchImpl,
    sessionStorage: {
      getItem: (key) => { if (blockedStorage) throw new Error("Storage bloqueado"); return store.get(key); },
      setItem: (key, value) => { if (blockedStorage) throw new Error("Storage bloqueado"); store.set(key, value); },
      removeItem: (key) => store.delete(key),
    },
    window: { location: { assign: (path) => redirects.push(path) } },
  });
  return { submit: () => handler({ preventDefault() {} }), redirects, button, status };
}

test("formulário só abre o jogo após confirmação e mantém UUID ao tentar novamente", async () => {
  const ids = [];
  const page = browser(async (_, options) => {
    ids.push(JSON.parse(options.body).submissionId);
    return ids.length === 1
      ? { ok: false, json: async () => ({ error: { message: "Indisponível" } }) }
      : { ok: true, json: async () => ({ jogador: { id: randomUUID() } }) };
  });
  await page.submit();
  assert.equal(page.button.disabled, false);
  assert.equal(page.status.dataset.type, "error");
  assert.deepEqual(page.redirects, []);
  await page.submit();
  assert.equal(ids[0], ids[1]);
  assert.deepEqual(page.redirects, ["/game/index.html"]);
});

test("formulário bloqueia clique duplicado e funciona com sessionStorage bloqueado", async () => {
  let resolveResponse;
  let calls = 0;
  const page = browser(() => { calls++; return new Promise((resolve) => { resolveResponse = resolve; }); }, true);
  const pending = page.submit();
  await page.submit();
  assert.equal(calls, 1);
  assert.deepEqual(page.redirects, []);
  resolveResponse({ ok: true, json: async () => ({ jogador: { id: randomUUID() } }) });
  await pending;
  assert.deepEqual(page.redirects, ["/game/index.html"]);
});

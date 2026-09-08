import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const baseUrl = "http://localhost:5286";
const compose = fileURLToPath(new URL("../docker-compose.yml", import.meta.url));
const sql = (query) => execFileSync("docker", ["compose", "-f", compose, "exec", "-T", "postgres",
  "psql", "-U", "goevo", "-d", "goevo", "-v", "ON_ERROR_STOP=1", "-tA", "-c", query], { encoding: "utf8" }).trim();
const put = (id, fase, tempoMs, cookie) => fetch(`${baseUrl}/api/jogadores/${id}/tempos/${fase}`, {
  method: "PUT", headers: { "Content-Type": "application/json", ...(cookie ? { Cookie: cookie } : {}) },
  body: JSON.stringify({ tempoMs }),
});

test("tempos são gravados na mesma linha do cadastro, com isolamento e reenvios seguros", async () => {
  const submissions = [randomUUID(), randomUUID()];
  try {
    const players = [];
    for (const submissionId of submissions) {
      const response = await fetch(`${baseUrl}/api/jogadores`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nome: "Teste Tempos", idade: 15, instituicao: "Escola Teste", nivel: "medio", submissionId }),
      });
      assert.equal(response.status, 201);
      const { jogador } = await response.json();
      const cookie = response.headers.get("set-cookie");
      assert.ok(cookie.includes(`path=/api/jogadores/${jogador.id}/tempos`));
      assert.match(cookie, /httponly/i);
      players.push({ id: jogador.id, cookie: cookie.split(";")[0] });
    }
    const [a, b] = players;
    const read = (id) => JSON.parse(sql(`SELECT row_to_json(j) FROM jogadores j WHERE id = '${id}'`));
    for (let fase = 1; fase <= 4; fase++) {
      assert.equal(read(a.id)[`tempo_fase_${fase}_ms`], null);
      const response = await put(a.id, fase, 1234 * fase, a.cookie);
      assert.equal(response.status, 200);
      assert.equal((await response.json()).tempoMs, 1234 * fase);
    }
    await Promise.all([9000, 6000, 1000, 9000].map((time) => put(a.id, 1, time, a.cookie)));
    const saved = read(a.id);
    assert.equal(saved.tempo_fase_1_ms, 9000);
    assert.equal(saved.tempo_fase_2_ms, 2468);
    assert.equal(saved.tempo_fase_3_ms, 3702);
    assert.equal(saved.tempo_fase_4_ms, 4936);
    assert.equal(saved.nome, "Teste Tempos");
    assert.equal(saved.idade, 15);
    assert.equal(saved.instituicao, "Escola Teste");
    assert.equal(saved.nivel, "medio");
    assert.equal(read(b.id).tempo_fase_1_ms, null);
    assert.equal((await put(b.id, 1, 20000, a.cookie)).status, 404);
    assert.equal((await put(a.id, 1, 20000)).status, 401);
    for (const [fase, time] of [[0, 1], [5, 1], [1, -1], [1, null], [1, 31536000001]]) {
      assert.equal((await put(a.id, fase, time, a.cookie)).status, 422);
    }
    assert.equal((await put(a.id, 1, 1.5, a.cookie)).status, 400);
    assert.equal(read(a.id).tempo_fase_1_ms, 9000);
  } finally {
    // Exclui exclusivamente os dois cadastros fictícios criados neste teste.
    sql(`DELETE FROM jogadores WHERE submission_id IN ('${submissions.join("', '")}')`);
  }
});

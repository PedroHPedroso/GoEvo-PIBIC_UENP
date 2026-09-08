// Ponte entre o Godot e o portal. Só envia tempos do jogador desta aba.
(() => {
  const read = (storage, key, fallback) => {
    try { return JSON.parse(storage.getItem(key)) ?? fallback; } catch { return fallback; }
  };
  let jogador = null;
  try { jogador = read(sessionStorage, "goevo:jogador", null); } catch { /* Armazenamento indisponível. */ }
  const playerId = typeof jogador?.id === "string" ? jogador.id : null;
  const key = `goevo:tempos:${playerId}`;
  let state = { values: [0, 0, 0, 0], pending: [false, false, false, false] };
  try {
    const saved = read(sessionStorage, key, null);
    if (saved?.values?.length === 4 && saved?.pending?.length === 4 &&
        saved.values.every((value) => Number.isSafeInteger(value) && value >= 0)) state = saved;
  } catch { /* A memória mantém a fila durante esta página. */ }
  let flight = null;
  let errorMessage = "";
  let storageAvailable = true;
  let beforeLeave = null;

  function persist() {
    if (!playerId) return;
    try { sessionStorage.setItem(key, JSON.stringify(state)); }
    catch { storageAvailable = false; }
  }

  function flush() {
    if (flight) return flight;
    if (!playerId || !state.pending.some(Boolean)) return Promise.resolve();
    flight = (async () => {
      try {
        for (let index = 0; index < 4; index++) {
          if (!state.pending[index]) continue;
          const snapshot = state.values[index];
          const response = await fetch(`/api/jogadores/${encodeURIComponent(playerId)}/tempos/${index + 1}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            credentials: "same-origin",
            body: JSON.stringify({ tempoMs: snapshot }),
            keepalive: true,
            signal: AbortSignal.timeout(8000),
          });
          if (!response.ok) {
            throw new Error(response.status === 401 || response.status === 404
              ? "Faça um novo cadastro para registrar os tempos desta jornada."
              : "Tempos pendentes. O jogo tentará salvar novamente.");
          }
          const result = await response.json();
          if (!Number.isSafeInteger(result.tempoMs) || result.tempoMs < snapshot) throw new Error("Resposta de tempo inválida.");
          // Um envio antigo nunca apaga um valor mais recente da fila.
          if (state.values[index] === snapshot) state.pending[index] = false;
          state.values[index] = Math.max(state.values[index], result.tempoMs);
          persist();
        }
        errorMessage = "";
      } catch (error) {
        errorMessage = error instanceof Error ? error.message : "Tempos pendentes de envio.";
      }
    })().finally(() => { flight = null; });
    return flight;
  }

  let volume = 70;
  try {
    const saved = read(localStorage, "goevo:volume", 70);
    if (Number.isFinite(saved)) volume = Math.min(100, Math.max(0, saved));
  } catch { /* Usa o volume padrão. */ }

  window.GoEvoSession = {
    setBeforeLeave(callback) { beforeLeave = callback; },
    getTime: (fase) => state.values[fase - 1] ?? 0,
    savePhase(fase, tempoMs) {
      if (!playerId || !Number.isInteger(fase) || fase < 1 || fase > 4 ||
          !Number.isSafeInteger(tempoMs) || tempoMs < 0) return;
      const index = fase - 1;
      state.values[index] = Math.max(state.values[index], tempoMs);
      state.pending[index] = true;
      persist();
      void flush();
    },
    getStatus() {
      if (!playerId) return "Faça um cadastro para registrar os tempos.";
      return errorMessage || (state.pending.some(Boolean) ? "Salvando tempos..." : "Tempos salvos.");
    },
    getVolume: () => volume,
    setVolume(value) {
      if (!Number.isFinite(value)) return;
      volume = Math.round(Math.min(100, Math.max(0, value)));
      try { localStorage.setItem("goevo:volume", JSON.stringify(volume)); } catch { /* Aplica nesta sessão. */ }
    },
    async returnToMenu() {
      persist();
      // A próxima página retoma a fila se a rede estiver indisponível.
      if (storageAvailable) {
        await Promise.race([flush(), new Promise((resolve) => setTimeout(resolve, 1500))]);
      } else {
        await flush();
        if (state.pending.some(Boolean)) return false;
      }
      window.location.assign("/index.html");
      return true;
    },
  };

  function bindVolume() {
    const slider = document.querySelector("#volume-som");
    if (!slider) return;
    const update = () => {
      const value = window.GoEvoSession.getVolume();
      slider.value = value;
      slider.setAttribute("aria-valuenow", value);
      const label = document.querySelector(".slider-value");
      if (label) { label.textContent = `${value}%`; label.setAttribute("aria-label", `Volume atual: ${value}`); }
      const footer = document.querySelector("#volume-status");
      if (footer) footer.textContent = `SOM: ${value}%`;
    };
    slider.addEventListener("input", () => { window.GoEvoSession.setVolume(Number(slider.value)); update(); });
    update();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", bindVolume);
  else bindVolume();
  window.addEventListener("online", () => { void flush(); });
  window.addEventListener("pagehide", () => {
    // Captura também os milissegundos desde o último envio periódico do Godot.
    beforeLeave?.();
    persist();
    void flush();
  });
  setInterval(() => { void flush(); }, 5000);
  void flush();
})();

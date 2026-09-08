const form = document.querySelector("#form-cadastro");
const submitButton = document.querySelector("#btn-finalizar");
const statusElement = document.querySelector("#cadastro-status");
let submitting = false;
let pendingSubmissionId;

function submissionId() {
  const storageKey = "goevo:cadastro-submission-id";
  if (pendingSubmissionId) return pendingSubmissionId;
  try {
    pendingSubmissionId = sessionStorage.getItem(storageKey) || crypto.randomUUID();
    sessionStorage.setItem(storageKey, pendingSubmissionId);
  } catch {
    pendingSubmissionId ??= crypto.randomUUID();
  }
  return pendingSubmissionId;
}

function showStatus(message, type = "info") {
  statusElement.textContent = message;
  statusElement.dataset.type = type;
  statusElement.hidden = false;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (submitting) return;

  form.elements.nome.value = form.elements.nome.value.normalize("NFC").trim().replace(/\s+/g, " ");
  form.elements.instituicao.value = form.elements.instituicao.value.normalize("NFC").trim().replace(/\s+/g, " ");

  if (!form.checkValidity()) {
    form.reportValidity();
    showStatus("Revise os campos destacados antes de continuar.", "error");
    return;
  }

  submitting = true;
  submitButton.disabled = true;
  submitButton.setAttribute("aria-busy", "true");
  submitButton.textContent = "SALVANDO PERFIL...";
  showStatus("Criando seu perfil de explorador...", "info");

  try {
    const payload = {
      nome: form.elements.nome.value,
      idade: Number(form.elements.idade.value),
      instituicao: form.elements.instituicao.value,
      nivel: form.elements.nivel.value,
      submissionId: submissionId(),
    };

    const response = await fetch("/api/jogadores", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(15000),
    });

    const result = await response.json().catch(() => null);
    if (!response.ok) {
      throw new Error(
        (result?.error?.fields ? Object.values(result.error.fields).join(" ") : null) ??
        result?.error?.message ??
          "Não foi possível concluir o cadastro. Tente novamente.",
      );
    }

    if (!result?.jogador?.id) {
      throw new Error("A API não confirmou o cadastro. Tente novamente.");
    }
    // Uma restrição de armazenamento não deve transformar um cadastro salvo em falha.
    try {
      sessionStorage.setItem("goevo:jogador", JSON.stringify(result.jogador));
      sessionStorage.removeItem("goevo:cadastro-submission-id");
    } catch { /* O perfil já está salvo no PostgreSQL. */ }
    showStatus("Cadastro concluído! Carregando o jogo...", "success");
    window.location.assign("/game/index.html");
  } catch (error) {
    submitting = false;
    showStatus(
      error instanceof Error
        ? error.message
        : "Ocorreu um erro inesperado. Tente novamente.",
      "error",
    );
    submitButton.disabled = false;
    submitButton.removeAttribute("aria-busy");
    submitButton.innerHTML = "▶&nbsp;&nbsp;INICIAR AVENTURA!";
  }
});

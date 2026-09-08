using GoEvo.Backend.Application;
using Microsoft.AspNetCore.Mvc;

namespace GoEvo.Backend.Controllers;

[ApiController]
[Route("api/jogadores/{jogadorId:guid}/tempos/{fase:int}")]
public sealed class TemposController(TempoService service) : ControllerBase
{
    [HttpPut]
    [Consumes("application/json")]
    public async Task<IActionResult> Salvar(Guid jogadorId, int fase, TempoRequest request,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParseExact(Request.Cookies[JogadoresController.SessionCookie], "D", out var submissionId))
            return Unauthorized(new { error = new { message = "Faça o cadastro para salvar os tempos." } });

        var result = await service.SalvarAsync(jogadorId, submissionId, fase, request, cancellationToken);
        if (!result.Valido)
            return UnprocessableEntity(new { error = new { message = "Informe uma fase de 1 a 4 e um tempo inteiro válido em milissegundos." } });
        if (result.TempoMs is null)
            return NotFound(new { error = new { message = "Este cadastro não pertence à sessão atual." } });
        return Ok(new { fase, tempoMs = result.TempoMs });
    }
}

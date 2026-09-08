using GoEvo.Backend.Application;
using Microsoft.AspNetCore.Mvc;

namespace GoEvo.Backend.Controllers;

[ApiController]
[Route("api/jogadores")]
public sealed class JogadoresController(CadastroService service) : ControllerBase
{
    public const string SessionCookie = "goevo_cadastro";
    [HttpPost]
    [Consumes("application/json")]
    public async Task<IActionResult> Cadastrar(CadastroRequest request, CancellationToken cancellationToken)
    {
        var result = await service.CadastrarAsync(request, cancellationToken);
        if (result.Cadastro is null)
            return UnprocessableEntity(new
            {
                error = new { code = "DADOS_INVALIDOS", message = "Revise os campos do cadastro.", fields = result.Errors }
            });

        // O UUID de submissão funciona como uma credencial privada deste cadastro.
        // O caminho por jogador mantém válidas as sessões de outras abas/cadastros.
        Response.Cookies.Append(SessionCookie, request.SubmissionId!, new CookieOptions
        {
            HttpOnly = true,
            SameSite = SameSiteMode.Strict,
            Secure = Request.IsHttps,
            Path = $"/api/jogadores/{result.Cadastro.Jogador.Id}/tempos",
            MaxAge = TimeSpan.FromDays(30)
        });

        return StatusCode(result.Cadastro.Criado ? 201 : 200, new
        {
            jogador = result.Cadastro.Jogador,
            message = "Cadastro concluído. Iniciando o jogo."
        });
    }
}

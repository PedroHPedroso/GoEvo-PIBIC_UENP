using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace GoEvo.Backend.Controllers;

[ApiController]
[Route("api/health")]
public sealed class HealthController(NpgsqlDataSource dataSource) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        // Confere conexão e tabela, sem retornar cadastros.
        await using var command = dataSource.CreateCommand("SELECT 1 FROM jogadores LIMIT 0");
        await command.ExecuteNonQueryAsync(cancellationToken);
        return Ok(new { status = "ok" });
    }
}
using GoEvo.Backend.Application;
using Npgsql;

namespace GoEvo.Backend.Infrastructure;

public sealed class PostgresJogadorRepository(NpgsqlDataSource dataSource) : IJogadorRepository
{
    public async Task<CadastroSalvo> CadastrarAsync(NovoJogador jogador, CancellationToken cancellationToken)
    {
        await using var insert = dataSource.CreateCommand("""
            INSERT INTO jogadores (id, submission_id, nome, idade, instituicao, nivel)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (submission_id) DO NOTHING
            RETURNING id, nome, nivel, created_at
            """);
        insert.Parameters.AddWithValue(Guid.NewGuid());
        insert.Parameters.AddWithValue(jogador.SubmissionId);
        insert.Parameters.AddWithValue(jogador.Nome);
        insert.Parameters.AddWithValue(jogador.Idade);
        insert.Parameters.AddWithValue(jogador.Instituicao);
        insert.Parameters.AddWithValue(jogador.Nivel);

        await using (var reader = await insert.ExecuteReaderAsync(cancellationToken))
        {
            if (await reader.ReadAsync(cancellationToken))
                return new CadastroSalvo(ReadJogador(reader), true);
        }

        // Nova consulta também enxerga o cadastro que uma requisição concorrente gravou.
        await using var select = dataSource.CreateCommand("""
            SELECT id, nome, nivel, created_at FROM jogadores WHERE submission_id = $1
            """);
        select.Parameters.AddWithValue(jogador.SubmissionId);
        await using var existing = await select.ExecuteReaderAsync(cancellationToken);
        if (!await existing.ReadAsync(cancellationToken))
            throw new InvalidOperationException("O cadastro existente não foi encontrado.");
        return new CadastroSalvo(ReadJogador(existing), false);
    }

    private static Jogador ReadJogador(NpgsqlDataReader reader) =>
        new(reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetDateTime(3));
}
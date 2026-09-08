using GoEvo.Backend.Application;
using Npgsql;

namespace GoEvo.Backend.Infrastructure;

public sealed class PostgresTempoRepository(NpgsqlDataSource dataSource) : ITempoRepository
{
    public async Task<long?> SalvarAsync(Guid jogadorId, Guid submissionId, int fase, long tempoMs,
        CancellationToken cancellationToken)
    {
        // Identificadores SQL vêm exclusivamente desta lista fixa.
        var column = fase switch
        {
            1 => "tempo_fase_1_ms", 2 => "tempo_fase_2_ms",
            3 => "tempo_fase_3_ms", 4 => "tempo_fase_4_ms",
            _ => throw new ArgumentOutOfRangeException(nameof(fase))
        };
        await using var command = dataSource.CreateCommand($"""
            UPDATE jogadores SET {column} = GREATEST({column}, $1)
            WHERE id = $2 AND submission_id = $3
            RETURNING {column}
            """);
        command.Parameters.AddWithValue(tempoMs);
        command.Parameters.AddWithValue(jogadorId);
        command.Parameters.AddWithValue(submissionId);
        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result is long value ? value : null;
    }
}

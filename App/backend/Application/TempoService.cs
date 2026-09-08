namespace GoEvo.Backend.Application;

public sealed record TempoRequest(long? TempoMs);
public sealed record TempoResult(bool Valido, long? TempoMs);

public interface ITempoRepository
{
    Task<long?> SalvarAsync(Guid jogadorId, Guid submissionId, int fase, long tempoMs,
        CancellationToken cancellationToken);
}

public sealed class TempoService(ITempoRepository repository)
{
    public async Task<TempoResult> SalvarAsync(Guid jogadorId, Guid submissionId, int fase,
        TempoRequest request, CancellationToken cancellationToken)
    {
        if (fase is < 1 or > 4 || request.TempoMs is null or < 0 or > 31_536_000_000)
            return new TempoResult(false, null);

        return new TempoResult(true, await repository.SalvarAsync(jogadorId, submissionId,
            fase, request.TempoMs.Value, cancellationToken));
    }
}

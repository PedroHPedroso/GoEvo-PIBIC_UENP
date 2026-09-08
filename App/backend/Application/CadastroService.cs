using System.Text;
using System.Text.RegularExpressions;

namespace GoEvo.Backend.Application;

public sealed record CadastroRequest(string? Nome, int? Idade, string? Instituicao,
    string? Nivel, string? SubmissionId);
public sealed record NovoJogador(string Nome, int Idade, string Instituicao,
    string Nivel, Guid SubmissionId);
public sealed record Jogador(Guid Id, string Nome, string Nivel, DateTime CreatedAt);
public sealed record CadastroSalvo(Jogador Jogador, bool Criado);
public sealed record CadastroResult(CadastroSalvo? Cadastro, IReadOnlyDictionary<string, string> Errors);

public interface IJogadorRepository
{
    Task<CadastroSalvo> CadastrarAsync(NovoJogador jogador, CancellationToken cancellationToken);
}

// Regras do cadastro independem de HTTP e do driver PostgreSQL.
public sealed partial class CadastroService(IJogadorRepository repository)
{
    public async Task<CadastroResult> CadastrarAsync(CadastroRequest request, CancellationToken cancellationToken)
    {
        var nome = Normalize(request.Nome);
        var instituicao = Normalize(request.Instituicao);
        var nivel = Normalize(request.Nivel);
        var errors = new Dictionary<string, string>();

        if (nome.Length is < 2 or > 50 || !NamePattern().IsMatch(nome))
            errors["nome"] = "Informe um nome de 2 a 50 caracteres, usando letras e separadores simples.";
        if (request.Idade is null or < 1 or > 100)
            errors["idade"] = "Informe uma idade inteira entre 1 e 100.";
        if (instituicao.Length is < 3 or > 100 || instituicao.Contains('\0'))
            errors["instituicao"] = "Informe uma instituição com 3 a 100 caracteres.";
        if (nivel is not ("fundamental1" or "fundamental2" or "medio" or "superior" or "outros"))
            errors["nivel"] = "Selecione um nível de ensino válido.";
        if (!Guid.TryParseExact(request.SubmissionId, "D", out var submissionId) || submissionId == Guid.Empty)
            errors["submissionId"] = "Identificador de envio inválido. Recarregue a página.";

        if (errors.Count > 0)
            return new CadastroResult(null, errors);

        var jogador = new NovoJogador(nome, request.Idade!.Value, instituicao, nivel, submissionId);
        return new CadastroResult(await repository.CadastrarAsync(jogador, cancellationToken), errors);
    }

    private static string Normalize(string? value) =>
        WhitespacePattern().Replace((value ?? "").Normalize(NormalizationForm.FormC).Trim(), " ");

    [GeneratedRegex(@"^\p{L}+(?:[ .'\-]\p{L}+)*$")]
    private static partial Regex NamePattern();
    [GeneratedRegex(@"\s+")]
    private static partial Regex WhitespacePattern();
}
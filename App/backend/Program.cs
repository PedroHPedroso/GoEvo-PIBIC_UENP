using GoEvo.Backend.Application;
using GoEvo.Backend.Infrastructure;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.StaticFiles;
using Npgsql;

// No desenvolvimento, o front permanece na pasta irmã; no publish, vai para wwwroot.
var frontPath = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "../Front"));
var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    WebRootPath = Directory.Exists(frontPath) ? frontPath : "wwwroot"
});
builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 16 * 1024);
builder.Services.AddControllers();
builder.Services.AddSingleton(_ =>
{
    var connectionString = builder.Configuration.GetConnectionString("Postgres");
    if (string.IsNullOrWhiteSpace(connectionString))
        throw new InvalidOperationException("Configure ConnectionStrings__Postgres antes de iniciar a API.");
    // Singleton seguro para acesso concorrente. Cada comando usa uma conexão do pool.
    return NpgsqlDataSource.Create(connectionString);
});
builder.Services.AddScoped<IJogadorRepository, PostgresJogadorRepository>();
builder.Services.AddScoped<CadastroService>();
builder.Services.AddScoped<ITempoRepository, PostgresTempoRepository>();
builder.Services.AddScoped<TempoService>();

var app = builder.Build();
app.UseExceptionHandler(handler => handler.Run(async context =>
{
    var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
    var unavailable = exception is NpgsqlException or TimeoutException;
    context.Response.StatusCode = unavailable ? 503 : 500;
    context.Response.Headers.CacheControl = "no-store";
    context.Response.Headers.XContentTypeOptions = "nosniff";
    await context.Response.WriteAsJsonAsync(new
    {
        error = new
        {
            code = unavailable ? "CADASTRO_INDISPONIVEL" : "ERRO_INTERNO",
            message = unavailable
                ? "O cadastro está temporariamente indisponível. Tente novamente."
                : "Não foi possível concluir a operação. Tente novamente."
        }
    });
}));

app.Use(async (context, next) =>
{
    context.Response.Headers.XContentTypeOptions = "nosniff";
    if (context.Request.Path.StartsWithSegments("/api"))
        context.Response.Headers.CacheControl = "no-store";
    if (context.Request.Path.StartsWithSegments("/game"))
    {
        context.Response.Headers["Cross-Origin-Opener-Policy"] = "same-origin";
        context.Response.Headers["Cross-Origin-Embedder-Policy"] = "require-corp";
    }
    await next();
});

var contentTypes = new FileExtensionContentTypeProvider();
contentTypes.Mappings[".wasm"] = "application/wasm";
contentTypes.Mappings[".pck"] = "application/octet-stream";
app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions { ContentTypeProvider = contentTypes });
app.MapControllers();
app.Run();

public partial class Program;

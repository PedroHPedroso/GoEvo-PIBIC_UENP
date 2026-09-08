FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY backend/Back.csproj backend/
RUN dotnet restore backend/Back.csproj
COPY backend/ backend/
COPY Front/ Front/
RUN dotnet publish backend/Back.csproj -c Release --no-restore -o /out

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /out .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Back.dll"]

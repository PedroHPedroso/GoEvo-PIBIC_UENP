# GoEvo

GoEvo é um jogo educacional 2D desenvolvido no Godot Engine. A experiência apresenta conceitos de evolução e seleção natural por meio de quatro fases, cada uma com personagens, objetivos e mecânicas próprias.

O portal Web possui cadastro com API C# e PostgreSQL. Consulte [as instruções do backend](App/backend/README.md) para iniciar o Docker, executar a API e verificar os cadastros.

## Sumário

- [Requisitos](#requisitos)
- [Como executar](#como-executar)
- [Controles](#controles)
- [Fases e objetivos](#fases-e-objetivos)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Executar uma fase isoladamente](#executar-uma-fase-isoladamente)
- [Exportação](#exportação)
- [Solução de problemas](#solução-de-problemas)
- [Licença](#licença)

## Requisitos

- Godot Engine 4.7 ou uma versão 4.x compatível.
- Sistema operacional compatível com o Godot: Windows, Linux ou macOS.
- Arquivos do projeto preservados na mesma estrutura de diretórios do repositório.

O jogo não exige instalação de bibliotecas externas, servidor ou banco de dados para ser executado no editor.

## Como executar

### Pelo gerenciador de projetos do Godot

1. Baixe ou clone este repositório.
2. Abra o Godot Engine.
3. No Gerenciador de Projetos, selecione **Importar**.
4. Localize e selecione o arquivo `project.godot` na raiz do projeto.
5. Aguarde a importação inicial dos recursos.
6. Abra o projeto e pressione **F6** para executar a cena atual ou **F5** para iniciar o jogo completo.

A cena principal configurada é `Cenas/Fase1/Fase1.tscn`. Ao usar **F5**, o jogo começa automaticamente na Fase 1.

### Pela linha de comando

Se o executável do Godot estiver disponível no `PATH`, abra um terminal e execute:

```bash
godot --editor --path /caminho/para/GoEvo
```

Para iniciar diretamente o jogo, sem abrir o editor:

```bash
godot --path /caminho/para/GoEvo
```

No Windows, também é possível informar o caminho completo do executável no PowerShell:

```powershell
& "C:\caminho\para\Godot_v4.7-stable_win64.exe" --editor --path "C:\caminho\para\GoEvo"
```

Substitua os caminhos dos exemplos pelos locais utilizados no computador.

## Controles

| Contexto | Ação | Tecla ou botão |
| --- | --- | --- |
| Movimentação | Mover o personagem | `W`, `A`, `S`, `D` ou setas direcionais, conforme a fase |
| Fases 1 e 4 | Pular | `Espaço` |
| Fase 1 | Atacar as moscas | Botão esquerdo do mouse |
| Fase 1 | Conversar com a sapa e avançar o diálogo | `E` |
| Fase 2 | Agarrar-se ao tronco e testar a camuflagem | Manter `E` ou `Espaço` pressionado |
| Fase 3 | Desfazer o último pigmento coletado | `Esc` |
| Fase 4 | Bicar ou coletar o alimento próximo | `E` |
| Menus | Selecionar uma opção | Botão esquerdo do mouse |

Na Fase 1 e na Fase 4, a movimentação principal é horizontal. Nas Fases 2 e 3, o personagem pode se mover nos eixos horizontal e vertical.

## Fases e objetivos

### Fase 1 — Seleção e sobrevivência

O jogador controla um sapo em um cenário de brejo. O objetivo é capturar dez moscas, explorar o ambiente e conversar com a sapa para concluir a etapa introdutória.

### Fase 2 — Melanismo industrial

A fase representa o caso das mariposas de Manchester. Em cada um dos quatro cenários, o jogador escolhe uma mariposa branca ou preta e deve encontrar uma região de tronco compatível com sua cor.

Para confirmar a camuflagem, é necessário permanecer sobre a área correta e manter `E` ou `Espaço` pressionado por 2,5 segundos. Uma combinação incorreta entre a cor da mariposa e a superfície do tronco ativa o predador.

Na terceira etapa, cada tronco possui regiões claras e escuras independentes. A cor selecionada precisa coincidir especificamente com a parte do tronco utilizada para o pouso.

### Fase 3 — Mimetismo batesiano

O jogador controla uma falsa-coral e coleta pigmentos para reproduzir o padrão visual de uma cobra-coral verdadeira. A sequência esperada é:

```text
Vermelho → Amarelo → Preto → Amarelo → Vermelho
```

O padrão correto ajuda a dissuadir predadores vulneráveis ao mimetismo. A tecla `Esc` remove o último pigmento coletado quando for necessário corrigir a sequência.

### Fase 4 — Irradiação adaptativa

O jogador acompanha um tentilhão em três ilhas com fontes de alimento diferentes. Em cada ilha, deve analisar o ambiente, escolher o formato de bico adequado e coletar alimento antes que o tempo ou a energia se esgotem. A ilha é concluída ao alcançar 90 de energia ou consumir todos os alimentos disponíveis.

| Ilha | Recurso predominante | Adaptação adequada |
| --- | --- | --- |
| Ilha das Sementes Duras | Sementes de casca espessa | Bico alicate |
| Ilha dos Cactos | Néctar em flores tubulares | Bico pinça longa |
| Ilha dos Troncos Antigos | Larvas escondidas na madeira | Bico formão |

Ao concluir cada fase, o jogo apresenta uma mensagem de conclusão e avança para a etapa seguinte. Depois da Fase 4, é possível reiniciar a jornada a partir da Fase 1.

## Estrutura do projeto

```text
GoEvo/
├── Animações/          Recursos visuais, cenários e sprites
├── Cenas/              Cenas organizadas por fase
│   ├── Fase1/
│   ├── Fase2/
│   ├── Fase3/
│   └── Fase4/
├── Fonts/              Fontes utilizadas na interface
├── Scripts/            Lógica de jogo em GDScript
├── Sons/               Efeitos sonoros e recursos de áudio
├── export_presets.cfg  Presets de exportação
└── project.godot       Configuração principal do projeto
```

As cenas principais são:

- `Cenas/Fase1/Fase1.tscn`
- `Cenas/Fase2/Fase2.tscn`
- `Cenas/Fase3/Fase3.tscn`
- `Cenas/Fase4/Fase4.tscn`

Elementos que precisam ser reposicionados visualmente, como troncos da Fase 2, plataformas da terceira etapa da Fase 4, flores de cacto e larvas, estão instanciados nas cenas correspondentes e podem ser ajustados diretamente pelo editor do Godot.

## Executar uma fase isoladamente

Para testar uma fase sem percorrer as anteriores:

1. Abra a cena principal da fase desejada pelo painel **Sistema de Arquivos** do Godot.
2. Pressione **F6** ou use **Executar cena atual**.
3. Quando o Godot solicitar confirmação, escolha a cena atualmente aberta.

O uso de **F5** sempre inicia o projeto pela Fase 1, pois ela é a cena principal configurada.

## Exportação

O projeto contém presets para **Web** e **Windows Desktop**.

1. No editor do Godot, acesse **Projeto > Exportar**.
2. Se necessário, instale os modelos de exportação solicitados pelo editor.
3. Selecione o preset desejado.
4. Defina o caminho do arquivo de saída.
5. Use **Exportar Projeto** para gerar a versão distribuível.

Para a versão Web, publique todos os arquivos gerados pelo Godot no mesmo diretório de um servidor HTTP. Abrir o arquivo HTML diretamente pelo sistema de arquivos pode impedir o carregamento correto do jogo em alguns navegadores.

## Solução de problemas

### O projeto não aparece no Godot

Confirme que foi selecionada a pasta que contém o arquivo `project.godot`, e não uma de suas subpastas.

### Sprites, fontes ou sons não carregam

Aguarde a conclusão da primeira importação. Se o problema continuar, selecione o recurso no painel **Sistema de Arquivos** e use a opção de reimportação. Verifique também se as pastas `Animações`, `Fonts` e `Sons` foram copiadas integralmente.

### As teclas não respondem

Abra **Projeto > Configurações do Projeto > Mapa de Entrada** e confirme a existência das ações `frente`, `tras`, `esquerda`, `direita`, `ataque` e `interacao`.

### A exportação não está disponível

Instale os modelos de exportação compatíveis com a versão do Godot utilizada e volte à janela **Projeto > Exportar**.

### O jogo abre em uma fase incorreta

Abra **Projeto > Configurações do Projeto > Aplicação > Executar** e confirme que `Cenas/Fase1/Fase1.tscn` está definida como cena principal.

## Licença

Este projeto é distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para os termos completos.

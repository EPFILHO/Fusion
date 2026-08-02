# Fusion

Fusion e um Expert Advisor para MetaTrader 5, escrito em MQL5, com foco em arquitetura modular, operacao segura e evolucao incremental.

O projeto nasceu como uma implementacao clean-room inspirada em boas ideias do Matrix, mas sem tratar os documentos ou a estrutura daquele repositorio como fonte da verdade. A regra aqui e simples: codigo limpo, modulos acoplaveis e decisoes documentadas desde o comeco.

## Estado Atual

- Opera no simbolo do grafico onde o EA esta anexado.
- Os timeframes operacionais sao definidos por estrategia/filtro e perfil, e nao pelo timeframe atual do grafico.
- Permite multiplas instancias em graficos diferentes, desde que cada grafico use perfil e Magic Number livres.
- Mantem uma posicao liquida por EA.
- Usa arquitetura multi-estrategia e multi-filtro.
- O Trend Filter possui M1 longa e M2 curta independentes; cada MA ativa exige BUY acima dela e SELL abaixo dela, usando preco e valor da media atuais.
- O Bollinger Filter pode, opcionalmente, bloquear sinais contra a inclinacao da linha central em candles fechados.
- Usa resolvedores de conflito plugaveis para sinais simultaneos.
- A estrategia que abriu a posicao e responsavel pela saida por sinal.
- Camadas de risco e protecao podem forcar saida independentemente da estrategia.
- Perfis nomeados sao salvos pela GUI para operacao em grafico.
- Perfis sao gravados atomicamente; arquivos incompletos nao substituem a configuracao em uso.
- Backtests devem priorizar os `input` do MT5 Strategy Tester.
- O reload de configuracao e controlado a frio: mudancas operacionais exigem pausar o EA ou estar em estado seguro, sem alteracao livre em plena operacao ou durante posicao gerenciada.

## Modulos

- `Core`: ciclo de vida, tipos centrais, inputs, logging e orquestracao do EA.
- `Signals`: agregacao de estrategias, filtros e resolucao de conflitos.
- `Strategies`: contrato base e implementacoes de estrategias.
- `Filters`: contrato base e implementacoes de filtros.
- `Risk`: lote, SL, TP, TP parcial, breakeven e trailing stop.
- `Protection`: spread, sessao, news, limites diarios, drawdown e streak.
- `Execution`: envio de ordens, sincronizacao de posicao e reconciliacao com historico.
- `Persistence`: perfis nomeados e autosave/autorestore por grafico.
- `Normalization`: normalizacao de simbolo, volume, preco e especificacoes da corretora.
- `UI`: painel grafico, validacoes visuais e traducao de acoes da GUI em comandos.

## Perfis e Magic Number

O Magic Number pertence ao perfil/EA, nao a cada estrategia individual. Essa decisao evita que uma mesma instancia misture posicoes ou interfira em outro grafico.

Perfis salvos devem ter Magic Numbers unicos. Isso impede, por exemplo, usar por engano um perfil calibrado para BTCUSD em XAUUSD ou B3. O runtime ainda tem uma protecao adicional para impedir duas instancias ativas do Fusion com o mesmo `Magic` no mesmo terminal.

## GUI

A GUI e parte central do projeto porque concentra operacao visual, perfis e validacoes. Ela nao e apenas decoracao.

Hoje ela permite:

- iniciar ou pausar o EA quando nao ha posicao aberta;
- bloquear edicao enquanto o EA esta rodando ou gerenciando posicao;
- salvar e carregar perfis;
- criar perfis novos;
- duplicar perfis com fluxo seguro, exigindo Magic Number unico antes de salvar;
- validar risco, protecoes, estrategias, filtros e Magic com feedback visual e marcadores vermelhos nas abas;
- configurar os timeframes operacionais dos modulos em `STRATS` e `FILTERS` com `ComboBox`;
- manter avisos operacionais persistentes na aba `STATUS`.
- refletir bloqueios de protecao ativos na `STATUS`, sem depender de logs ou eventos de mouse para o usuario perceber o motivo.

## Manual do Usuario

O [Manual do Usuario](docs/USER_MANUAL.md) descreve instalacao, primeiro uso, todas as abas da GUI, estrategias, filtros, risco, protecoes, perfis, indicadores visuais e a referencia completa dos `input` do Strategy Tester.

O manual documenta somente o comportamento efetivamente presente na versao 1.057. Planos, checkpoints e handoffs com numero de versao permanecem no repositorio como historico tecnico e nao devem ser interpretados como funcionalidades atuais ou instrucoes de uso.

## Documentacao Tecnica

- [Manual do Usuario 1.057](docs/USER_MANUAL.md)
- [Indice da Documentacao](docs/README.md)
- [Auditoria da Documentacao 1.057](docs/DOCUMENTATION_AUDIT_1057.md)
- [Arquitetura](docs/ARCHITECTURE.md)
- [Decisoes do Projeto](docs/DECISIONS.md)
- [Persistencia e Filtros Direcionais 1.056](docs/SAFE_FILTER_EXPANSION_1056.md)
- [Changelog](CHANGELOG.md)

## Compilacao

O `Fusion.ex5` incorpora tres indicadores visuais como recursos. Em um clone novo, compile primeiro esses indicadores e somente depois o EA. O script `build.ps1` executa toda a sequencia, valida a linha `Result:` de cada log e confirma a existencia dos quatro EX5.

Ordem usada pelo script:

1. `VisualIndicators/FusionVisualMA.mq5`;
2. `VisualIndicators/FusionVisualBands.mq5`;
3. `VisualIndicators/FusionVisualRSI.mq5`;
4. `Fusion.mq5`.

### Projeto fora da pasta MQL5

A partir do MetaEditor `5.0.0.6061`, o compilador exige que os arquivos declarados em `#resource` resolvam dentro da arvore `MQL5`. Um clone mantido fora dela falha com `error 313: invalid resource path` nos tres indicadores, mesmo com o codigo correto.

Use `build-linked.ps1` nesse caso. Ele cria um vinculo de diretorio em `MQL5\Experts\FusionBuild\<nome-da-pasta>`, chama o `build.ps1` por esse caminho e remove o vinculo ao final. Os EX5 continuam sendo gravados na pasta do projeto, e o repositorio permanece onde esta.

```powershell
.\build-linked.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'
```

`-Mql5` **nao precisa ser informado**: a raiz e derivada do proprio MetaEditor, casando por `origin.txt` — o mesmo vinculo instalacao/pasta-de-dados que o MetaEditor usa. Informe-a apenas para forcar outra. Use `-KeepLink` para manter o vinculo e abrir o projeto no MetaEditor por um caminho que o compilador aceita.

> **A raiz precisa ser a do MetaEditor escolhido, e nao uma qualquer.** Sem `/inc` (ver abaixo), os `#resource` iniciados por `\` resolvem contra a pasta de dados **do editor**. Apontar para outra faz os tres `#resource` dos indicadores falharem com `invalid resource path` — o arquivo existe, mas nao na arvore que o compilador considera sua. Com dezenas de pastas de dados na maquina, todas com cara de validas, errar era facil e o erro acusava o projeto em vez do argumento.

Se o clone ja estiver dentro de `MQL5`, o `build.ps1` sozinho basta.

### Uso com caminhos explicitos

Este e o modo mais seguro quando existem varias instalacoes do MetaTrader 5 — basta dizer **qual editor**, e a raiz `MQL5` vem pareada com ele:

```powershell
.\build.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'
```

Se a politica de execucao do PowerShell bloquear scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 `
  -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'
```

`-Mql5` continua existindo como forcador manual e recebe a raiz `MQL5`, nao apenas a subpasta `Include`. Prefira omiti-lo: informar uma raiz que nao seja a do editor escolhido quebra os `#resource`.

### Autodeteccao

Tambem e possivel executar:

```powershell
.\build.ps1
```

O script autodetecta o `MetaEditor64.exe` somente quando encontra exatamente um. Havendo varias instalacoes, ele lista as opcoes e encerra sem escolher silenciosamente; execute novamente informando `-MetaEditor`.

A raiz `MQL5`, essa, nunca precisa ser informada: ela e **derivada do MetaEditor** por `origin.txt` (`build-paths.ps1`). A versao anterior aceitava qualquer pasta contendo `Include/Controls/Dialog.mqh` e desistia diante de varias — o que empurrava para informar `-Mql5` a mao, e informar a errada quebrava os `#resource`.

### O compilador e o `/inc`

**O `build.ps1` nao passa `/inc` ao MetaEditor, e nao deve voltar a passar.** A partir do `5.0.0.6090` esse argumento quebra a compilacao em dois lugares, ambos dentro de arquivos da propria MetaQuotes — o que faz o defeito parecer do ambiente:

- `Include\Canvas\Canvas.mqh` acusa 6 erros dentro do proprio arquivo (`cannot convert parameter 'int' to 'uint&'`, `wrong parameters count` em `TextOut`, com o aviso *"due to new rules of method hiding"*);
- todo `#resource` e recusado com `invalid resource path`, inclusive os `res\*.bmp` que `Include\Controls` declara e que existem em disco.

Sem `/inc`, os mesmos arquivos compilam `0 errors, 0 warnings`. Nesse modo o compilador deduz a raiz `MQL5` pela localizacao do fonte — que e exatamente o que o `build-linked.ps1` garante ao expor o projeto dentro de `Experts`.

O `ExitCode` do MetaEditor nao e usado para julgar sucesso, pois pode ser diferente de zero mesmo em compilacoes validas. A autoridade e `Result: 0 errors, 0 warnings` no log e a existencia do EX5 correspondente.

Os logs `compile_build_*.log` sao gerados na raiz do projeto, e cada `*.ex5` fica ao lado de seu respectivo fonte. Todos permanecem ignorados pelo Git.

Em um ambiente validado do projeto, o MetaEditor build 6061 distribuido com o terminal FOT apresentou erros 313 de recursos inclusive em versoes antes funcionais. O MetaEditor padrao build 5833 compilou os quatro alvos com `0 errors, 0 warnings`. Se ocorrerem erros 313, informe explicitamente outro MetaEditor conhecido como funcional.

## Distribuicao

Para o usuario final, distribua somente o `Fusion.ex5` produzido ao final do build. Os tres indicadores visuais ja ficam incorporados nele e nao precisam ser instalados separadamente. O arquivo deve ser copiado para `MQL5/Experts`; depois, atualize o Navegador ou reinicie o terminal.

Para desenvolvimento ou validacao de compilacao, distribua o repositorio completo e use `build.ps1`.

Arquivos `*.ex5`, logs de compilacao e arquivos locais do editor sao ignorados pelo Git.

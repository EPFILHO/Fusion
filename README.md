# Fusion

Fusion e um Expert Advisor para MetaTrader 5, escrito em MQL5, com foco em arquitetura modular, operacao segura e evolucao incremental.

O projeto nasceu como uma implementacao clean-room inspirada em boas ideias do Matrix, mas sem tratar os documentos ou a estrutura daquele repositorio como fonte da verdade. A regra aqui e simples: codigo limpo, modulos acoplaveis e decisoes documentadas desde o comeco.

## Estado Atual

- Opera no simbolo do grafico onde o EA esta anexado.
- Os timeframes operacionais caminham para ser definidos por modulo e perfil, e nao pelo timeframe atual do grafico.
- Permite multiplas instancias em graficos diferentes, desde que os perfis usem Magic Numbers distintos.
- Mantem uma posicao liquida por EA.
- Usa arquitetura multi-estrategia e multi-filtro.
- Usa resolvedores de conflito plugaveis para sinais simultaneos.
- A estrategia que abriu a posicao e responsavel pela saida por sinal.
- Camadas de risco e protecao podem forcar saida independentemente da estrategia.
- Perfis nomeados sao salvos pela GUI para operacao em grafico.
- Backtests devem priorizar os `input` do MT5 Strategy Tester.
- Hot reload existe como preocupacao arquitetural, mas edicao em producao fica bloqueada enquanto o EA esta rodando ou gerenciando posicao.

## Modulos

- `Core`: ciclo de vida, tipos centrais, inputs, logging e orquestracao do EA.
- `Signals`: agregacao de estrategias, filtros e resolucao de conflitos.
- `Strategies`: contrato base e implementacoes de estrategias.
- `Filters`: contrato base e implementacoes de filtros.
- `Risk`: lote, SL, TP, TP parcial, breakeven e trailing stop.
- `Protection`: spread, sessao, limites diarios, drawdown e streak.
- `Execution`: envio de ordens, sincronizacao de posicao e reconciliacao com historico.
- `Persistence`: perfis nomeados e autosave/autorestore por grafico.
- `Normalization`: normalizacao de simbolo, volume, preco e especificacoes da corretora.
- `UI`: painel grafico, validacoes visuais e traducao de acoes da GUI em comandos.

## Perfis e Magic Number

O Magic Number pertence ao perfil/EA, nao a cada estrategia individual. Essa decisao evita que uma mesma instancia misture posicoes ou interfira em outro grafico.

Perfis salvos devem ter Magic Numbers unicos. Isso impede, por exemplo, usar por engano um perfil calibrado para BTCUSD em XAUUSD ou B3. O runtime ainda tem uma protecao adicional para impedir duas instancias ativas com o mesmo `simbolo + magic` no mesmo terminal.

## GUI

A GUI e parte central do projeto porque concentra operacao visual, perfis e futuras validacoes. Ela nao e apenas decoracao.

Hoje ela permite:

- iniciar ou pausar o EA quando nao ha posicao aberta;
- bloquear edicao enquanto o EA esta rodando ou gerenciando posicao;
- salvar e carregar perfis;
- criar perfis novos;
- duplicar perfis com fluxo seguro, exigindo Magic Number unico antes de salvar;
- validar lote, spread e magic com feedback visual;
- configurar os timeframes operacionais dos modulos em `STRATS` e `FILTERS` com `ComboBox`;
- manter avisos operacionais persistentes na aba `STATUS`.

## Documentacao Tecnica

- [Arquitetura](docs/ARCHITECTURE.md)
- [Decisoes do Projeto](docs/DECISIONS.md)
- [Changelog](CHANGELOG.md)

## Compilacao

Abra `Fusion.mq5` no MetaEditor 5 e compile. O projeto usa apenas MQL5 e includes padrao do MetaTrader 5.

Arquivos `*.ex5`, logs de compilacao e arquivos locais do editor sao ignorados pelo Git.

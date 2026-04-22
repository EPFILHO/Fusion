# Fusion

Fusion é um Expert Advisor para MetaTrader 5, escrito em MQL5, com foco em arquitetura modular, operação segura e evolução incremental.

O projeto nasceu como uma implementação clean-room inspirada em boas ideias do Matrix, mas sem tratar os documentos ou a estrutura daquele repositório como fonte da verdade. A regra aqui é simples: código limpo, módulos acopláveis e decisões documentadas desde o começo.

## Estado Atual

- Opera somente o símbolo e timeframe do gráfico onde o EA está anexado.
- Permite múltiplas instâncias em gráficos diferentes, desde que os perfis usem Magic Numbers distintos.
- Mantém uma posição líquida por EA.
- Usa arquitetura multi-estratégia e multi-filtro.
- Usa resolvedores de conflito plugáveis para sinais simultâneos.
- A estratégia que abriu a posição é responsável pela saída por sinal.
- Camadas de risco e proteção podem forçar saída independentemente da estratégia.
- Perfis nomeados são salvos pela GUI para operação em gráfico.
- Backtests devem priorizar os `input` do MT5 Strategy Tester.
- Hot reload existe como preocupação arquitetural, mas edição em produção fica bloqueada enquanto o EA está rodando ou gerenciando posição.

## Módulos

- `Core`: ciclo de vida, tipos centrais, inputs, logging e orquestração do EA.
- `Signals`: agregação de estratégias, filtros e resolução de conflitos.
- `Strategies`: contrato base e implementações de estratégias.
- `Filters`: contrato base e implementações de filtros.
- `Risk`: lote, SL, TP, TP parcial, breakeven e trailing stop.
- `Protection`: spread, sessão, limites diários, drawdown e streak.
- `Execution`: envio de ordens, sincronização de posição e reconciliação com histórico.
- `Persistence`: perfis nomeados e autosave/autorestore por gráfico.
- `Normalization`: normalização de símbolo, volume, preço e especificações da corretora.
- `UI`: painel gráfico, validações visuais e tradução de ações da GUI em comandos.

## Perfis e Magic Number

O Magic Number pertence ao perfil/EA, não a cada estratégia individual. Essa decisão evita que uma mesma instância misture posições ou interfira em outro gráfico.

Perfis salvos devem ter Magic Numbers únicos. Isso impede, por exemplo, usar por engano um perfil calibrado para BTCUSD em XAUUSD ou B3. O runtime ainda tem uma proteção adicional para impedir duas instâncias ativas com o mesmo `símbolo + magic` no mesmo terminal.

## GUI

A GUI é parte central do projeto porque concentra operação visual, perfis e futuras validações. Ela não é apenas decoração.

Hoje ela permite:

- iniciar ou pausar o EA quando não há posição aberta;
- bloquear edição enquanto o EA está rodando ou gerenciando posição;
- salvar/carregar perfis;
- criar perfis novos;
- duplicar perfis com fluxo seguro, exigindo Magic Number único antes de salvar;
- validar lote, spread e magic com feedback visual.

## Documentação Técnica

- [Arquitetura](docs/ARCHITECTURE.md)
- [Decisões do Projeto](docs/DECISIONS.md)
- [Changelog](CHANGELOG.md)

## Compilação

Abra `Fusion.mq5` no MetaEditor 5 e compile. O projeto usa apenas MQL5 e includes padrão do MetaTrader 5.

Arquivos `*.ex5`, logs de compilação e arquivos locais do editor são ignorados pelo Git.

# Arquitetura do Fusion

Este documento descreve a arquitetura atual do Fusion e serve como guia para manutenção humana ou assistida por IA.

## Objetivo

O Fusion é um EA modular para MT5. A meta é permitir que estratégias, filtros, proteções e regras de risco sejam adicionados sem transformar o projeto em um bloco único difícil de testar e manter.

O projeto deve permanecer simples, mas não simplista: cada módulo precisa ter responsabilidade clara, poucas dependências e um ponto previsível de integração.

## Fluxo Principal

1. `Fusion.mq5` cria uma instância de `CFusionApplication`.
2. `CFusionApplication` carrega inputs, estado salvo do gráfico e módulos principais.
3. Estratégias e filtros são registrados no `CSignalManager`.
4. A cada tick, o EA sincroniza a posição, gerencia posição aberta e, se permitido, avalia novo sinal.
5. O sinal passa por filtros e por um resolvedor de conflito.
6. O plano de risco é calculado por `CRiskManager`.
7. A ordem é enviada por `CExecutionService`.
8. Proteções podem bloquear entrada ou forçar saída.
9. A GUI envia comandos para a aplicação, mas a aplicação continua sendo dona do estado operacional.

## Responsabilidades dos Módulos

### `Core`

Contém o ciclo de vida do EA, tipos compartilhados, inputs, logger, registro de instância e a classe `CFusionApplication`.

`CFusionApplication` é o orquestrador. Ele não deve virar um depósito de regras específicas de estratégia. Sempre que uma regra puder pertencer a risco, proteção, execução, persistência ou sinal, ela deve sair do core.

### `Signals`

Coordena estratégias, filtros e resolvedores.

As estratégias produzem sinais. Os filtros aprovam ou bloqueiam sinais. O resolvedor decide o que fazer quando mais de uma estratégia produz sinal ao mesmo tempo.

### `Strategies`

Cada estratégia herda de `CStrategyBase`.

Uma estratégia deve:

- carregar seus próprios parâmetros;
- inicializar e liberar indicadores;
- produzir sinal de entrada;
- produzir sinal de saída apenas para posições que ela abriu.

Uma estratégia não deve abrir ordem diretamente, alterar lote, nem fazer gestão financeira. Isso fica em `Risk`, `Protection` e `Execution`.

### `Filters`

Cada filtro herda de `CFilterBase`.

Um filtro deve responder se um sinal pode seguir adiante. Ele não deve gerar entrada por conta própria. Filtros são camadas de validação, não donos da posição.

### `Risk`

Calcula plano de entrada e gestão de posição:

- lote fixo;
- stop loss;
- take profit;
- TP parcial;
- breakeven;
- trailing stop.

Este módulo não envia ordens. Ele calcula o que deve ser feito.

### `Protection`

Bloqueia entradas ou força saídas com base em regras de segurança:

- spread;
- janela de sessão;
- limites diários;
- drawdown;
- streak de ganho/perda.

O módulo deve evoluir para expor motivos de bloqueio de forma estruturada para a GUI.

### `Execution`

Centraliza envio, fechamento parcial, fechamento total, modificação de stops e sincronização de posição.

Este é o único lugar que deve conversar diretamente com operações de trade de baixo nível, salvo exceções justificadas.

### `Persistence`

Salva e carrega perfis nomeados e estado automático por gráfico.

Perfis são configurações operacionais. Estado de gráfico é restauração local da instância. Esses dois conceitos não devem ser misturados.

### `Normalization`

Centraliza detalhes de símbolo e corretora:

- volume mínimo;
- volume máximo;
- step de volume;
- digits;
- point;
- tick size;
- tick value;
- stops level;
- freeze level.

Qualquer regra que dependa de especificação do ativo deve preferir este módulo.

### `UI`

A GUI é parte do projeto porque concentra operação em gráfico, perfis e validações visuais.

A UI não deve executar trade diretamente. Ela monta comandos e envia para `CFusionApplication`.

## Hot Reload

O projeto já possui `RELOAD_HOT`, `RELOAD_WARM` e `RELOAD_COLD`, e os módulos principais têm pontos de recarga.

Mesmo assim, a política atual é conservadora: a GUI bloqueia edição enquanto o EA está rodando ou existe posição aberta. Isso evita alterações ambíguas em produção e reduz risco operacional.

No futuro, hot reload pode ser reabilitado por categorias de alteração, desde que cada módulo declare claramente o que pode ser alterado com segurança em runtime.

## Próximas Evoluções Arquiteturais

- Criar um modelo estruturado para status de bloqueios.
- Expor estatísticas reais para `RESULTS` e `STATS`.
- Separar partes da `UIPanel.mqh` por aba quando a GUI crescer mais.
- Transformar trailing, breakeven, drawdown, streak e limites diários em submódulos mais independentes se a complexidade aumentar.
- Ampliar validações de volume, stops, freeze level e distância mínima.

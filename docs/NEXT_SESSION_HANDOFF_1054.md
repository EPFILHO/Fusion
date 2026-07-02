# Fusion 1.054 - Session Preparation

Este documento prepara a proxima sessao da 1.054. A 1.053 ficou como checkpoint funcional com commit/push feito em:

- `3cfbc0b Stabilize Fusion 1.053 protections and risk`

## Objetivo Da 1.054

Entrar na 1.054 com uma fase inicial de auditoria, limpeza e otimizacao curta antes de abrir novas features. A prioridade e preservar o que foi validado na 1.053 e reduzir risco acumulado em `Risk`, `Protect`, status operacional, persistencia e GUI.

## Preparacao De Pasta

Antes de codar, criar ou confirmar uma pasta propria para a 1.054. A 1.053 deve ficar como checkpoint intacto.

Repositorio atual da 1.053:

```text
C:\Users\Famil\Documents\Codex\2026-05-24\vamos-iniciar-a-versao-1-053\Fusion-1.053
```

Pasta sugerida para a 1.054:

```text
C:\Users\Famil\Documents\Codex\2026-05-24\vamos-iniciar-a-versao-1-053\Fusion-1.054
```

Opcao recomendada: clonar ou copiar a partir do estado remoto `main` ja atualizado, sem sobrescrever a 1.053.

## Inicio Obrigatorio

1. Rodar `git status`.
2. Ler:
   - `docs/NEXT_SESSION_HANDOFF_1054.md`;
   - `docs/NEXT_SESSION_HANDOFF_1053.md`;
   - `docs/FUNCTIONAL_EXPANSION_PLAN_1052.md`;
   - `docs/ARCHITECTURE.md`;
   - `CHANGELOG.md`.
3. Confirmar que a base contem o commit `3cfbc0b`.
4. Atualizar a versao para `1.054` somente depois de confirmar que a nova pasta/base esta correta.

## Estado Herdado Da 1.053

Ja entregue e validado parcialmente:

- Bollinger Filter separado da Bollinger Strategy.
- Descarte fixo de sinais bloqueados.
- Inputs amigaveis em portugues ASCII.
- Timeframes via enum `TIMEFRAME_*`.
- `CONFIG > RISK` com subtabs:
  - `LOTE`;
  - `SL/TP`;
  - `TP PARCIAL`;
  - `BREAKEVEN`;
  - `TRAILING`.
- `TP Final Livre`.
- BE e trailing com logs `SL antigo -> SL novo`.
- Comentarios de ordem com prefixo `EP Fusion - `.
- Resync de posicao aberta ao reiniciar EA/MT5.
- STREAK independente por Loss/Win, persistente e resistente a pausa/edicao.
- DAY/DD persistentes no chart state.
- Session/News/DAY/DD/Streak com destaque operacional amarelo.
- Status superior e `STATUS > Aviso` priorizando bloqueios operacionais.
- `stopsLevel` validado para SL/TP fixos de entrada.
- Opcoes de compensar spread para SL e TP.

## Auditoria Inicial Da 1.054

Fazer antes de qualquer feature:

- procurar codigo morto obvio introduzido na 1.053;
- procurar duplicacao simples entre validacoes de `DAY`, `DD`, `STREAK`, `SESSION` e `NEWS`;
- revisar nomes/rodapes de GUI que ficaram grandes demais;
- revisar se flags operacionais antigas sao limpas ao desligar protecoes;
- revisar se `STATUS`, status superior e abas amarelas contam a mesma historia;
- revisar se logs de protecao estao uteis sem excesso;
- confirmar que nenhuma mudanca tocou em `CFusionHitGroup`;
- confirmar que ComboBoxes seguem no padrao estabilizado, sem `Enable()`/`Disable()`;
- compilar com MetaEditor ao fim de qualquer mudanca de codigo.

## Pendencias Funcionais Prioritarias

### 1. DAY/DD em mercado aberto

Testar e, se necessario, ajustar:

- `Max Trades`;
- `Max Perda`;
- `Max Ganho`;
- `Acao Ganho = PARAR`;
- `Acao Ganho = ATIVAR DD`;
- DD financeiro;
- DD percentual;
- pico realizado;
- pico flutuante;
- reset automatico no novo dia operacional.

Observacao: limite diario de perda e calculado no tick. O EA fecha a mercado quando `P/L fechado + P/L flutuante` cruza o limite; o resultado final pode passar do limite por spread, slippage, comissao/swap, latencia entre ticks ou SL no servidor. O que nao pode acontecer e abrir nova operacao depois do limite atingido.

### 2. Log diagnostico de DAY

Adicionar log apenas quando DAY bloquear ou forcar fechamento, nao a cada tick:

- P/L fechado;
- P/L flutuante;
- P/L projetado;
- limite configurado;
- motivo: `Max Perda`, `Max Ganho` ou `Max Trades`.

Manter linguagem curta e clara.

### 3. Slippage na GUI

`Slippage` ja existe nos inputs. Decidir onde expor:

- sugestao conservadora: `CONFIG > RISK > LOTE`, por ser parametro de execucao da ordem;
- alternativa: `CONFIG > RISK > SL/TP`, por proximidade com risco/preco.

Validacao esperada:

- inteiro `0..1000` pontos inicialmente;
- rodape explicando que slippage e tolerancia de execucao, nao garantia de preco.

### 4. freezeLevel

Primeira fatia concluida na 1.054:

- BE;
- trailing;
- remocao de TP final livre.

O EA agora evita modificacoes de SL/TP quando o SL/TP atual ou desejado esta dentro do `freezeLevel` informado pela corretora. Nesses casos, a mudanca nao altera estado interno e fica para nova tentativa no proximo tick. A validacao em mercado segue em andamento.

### 5. Reconciliacao de fechamentos e virada do dia - implementada, em teste

Em 2026-06-30, uma perda de conexao no WIN mostrou uma ocorrencia reproduzivel: o historico continha a parcial de `5/10` contratos, mas o deal final ainda nao estava disponivel. O Fusion encontrou uma saida e registrou prematuramente apenas `155`, enquanto a posicao completa depois apareceu no MT5 com `550`.

A correcao agora:

- preserva o estado da posicao como fechamento pendente;
- exige que o volume acumulado de saida cubra todo o volume acumulado de entrada;
- bloqueia novas entradas e VM enquanto o resumo estiver incompleto;
- repete a consulta no tick, timer e depois de eventos de trade, sem spam de log;
- persiste a pendencia para reinicio ou troca de timeframe;
- usa o horario do ultimo deal para nao lançar fechamento antigo em DAY/DD/STREAK do dia atual;
- cancela a pendencia se a mesma posicao reaparecer apos oscilacao de conexao.

O chart state antigo pode ja conter um P/L incorreto sem qualquer posicao pendente. Por isso, a inicializacao tambem audita os deals de saida do dia por ativo/magic e corrige P/L bruto, Trades, Loss/Win/BE e streak quando houver divergencia. Se o terminal ainda estiver desconectado ou o historico estiver incompleto, a auditoria aguarda e repete automaticamente.

Entradas ficam bloqueadas durante essa espera. Historico vazio ou com menos trades que o estado confirmado nao pode sobrescrever o chart state. Ao trocar de magic com DD inativo, DAY/DD/STREAK sao reiniciados e reconstruidos para a nova identidade; com DD ativo, a troca de magic permanece proibida.

Os valores exibidos pelo Fusion sao `P/L Bruto`. Custos externos, comissao, swap e emolumentos nao sao estimados. Desenho e matriz de testes: `docs/CLOSURE_RECONCILIATION_PLAN_1054.md`.

### 6. Observacao de PLACED/DONE_PARTIAL

Antes de implementar uma maquina de estados de execucao, a 1.054 passa a registrar em CSV os resultados reais de:

- entrada;
- fechamento total;
- fechamento parcial.

O registro nao muda o comportamento atual. Ele existe para confirmar se `TRADE_RETCODE_PLACED` e `TRADE_RETCODE_DONE_PARTIAL` aparecem nas corretoras e ativos usados nos testes. Depois de um periodo de coleta, os arquivos devem ser analisados antes de qualquer alteracao no fluxo de execucao.

Finalidade, campos, localizacao e procedimento de coleta estao em `docs/TRADE_REQUEST_DIAGNOSTICS_1054.md`.

## Limpeza/Otimizacao Cautelosa

Preferir pequenas melhorias seguras:

- extrair helpers somente quando reduzir duplicacao real;
- remover wrappers sem chamada;
- reduzir mensagens repetidas;
- simplificar validacoes que ficaram duplicadas;
- documentar decisoes no rodape/status quando isso evitar confusao de produto.

Evitar nesta fase:

- refatoracao ampla de GUI;
- reestruturar abas;
- mudar layout de ComboBox sem bug reproduzivel;
- per-strategy TP/SL;
- ATR/range;
- overrides por estrategia.

## Smoke Tests Recomendados

Depois de cada fatia com codigo:

- compilar MetaEditor com `0 errors, 0 warnings`;
- iniciar/pausar pelo painel;
- salvar configuracao e confirmar pending changes;
- abrir operacao com MA Cross simples;
- confirmar filtros bloqueando entrada;
- confirmar que DAY/DD/STREAK bloqueados persistem apos pausa;
- confirmar que Session/News OFF limpam aviso superior;
- confirmar que status superior, `STATUS > Aviso` e aba amarela concordam.

## Prompt Para A Proxima Sessao

```text
Vamos iniciar a versao 1.054 do Fusion.

Use uma pasta propria para a 1.054, sem sobrescrever a 1.053. A base da 1.053 esta no commit:
3cfbc0b Stabilize Fusion 1.053 protections and risk

Comece rodando git status e lendo docs/NEXT_SESSION_HANDOFF_1054.md, docs/NEXT_SESSION_HANDOFF_1053.md, docs/FUNCTIONAL_EXPANSION_PLAN_1052.md, docs/ARCHITECTURE.md e CHANGELOG.md.

A 1.053 ficou como checkpoint funcional com Bollinger Filter separado, Risk com LOTE/SL-TP/TP PARCIAL/BREAKEVEN/TRAILING, TP Final Livre, BE/trailing validados, STREAK persistente, DAY/DD persistentes, Session/News/DAY/DD/Streak com destaque amarelo, stopsLevel para SL/TP e compensacao de spread.

Na 1.054, comece com auditoria, limpeza e otimizacao curta e segura. Procure codigo morto obvio, duplicacao simples, mensagens/rodapes confusos e pontos pequenos de risco acumulado, especialmente em Risk, Protection, EAApplication e partials de UI. Nao faca refatoracao grande de GUI, nao mexa em CFusionHitGroup e nao altere ComboBoxes alem do necessario.

Depois da auditoria, as pendencias prioritarias sao:
1. testar/ajustar DAY/DD em mercado aberto;
2. adicionar log diagnostico de DAY apenas quando bloquear/forcar fechamento;
3. expor Slippage na GUI;
4. validar freezeLevel em mercado e ampliar a cobertura se surgirem novos fluxos de modificacao de SL/TP.

Compile com MetaEditor apos qualquer mudanca de codigo. Nao commit/push sem pedido explicito.
```

# Fusion 1.053 - Next Session Handoff

Estado funcional de partida da 1.053: `0ee01a1 Log protection blocker recovery`, mais este handoff documental.
A 1.052 fica tratada como checkpoint funcional testavel, nao como roadmap completo de risk/filtros.

## Baseline Atual

- Branch alvo: `main`.
- Ultimo ciclo funcional testado pelo usuario na 1.052:
  - `MA Cross` com `Sinal Oposto`/`VM` fechando e revertendo corretamente.
  - `RSI Strategy` com modos `Saida da Zona`, `Dentro da Zona` e `Cruz. Media`, incluindo saida por `Cruz. Media`.
  - `Bollinger Strategy` com painel concreto, modos `FFFD`, `Toque/Rejeicao` e `Rompimento`.
  - `Trend Filter` e `RSI Filter` com paineis concretos, validacoes e logs de bloqueio por episodio.
  - `ENTRY` em `CONFIG > PROTECT` expondo `Spread` e `Direcao`.
  - Guard de AutoTrading/conexao retomando depois de reconnect do MT5.
  - Logs de sessao/news uma vez ao bloquear e uma vez ao limpar o bloqueio.
- Ultima compilacao de codigo antes deste handoff: MetaEditor com `0 errors, 0 warnings`.
- `CHANGELOG.md` contem a historia detalhada da 1.052.

## Guardrails

- Antes de codar, rodar `git status` e confirmar worktree limpo.
- Nao alterar comportamento durante a limpeza curta.
- Nao mexer em `CFusionHitGroup`.
- Nao usar `Enable()`/`Disable()` em `ComboBox`; manter o padrao que estabilizou as combos.
- Compilar fora da sandbox com MetaEditor apos cada mudanca de codigo.
- Trabalhar em fatias pequenas e pedir teste manual antes de commit/push, salvo pedido explicito.
- Separar limpeza, `Bollinger Filter` e `Risk`; nao misturar tudo no mesmo commit.
- Evitar inflar `Core/EAApplication.mqh`; se tocar nele, preferir extracao pequena e segura.

## Ordem Recomendada Para 1.053

1. Limpeza curta e segura, sem feature:
   - procurar lixo obvio, helpers mortos ou duplicacao simples;
   - revisar especialmente `Core/EAApplication.mqh` e os partials de `UI`;
   - nao iniciar refatoracao grande de GUI sem caso reproduzivel;
   - compilar se houver mudanca de codigo.
2. `Bollinger Filter`:
   - criar settings proprios com prefixo `bbFilter*`;
   - nao compartilhar campos ambiguos com a estrategia Bollinger (`bb*`);
   - criar runtime proprio derivado de `CFilterBase`;
   - filtro nunca gera entrada, apenas aprova ou bloqueia sinal recebido;
   - inspiracao Matrix: anti-squeeze bloqueia quando bandas estao estreitas;
   - modos a discutir/implementar com cautela: `Absoluto`, `Relativo (%)` e possivelmente `Percentil`;
   - painel em `FILTERS > BB`, com validacao, rodape claro e logs de bloqueio por episodio.
3. `Risk` global:
   - expor/validar TP parcial, BE e trailing;
   - validar combinacoes de TP/SL quando saida `TP/SL` estiver ativa;
   - deixar per-strategy TP/SL, ATR/range e overrides para uma fase posterior.

## Pendencias Conhecidas

- `STATUS` ainda pode evoluir para telemetria de sinais/bloqueios mais rica: ultimo sinal, origem, filtro, motivo e resultado.
- `CONFIG > PROTECT` ainda pode ser limpo futuramente para ficar mais parecido com o padrao concreto de `STRATS`/`FILTERS`.
- A 1.053 recebeu apenas mitigacao pontual para residuos visuais de status no topo ao trocar abas. A limpeza arquitetural da GUI em duas fases (esconder tudo do grupo e depois mostrar somente o ativo) fica como divida tecnica futura, fora do escopo desta versao.
- Residuos visuais em troca de abas/subabas devem continuar sendo tratados apenas com reproduzibilidade clara, para nao reabrir regressao de ComboBox.
- Novo dia/reset diario e outros logs de transicao podem ser melhorados em fatia propria, sem misturar com filtro/risco.

## Prompt Para A Proxima Sessao

```text
Vamos iniciar a versao 1.053 do Fusion no repositorio:
C:\Users\Famil\Documents\Codex\2026-05-12\vamos-iniciar-a-1-052-do\Fusion-1.052

Comece rodando git status e lendo docs/NEXT_SESSION_HANDOFF_1053.md, docs/FUNCTIONAL_EXPANSION_PLAN_1052.md, docs/ARCHITECTURE.md e CHANGELOG.md. A 1.052 ficou como checkpoint funcional testavel: MA/RSI/Bollinger Strategy, Trend Filter, RSI Filter, direcao de entrada, guards de AutoTrading/conexao e logs de sessao/news estao funcionando.

Quero seguir com cautela. Primeiro faca uma limpeza/otimizacao curta e segura, sem mudar comportamento: procure codigo morto obvio, duplicacao simples ou pontos pequenos que reduzam risco, especialmente em EAApplication e partials de UI. Nao faca refatoracao grande de GUI e nao mexa nos ComboBoxes alem do necessario. Nao toque em CFusionHitGroup. Compile com MetaEditor se houver qualquer mudanca de codigo.

Depois da limpeza, se estiver tudo ok, vamos iniciar o Bollinger Filter. Ele deve ser separado da Bollinger Strategy: settings proprios com prefixo bbFilter*, runtime proprio derivado de CFilterBase, painel em FILTERS > BB, validacoes e rodape claro. O filtro nao abre trades; apenas aprova ou bloqueia sinais. Use como inspiracao o anti-squeeze do EPBot Matrix: bloquear entradas quando as bandas estiverem estreitas, com modos Absoluto, Relativo (%) e talvez Percentil. Antes de codar o modo Percentil, confirme se vale entrar nessa complexidade agora.

Nao avance para Risk nesta mesma fatia sem alinharmos. A fase seguinte sera risk global: TP parcial, breakeven, trailing e validacoes de TP/SL. Per-strategy TP/SL, ATR/range e overrides ficam para depois.

Trabalhe em fatias pequenas, explique o que vai tocar antes de editar, compile apos codigo, e nao commit/push sem eu pedir explicitamente.
```

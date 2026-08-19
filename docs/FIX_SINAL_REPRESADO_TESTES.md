# Roteiro de teste — sinal represado apos restauracao da permissao

Branch `fix/stale-signal-reconnect`. Marque cada caixa **so depois de rodar**. O que nao rodar fica
desmarcado, com o motivo.

**Conta DEMO e lote minimo.** O Bloco B exige derrubar a rede da maquina; nao faca isso com posicao
real aberta.

---

## Preparacao

- [ ] **P1 — Compilar mantendo o vinculo.** Sem `-KeepLink` o vinculo e removido no fim e o EA some do
  Navigator.

  ```powershell
  cd 'C:\Users\Famil\Documents\Codex\Fusion\Fusion-2.000'
  .\build-linked.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe' -KeepLink
  ```

  Esperado: `0 errors, 0 warnings` nos quatro alvos.

- [ ] **P2 — Achar o EA no MT5.** Navigator > Expert Advisors > botao direito > *Atualizar*. O EA
  aparece em `FusionBuild\Fusion-2.000\Fusion`.

- [ ] **P3 — Conferir o binario ANTES de interpretar qualquer teste.** Ao anexar, o log deve trazer
  `Painel: canvas (GUI 2.0)`. Confira tambem a data/hora de `Fusion.ex5` na pasta do projeto: tem de
  ser a da compilacao de agora. *(Um `.ex5` desatualizado ja invalidou uma rodada inteira.)*

- [ ] **P4 — Ligar o debug.** Nas propriedades do EA (F7), `Ativar logs detalhados de debug` = `true`.
  Sem isso a linha que prova o consumo dos sinais nao aparece.

- [ ] **P5 — Configuracao que produz cruzamento rapido.** Grafico **M1**; so **MA Cross** ligada (RSI e
  Bollinger desligadas, para nao misturar origem de sinal); modo de entrada `Candle seguinte`; medias
  curtas (ex.: rapida 3, lenta 8); **nenhum filtro e nenhuma protecao que bloqueie** — com o
  `CanOpen()` bloqueando, a avaliacao de entrada nem roda e o teste nao prova nada. Simbolo liquido e
  em pregao.

**Onde olhar:** aba **Experts** do MT5 (nao a aba Journal). As linhas citadas abaixo sao trechos; o
prefixo do Fusion vem antes.

---

## Bloco A — AutoTrading desligado e religado

Exercita a **transicao** e a **barreira**. ⚠️ **Nao reproduz o defeito original**: os ticks continuam
chegando e o EA vai consumindo os sinais a cada um. Serve para provar que a barreira segura, nao que
o represamento acabou.

- [ ] **A1 — Transicao percebida.** Com o EA iniciado e sem posicao, desligue o AutoTrading (botao da
  barra do MT5). Espere ~1 minuto. Religue.

  Esperado, na ordem:
  - `WARN ... AUTOTRADE ... AutoTrading desabilitado no MT5. Habilite para iniciar.`
  - ao religar: `INFO ... AUTOTRADE ... Trading habilitado novamente. Aguardando sinal formado apos a liberacao.`
  - logo depois: `DEBUG ... SIGNAL ... Sinais descartados durante bloqueio: Permissao de trading restaurada.`

  A segunda linha e a **unica** vez que ela aparece por transicao — se repetir a cada segundo, o
  requisito de nao poluir o log falhou.

- [ ] **A2 — Nenhuma ordem no candle da liberacao.** Religue o AutoTrading **no meio de um candle M1**
  em que o indicador visual mostre um cruzamento recente. Nenhuma ordem pode nascer nesse candle,
  mesmo que o cruzamento esteja visivel no grafico.

  Evidencia: **ausencia** de `INFO ... STRAT_MA ... NEXT_CANDLE ...` e ausencia de linha `TRADE`
  enquanto aquele candle estiver aberto. *(Um cruzamento barrado nao gera linha propria — a prova e
  o cruzamento visivel no grafico sem log e sem ordem.)*

- [ ] **A3 — Sinal genuinamente novo entra.** Continue observando. No primeiro cruzamento formado num
  candle **iniciado depois** da liberacao, o EA deve abrir normalmente.

  Esperado: `INFO ... STRAT_MA ... NEXT_CANDLE fast[2]=... => BUY` (ou `SELL`) seguido da ordem.
  Anote o horario do candle: ele tem de ser posterior ao candle em que voce religou.

- [ ] **A4 — Com posicao aberta, o gerenciamento retoma.** Com uma posicao aberta, desligue o
  AutoTrading, espere ~1 minuto, religue.

  Esperado: aviso com o texto de posicao (`... Gerenciamento da posicao interrompido. Habilite
  imediatamente.`); ao religar, o gerenciamento volta e **nada de SL/TP/trailing/breakeven/parcial e
  perdido** — a posicao continua com os mesmos niveis e o painel Resultados segue coerente.

- [ ] **A5 — PAUSAR/INICIAR intactos.** Sem mexer em AutoTrading: PAUSAR, esperar um candle, INICIAR.
  O comportamento tem de ser o de sempre — o EA aguarda um sinal novo, sem nenhuma mensagem nova.

- [ ] **A6 — Operacao normal.** Deixe rodando alguns candles sem tocar em nada. `Candle seguinte`
  entra no cruzamento; troque para `Segundo candle` e confirme que espera um candle antes de entrar.
  Com a barreira desarmada, nada muda em relacao ao comportamento conhecido.

---

## Bloco B — desconexao real

Este e o **unico** bloco que reproduz o defeito original: sem ticks, o estado das estrategias congela
no instante da queda.

- [ ] **B1 — Cruzamento formado no escuro NAO entra.** Com o EA iniciado, **sem posicao aberta**,
  desative o adaptador de rede (ou desligue o Wi-Fi) por **3 a 5 minutos** — tempo suficiente para o
  M1 formar candles e cruzar. Reative a rede e deixe o MT5 reconectar.

  Esperado:
  - `WARN ... CONNECTION ... Conexao com servidor perdida. Entradas bloqueadas.`
  - na volta: `INFO ... CONNECTION ... Conexao com servidor restaurada. Verificando permissoes de trading.`
  - `INFO ... AUTOTRADE ... Trading habilitado novamente. Aguardando sinal formado apos a liberacao.`
  - **nenhuma ordem** no primeiro tick, mesmo com o grafico mostrando o cruzamento que se formou
    durante a queda.

  ⚠️ **Este e o caso que motivou todo o trabalho.** Antes da correcao, a ordem nascia aqui.

- [ ] **B2 — Recuperacao.** Continue observando ate o proximo cruzamento formado com o EA ja
  conectado. Ele deve entrar normalmente. Se **nao** entrar, a quarentena nao desarmou — anote o
  horario e pare o teste.

- [ ] **B3 — Repetir com posicao aberta.** Com uma posicao aberta, repita a queda de rede por ~2
  minutos. Na volta: gerenciamento retoma, nenhum estado de saida se perde, e nenhuma **entrada** nova
  nasce do periodo sem ticks.

---

## O que registrar

Para cada caixa marcada, guarde:

1. **trecho do log** da aba Experts, com horario;
2. **captura do grafico** no momento — o cruzamento barrado so se prova visualmente;
3. horario de abertura do candle da liberacao e do candle que finalmente entrou.

## Limitacao conhecida de observabilidade

Quando a barreira barra um sinal, **nao ha linha de log propria**. A prova e indireta: cruzamento
visivel no grafico, sem `STRAT_MA` e sem ordem. Se isso tornar o aceite dificil de defender, existe a
opcao de instrumentar — uma linha `DEBUG` no bloqueio, limitada a uma por candle por estrategia (o
sinal ja e consumido, entao nao repetiria por tick). **Nao foi feito**: e mudanca de codigo depois da
auditoria aprovada, e a decisao e do usuario.

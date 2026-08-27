# Roteiro de teste — sinal represado apos restauracao da permissao

Branch `fix/stale-signal-reconnect`. Tres testes dirigidos. Marque cada caixa **so depois de rodar**;
o que nao rodar fica desmarcado, com o motivo.

**Conta DEMO e lote minimo.**

---

## Preparacao

- [ ] **P1 — Compilar mantendo o vinculo.** Sem `-KeepLink` o vinculo e removido no fim e o EA some do
  Navigator.

  ```powershell
  cd 'C:\Users\Famil\Documents\Codex\Fusion\Fusion-2.000'
  .\build-linked.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe' -KeepLink
  ```

- [ ] **P2 — Achar o EA.** Navigator > Expert Advisors > botao direito > *Atualizar*. Ele aparece em
  `FusionBuild\Fusion-2.000\Fusion`.

- [ ] **P3 — Conferir o binario ANTES de interpretar qualquer teste.** Ao anexar, o log deve trazer
  `Painel: canvas (GUI 2.0)`, e a data/hora de `Fusion.ex5` na pasta do projeto tem de ser a da
  compilacao de agora. *(Um `.ex5` desatualizado ja invalidou uma rodada inteira.)*

- [ ] **P4 — Ligar o debug.** Propriedades do EA (F7) > `Ativar logs detalhados de debug` = `true`.
  **Sem isso a linha que prova o bloqueio nao e impressa** e o teste volta a depender de deducao.

- [ ] **P5 — Configuracao.** Grafico **M1**, so **MA Cross** ligada (RSI e Bollinger desligadas),
  modo `Candle seguinte`, medias curtas (ex.: 3 e 8). **Nenhum filtro e nenhuma protecao que
  bloqueie** — com o `CanOpen()` bloqueando, a avaliacao de entrada nem roda e o teste nao prova nada.

**Onde olhar:** aba **Experts** do MT5 (nao a Journal).

---

## As tres linhas que interessam

| quando | linha |
|---|---|
| permissao volta | `INFO ... AUTOTRADE ... Trading habilitado novamente. Aguardando sinal formado apos a liberacao.` |
| estado consumido | `DEBUG ... SIGNAL ... Sinais descartados durante bloqueio: Permissao de trading restaurada.` |
| **sinal recusado** | `DEBUG ... SIGNAL ... Sinal bloqueado pela quarentena - MA Cross. Candle do sinal 2026.08.19 16:03:00, barreira 2026.08.19 16:05:00.` |

A terceira e evidencia direta, **uma linha por candle de sinal, por estrategia**, nunca por tick.
Compare os dois horarios: o candle do sinal e igual ou anterior ao da barreira, e e por isso que ele
foi recusado.

### ⚠️ Duas camadas, duas evidencias diferentes

**A linha de quarentena NAO aparece em todo caso barrado.** Sao dois cenarios:

| cenario | quem barra | o que procurar |
|---|---|---|
| **A** — cruzamento **ja fechado** durante a queda; na volta ele ja esta em `[1]` | `PrimeEntryStates()` consome o `[1]` antes de a estrategia consultar a barreira | `Sinais descartados durante bloqueio` + cruzamento visivel no grafico + **nenhuma ordem**. A linha de quarentena **provavelmente nao aparece** |
| **B** — candle estava **aberto** na liberacao e fecha depois, apresentando o sinal | a barreira, na deteccao | `Sinal bloqueado pela quarentena - ...` |

**O defeito que voce relatou e tipicamente o A.** Entao **nao** trate a busca por `quarentena` como
prova do caso original: no A a evidencia continua sendo a linha generica de descarte mais o
cruzamento no grafico sem ordem. A palavra `quarentena` e util como monitoramento, e prova o caso B.

---

## Teste 1 — AutoTrading desligado e religado

Determinstico, leva um minuto. Prova a **transicao**; nao prova o represamento (os ticks continuam
chegando durante o bloqueio, e o EA vai consumindo os sinais a cada um).

- [x] Com o EA iniciado e sem posicao, desligue o AutoTrading. Espere ~1 minuto. Religue.

  Esperado: o aviso de bloqueio, depois a linha `Trading habilitado novamente...` **uma unica vez**, e
  em seguida `Sinais descartados durante bloqueio: Permissao de trading restaurada.` Se a linha da
  liberacao repetir a cada segundo, o requisito de nao poluir o log falhou.

---

## Teste 2 — desconexao sem posicao aberta

O caso que motivou o trabalho.

⚠️ **Uma queda curta pode nao provar nada.** O teste so e conclusivo se um **cruzamento se formar
durante a desconexao** — e isso nao se controla pelo relogio. Nao existe duracao que garanta
cruzamento. Se voltar sem cruzamento no periodo, o teste e **inconclusivo** e precisa ser repetido.

**Faca pelo menos uma desconexao controlada em conta demo.** Observar no dia a dia e bom
monitoramento, mas nao basta para aceitar a correcao: pode demorar muito, e — pelo cenario A acima —
o evento pode ser consumido pelo priming **sem gerar a palavra `quarentena`**. Se a queda passar sem
cruzamento, marque **inconclusivo** e repita oportunamente. Forcar a queda rende mais se voce ja vir
o preco perto de um cruzamento.

- [x] **Sinal formado na queda foi barrado.** Sem posicao aberta, desconecte (desative o adaptador de
  rede ou o Wi-Fi), aguarde, reconecte.

  Esperado sempre: `WARN ... CONNECTION ... Conexao com servidor perdida.`, na volta
  `INFO ... CONNECTION ... Conexao com servidor restaurada...`, a linha de `AUTOTRADE` e
  `Sinais descartados durante bloqueio: Permissao de trading restaurada.`

  E entao, conforme o caso:
  - **cenario A** (cruzamento fechou durante a queda): cruzamento visivel no grafico, **nenhuma
    ordem**, e possivelmente **nenhuma** linha de quarentena. Aqui a captura do grafico e a evidencia.
  - **cenario B** (o candle aberto na volta fecha e apresenta o sinal):
    `Sinal bloqueado pela quarentena - MA Cross`, com o candle do sinal igual ou anterior a barreira.

  Sem cruzamento nenhum no periodo: **inconclusivo**, repetir.

- [x] **Sinal realmente novo entra.** Continue observando ate um cruzamento formado com o EA ja
  conectado. Ele deve entrar normalmente: `INFO ... STRAT_MA ... NEXT_CANDLE ... => BUY` (ou `SELL`)
  seguido da ordem. Se **nao** entrar, a quarentena nao desarmou — anote o horario e pare.

---

## Teste 3 — desconexao com posicao aberta

- [x] Com uma posicao aberta, repita a queda de rede. Na volta: o gerenciamento retoma (SL/TP,
  trailing, breakeven e parcial seguem coerentes, nada zerado no painel Resultados) e **nenhuma
  entrada nova** nasce do periodo sem ticks.

---

## Regressao, depois

Nao precisa ser na mesma sessao. Depois que os tres acima fecharem:

- [ ] PAUSAR/INICIAR continuam consumindo o estado vigente como antes;
- [ ] operacao normal sem desconexao mantem `Candle seguinte` e `Segundo candle`;
- [ ] RSI e Bollinger ligadas nao reapresentam sinais acumulados.

---

## O que registrar

Para cada caixa marcada: **trecho do log** com horario e, no Teste 2, a **captura do grafico** com o
cruzamento. Anote o horario de abertura do candle da liberacao e o do candle que finalmente entrou.

---

## Registro de execucao — 2026-08-19, conta demo

Binario: `b48e5da`. `WINV26`, M5, posicao aberta (Magic 202). Debug ligado a partir de 17:12:46
(`[DEBUG][INIT] Restore=0ms...` presente); antes disso estava desligado.

### Fechado

**Teste 3 — desconexao com posicao aberta.** Queda 17:13:28 -> 17:14:14 (46 s), EA iniciado as
17:12:50.

- transicao percebida **uma unica vez**: `[AUTOTRADE] Trading habilitado novamente. Aguardando sinal
  formado apos a liberacao.` as 17:14:14.239;
- gerenciamento retomou em **34 ms**: `[RISK] Trailing stop updated SL 170785 -> 170805` as
  17:14:14.273;
- o SL partiu de **170785**, onde tinha parado as 17:10:40 — atravessou a queda **e** o reinicio do EA
  das 17:12:46 sem perder estado de saida.

⚠️ A outra metade do criterio ("nenhuma entrada represada") e **vacua com posicao aberta**: entradas
estao bloqueadas de todo jeito. O Teste 3 nao substitui o Teste 2.

**Quatro transicoes, uma linha cada** (17:11:48, 17:12:04, 17:14:14, 17:14:37). Nenhuma repeticao por
timer ou tick — requisito de nao poluir o log conferido em execucao.

**Ramo de aviso com posicao** conferido de brinde: `AutoTrading desabilitado no MT5. Gerenciamento da
posicao interrompido. Habilite imediatamente.`

### Em aberto

- **Teste 1** — as transicoes de AutoTrading foram vistas, mas a linha `Sinais descartados durante
  bloqueio` **nao apareceu, e nao podia**: `DiscardBlockedEntrySignals()` exige `m_started &&
  !hasPosition`. O criterio so e observavel **sem posicao aberta**.
- **Teste 2** — nao executado.
- **Nenhuma barreira foi exercitada em nenhuma das quatro transicoes.** As duas quedas cairam inteiras
  dentro do candle M5 das 17:10 (17:11:05–17:11:48 e 17:13:28–17:14:14), sem atravessar fechamento.
  Sem candle fechando, nenhum sinal se forma e nada e barrado — nem no cenario A nem no B.

### Ajuste combinado

Passar para **M1**. Em M5 a queda precisa de 5+ minutos alinhados com um cruzamento; em M1 uma queda
de 2–3 minutos ja atravessa varios fechamentos e, com medias curtas, o cruzamento aparece sozinho.

---

## Registro de execucao — Teste 2, 2026-08-19, `BTCUSD` M1, conta demo

Binario `b48e5da`, Magic 987, sem posicao aberta, EA iniciado as 17:25:25. Horarios do log sao locais;
os horarios DENTRO das mensagens sao de servidor (+6h).

### O sinal represado foi barrado — cenario B, com prova direta

Queda 17:26:40.989 -> 17:27:18.974 (38 s), atravessando o fechamento do candle das 23:26.

```
17:27:18.974  [AUTOTRADE] Trading habilitado novamente. Aguardando sinal formado apos a liberacao.
17:27:18.974  [SIGNAL]    Sinais descartados durante bloqueio: Permissao de trading restaurada.
17:27:19.519  [SIGNAL]    Sinal bloqueado pela quarentena - MA Cross. Candle do sinal 23:26:00, barreira 23:26:00.
```

⚠️⚠️ **A barreira pegou um sinal que o priming NAO consumiu.** Meio segundo depois do descarte, a MA
apresentou o cruzamento do candle das 23:26 — aberto quando a conexao caiu e fechado durante a queda.
Sem a barreira, `crossBarTime` (23:26) seria diferente do `m_lastCrossTime` gravado pelo priming
(23:25), o modo `Candle seguinte` retornaria o sinal e **uma ordem teria nascido as 17:27:19.519**.

E a prova em execucao de que consumir o `[1]` vigente nao basta — o segundo achado da auditoria.
Repare que **candle do sinal e barreira sao iguais** (23:26:00): quem barrou foi o `>` estrito. Com
`>=` teria entrado.

Nenhuma ordem em nenhuma das quatro transicoes; a linha de quarentena nao repetiu (dedup). As linhas
de descarte as 17:27:28 e 17:28:28 sao o throttle de 60 s ja existente em
`ShouldLogDiscardedSignalDebug`, nao sao por tick. As 17:27:34, com a conexao voltando e o AutoTrading
ainda desligado, o guard corretamente **nao** anunciou liberacao.

### O sinal novo entrou

Quarentena rearmada as 17:28:37. Depois de dois ciclos PAUSAR/INICIAR (17:29:02/17:30:09 e
17:30:16/17:32:21, todos normais):

```
17:33:58.999  [STRAT_MA] NEXT_CANDLE fast[2]=68700.28346 fast[1]=68745.44782 slow[2]=68708.35000 slow[1]=68720.60333 => BUY
17:33:59.226  [EXEC]     Entry sent by MA Cross (BUY)
```

Inversao de sinal entre `[2]` e `[1]`, cruzamento legitimo, candle muito posterior a barreira. **A
quarentena desarmou sozinha.**

### Fresta observada, para decisao da auditoria

A barreira foi armada as 17:27:18.974 — servidor **23:27:18** — e capturou **23:26:00** como candle
corrente: a serie ainda nao tinha criado o candle das 23:27, porque nenhum tick havia chegado nesse
minuto. A barreira ficou **um candle mais velha** que o candle realmente em formacao.

Aqui nao houve consequencia (o sinal era do proprio 23:26). Mas um cruzamento no candle das 23:27
passaria (`23:27 > 23:26`), e esse candle comecou 18 s **antes** de a permissao voltar — o contrato
diz "candle cuja formacao comecou depois da restauracao". Estreito, porem **nao teorico: ocorreu na
primeira tentativa**, e erra para o lado menos conservador. Nenhuma alteracao de motor feita: a
auditoria proibiu nesta rodada.

### Observacao menor

O disparo veio as 23:33:58, quase no fim do candle. E o comportamento pre-existente do `Candle
seguinte` (aceita o cruzamento no primeiro tick recebido em qualquer momento do candle corrente),
citado no diagnostico original e **nao alterado** por esta correcao.

---

## ⚠️ Teste 2 INVALIDADO pela correcao do P1 — repetir com o binario novo

A fresta registrada acima virou achado P1 da auditoria e foi corrigida: a captura da barreira saiu de
`SuspendEntriesUntilFreshCandle()` e ficou **so** em `RefreshFreshCandleBarrier()`, debaixo de um
tick. A barreira nasce desconhecida, e desconhecida bloqueia.

**A segunda metade do Teste 2 (sinal novo entrando) precisa ser refeita com o binario corrigido** —
aprovar a recuperacao de uma implementacao com janela conhecida nao vale como aceite. As duas caixas
do Teste 2 voltam a valer como **a repetir**; o registro da execucao de 2026-08-19 fica como historico
do que a versao anterior fazia.

O que muda na observacao: a barreira passa a ser captada no **primeiro tick que alcancar a avaliacao
normal de entrada**, entao o horario que aparece na linha `Sinal bloqueado pela quarentena` e o candle
corrente **daquele** momento, nunca um candle velho herdado do ultimo tick antes da queda.

**Criterio de conferencia — a barreira tem de ser igual ou POSTERIOR ao candle da restauracao, nunca
anterior.** Compare com o horario de servidor da linha de `AUTOTRADE`:

| barreira | veredito |
|---|---|
| **anterior** ao candle da restauracao | **defeito** — e o P1 que motivou o `b699a60` (visto em 19/08: restauracao `23:27:18`, barreira `23:26:00`) |
| **no mesmo** candle | correto, caso comum |
| num candle **posterior** | tambem correto e seguro |

O terceiro caso acontece quando o primeiro tick que alcanca a avaliacao chega depois da virada:
restauracao as `23:27:59`, tick util as `23:28:01`, barreira `23:28`. Mais conservador, nao menos.

⚠️ "Primeiro tick" nunca significa "o proximo tick do simbolo": significa **o primeiro que chega ate
`GetEntryDecision()`**. Com posicao aberta, EA pausado ou protecao bloqueando, a avaliacao nem roda e a
captura espera — de proposito.

---

## Registro de execucao — binario corrigido, 2026-08-19 noite, `BTCUSD` M1, demo

`Fusion.ex5` de 20:06:33 (arvore em `dfa04cd`, comportamento identico a `b699a60`), EA anexado as
20:47:17. Horarios de log sao locais; os de dentro das mensagens sao de servidor (**+6h**).

### Teste 1 — FECHADO

```
21:46:09.803  [AUTOTRADE] Trading habilitado novamente. Aguardando sinal formado apos a liberacao.
21:46:09.803  [SIGNAL]    Sinais descartados durante bloqueio: Permissao de trading restaurada.
```

A segunda linha era o criterio que faltava — exige `!hasPosition`, e nas tentativas de 17h havia
posicao aberta.

### Teste 2 — o P1 corrigido, provado por comparacao

Queda **21:54:58 -> 21:57:42** (2 min 44 s), sem posicao (fechada as 21:52:50, P/L +0.35),
atravessando o fechamento dos candles `03:55` e `03:56` de servidor.

```
21:57:42.689  [CONNECTION] Conexao com servidor restaurada.
21:57:42.689  [AUTOTRADE]  Trading habilitado novamente. Aguardando sinal formado apos a liberacao.
21:57:42.689  [SIGNAL]     Sinais descartados durante bloqueio: Permissao de trading restaurada.
21:57:42.953  [SIGNAL]     Sinal bloqueado pela quarentena - MA Cross. Candle do sinal 03:56:00, barreira 03:57:00.
```

| | restauracao (servidor) | barreira | veredito |
|---|---|---|---|
| binario anterior, 19/08 tarde | `23:27:18` | `23:26:00` — **um candle ANTES** | P1: candle iniciado antes da liberacao viraria elegivel |
| binario corrigido, 19/08 noite | `03:57:42` | `03:57:00` — **o proprio candle** | correto |

⚑ **Mesmo simbolo, mesmo timeframe, mesma manobra.** A barreira deixou de herdar o candle velho da
serie parada e passou a nascer do primeiro tick que alcanca a avaliacao de entrada. O sinal barrado
veio do candle `03:56`, que se formou e fechou **inteiro dentro da queda** — represamento classico,
recusado.

### Nota sobre linhas ausentes nas quedas curtas

Em `21:58:22` e `21:58:36` as transicoes foram anunciadas, mas sem a linha
`Sinais descartados durante bloqueio`. Nao e falha: o `ShouldLogDiscardedSignalDebug` suprime o mesmo
motivo dentro de 60 s. O priming roda de qualquer forma — a supressao e so do log.

### Ciclo completo num log so — 21:58 a 22:01

O que faltava: quarentena armada por **desconexao**, sinal represado recusado e entrada nova, em
sequencia, sem nenhuma outra manobra no meio.

```
21:58:35.427  [CONNECTION] Conexao com servidor perdida.
21:58:36.414  [CONNECTION] Conexao com servidor restaurada.
21:58:36.414  [AUTOTRADE]  Trading habilitado novamente. Aguardando sinal formado apos a liberacao.
21:59:00.097  [SIGNAL]     Sinal bloqueado pela quarentena - MA Cross. Candle do sinal 03:58:00, barreira 03:58:00.
22:01:00.206  [STRAT_MA]   NEXT_CANDLE fast[2]=69421.63480 fast[1]=69453.64493 slow[2]=69439.21333 slow[1]=69438.92667 => BUY
22:01:00.431  [EXEC]       Entry sent by MA Cross (BUY)
```

| momento (servidor) | o que aconteceu |
|---|---|
| `03:58:36` | permissao volta; barreira captada em `03:58` — **o proprio candle da restauracao** |
| `03:59:00` | cruzamento do candle `03:58` recusado: `03:58 > 03:58` e falso. **De novo o `>` estrito** |
| `04:01:00` | cruzamento do candle `04:00` aceito: `04:00 > 03:58`. Inversao correta (`fast` cruza de baixo para cima). Ordem 225 ms depois |

Nao houve entrada em `04:00:00` porque nao houve cruzamento no candle `03:59` — ausencia esperada, nao
bloqueio.

**Os quatro itens do aceite fechados no binario corrigido**: desconexao em M1; barreira nunca anterior
ao candle da restauracao; sinal represado recusado; cruzamento genuinamente novo entrando.

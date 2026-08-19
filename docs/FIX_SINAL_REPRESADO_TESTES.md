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

A terceira e a evidencia direta do aceite: **uma linha por candle de sinal, por estrategia**, nunca
por tick. Compare os dois horarios — o candle do sinal e igual ou anterior ao da barreira, e e por
isso que ele foi recusado.

Procure por `quarentena` no filtro da aba Experts.

---

## Teste 1 — AutoTrading desligado e religado

Determinstico, leva um minuto. Prova a **transicao**; nao prova o represamento (os ticks continuam
chegando durante o bloqueio, e o EA vai consumindo os sinais a cada um).

- [ ] Com o EA iniciado e sem posicao, desligue o AutoTrading. Espere ~1 minuto. Religue.

  Esperado: o aviso de bloqueio, depois a linha `Trading habilitado novamente...` **uma unica vez**, e
  em seguida `Sinais descartados durante bloqueio: Permissao de trading restaurada.` Se a linha da
  liberacao repetir a cada segundo, o requisito de nao poluir o log falhou.

---

## Teste 2 — desconexao sem posicao aberta

O caso que motivou o trabalho.

⚠️ **Uma queda curta pode nao provar nada.** O teste so e conclusivo se um **cruzamento se formar
durante a desconexao** — e isso nao se controla pelo relogio. Nao existe duracao que garanta
cruzamento. Se voltar sem cruzamento no periodo, o teste e **inconclusivo** e precisa ser repetido.

**Por isso o caminho recomendado e observar no uso normal:** deixe o EA operando no dia a dia e, na
primeira queda de conexao que coincidir com um cruzamento, a evidencia fica gravada sozinha. Procure
`quarentena` no Experts de tempos em tempos. Forcar a queda so vale a pena se voce vir o preco perto
de um cruzamento.

- [ ] **Sinal formado na queda foi barrado.** Sem posicao aberta, desconecte (desative o adaptador de
  rede ou o Wi-Fi), aguarde, reconecte.

  Esperado: `WARN ... CONNECTION ... Conexao com servidor perdida.`, na volta
  `INFO ... CONNECTION ... Conexao com servidor restaurada...`, a linha de `AUTOTRADE`, e
  **`Sinal bloqueado pela quarentena - MA Cross`** com o candle do sinal anterior ou igual a barreira.
  Nenhuma ordem nesse momento.

  Se nao houver linha de quarentena e o grafico nao mostrar cruzamento no periodo: **inconclusivo**,
  repetir.

- [ ] **Sinal realmente novo entra.** Continue observando ate um cruzamento formado com o EA ja
  conectado. Ele deve entrar normalmente: `INFO ... STRAT_MA ... NEXT_CANDLE ... => BUY` (ou `SELL`)
  seguido da ordem. Se **nao** entrar, a quarentena nao desarmou — anote o horario e pare.

---

## Teste 3 — desconexao com posicao aberta

- [ ] Com uma posicao aberta, repita a queda de rede. Na volta: o gerenciamento retoma (SL/TP,
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

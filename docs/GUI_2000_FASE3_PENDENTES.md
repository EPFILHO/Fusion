# Fase 3 — o que falta, e quanto custa cada um

Retrato de **2026-08-16**, HEAD `c7312fd`, arvore limpa, gate 0/0 nos seis alvos.

`docs/GUI_2000_FASE3_TESTES.md` esta com **77 passos marcados e 12 pendentes**.
Os blocos **D e E — a razao de a Fase 3 existir — estao inteiros e aprovados**:
sao os caminhos em que a gravacao FALHA, que nunca tinham rodado fora do
compilador.

Este documento existe porque "faltam 12" nao diz o que interessa. Alguns custam
trinta segundos e outros exigem uma posicao aberta pelo EA numa conta real.

---

## 1. ⚠️ A conta nao e 12 — a matriz I2 nao tem marcacao

A tabela **I2.1 a I2.19** (secao "Cabecalho: por que a acao nao esta disponivel")
e uma **tabela**, nao uma lista de caixas. So o `I2.13` e o `I2.14` viraram
passos marcaveis; **os outros 17 estados nao tem `[ ]` nenhum** e portanto nao
entram na contagem.

Nao e a mesma numeracao do bloco I (`I1`…`I6`) — o rotulo `I2` aparece com dois
sentidos no roteiro, e isso confunde. Fica registrado como divida do documento.

**Consequencia pratica:** dos 17 estados da matriz, **seis exigem posicao aberta**
(I2.11, I2.12, I2.15, I2.17, I2.18, I2.19) e caem na mesma dificuldade do `I6`
abaixo. Se eles ja foram conferidos ao longo do aceite, vale marcar; se nao,
entram na lista de custo alto.

---

## 2. Os 12, agrupados pelo que exigem

O agrupamento **e** o plano de execucao: cada bloco e uma sentada.

### Sessao A — dois graficos, tudo numa vez (8 dos 12)

Monte `FusionCanvas` em dois graficos do mesmo simbolo e resolva:

| Passo | O que e |
|---|---|
| `H1b` | peer lock + pendencia: CARREGAR outro perfil, e o EA vence com aviso |
| `H5.6` | armar EXCLUIR e criar o peer lock pelo outro grafico — a confirmacao cai sozinha |
| `I5` | Magic repetido do perfil **ativo** tambem bloqueia o INICIAR |
| `I2.13` | marcador **ambar** na aba Status (nos casos I2.2 e I2.10; o I2.12 fica para a Sessao C) |
| `J1` | os dois paineis lado a lado concordam sobre o que descrevem |
| `J2` | trocar o EA de um grafico nao deixa objeto do painel anterior |
| `J3` | reverter para producao — remover o canvas, anexar o `Fusion` |
| `I6` | ⚠️ **so com posicao aberta — ver secao 3** |

O `H5.6` tem um caminho **(b)** que dispensa mexer em arquivo: carregar, no outro
grafico, o perfil que este tem ativo. E o mais barato.

### Sessao B — um grafico, com preparo de disco (2)

| Passo | O que e |
|---|---|
| `H5.7` | ⚠️ **o mais importante que sobrou.** Arquivo do ativo fora **+** gravacao presa pelo `.tmp` (receita 1.5). Prova que a trava do perfil orfao nao virou beco: os botoes tem de VOLTAR quando o SALVAR falha |
| `G7` | duplicar um perfil compativel, com nome livre — o caso limpo, sem caixa de aviso. Trinta segundos |

A receita do `.tmp` do `H5.7` e a **mesma** ja usada no `D2` e no `E4`, entao o
mecanismo esta dominado.

### Sessao C — estado caro (2, e sao os que doem)

| Passo | O que e | Por que custa |
|---|---|---|
| `H4` | carregar perfil com DD diferente **com a protecao de drawdown em curso** | exige a meta do dia BATIDA e o DD armado — ou seja, negociacao real que fecha no lucro |
| `I6` | posicao aberta **e** perfil preso por outro grafico: CARREGAR tem de ficar apagado | exige **posicao aberta pelo EA** e dois graficos |

### Fora dos grupos — tedioso, nao dificil (1)

`I2.14` — geometria nas **tres escalas** (Menor/Padrao/Maior) e num **grafico
baixo**, percorrendo as sete abas. Sem preparo nenhum, mas e o passo mais longo
do roteiro: reserve uns 20 minutos e faca com calma, porque e o unico que olha o
desenho e nao o comportamento.

---

## 3. Sim, ha um pior que o H4: o `I6`

Voce perguntou se algum outro e tao dificil quanto o `H4`. **E o `I6`, e ele e
pior**, por tres razoes somadas:

**1. A posicao tem de ser do EA.** Nao adianta abrir a mao: o Fusion so reconhece
como sua a posicao cujo `POSITION_MAGIC` bate com o Magic do perfil
(`ExecutionService.mqh:403`). Uma ordem aberta manualmente entra com magic 0 e o
painel a ignora. **A posicao precisa ter sido aberta pelo proprio EA**, ou seja,
o EA tem de rodar e a estrategia tem de disparar.

**2. Ele colide com a regra de seguranca do proprio roteiro.** A secao 1.1 diz,
em maiusculas, **"Nao rode com posicao aberta"** e **"Use conta DEMO"**. As
capturas desta fase mostram `GenialInvestimentos-PRD`. Executar o `I6` na conta
que aparece nelas contraria as duas linhas.

**3. Precisa dos dois ao mesmo tempo** — posicao aberta **e** peer lock, o que
significa segundo grafico montado antes de a posicao abrir e mantido enquanto ela
durar.

⚠️ **E o `I6` e o passo cuja falha e mais grave de todos os que sobraram**: ele
confere que CARREGAR fica APAGADO com posicao aberta. Se ele acender, o clique
trocaria a configuracao — **inclusive o Magic** — com uma operacao em
gerenciamento. Foi o unico achado desta migracao com consequencia de dinheiro, e
o `I6` e o teste dele.

**As seis linhas da matriz I2 que exigem posicao** (I2.11, I2.12, I2.15, I2.17,
I2.18, I2.19) estao na mesma situacao. E duas delas sao piores ainda: **I2.18 e
I2.19 vivem na janela entre fechar a posicao e o historico confirmar** — poucos
segundos, so visiveis olhando o painel no instante de um fechamento.

---

## 4. O que torna os caros baratos

Uma unica preparacao destrava `H4`, `I6` e as seis linhas da matriz de uma vez:

**Uma conta DEMO, num ativo que se mexe, com o EA configurado para disparar
rapido.** Concretamente:

- **conta DEMO** — resolve a objecao (2) do `I6` e obedece a secao 1.1;
- **lote minimo**, para o resultado nao importar;
- **uma estrategia que dispara com frequencia** (cruzamento de medias curtas em
  M1, por exemplo) — assim a posicao aparece em minutos em vez de horas, e o
  `I6`, o `I2.11/12/15/17` e a janela do `I2.18/19` vem junto;
- **`Max Ganho` minusculo** (o menor valor aceito) com `Limites Diarios` ligados,
  acao **ATIVAR DD** e `Drawdown` ligado — assim **a primeira operacao positiva
  ja arma a protecao** e o `H4` fica ao alcance, sem esperar um dia de ganho de
  verdade.

Sem isso, `H4` e `I6` nao sao "dificeis": sao **indefinidos**, porque dependem de
o mercado colaborar num ativo real.

---

## 5. Recomendacao

**Sessao A** (dois graficos) e **Sessao B** (disco) fecham 10 dos 12 e nao pedem
nada de mercado. Faria as duas primeiro — o `H5.7` de preferencia logo, porque e
o que fecha a protecao do perfil orfao.

**`I2.14`** entra em qualquer momento; e so tempo.

**`H4` e `I6` dependem da conta demo.** Se ela nao existir hoje, a decisao honesta
e **deixa-los pendentes por escrito** — junto das seis linhas da matriz — e nao
marca-los. Um passo marcado sem ter rodado e pior que um passo pendente: o
primeiro mente, o segundo apenas espera.

⚠️ **O `I6` nao deveria ir para a Fase 4 sem resposta.** Ele guarda o unico
defeito desta migracao que custava dinheiro. Se a demo nao for viavel agora, vale
registra-lo como **condicao de entrada da Fase 4** em vez de simplesmente
pendencia — a remocao do painel antigo pode esperar por ele.

---

Relacionado: `GUI_2000_FASE3_TESTES.md` (o roteiro), `GUI_2000_PLANO.md`
(secao 6, dividas registradas; secao 8, licoes).

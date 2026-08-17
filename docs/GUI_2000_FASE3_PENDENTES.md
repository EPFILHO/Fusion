# Fase 3 — fechamento e o que ficou de fora

**ENCERRADA em 2026-08-16**, HEAD `1bb6bf2`+, arvore limpa, gate 0/0 nos seis
alvos. `docs/GUI_2000_FASE3_TESTES.md` fechou com **88 passos marcados**.

---

## 1. O que a fase entregou

O interruptor de compilacao (`FUSION_USE_CANVAS_PANEL`), o sexto alvo
(`FusionCanvas.mq5`) e os handlers compartilhados (`Core/EAEntryPoints.mqh`)
foram **tres commits**. Todo o resto saiu do usuario executando o painel em
grafico real, com auditoria externa revisando cada entrega.

⚠️ **Foi essa proporcao que validou a decisao de fazer a Fase 3 antes de seguir.**
Quase nenhum dos achados apareceria pelo harness: ele dirige o renderizador
direto e nao alcanca o caminho de volta — clique, comando, EA, disco, resposta.

**Os blocos D e E — a razao de a fase existir — foram executados e aprovados.**
Sao os caminhos em que a gravacao FALHA (`D2`, `E4`–`E7`), que ate entao nunca
tinham rodado fora do compilador. Junto com eles passaram o rollback da criacao
falhada, a conferencia da gravacao em disco, `m_notSaved` e a politica de
conflito na recarga.

**O achado com consequencia de dinheiro** foi o `AccCanLoadProfile` devolvendo
`true` no peer lock antes de olhar `hasPosition`, com o motor sem guarda de
posicao aberta no `LOAD_PROFILE`: CARREGAR trocava a configuracao ativa —
inclusive o Magic — com uma operacao em gerenciamento. Corrigido nos dois niveis
e conferido pelo `I6`.

---

## 2. O que ficou de fora, por escrito

### ~~`H4` — NAO EXECUTADO~~ → ✅ EXECUTADO E APROVADO EM 2026-08-17

> ⚠️ **ADENDO, posterior ao fechamento desta fase.** O `H4` **passou** em
> 2026-08-17, ja depois de a Fase 4 ter removido o painel classico. O roteiro
> fecha em **89 de 89**, e nao nos 88 que esta secao registra. O texto original
> segue abaixo porque descreve por que a decisao de adiar foi correta na epoca —
> e ela foi: o passo exigia um estado que o mercado produz.

**O que aconteceu:** com o DD diario ativo, o CARREGAR foi recusado e a frase do
motor chegou a tela nova — *"Perfil nao carregado: DD diario ativo. O novo perfil
deve manter a mesma regra ate o novo dia."* Detalhes em `GUI_2000_FASE4.md`,
secao 5.

**Texto original, mantido como registro:**

> Com protecao de drawdown **em curso**, carregar um perfil de parametros de DD
> diferentes. Esperado: recusa com a mensagem de drawdown.

**Por que ficou:** exige a meta do dia **batida** e o DD **armado** — ou seja,
negociacao real que fecha no lucro. Nao e um estado que se monta na interface; e
um estado que o mercado produz.

**O que o custo seria:** conta DEMO, lote minimo, estrategia de disparo rapido
(cruzamento de medias curtas em M1) e `Max Ganho` no menor valor aceito, com
`Limites Diarios` ligados, acao **ATIVAR DD** e `Drawdown` ligado. Assim a
primeira operacao positiva arma a protecao e o passo fica ao alcance em minutos.

**Nao foi marcado de proposito.** Um passo marcado sem ter rodado mente; um passo
pendente apenas espera. Atravessou a Fase 4 sem ser executado — o usuario optou
por remover o painel classico primeiro —, **e foi executado logo depois dela**
(ver o adendo no topo desta secao).

**O risco de deixa-lo:** baixo e delimitado. A recusa que ele confere e do
**motor**, nao do painel — `LOAD_PROFILE` ja barrava por drawdown antes desta
migracao, e o codigo daquele ramo **nao foi tocado** pela 2.0. O que o `H4`
verificaria e a mensagem chegando a tela nova. Nao e o caminho de nenhum dos
defeitos encontrados nesta fase.

### A matriz `I2` continua sem marcacao — divida do documento

`I2.1` a `I2.19` e uma **tabela**, nao lista de caixas: so o `I2.13` e o `I2.14`
viraram passos marcaveis. Os outros 17 estados foram conferidos ao longo do
aceite mas **nao tem registro individual**.

E o rotulo `I2` aparece com **dois sentidos** no roteiro — o item `I2` do bloco I
(SALVAR sob peer lock) e a matriz `I2.x` do cabecalho. Confunde na leitura.

**Para a Fase 4:** se a matriz sobreviver ao roteiro novo, transformar as linhas
em caixas e renumerar. Um documento de aceite que nao registra o que foi conferido
so funciona enquanto quem conferiu esta na sala.

---

## 3. Estado para a proxima sessao

> ⚠️ **Esta secao descreve o estado no fim da Fase 3. A Fase 4 ja aconteceu** —
> ver `GUI_2000_FASE4.md`. O que segue vale como registro do ponto de partida
> dela, e o checkpoint citado e justamente o commit para onde se volta.

- Branch **`gui-2.0` publicada em `origin`** (HEAD `9d6b2ce`, depois `5f9524a`),
  como checkpoint remoto **antes** da Fase 4 — ela remove arquivos, e a partir
  dali a reversao deixa de ser "trocar o EA do grafico" e passa a ser pelo Git.
  `main` no GitHub segue na 1.058.
- **O painel novo nao estava em producao** neste ponto. O `Fusion.ex5` era o
  caminho seguro, com o painel classico dentro, e a reversao era trocar o EA do
  grafico, sem recompilar (`J3`, conferido). **A Fase 4 inverteu isso:** o
  `Fusion.ex5` passou a ser o painel novo.
- Dividas registradas na **secao 6 do `GUI_2000_PLANO.md`**, todas conscientes:
  criar perfil sempre ATIVA (a que mais encostou na tela, tres vezes),
  `ApplySettings` nao transacional, corrida de unicidade entre graficos, campo
  aceso com a chave desligada, perfil com espaco no nome, e a mensagem "o motivo
  esta no log" — esta ultima com gatilho de promocao ja escrito.

**Proximo passo: Fase 4** — remocao do painel antigo. Saem o painel classico, o
harness e o `FusionCanvas.mq5`; o `Fusion.mq5` volta a ser o unico EA, ja com o
painel novo. O plano condiciona a fase a "confianca no novo", e e isso que os 88
passos compraram.

---

Relacionado: `GUI_2000_FASE3_TESTES.md` (o roteiro), `GUI_2000_PLANO.md`
(secao 6, dividas; secao 8, licoes).

# Fase 4 — remocao do painel classico

**ENCERRADA em 2026-08-16.** Arvore limpa, gate 0/0 nos quatro alvos.

A fase estava condicionada, desde a escrita do plano, a "confianca no novo". Os
88 passos de aceite da Fase 3 foram o que a comprou — em especial os blocos D e
E, os caminhos em que a gravacao de perfil FALHA, que ate ali nunca tinham rodado
fora do compilador.

---

## 1. O que saiu

| | |
|---|---|
| `.mqh` alcancaveis somente pelo painel antigo | **61** |
| Linhas neles | **13.068** |
| Alvos de build removidos | `FusionCanvas.mq5`, `Prototype/FusionCanvasPhase1.mq5` |
| Pasta removida | `Prototype/` (harness + prototipo congelado) |
| Alvos do gate | de **6** para **4** |

Sobraram em `UI/`, fora de `Canvas/`, apenas `ChartIndicatorVisualizer.mqh` e
`IndicatorLegendOverlay.mqh` — que desenham os indicadores no grafico e nunca
foram painel.

### A lista nao foi escrita a mao

Foi calculada: o fecho transitivo de `#include` a partir de `UI/UIPanel.mqh`,
menos o fecho a partir do que fica (`UI/Canvas/CanvasPanel.mqh` e
`UI/ChartIndicatorVisualizer.mqh`). Deu 61, e a conferencia inversa e a que
importa de verdade:

⚠️ **Nenhum arquivo de `UI/Canvas/` inclui coisa alguma da raiz de `UI/`.**

Essa separacao nao apareceu nesta fase. Foi construida na Fase 2, quando
`Core/VolumeFormat.mqh`, `Core/TextParse.mqh` e `Core/SettingsNotices.mqh` foram
**extraidos** de `UI/PanelUtils.mqh` em vez de copiados — justamente para que a
remocao fosse uma exclusao de arquivos e nao uma cirurgia. O gate passou 0/0 na
primeira tentativa por causa daquele trabalho, nao por sorte.

## 2. O que mudou no codigo que fica

**O interruptor sumiu.** `Core/EAApplication.mqh` incluia `CanvasPanel.mqh` ou
`UIPanel.mqh` conforme `FUSION_USE_CANVAS_PANEL`; agora inclui o primeiro e
pronto. Era o combinado desde a Fase 1, e a razao de ter sido escolhida troca em
tempo de compilacao em vez de indirecao de runtime: a indirecao sobreviveria a
transicao sem uso, o `#define` nao.

**`UI/UIPanelTypes.mqh` deixou de existir.** Seus seis enums de aba e pagina e
tres structs de estado de acesso eram vocabulario do painel classico. Os quatro
defines de geometria que sobreviveram viraram `FCV_PANEL_X` e `FCV_PANEL_Y` em
`UI/Canvas/CanvasLayout.mqh`, ao lado de `FCV_PANEL_W`.

**`CreatePanel` perdeu quatro parametros:** `name`, `subwin`, `x2` e `y2`.
Nenhum era lido — conferido um a um. Existiam porque `CFusionPanel` herdava de
`CAppDialog`: `name` era a legenda do dialogo, `subwin` a subjanela, `x2,y2`
fechavam o retangulo. O canvas usa `FCV_OBJ_NAMESPACE` como prefixo, desenha o
proprio titulo, vive sempre na janela 0, tem largura `FCV_PANEL_W` e tira a
altura de `DecidePanelHeight()`.

> ⚠️ Enquanto os dois paineis conviviam a assinatura **tinha** de ser identica
> nos dois lados: era ela que fazia o compilador garantir a troca (secao 5 do
> plano). Com um painel so, ela passou a afirmar que o painel aceita coisas que
> ignora.

**Tres funcoes mortas em `Core/Version.mqh`:** `FusionWindowTitle()`,
`FusionDialogProgramName()` e `FusionHeaderTitle()`. So alimentavam a legenda e o
cabecalho do dialogo antigo. `FUSION_APP_VERSION` fica — e o `#property version`
do `Fusion.mq5` e o numero que o canvas escreve na barra de titulo.

**Sete blocos de comentario** citavam `UI/PanelUtils.mqh`, `UI/Pages/StatusPage.mqh`,
`UI/Pages/ResultsPage.mqh` ou `Prototype/FusionCanvasPrototype.mq5` como fonte de
uma regra. A citacao continua valendo — e dali que as regras sairam —, mas o
caminho deixou de resolver nesta arvore; agora dizem "da 1.058" ou apontam para o
historico. Um deles estava simplesmente **falso**: `VolumeFormat.mqh` afirmava no
presente que "PanelUtils passa a incluir este arquivo".

## 3. Decisao registrada: nenhuma varredura das sobras do painel classico

O painel antigo deixava no grafico controles sob nomes fixos `Fusion_*` (cerca de
270 deles) e a casca do dialogo sob um prefixo numerico aleatorio do `CAppDialog`.
Removido o painel, nao sobra codigo capaz de varrer aquilo.

**Decisao do usuario: nao acrescentar limpeza.** As razoes:

- na troca normal o assunto nao existe — trocar o EA do grafico roda o
  `Destroy()` do painel que sai, conferido nos passos `J2` e `J3` da Fase 3;
- o caso descoberto e estreito: terminal encerrado de forma **anormal** com o
  painel antigo no ar, e so depois a atualizacao. Ali as sobras se apagam **uma
  vez**, pela lista de objetos do grafico;
- escrever limpeza nova dentro da fase que existe para remover codigo seria
  trocar o problema de lugar. A auditoria da Fase 3 ja tinha ensinado que
  inventario incompleto vira limpeza ampla, que e o defeito removido no P1.

⚠️⚠️ **CORRECAO: a primeira versao deste documento dizia que uma varredura por
`Fusion_` seria "tecnicamente estreita, sem interseccao". ISSO ERA FALSO E
PERIGOSO** — sob aquele prefixo vive um objeto legitimo:

- **`Fusion_indicator_legend_*`** — a **legenda das medias**: seis objetos, um
  `OBJ_RECTANGLE_LABEL` de fundo e cinco `OBJ_LABEL`, criados por
  `UI/IndicatorLegendOverlay.mqh`. Esse arquivo **sobreviveu a Fase 4** justamente
  porque nunca foi painel: desenha no grafico.

`ObjectsDeleteAll(chart,"Fusion_")` apagaria a legenda de quem estivesse com os
indicadores visuais ligados. **A unica limpeza automatica permitida e pelo
namespace exato `Fusion2.Canvas.`** (`FCV_OBJ_NAMESPACE`). Nao alargar.

> ⚠️ **SEGUNDA CORRECAO, da rodada seguinte da auditoria — e ela derrubou tambem
> a versao corrigida acima.** A primeira correcao listava um segundo prefixo,
> `Fusion_visual_ma_*`, como "as linhas das medias". **Errado nas duas metades:**
>
> - **nada cria `Fusion_visual_ma_*`.** E o nome ANTIGO da legenda, e sobrevive so
>   dentro de `DeleteLegacyLegend()`, que o apaga por compatibilidade.
>   `LegacyLegendName()` e `DeleteLegacyLegend()` sao os unicos usos, e todos sao
>   `ObjectDelete`. Uma varredura por `Fusion_` nao teria o que apagar ali;
> - **as linhas nao sao objeto de grafico.** Sao **indicadores**, anexados por
>   `ChartIndicatorAdd()` com os nomes curtos `Fusion Visual MA|BB|RSI <chartId>`.
>   Aparecem em `Ctrl+I`, nunca em `Ctrl+B`, e nenhuma varredura de objeto as
>   alcanca — quem as remove e `ChartIndicatorDelete()`.
>
> **A conclusao operacional nao mudou:** varredura por `Fusion_` continua proibida,
> por causa da legenda. Mudou o motivo, e e por isso que a correcao vale registro.
>
> ⚠️ **A licao nova: um nome que so aparece sendo APAGADO se le como um nome
> vivo.** Eu vi `Fusion_visual_ma_` no codigo, num `ObjectDelete`, e conclui que
> algo o criava. Perguntar "quem escreve isto?" e diferente de "isto aparece?" —
> e para prefixo de objeto e a unica pergunta que importa.

> **Como o erro entrou, porque vale mais que a correcao.** Eu levantei os
> prefixos com um `grep` sobre `UI/`, **agrupei por prefixo e joguei fora a
> atribuicao de arquivo**. `Fusion_visual` e `Fusion_indicator` apareceram na
> saida, uma ocorrencia cada, e eu os li como mais dois nomes do painel classico
> no meio de `Fusion_cfg` (100x) e `Fusion_protect` (96x). A evidencia estava na
> tela; o agrupamento e que destruiu a informacao que decidia.
>
> ⚠️ **Contar ocorrencias por prefixo responde "qual e comum", nao "de quem e".**
> Quando a pergunta e de propriedade, a resposta tem de sair por arquivo.
>
> E o pior: isto e **exatamente** o defeito que o P1 da auditoria da Fase 3
> removeu — uma limpeza ampla apagando o que nao devia. A decisao de nao
> implementar nada foi o que impediu o dano; a justificativa e que estava errada.

Se o caso das sobras aparecer na pratica, o caminho e um inventario explicito dos
nomes do painel antigo — nunca um prefixo compartilhado.

## 4. ⚠️ Reverter mudou de natureza

Ate a Fase 3, voltar ao painel antigo era **trocar o EA do grafico**, sem
recompilar nada (`J3`, conferido em execucao). A partir daqui e **operacao de
Git**:

> **`5f9524a`** — publicado em `origin/gui-2.0`, e o ultimo commit em que os dois
> paineis coexistem.

Foi exatamente para isso que a branch foi publicada **antes** desta fase.

E o `Fusion.ex5` mudou de significado: ate ontem era o caminho seguro com o
painel classico dentro; agora e o painel novo. Quem deployar por cima de uma
instalacao antiga esta trocando de GUI, nao atualizando o motor.

## 5. Pendencias que atravessaram a fase

Duas, ambas herdadas da Fase 3 e nenhuma bloqueante.

### `H4` — nao executado

> Com protecao de drawdown **em curso**, carregar um perfil de parametros de DD
> diferentes. Esperado: recusa com a mensagem de drawdown.

Exige a meta do dia **batida** e o DD **armado** — estado que o mercado produz,
nao a interface. **Nao foi marcado de proposito:** passo marcado sem ter rodado
mente; passo pendente apenas espera.

**Risco delimitado.** A recusa que ele confere e do **motor**, e o ramo de
drawdown do `LOAD_PROFILE` **nao foi tocado** nem pela migracao nem por esta
fase. O que falta verificar e a mensagem chegando a tela nova.

**Custo de encena-lo:** conta demo, lote minimo, estrategia de disparo rapido
(cruzamento de medias curtas em M1), `Max Ganho` no menor valor aceito com
`Limites Diarios` ligados, acao **ATIVAR DD**, e `Drawdown` ligado. A primeira
operacao positiva arma a protecao e o passo fica ao alcance em minutos.

### A matriz `I2` do roteiro

`I2.1` a `I2.19` e uma **tabela**, nao lista de caixas: so `I2.13` e `I2.14`
viraram passos marcaveis, e os outros 17 estados foram conferidos ao longo do
aceite **sem registro individual**. O rotulo `I2` tambem aparece com dois
sentidos no documento.

Se um roteiro novo reaproveitar a matriz, transformar as linhas em caixas e
renumerar. **Documento de aceite que nao registra o que foi conferido so funciona
enquanto quem conferiu esta na sala.**

## 6. Smoke test do `Fusion.ex5` definitivo

Pequeno, mas obrigatorio: o gate compila, e nao prova que o binario de producao
sobe. Cinco minutos, contando a preparacao.

⚠️ **Duas listas diferentes do terminal, e confundi-las invalida o teste:**
`Ctrl+B` lista **objetos** de grafico; `Ctrl+I` lista **indicadores**. As linhas
visuais do Fusion sao indicadores; a legenda e a barra do painel sao objetos.

**Pre-condicao (senao os passos 4 e 8 sao impossiveis).** `showChartIndicators`
nasce **`false`**, entao o perfil de teste precisa:

- [ ] **0a.** `Indicadores no Grafico` **ligado** (aba `Layout`);
- [ ] **0b.** ao menos uma estrategia ou filtro visual habilitado, em **timeframe
  compativel com o do grafico** — sem isso nao ha o que desenhar;
- [ ] **0c.** salvar o perfil, para o estado sobreviver a reanexacao.

**O teste:**

- [ ] **1.** No grafico, criar uma linha horizontal e renomea-la para
  **`EP Fusion MinhaLinha`**. ⚠️ **Este passo e o teste, nao preparacao.** O nome
  comeca por "EP Fusion" de proposito: era o prefixo que a **primeira** versao da
  limpeza do canvas varria, e apagar anotacao do usuario foi o P1 da auditoria da
  Fase 3. Se a linha desaparecer, a limpeza voltou a ser ampla.
- [ ] **2.** Copiar o `Fusion.ex5` novo para `<terminal>\MQL5\Experts\`, atualizar
  o Navegador, e anexar **esse** EA a um grafico com `inp_ShowPanel = true`.
- [ ] **3.** No log do terminal, confirmar `Painel: canvas (GUI 2.0)`. Dizendo
  outra coisa, o `.ex5` que subiu nao e o deste build — **parar aqui**.
- [ ] **4.** Navegar entre as abas e editar um campo (o valor volta ao sair, ou
  fica, conforme a regra da tela — o que importa e o campo responder).
- [ ] **5.** **Antes de remover**, confirmar que existem: as linhas no grafico, a
  legenda das medias, e em **`Ctrl+I`** os indicadores `Fusion Visual MA`,
  `Fusion Visual BB` ou `Fusion Visual RSI` (os que o perfil ligou).
- [ ] **6.** Remover o EA do grafico.
- [ ] **7.** Em **`Ctrl+I`**, confirmar que **nenhum `Fusion Visual ...` sobrou**.
- [ ] **8.** Em **`Ctrl+B`**, confirmar que **nao sobrou objeto comecando por
  `Fusion2.Canvas.`** (o painel) **nem por `Fusion_indicator_legend_`** (a
  legenda).
- [ ] **9.** Confirmar que **`EP Fusion MinhaLinha` continua la**.

⚠️ **Os passos 7 e 8 perguntam por sobras NOMEADAS, e nao se o grafico ficou
vazio.** Um grafico normal tem objetos do usuario, e exigir "nenhum objeto"
transformaria o passo em falso negativo garantido.

⚠️ **Nao ha passo procurando `Fusion_visual_ma_*`**, e a ausencia e deliberada:
nada cria esse nome (ver a segunda correcao da secao 3). Um passo que procura o
que nunca existe passa sempre, e passo que passa sempre nao testa nada.

## 7. Dividas de projeto, inalteradas

Seguem na **secao 6 do `GUI_2000_PLANO.md`**, todas conscientes e nenhuma tocada
por esta fase: criar perfil sempre ATIVA, `ApplySettings` nao transacional,
corrida de unicidade de nome/Magic entre graficos, perfil com espaco no nome
(`FusionListProfiles` lista o nome cru e `FusionLoadProfile` saneia antes de
abrir — vale para a 1.058 tambem), e a mensagem "o motivo esta no log", esta
ultima com o conserto ja escrito e ordenado.

---

Relacionado: `GUI_2000_PLANO.md` (o plano; secao 6 para as dividas, secao 8 para
as licoes), `GUI_2000_FASE3_TESTES.md` (o roteiro de aceite),
`GUI_2000_FASE3_PENDENTES.md` (o fechamento da fase anterior).

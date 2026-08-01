# Fusion 2.0 — Plano da nova GUI em canvas

Ponto de partida da versao 2.0. Existe para que o projeto nao dependa da memoria de
uma conversa: tudo que foi decidido, medido ou descoberto sobre a migracao da
interface esta aqui.

A 1.058 fica congelada como a ultima versao da linha 1.x e como referencia de
comparacao durante a transicao.

---

## 1. Por que 2.0

Nao quebra compatibilidade: formato de perfil, estado de grafico e toda a logica
operacional continuam identicos. O numero maior comunica outra coisa — quem
atualiza vai encontrar uma interface diferente. `1.x` e o EA funcional, `2.0` e o
EA moderno.

O painel atual usa objetos nativos (`CAppDialog`, `CButton`, `CLabel`, `CEdit`,
`CPanel`). A 2.0 desenha em `CCanvas` e mantem como objeto nativo apenas os campos
de digitacao.

---

## 2. O que o prototipo provou

`Prototype/FusionCanvasPrototype.mq5` e descartavel e nao faz parte do EA. Foi
anexado a um grafico real ao longo de varias rodadas. Padroes validados:

| Padrao | Situacao |
|---|---|
| Abas em fichario, dois niveis | OK |
| Trilho vertical no terceiro nivel | OK |
| Campo de digitacao nativo sobre o canvas | OK |
| Toggle desenhado | OK |
| Combobox desenhado | OK |
| Grade de cores | OK |
| Rolagem: roda, arrasto, teclado, barra | OK |
| Arrastar painel, minimizar, reajustar altura | OK |
| Tema claro e escuro, deteccao automatica | OK |
| Propagacao de erro pela cadeia de abas | OK |
| Aviso que cresce com o texto | OK |
| Lista de perfis | OK |

### Regras tecnicas — descobertas na pratica

- **Ordem de desenho e a ordem de criacao.** `OBJPROP_ZORDER` so roteia eventos de
  mouse. Os `OBJ_EDIT` devem ser criados **depois** do `OBJ_BITMAP_LABEL`.
- **Objeto nativo pinta SEMPRE acima do canvas.** Nenhum z-order muda isso. Por
  consequencia, **todo popup desenhado precisa suprimir os campos nativos que
  cobre** — publica seu retangulo, e o campo dentro dele nao e criado naquele
  quadro. Sem isso o dropdown aparece furado.
- **Objeto nativo nao se recorta.** Num conteudo rolavel, o campo que nao cabe
  **inteiro** na area visivel e destruido, nao reposicionado.
- **Em tela rolavel, desenhe o conteudo primeiro e o chrome por cima.** Repintar
  as faixas de fora da area util devolve ao canvas o recorte que ele nao faz
  sozinho. A ordem inversa deixa o conteudo rolado pintar sobre as abas.
- **Publique a caixa de clique durante o desenho.** Alvo e pintura nao podem
  divergir, e o alvo passa a acompanhar a rolagem sem aritmetica extra. Ainda
  assim, verifique se o controle esta dentro da area visivel antes de aceitar o
  clique.
- **Zere os contadores de controle no inicio de cada passada.** Um contador
  herdado da tela anterior faz aparecer controle de outra subaba, em posicao
  velha.
- **`color` do MQL5 e BGR; o canvas trabalha em ARGB.** Converter explicitamente
  ao configurar objetos nativos, senao vermelho vira azul.
- **`CCanvas` nao antialiasa.** Cantos arredondados sao suavizados a mao,
  misturando com a cor de fundo conhecida.
- **Roda do mouse:** `CHARTEVENT_MOUSE_WHEEL` exige `CHART_EVENT_MOUSE_WHEEL`
  habilitado. `lparam` empacota X na palavra baixa e Y na alta; `dparam` traz o
  delta.
- **Nao existe seletor de cores do sistema em MQL5.** Só via importacao de DLL,
  que obriga o usuario a baixar uma protecao — nao cabe num EA distribuido. A
  grade desenhada resolve melhor de qualquer forma.
- **Objeto nativo em foco nao acompanha o objeto.** Com um `OBJ_EDIT` em edicao,
  o controle interno do terminal nao segue a mudanca de posicao: rolar o
  conteudo deixa o controle parado, solto sobre o painel. Destruir o objeto
  tambem nao resolve — o controle sobrevive a ele. E **nao ha API** para
  consultar nem para soltar o foco; as unicas solucoes publicadas usam WinAPI
  via DLL. Tentado e reprovado: soltar o foco por `OBJPROP_TIMEFRAMES`.
  **Consequencia aceita: com um campo em edicao, a roda do mouse nao rola o
  conteudo.** Barra de rolagem, setinhas, teclado e arrasto continuam
  funcionando, e confirmar o campo devolve a roda no ato.
- **Campos nativos sao sincronizados por diferenca, nunca apagados em massa.**
  Apagar e recriar a cada quadro perdia o texto ainda nao confirmado no meio da
  digitacao, alem de orfanar o controle de edicao. Sai so o que saiu da tela,
  nasce so o que entrou, o que permanece e movido, e o texto so e reescrito
  quando o valor de origem muda.

### Risco ainda nao medido

**Custo de desenho com o painel cheio.** O prototipo redesenha o canvas inteiro a
cada interacao e desenha uma fracao do que o painel real tera. No EA sao centenas
de rotulos, atualizando a cerca de 5 Hz com dados vivos, e o antialias dos cantos e
laco por pixel. Medir cedo na Fase 1; se pesar, o caminho e redesenho parcial por
regiao suja em vez de quadro inteiro.

---

## 3. O tamanho real do trabalho

Medicao sobre a 1.058 (`UI/`, 14.469 linhas):

| Camada | Linhas | Destino |
|---|---|---|
| Desenho (cria e posiciona controles) | 1.608 | reescrever em canvas |
| Visibilidade (mostra/esconde) | 1.079 | **desaparece** — no canvas se redesenha |
| Logica (validacao, draft, acesso, comandos) | 3.131 | **preservar** |

**O achado que torna isso viavel:** a logica de validacao le direto dos campos de
edicao (26 ocorrencias de `LiveEditText` e similares). Como a abordagem hibrida
mantem os campos como objetos nativos, esse codigo continua funcionando sem
alteracao.

Nao e reescrever 14 mil linhas. E trocar cerca de 2.700 de renderizacao e preservar
as 3.131 que contem as regras.

---

## 4. O que o `CAppDialog` dava de graca e agora e nosso

- **Arrastar** — captura de mouse mais supressao de `CHART_MOUSE_SCROLL` enquanto o
  cursor esta sobre o painel. Sem isso o grafico se move no lugar do painel.
- **Minimizar** — redimensionar o canvas e destruir os campos de digitacao; um
  `OBJ_EDIT` escondido continuaria aceitando clique.
- **Hit-testing** — cada alvo desenhado publica sua caixa no momento do desenho.

---

## 5. A fronteira EA <-> painel

O `CFusionApplication` toca o painel em **10 pontos, 8 metodos**:

```
BuildPanelSnapshot() -> m_panel.Update(snapshot)     (saida)
m_panel.ConsumeCommand(command) -> HandleUICommand   (entrada)
CreatePanel / StartDialog / Destroy / ChartEvent     (ciclo de vida)
HasUnsavedDraftChanges                               (consulta)
LoadSettings                                         (recarga)
```

E essa fronteira estreita que permite construir o painel novo ao lado e troca-lo
sem alterar o EA.

---

## 6. Plano de execucao

**Fase 1 — Renderizador completo com dados falsos.** Todas as abas e subabas
desenhadas, com todos os estados visuais. Medir o custo de desenho cedo.

**Fase 2 — `CFusionCanvasPanel` com a mesma interface.** Implementa os 8 metodos da
secao 5. Os fragmentos de validacao, draft e acesso sao incluidos praticamente como
estao — sao fragmentos de corpo de classe.

### Pendencias registradas para a Etapa 2d (validacao / acesso / conflito)

Tres coisas foram deixadas de fora de proposito ate aqui. Nenhuma e esquecimento;
todas pertencem a mesma camada e se resolvem juntas.

**1. A camada de acesso — FEITA.** Os predicados da 1.058 (`UIPanelAccessState.mqh`)
foram portados para `CanvasRendererChrome.mqh`: iniciar, pausar, salvar, cancelar,
carregar, criar e excluir perfil, alem do bloqueio dos campos com o EA rodando ou
com posicao aberta. Falta apenas `configInputsValid`, que depende do item 2 — ate
la vale `true`, o que **afrouxa** a regra e nunca a aperta.

**2. Validacao e regras cruzadas.** Digitar letra num campo numerico vira zero sem
reclamar. Faltam as faixas (`prioridade 0..1000`, `periodo 1..1000`) e as relacoes
entre campos (`MA rapida < MA lenta`, `sobrevenda < media < sobrecompra`). As regras
existem na 1.058; o que precisa ser reescrito e a camada de leitura, porque o modelo
por slot nao tem os membros nomeados que os fragmentos originais esperam.

**3. Politica de conflito durante a edicao.** Enquanto o usuario digita, o texto em
andamento esta protegido — mas nao pela regra do `m_dirty`, e sim porque a
sincronizacao diferencial compara o valor de origem com **o que nos escrevemos por
ultimo no objeto**, nao com o que esta na caixa. Enquanto o valor de origem daquele
campo nao muda, o `OBJ_EDIT` nao e reescrito e a digitacao sobrevive ao refresh
periodico.

O caso residual e quando o valor de origem **muda de verdade** no meio da digitacao:
carga ou troca de perfil, restauracao, importacao. Ai o novo valor disputa com o
texto ainda nao confirmado. Nao ha resposta obviamente certa — descartar o que o
usuario digitava ou ignorar o que o EA mandou — e por isso e uma decisao de politica,
nao um bug a corrigir sozinho. Fica com o item 1: "o campo aceita edicao agora?" e
"quem ganha se o valor mudar por baixo?" sao a mesma pergunta vista de dois angulos.

**Fase 3 — Troca por interruptor.** Um input escolhe qual painel construir. Os dois
convivem, comparaveis no mesmo grafico, com reversao imediata.

> **Correcao (Fase 1).** A promessa original — "o EA nao muda uma linha" — estava
> errada. `m_panel` e um `CFusionPanel` concreto em `Core/EAApplication.mqh`, e
> escolher o painel em tempo de execucao exige uma indirecao que nao existe.
> **Decidido: troca em tempo de compilacao.** Um `#define` escolhe qual classe o
> membro `m_panel` tem. O fonte do EA realmente nao muda, o custo em codigo e
> nulo e nao existe indirecao para manter depois que a Fase 4 remover o painel
> antigo. O preco e nao poder alternar sem recompilar — aceitavel, porque quem
> compara os dois durante a transicao e quem desenvolve, e recompilar leva
> segundos com o `build-linked.ps1`.

**Fase 4 — Remocao do painel antigo**, somente depois de confianca no novo.

A integracao acontece na fase 3, cedo e reversivel — nao no fim.

---

## 7. Sistema visual aprovado

### Paleta

Escuro: `ground 0B0F14` · `surface 151A22` · `inset 0B0F14` · `line 28323F` ·
`soft 1B222B` · `fg E8EDF4` · `muted 93A0B2` · `faint 5F6B7A` · `acc 4A96D6` ·
`accs 7CB8E8` · `accd 1B3448` · `good 35B87A` · `bad DE5760` · `warn D9982F`

Claro: `ground EFF2F7` · `surface FFFFFF` · `inset F4F6FA` · `line D5DCE6` ·
`soft E7ECF3` · `fg 131A24` · `muted 54627A` · `faint 8A96A8` · `acc 2A6FB0` ·
`accs 1E5A93` · `accd DDEAF7` · `good 17864C` · `bad C0353D` · `warn 9C6B10`

Regras que produziram essa paleta, e que valem para qualquer ajuste futuro:

- **Dois fundos, nao tres.** Degraus a menos de 10 pontos de luminancia leem como
  sujeira, nao hierarquia. O campo de entrada e *recuado* ao fundo do painel, com
  borda, em vez de ser um quarto degrau.
- **Tres niveis de texto com distancia real.** Dois cinzas proximos nao criam
  hierarquia, criam ruido.
- **Semanticas dentro do sistema.** Saturacao reduzida e temperatura aproximada dos
  neutros; em saturacao cheia elas parecem coladas por cima da interface.
- **No tema claro as semanticas sao mais escuras, nao as mesmas invertidas.** Um
  verde que brilha sobre preto fica ilegivel sobre branco. Inverter sem
  re-escurecer e o erro mais comum em tema duplo.
- **No tema escuro os tons medios sao mais claros** do que a simetria com o claro
  sugeriria: o olho perde tom baixo antes sobre fundo escuro.
- **Contorno de 1px no painel.** Sem ele, painel escuro sobre grafico escuro perde
  a silhueta.

### Tipografia

`Segoe UI` para interface, `Consolas` para numeros — ambas ja existem no Windows.
Nao inventar fonte que o MetaTrader nao consiga renderizar.

### Navegacao

Niveis 1 e 2 como **abas de fichario**: a aba ativa perde a borda de baixo e recebe
o fundo da superficie logo abaixo; a linha do fichario atravessa **toda a largura**
na cor do estado — azul normal, vermelha com erro dentro. E isso que faz a selecao
ser vista de longe e o nivel 2 parecer contido no nivel 1, sem caixas aninhadas.

Nivel 3 vira **trilho vertical** de 136 px, so onde existe (Gestao > Risco e
Gestao > Protecao). Sete itens numa faixa horizontal de 590 px ficariam com 80 px
cada e rotulos abreviados; no trilho cabem por extenso.

### Estados

- **Erro prevalece sobre selecao.** O preenchimento diz onde voce esta, a cor diz o
  que precisa de atencao. Se a selecao apagasse o vermelho, o problema sumiria da
  tela justamente ao abrir a aba para resolve-lo.
- **Erro sobe a cadeia inteira.** Um item invalido pinta todos os ancestrais ate a
  aba de topo. Quem esta em Status ve que ha problema em Config sem abrir Config.
- **Um unico botao preenchido por vez.** O preenchido e o proximo passo: Salvar com
  pendencias, Iniciar sem elas. Tres botoes coloridos lado a lado nao instruem
  nada.
- **Aviso cresce com o texto.** O painel da 1.058 tem tres `CLabel` fixos e corta em
  174 caracteres. No canvas a caixa e dimensionada pelo texto medido.
- **Numeros de coluna sao justificados a direita** contra o limite da linha ou do
  badge. Alinhados a esquerda depois de um nome, flutuam com o comprimento do nome
  e nao podem ser comparados.

### Altura

Lida de `CHART_HEIGHT_IN_PIXELS` **uma vez, ao anexar**, entre 560 e 900 px. So
encolhe se o grafico deixar de conte-la; **nunca cresce sozinha** — um painel que
muda de tamanho durante o uso faz a informacao mudar de lugar sem o usuario ter
feito nada. Um controle no cabecalho reajusta sob demanda.

### Rotulos

Portugues, com ingles apenas no jargao de mercado.

| Nivel | Rotulos |
|---|---|
| 1 | Status · Resultados · Estrategias · Filtros · Gestao · Perfis · Layout |
| 2 (Gestao) | Risco · Protecao |
| 2 (Estrategias) | Geral · Medias · RSI · Bollinger |
| 2 (Filtros) | Geral · Tendencia · RSI · Bollinger |
| 3 (Risco) | Lote · SL/TP · TP Parcial · BreakEven · Trailing |
| 3 (Protecao) | Geral · Spread/Lado · Sessao · Noticias · Limites Diarios · Drawdown · Sequencias |

A aba **Config** deixou de existir. Ela agrupava coisas sem parentesco: Risco e
Protecao decidem dinheiro, a antiga subaba Visual decide aparencia. "Config" nao
descrevia conteudo — descrevia a indecisao sobre onde as coisas moravam. Agora
**Gestao** reune o que decide dinheiro e **Layout** e aba propria (nome de
tela, nao a aba antiga — mais reconhecivel que "Visual" para quem chega de
outros produtos). A ordem de nivel 1 passa a contar a sequencia de configurar o
EA: quando entrar, quando nao entrar, quanto arriscar, o que guardar.

Magic Number foi para **Perfis** (identidade do perfil, e a lista ja o exibe) e
Resolver Conflito para **Estrategias > Geral** (e regra entre estrategias). Logs
Debug saiu da GUI: e ferramenta de quem desenvolve, e o input basta.

**Restricao criada:** sao sete abas em 590 px logicos. Nenhum rotulo de aba pode
crescer sem medir. O painel loga a folga da faixa ao anexar.

Ficam em ingles: `Drawdown`, `Trailing`, `BreakEven`, `SL/TP`, `Spread`,
`Layout` — jargao sem equivalente melhor ou termo ja consagrado no genero.
`Status` e `Config` sao iguais nas duas linguas (Config nao existe mais como aba).

### Icones

Sem ambiguidade com acoes destrutivas. Duas setas divergentes leem como "X" de
fechar; num painel que opera dinheiro isso e inaceitavel. Maximizar usa o
retangulo convencional.

---

## 8. Licoes que devem sobreviver a esta versao

Erros cometidos durante a 1.058 e o prototipo, todos encontrados pelo usuario
testando:

1. **Nao escrever mensagem que instrui acao que a interface impede.** Aconteceu
   duas vezes: um bloqueio que desabilitava a aba que a propria mensagem mandava
   abrir, e um aviso pedindo `SALVAR` que estava desabilitado.
2. **Todo bloqueio precisa de saida pela propria GUI.**
3. **Medir a mensagem contra o espaco disponivel** antes de escreve-la.
4. **Conferir o binario deployado** antes de interpretar um teste. Um `.ex5`
   desatualizado ja invalidou uma rodada inteira.
5. **Correlacao nao e causa.** Uma troca de perfil foi atribuida a uma troca de
   conta com base em coincidencia temporal; o teste do usuario desmentiu. A causa
   real era um carregamento manual que nao era registrado em log.

---

## 9. Compilacao

A partir do MetaEditor `5.0.0.6061`, `#resource` exige que o arquivo resolva dentro
da arvore `MQL5`. Com o projeto fora dela, usar `build-linked.ps1` (ver
`README.md`). O gate continua sendo **0 errors, 0 warnings** nos alvos — **cinco**
desde a Fase 1: os tres indicadores, o `Fusion.mq5` e o harness
`Prototype/FusionCanvasPhase1.mq5`, que compila os modulos de `UI/Canvas/` e
por isso entra no gate. O harness sai quando a Fase 4 remover o painel antigo.

O deploy e manual: copiar o `.ex5` para `<terminal>\MQL5\Experts\`.

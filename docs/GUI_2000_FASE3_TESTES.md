# Fase 3 — roteiro de aceite do painel em canvas

Este documento existe por um motivo especifico, e nao por formalidade.

A Etapa 2c/2d fechou com oito rodadas de revisao, e **tudo o que saiu delas vive
no painel e nunca rodou fora do compilador**: a conferencia da gravacao em disco,
`m_notSaved`, o rollback da criacao que falhou, a revalidacao no instante do
clique, a politica de conflito na recarga. O harness da Fase 1 nao alcanca nada
disso — ele dirige o renderizador direto, e `CFusionCanvasPanel` so entra la para
o gate compilar. **Foi este o argumento que motivou a Fase 3.**

Compilar em `0 errors, 0 warnings` prova que as duas classes tem a mesma
fronteira. Nao prova que o painel novo faz a coisa certa. Isso e o que este
roteiro cobre.

> **O que ja esta verificado e nao precisa ser retestado aqui:** as sete abas
> lendo dados (Etapa 2b, exercitada pelo harness com tipos reais) e o desenho em
> si. O foco e o **caminho de volta** — do clique ate o disco — e o que o EA
> devolve.

---

## 1. Antes de comecar

### 1.1 Seguranca

⚠️ **Use conta DEMO.** Este roteiro cria, carrega e apaga perfis, e perfil
carrega **lote e Magic Number**. Um perfil calibrado para um ativo aplicado em
outro e exatamente o acidente que o Magic unico existe para impedir.

⚠️ **Nao rode com posicao aberta.** Varios passos trocam configuracao; a parte
E (criacao que falha) chega a deixar a sessao rodando uma configuracao cujo
arquivo nao existe — de proposito, e por poucos segundos, mas nao com dinheiro
exposto.

### 1.2 Copia dos perfis

A pasta fica no terminal onde o EA sera anexado (`Arquivo > Abrir pasta de
dados`), em `MQL5\Files\Fusion\Profiles`. Copie-a inteira para outro lugar antes
de comecar. Os passos F e E apagam e criam arquivos de verdade.

```powershell
$perfis = "$env:APPDATA\MetaQuotes\Terminal\<SEU-TERMINAL>\MQL5\Files\Fusion\Profiles"
Copy-Item -Recurse -LiteralPath $perfis -Destination "$env:USERPROFILE\Desktop\Perfis-backup"
```

### 1.3 Deploy dos dois executaveis

O build produz seis alvos; dois deles sao o **mesmo EA**:

| Arquivo | Painel | Papel |
|---|---|---|
| `Fusion.ex5` | classico (Controls) | producao, referencia de comparacao |
| `FusionCanvas.ex5` | canvas (GUI 2.0) | **em avaliacao** — o que este roteiro testa |

Copie os dois para `MQL5\Experts\` do terminal e atualize o Navegador. Eles
aparecem com nomes diferentes e podem ficar em graficos diferentes ao mesmo
tempo — e assim que a comparacao lado a lado acontece.

### 1.4 Confirmar qual painel esta rodando — faca isto sempre

A licao 4 da secao 8 do plano ("conferir o binario deployado antes de
interpretar um teste") vale em dobro agora que existem dois `.ex5`. O EA
responde sozinho: na aba **Especialistas** do terminal, a cada inicializacao,

```
Painel: canvas (GUI 2.0, em avaliacao)
```

ou

```
Painel: classico (Controls)
```

**Se a linha nao aparecer, o `.ex5` e antigo** — recompile e copie de novo antes
de qualquer coisa. Se aparecer a errada, voce anexou o outro EA.

### 1.5 Como forcar uma falha de gravacao

Tres passos do roteiro (D2, E4 e o que vem depois dele) exigem que a gravacao
**falhe**. Sao os caminhos mais importantes deste documento e os unicos que nao
acontecem por acidente.

`FusionSaveProfile` (`Persistence/Modules/ProfileStore.mqh`) sempre escreve um
`.tmp` na pasta de perfis antes de promover. **Prender exclusivamente esse
arquivo temporario** derruba a gravacao no primeiro passo, sem alterar permissao
nenhuma e sem corromper nada — e desfaz-se fechando o PowerShell:

```
FileDelete(<perfil>.cfg.tmp);
handle = FileOpen(<perfil>.cfg.tmp, FILE_WRITE|FILE_TXT|FILE_ANSI);
if(handle == INVALID_HANDLE) return false;   // <- e aqui que o teste entra
```

Entao basta que esse `.tmp` **exista e esteja preso por outro processo**: o
`FileDelete` nao o remove e o `FileOpen` nao o abre. Escolha antes o nome do
perfil que o passo vai gravar (`P`) e, numa **janela separada** do PowerShell:

```powershell
$perfis = "$env:APPDATA\MetaQuotes\Terminal\<SEU-TERMINAL>\MQL5\Files\Fusion\Profiles"
$alvo   = Join-Path $perfis 'P.cfg.tmp'     # troque P pelo nome do perfil do passo
$fs = [IO.File]::Open($alvo,'OpenOrCreate','Write','None')
'Preso. Rode o passo no MT5 e volte aqui.'
```

**Desfazer** — na mesma janela, quando o passo terminar:

```powershell
$fs.Close(); Remove-Item -LiteralPath $alvo -Force
```

Vale para os dois casos: em **D2** `P` e o perfil ativo; em **E4** e o nome que
voce vai digitar no formulario. O `.tmp` nao atrapalha a validacao — o painel
procura `P.cfg`, e o `.tmp` nao ocupa o nome.

> ⚠️ **Se a gravacao der certo mesmo com o arquivo preso**, a injecao nao pegou —
> confira o caminho e o nome. O teste nao produz falso positivo: injecao que
> falha aparece como `PERFIL SALVO`, que e obviamente "o preparo nao funcionou",
> e nao "o painel passou".

> **Por que nao `icacls`.** A versao anterior deste roteiro negava a escrita na
> pasta e desfazia com `/remove:d`, que apaga **todos** os ACEs de negacao
> daquele usuario — inclusive um que existisse por outro motivo. Trocar aquilo
> por `/save` + `/restore` tambem nao resolve: o `/save` grava os nomes
> **relativos a pasta pai** do alvo, entao salvar e restaurar pelo mesmo caminho
> restaura zero objetos; e, corrigido o caminho, o `/restore` ainda falha sem
> elevacao com *"nem todos os privilegios ou grupos mencionados estao atribuidos
> ao chamador"*, porque a DACL da pasta e toda herdada. Um roteiro de teste nao
> deveria pedir elevacao nem arriscar deixar permissao alterada — prender um
> arquivo nao arrisca nenhuma das duas coisas.
>
> Se ainda assim preferir o caminho por permissao, a forma que funciona sem
> elevacao e guardar e devolver **so a DACL**:
> `$antes=(Get-Acl $perfis).Sddl` … `$a=Get-Acl $perfis;`
> `$a.SetSecurityDescriptorSddlForm($antes,'Access'); Set-Acl $perfis $a`.

Notas:

- Atinge **um perfil por vez**, e so a gravacao dele. Tudo o mais continua
  normal: os outros perfis salvam, e o estado do grafico (`Fusion\ChartState`)
  nunca e tocado. E o recorte mais estreito possivel para este teste.
- Nao e preciso fechar nem reiniciar o terminal — a trava vale a partir da
  proxima tentativa de gravacao.
- Prender o **`.cfg`** em vez do `.tmp` tambem derruba o `SALVAR` de um perfil
  existente, pela promocao (`FileMove`). Nao serve para o **E4**: ali o `.cfg`
  ainda nao existe, e cria-lo vazio a mao faria o painel recusar antes, por nome
  ja existente. Por isso a receita e no `.tmp`, que cobre os dois.

---

## 2. Roteiro

Ordem deliberada: **D e E primeiro**. Sao os caminhos onde uma falha silenciosa
custa dados, e onde o painel pode contar a pior mentira que ele sabe contar —
anunciar que gravou sem ter gravado.

Para cada item: `[ ]` o que fazer, **Esperado**, e — quando o desvio for
ambiguo — o que ele significaria.

### A. Ciclo de vida

- [x] **A1.** Anexar `FusionCanvas` a um grafico com `inp_ShowPanel = true`.
      **Esperado:** o painel aparece; a linha `Painel: canvas...` no log.
- [x] **A2.** Arrastar o painel pela barra de titulo.
      **Esperado:** o painel se move, o **grafico nao**. Se o grafico rolar
      junto, a supressao de `CHART_MOUSE_SCROLL` nao esta valendo.
- [x] **A1b.** ⚠️ **No grafico o painel aparece SEMPRE.**
      Anexar com `inp_ShowPanel = false`, em qualquer perfil — inclusive num
      gravado com o campo desligado.
      **Esperado:** o painel aparece do mesmo jeito. O input nao esconde a GUI
      no grafico; quem quer espaco usa o **minimizar** da barra de titulo.
      **Por que:** a GUI e o unico lugar de onde se opera o EA — iniciar,
      pausar, salvar, trocar de perfil. Esconde-la deixava um EA sem controle, e
      sem caminho de volta pela propria interface.
- [x] **A1c.** **No Strategy Tester o input manda.** Rodar em modo visual com
      `inp_ShowPanel = false`.
      **Esperado:** o painel **nao** aparece. Com `true`, aparece. Fora do modo
      visual nao aparece em nenhum caso — nao ha grafico onde desenhar.
- [x] **A2b.** ⚠️ **Tentar arrastar o painel para fora, nos quatro sentidos.**
      **Esperado:** ele para. Para baixo, a barra de titulo inteira continua na
      tela; para a direita, sobra a faixa da esquerda com "EP Fusion" — e ela e
      area de arrasto, entao **sempre da para trazer o painel de volta**. Para
      cima e para a esquerda ele ja parava na borda.
- [x] **A2c.** Com o painel encostado na borda de baixo ou da direita,
      **diminuir a janela do MT5** (ou o gráfico).
      **Esperado:** o painel e trazido de volta para dentro sozinho. E o caso
      que o limite do arrasto nao cobre: aqui ninguem arrastou nada — o que
      mudou foi o tamanho do grafico.
      **Nota:** a posicao **nao** e guardada entre sessoes; reanexar o EA
      sempre devolve o painel ao canto superior esquerdo. E a rede de seguranca,
      mantida de proposito enquanto a Fase 3 nao fecha.
- [x] **A3.** Minimizar e restaurar.
      **Esperado:** os campos de digitacao **somem** ao minimizar. Um `OBJ_EDIT`
      apenas escondido continuaria aceitando clique.
- [x] **A4.** Remover o EA do grafico.
      **Esperado:** nenhum objeto sobra — sem retangulo, sem campo de texto.
- [x] **A5.** Trocar o timeframe do grafico com o painel aberto.
      **Esperado:** o painel se reconstroi inteiro e o distintivo do cabecalho
      mostra o **TF do grafico** (nao o resumo operacional, que e a linha de
      largura inteira do cartao SESSAO).
- [x] **A7.** ⚠️ **Campos nativos durante a rolagem.** Numa aba com barra —
      Estrategias > Medias serve —, **arrastar a barra** de cima a baixo.
      **Esperado:** os campos de digitacao permanecem visiveis **durante** o
      movimento, aparecendo e sumindo apenas nas bordas da area util (objeto
      nativo nao se recorta: o que nao cabe inteiro e destruido, nao cortado).
      Conferir tambem, na mesma sequencia:
      1. rolar com a **roda**: comportamento identico;
      2. abrir um **combo** e escolher um item cujo botao fique sobre um campo —
         o campo atras **nao** pode roubar o foco ao reaparecer;
      3. repetir nas **tres escalas**;
      4. arrastar ate os limites **superior e inferior**;
      5. **soltar o botao fora do painel** — os campos tem de estar todos la.
      **Por que este passo existe:** a criacao de campo nativo era adiada
      sempre que o botao do mouse estivesse apertado, para o terminal nao
      entregar o foco a um objeto nascido sob o cursor. Arrastar a barra
      tambem mantem o botao apertado, entao nada nascia enquanto o conteudo
      rolava — e o que saia de vista continuava sendo destruido. A guarda hoje
      exige que o cursor esteja **sobre o proprio campo**; o item 2 e o que
      confere que o caso original continua protegido.
- [x] **A6.** Fechar e reabrir o terminal com o EA anexado.
      **Esperado:** volta com o mesmo perfil ativo e a mesma aparencia (paleta,
      tema e escala escolhidas na aba Layout sobrevivem — ficam em variavel
      global do terminal).

### B. O EA alimentando a tela

Ate aqui todos os numeros vinham do harness. Agora sao reais.

- [x] **B1.** Comparar a aba **Status** com a do `Fusion.ex5` no mesmo perfil.
      **Esperado:** mesmo estado (RODANDO / PAUSADO / BLOQUEADO), mesmos avisos,
      mesmo resumo de TFs operacionais.
- [x] **B2.** Comparar a aba **Resultados**.
      **Esperado:** os mesmos numeros, com **ponto decimal**; lucro colorido pelo
      sinal com zero neutro; streak desligada aparece **OFF**, nao zero; sem base
      de drawdown os campos ficam `--`, nao zerados.
- [x] **B3.** Clicar **INICIAR** e depois **PAUSAR**.
      **Esperado:** a capsula do cabecalho e o Status acompanham. Com posicao
      aberta o distintivo mostra **OPERANDO** e o botao fica em **PAUSAR
      apagado** — quem explica por que e a faixa. (Detalhado em I2.11.)
- [x] **B4.** Editar um campo de Estrategias e observar o Status.
      **Esperado:** o Status **nao muda** — ele descreve o que o EA esta
      rodando, e a edicao so vale depois do SALVAR. **Isto e o correto**, e ja
      foi reportado como defeito uma vez.

### C. Pendencia e validacao

- [x] **C1.** Alterar um campo qualquer.
      **Esperado:** SALVAR e CANCELAR acendem. Sem alteracao nenhuma eles ficam
      apagados — nao ha o que gravar nem o que descartar.
- [x] **C2.** Clicar **CANCELAR**.
      **Esperado:** o campo volta ao valor comprometido e os dois botoes apagam.
- [x] **C3.** Digitar texto invalido num campo numerico (`abc`) e sair do campo.
      **Esperado:** o valor **anterior volta sozinho** e aparece o aviso
      `VALOR NAO ACEITO`, citando o que foi digitado e **expirando em 5 s**. O
      campo **nao** fica vermelho e a validacao **nao** e afetada — a aba nao
      acende, nada na cadeia de erro muda.
      **Por que assim:** texto recusado nunca chega ao rascunho, e a validacao
      responde sobre o rascunho. Marcar o campo era a primeira versao e foi
      removida: o `BuildEdits` reescreve o objeto no mesmo quadro, entao um
      quadro depois nao existe texto ruim em lugar nenhum e a marca ficava acesa
      para sempre. O que o usuario precisa e saber **por que** o valor voltou, e
      isso e recado, nao estado (`CanvasRendererValidate.mqh:17-33`).
      **O que continua valendo:** `abc` nao pode virar **zero** em silencio —
      zero e valor legitimo em quase todo campo.
- [x] **C4.** Digitar `0,30` num campo decimal.
      **Esperado:** aceito como `0.30`. A virgula e normalizada na entrada.
- [x] **C5.** Deixar um campo reprovado na validacao e olhar o cabecalho.
      **Esperado:** INICIAR, SALVAR e CRIAR PERFIL apagam, e **a tela diz por
      que e em que aba** — botao apagado sem explicacao e a licao 1 da secao 8.

### D. SALVAR — o caminho critico

- [x] **D1.** Alterar um campo e clicar **SALVAR**.
      **Esperado:** aviso `PERFIL SALVO` (some em 5 s). Conferir **no arquivo**
      `.cfg` que o valor mudou. O painel confere isso sozinho relendo o disco;
      este passo confere o conferidor.
- [x] **D2.** ⚠️ **Com a gravacao bloqueada (1.5, `.tmp` do perfil ativo preso)**:
      alterar um campo e clicar **SALVAR**.
      **Esperado:** aviso `PERFIL NAO GRAVADO`, **sem prazo para sumir**, dizendo
      as duas metades — a configuracao **vale nesta sessao**, o arquivo **nao foi
      escrito**. O SALVAR **continua aceso**.
      **Se aparecer `PERFIL SALVO`, pare o teste e reporte**: e o defeito que a
      conferencia em disco existe para impedir, e o pior que este painel pode
      fazer.
- [x] **D3.** Ainda bloqueado: navegar para outra aba e voltar.
      **Esperado:** a marca de gravacao pendente **permanece** — ela so cai na
      proxima gravacao bem-sucedida.
- [x] **D4.** Soltar o `.tmp` (o `$fs.Close()` da secao 1.5) e clicar **SALVAR**
      de novo.
      **Esperado:** `PERFIL SALVO`, a marca some, o arquivo tem o valor novo.

### E. CRIAR PERFIL — o caminho com rollback

- [x] **E1.** Aba Perfis > **NOVO**, nome e Magic livres, **CRIAR PERFIL**.
      **Esperado:** `PERFIL CRIADO`, o perfil aparece na lista **e fica ativo**
      neste grafico (criar sempre ativa — divida aceita, secao 6 do plano).
- [x] **E2.** **NOVO** com um nome que ja existe.
      **Esperado:** `NOME JA EXISTE`. A conferencia e em **disco**: crie um
      `.cfg` a mao pela pasta com o formulario ja aberto e o nome ainda assim
      deve ser recusado.
- [x] **E3.** **NOVO** com o Magic de outro perfil.
      **Esperado:** `MAGIC JA USADO`, **nomeando o perfil dono** do numero.
> **O marcador dos passos E4–E7 e o MAGIC, e nao um campo qualquer.** Entrar em
> NOVO exige **nao haver pendencia** (`profileCreateAllowed`), entao no instante
> da criacao o rascunho e, por construcao, identico a configuracao do perfil
> ativo. O unico campo que difere no perfil que esta nascendo e o **Magic** — e
> ele e justamente a identidade que impede dois graficos de colidirem. Anote o
> Magic do perfil ativo (chame de `M_ANT`) e escolha um bem diferente para o
> perfil novo (`M_NOVO`) antes de comecar.

- [x] **E4.** ⚠️ **Com a gravacao bloqueada (1.5)**: prenda o `.tmp` do nome que
      vai digitar — se o perfil novo se chamara `X`, prenda `X.cfg.tmp` — e
      entao **NOVO**, nome `X`, Magic `M_NOVO`, **CRIAR PERFIL**.
      **Esperado:** `PERFIL NAO CRIADO`, **o formulario continua aberto**, e o
      texto manda clicar **CRIAR PERFIL** para tentar de novo — nunca SALVAR (o
      SALVAR grava no perfil **ativo**, que aqui e o anterior).
      **Estado real neste ponto, e e o que torna o resto perigoso:** o EA ja
      **aplicou** `M_NOVO`. A sessao roda o Magic do perfil que nao existe, sob o
      nome do perfil anterior.
- [x] **E5.** Sem sair do formulario, soltar o `.tmp` e clicar **CRIAR PERFIL**
      de novo.
      **Esperado:** `PERFIL CRIADO`, com a configuracao **que estava no
      formulario** — nao a de antes da primeira tentativa.
- [x] **E6.** Repetir E4 (prender, tentar, falhar) e entao clicar **DESCARTAR**.
      **Esperado:** aviso `CRIACAO ABANDONADA` dizendo que a configuracao
      anterior voltou a valer, e o Magic exibido volta a `M_ANT`. O formulario
      **so fecha quando a volta chega**; se o EA recusar, ele continua aberto com
      `NAO FOI POSSIVEL ABANDONAR`.
- [x] **E7.** ⚠️ **A regressao que este mecanismo existe para impedir.**
      Solte o `.tmp`, se ainda nao soltou, e siga na ordem:
      1. **Confira que o SALVAR esta APAGADO.** Isso e parte da assercao, nao um
         obstaculo: apos o abandono o rascunho voltou ao comprometido, a divida
         de gravacao foi restaurada ao que era antes e o estado de criacao
         falhada foi desarmado — sem nada disso pendente, nao ha o que gravar.
         SALVAR **aceso** aqui ja e defeito.
      2. **Acenda o SALVAR** clicando dentro de um campo editavel qualquer. Essa
         e a politica em vigor: o texto de um `OBJ_EDIT` so e publicado no
         `ENDEDIT`, entao entrar no campo e o unico sinal disponivel. (Alterar um
         valor de verdade tambem serve, e torna o teste mais forte — o arquivo
         tem de sair com a alteracao **e** com `M_ANT`.)
      3. **Clique SALVAR** e abra o `.cfg` do perfil anterior.
      **Esperado:** o arquivo tem **`M_ANT`**.
      **Se sair com `M_NOVO`, pare e reporte** — e a sequencia
      `CRIAR X -> falha -> DESCARTAR -> SALVAR` gravando a identidade do perfil
      que nunca existiu por cima do perfil anterior.
      **Se o arquivo do perfil anterior sair com a configuracao do perfil que
      falhou, reporte** — e a sequencia `CRIAR X -> falha -> DESCARTAR -> SALVAR`
      sobrescrevendo o perfil errado.

### F. EXCLUIR — nao passa pelo EA

- [x] **F1.** Selecionar um perfil qualquer (nao o ativo) e clicar **EXCLUIR**.
      **Esperado:** o botao vermelho vira **SIM**, com **NAO** ao lado na mesma
      altura, e **todo o resto da coluna apaga**. A pergunta inteira aparece no
      aviso do rodape.
- [x] **F2.** Clicar **NAO**.
      **Esperado:** volta ao normal, nada e apagado.
- [x] **F3.** Armar de novo e, sem confirmar, **trocar de aba** (ou trocar a
      selecao).
      **Esperado:** a confirmacao **desarma sozinha**. Armada sobre um indice,
      ela apagaria o perfil errado.
- [x] **F4.** Armar e clicar **SIM**.
      **Esperado:** `PERFIL EXCLUIDO`, o arquivo some do disco e da lista.
- [x] **F5.** Selecionar o perfil **ativo**.
      **Esperado:** EXCLUIR apagado, **com o motivo escrito**.
- [x] **F6.** Selecionar o perfil `default`.
      **Esperado:** EXCLUIR apagado — o `default` nao se exclui, como na 1.058.

### G. DUPLICAR — tambem nao passa pelo EA

> ⚠️ **PRE-CONDICAO: duplique um perfil COMPATIVEL com o simbolo do grafico.**
> Num grafico WINQ26, duplique o `WIN` — nao o `US500`.
>
> Nao e limitacao do teste, e a **divida registrada** ("criar perfil sempre
> ATIVA", secao 6 do plano) aparecendo na pratica. Criar tambem ATIVA o perfil
> neste grafico, entao `configInputsValid` pesa aqui tanto quanto no SALVAR — e
> um perfil de outro ativo reprova por motivo legitimo (um lote de 1.00 do US500
> nao cabe no WIN). O CRIAR COPIA fica apagado e a caixa do rodape explica,
> corretamente, que a configuracao precisa valer para o simbolo do grafico.
>
> Com um perfil compativel o fluxo exercitado e o mesmo — nome sugerido, Magic
> livre, CRIAR COPIA, aparece na lista —, que e o que o bloco G existe para
> verificar. **A pre-condicao cai quando a divida for paga**, dividindo o
> `ConfigInputsValid` em intrinseca e do-grafico: so a segunda deveria pesar
> sobre um perfil escrito para a biblioteca.

- [x] **G1.** Selecionar um perfil e clicar **DUPLICAR**.
      **Esperado:** o formulario abre com o nome sugerido `<nome>_copy` (ou
      `_copy_2`...) e os valores **lidos do arquivo de origem**, nao do perfil
      ativo.
- [x] **G2.** Clicar **CRIAR COPIA**.
      **Esperado:** `PERFIL CRIADO`. O Magic da copia precisa ser trocado antes —
      dentro do formulario o Magic do rascunho **nao** e cobrado por unicidade
      (ele veio da origem, por definicao), mas a gravacao o cobra.
- [x] **G3.** Entrar em NOVO, digitar um nome, sair sem criar, e voltar para a
      lista.
      **Esperado:** o texto digitado **nao reaparece** dentro do campo Magic da
      lista. (Foi um bug real de slot compartilhado entre modos da mesma tela.)
- [x] **G4.** Agora o contrario do G1: duplicar um perfil **INCOMPATIVEL** com o
      simbolo do grafico (no WINQ26, duplicar o `US500`).
      **Esperado:** o formulario abre, **CRIAR COPIA apagado**, e a caixa do
      rodape diz o motivo verdadeiro — a configuracao nao vale para o simbolo
      deste grafico. **CRIAR COPIA e DESCARTAR visiveis sem rolar a mao**: o
      conteudo tem de chegar ao fim sozinho.
      Nao e um caminho de erro a evitar, e o lado visivel da divida do G — o
      teste existe para provar que ela **se explica** em vez de apenas apagar o
      botao (licao 1). E o unico caso em que o formulario abre ja com a caixa
      ocupada, entao e ele que exerce a segunda borda da rolagem automatica.
- [x] **G5.** Provocar um aviso na tela de Perfis (por exemplo EXCLUIR um perfil)
      e, **enquanto ele ainda esta visivel**, entrar em NOVO ou DUPLICAR com uma
      configuracao invalida.
      **Esperado:** o aviso anterior some, o erro do formulario ocupa a caixa, e o
      conteudo rola ate os botoes. (Sem o tratamento das duas bordas a caixa
      trocava de conteudo sem passar por zero e a rolagem nao disparava.)
- [x] **G6.** No formulario com configuracao invalida, digitar um nome **ja
      existente** e depois corrigi-lo.
      **Esperado:** a caixa troca do erro de nome (curto) para o da configuracao
      (mais longo, que nomeia a aba e o campo) e **o conteudo rola de novo**. A
      caixa nao sumiu no meio — foi so o texto que cresceu, e e a altura dela que
      come a area util.
- [ ] **G7.** ⚠️ **Rolar SEM caixa de aviso nenhuma.** Duplicar um perfil
      **compativel** com o grafico, com nome sugerido livre — o caso limpo, em que
      o rodape fica vazio.
      **Esperado:** o conteudo rola ate **CRIAR COPIA** e **DESCARTAR** do mesmo
      jeito.
      **Por que este passo existe:** ate 2026-08-14 a rolagem exigia caixa de
      aviso presente, e este caso nao tem nenhuma — o campo Magic abre VAZIO, e
      campo por preencher **nao e erro**, entao `ProfileFormReady` nao devolve
      mensagem. Os botoes ficavam abaixo da dobra e so a roda do mouse os
      alcancava. O gatilho passou a ser ENTRAR no formulario: os dois botoes vivem
      no fim do conteudo rolavel, e a lista de perfis sozinha ja os empurra para
      fora da tela — o aviso era so mais um empurrao, nunca a causa.

### H. CARREGAR — a politica de conflito

- [x] **H1.** Com alteracoes pendentes (de configuracao **ou** do Magic),
      selecionar outro perfil.
      **Esperado:** **CARREGAR fica apagado**, e o cartao PERFIL SELECIONADO diz
      por que ("Salve ou cancele as alteracoes pendentes primeiro").
      ⚠️ **Este passo estava escrito ao contrario ate 2026-08-13**, mandando
      clicar num CARREGAR que o painel nunca acende. Ele descrevia o MOTOR, nao
      o painel: `AccCanLoadProfile` termina em `!HasPending()`, e o painel e
      deliberadamente mais rigido que o EA aqui. Ver a nota no plano.
- [ ] **H1b.** A politica do motor — "na recarga deliberada o EA vence, com
      aviso" — existe e e alcancavel, mas **so sob peer lock**: ali
      `AccCanLoadProfile` devolve `true` antes de olhar a pendencia, porque
      carregar outro perfil e a saida daquele bloqueio. Com o perfil ativo preso
      por outro grafico e alteracoes pendentes, clicar **CARREGAR** em outro
      perfil.
      **Esperado:** o perfil novo entra e o painel avisa que a digitacao foi
      descartada. (Precisa de dois graficos — pode ser feito junto do bloco I.)
- [x] **H2.** Carregar um perfil e conferir o cabecalho.
      **Esperado:** nome do perfil novo, SALVAR e CANCELAR apagados (nao ha
      pendencia recem-carregada).
- [x] **H3.** Renomear um `.cfg` por fora para algo ilegivel e tentar carregar.
      **Esperado:** `PERFIL NAO CARREGADO`, **a configuracao atual preservada**.
- [ ] **H4.** Com protecao de drawdown em curso, carregar um perfil de
      parametros de DD diferentes.
      **Esperado:** recusa com a mensagem de drawdown. Trocar ali recomecaria a
      conta no meio.

### H5. Perfil ativo SEM ARQUIVO — a trava do "grave primeiro"

> Encontrado testando o H, em 2026-08-13, e o achado foi **perda de dados
> real**: a configuracao em uso passou a existir so na memoria e o painel
> continuou oferecendo as quatro acoes que a abandonam. O estado acendia o
> SALVAR e nao segurava nenhuma porta.
>
> **Preparo:** com o EA parado, mova o `.cfg` do perfil ATIVO para fora da pasta
> (ou renomeie). Em ate ~1 s o cabecalho passa a dizer
> `· arquivo do perfil nao encontrado`. **Devolva o arquivo ao fim do bloco.**

- [x] **H5.1.** Conferir a faixa do cabecalho.
      **Esperado:** `PERFIL EM USO SEM ARQUIVO — grave antes de iniciar ou trocar
      de perfil`, em vermelho. Ela vence "alteracoes pendentes" **e tambem
      "configuracao invalida"**. Perde, na ordem, para: bloqueio de runtime,
      reconciliacao de fechamento, formulario de perfil aberto, peer lock e
      conflito de Magic — todos acima dela na escada, e todos por descreverem algo
      que impede o proprio SALVAR ou que passa sozinho.
- [x] **H5.2.** Ir para Perfis e olhar a coluna de acoes.
      **Esperado:** **CARREGAR, NOVO, DUPLICAR e EXCLUIR apagados**; so
      `Atualizar lista` responde. O cartao do perfil ativo explica que SALVAR
      grava a configuracao em uso de volta nesse nome.
- [x] **H5.2b.** Olhar o **INICIAR**.
      **Esperado:** apagado tambem — sao **cinco** botoes, e nao quatro.
      **Por que, e o motivo nao e o das outras quatro:** INICIAR nao abandona o
      perfil, ele **fecha a porta da recuperacao**. O SALVAR exige o EA parado,
      entao iniciar com o arquivo ausente deixaria a unica copia da configuracao
      presa na memoria, sem forma de grava-la, a um reinicio de sumir.
      (Efeito de estar na escada: todo ramo dela retorna com o botao desabilitado.
      Foi achado pela auditoria, conferido, e mantido de proposito — a faixa
      nomeia as duas coisas justamente porque ela e a unica explicacao que o
      INICIAR apagado tem.)
- [x] **H5.3.** Clicar **SALVAR** no cabecalho.
      **Esperado:** `PERFIL SALVO`, o arquivo reaparece na pasta, a faixa some e
      **os quatro botoes voltam**. E a saida pela propria GUI (licao 2).
- [x] **H5.4.** ⚠️ **A metade que impede o beco — e o caso que o usuario
      encontrou.** Repetir o preparo com um perfil ativo **de outro ativo** (no
      WIN, um perfil de lote `0.40`), ou deixar a configuracao invalida de
      proposito.
      **Esperado:** a faixa diz
      `PERFIL SEM ARQUIVO E INVALIDO NESTE ATIVO — restaure o arquivo para
      preservar`, e **os botoes de perfil NAO travam** — CARREGAR, NOVO,
      DUPLICAR e EXCLUIR ficam disponiveis conforme as regras normais.
      **Por que os dois ao mesmo tempo:** o SALVAR nao acende (exige configuracao
      valida), entao travar viraria beco — nao ha saida a oferecer. Mas o risco
      continua, e calar seria esconde-lo. **A faixa avisa onde a trava se cala**,
      e a protecao vem por confirmacao (H5.8).
      ⚠️ A faixa **nao** manda "corrigir a configuracao": a incompatibilidade pode
      ser so com este ativo, e corrigir descaracterizaria um perfil que esta certo
      para o ativo dele.

- [x] **H5.5.** O mesmo com o perfil ativo **preso por outro grafico** (exige
      dois graficos; ver bloco I).
      **Esperado:** as acoes **nao** ficam trancadas e CARREGAR segue disponivel.
      Ali o SALVAR nem acende, e carregar outro perfil e a unica saida — trancar
      as quatro deixaria o usuario sem nenhuma.
- [ ] **H5.6.** Armar o **EXCLUIR** num perfil qualquer e, **com a confirmacao no
      ar**, fazer o acesso sumir sem tocar no painel. Dois caminhos servem:
      **(a)** mover o `.cfg` do **PERFIL ATIVO** — nao o do perfil que esta na
      pergunta; **(b)** mais facil, com dois graficos: carregar o **perfil ativo
      deste grafico** no outro, criando o peer lock.
      **Esperado:** a confirmacao **se desarma sozinha** junto com o botao.
      Desenho e Render leem a mesma funcao (`AccCanDeleteSelected`); divergindo,
      sobraria um SIM armado para uma acao que a tela ja nao oferece.
      ⚠️ **Confira o preparo pelo cabecalho, no caminho (a):** ele tem de ganhar
      `· arquivo do perfil nao encontrado` em ate ~1 s. **Se nao ganhar, voce moveu
      o arquivo errado** — e comum mover o do perfil que esta na pergunta de
      exclusao, e esse nao muda nada.
      ⚠️ **Nao use o `default` como perfil ativo aqui.** Se o EA reiniciar com o
      `default.cfg` ausente, ele o **recria sozinho** a partir dos inputs
      (`EAApplication.mqh`), e o estado some sem voce ter feito nada. Carregue
      outro perfil antes de comecar.
      ⚠️ **O "IMPEDIDO" do distintivo nao atrapalha** — ele e permissao de
      negociacao (`tradePermissionBlocked`) e nenhuma regra de acesso a perfil o
      consulta. Quem trancaria e o `runtimeBlocked`, e esse apareceria como
      **BLOQUEADO**.
- [ ] **H5.7.** ⚠️ **A SAIDA, e o passo mais importante do bloco.** Com o arquivo
      fora **e a trava no ar**, prender tambem a gravacao (receita 1.5, no `.tmp`
      do perfil ativo) e clicar **SALVAR**.
      **Esperado:** `NAO FOI POSSIVEL SALVAR`, o cabecalho passa a
      `· nao gravado no disco` e **os quatro botoes VOLTAM** — a faixa do arquivo
      some.
      **Por que:** a trava vale enquanto o SALVAR e uma saida plausivel. A
      tentativa que falha e a prova de que ele nao resolve, e a partir dali vale
      a politica registrada no plano — CARREGAR liberado, com a perda anunciada.
      Sem isso a trava viraria beco: quatro botoes apagados e um SALVAR que falha
      a cada clique.
      **Se os botoes continuarem apagados**, a trava esta lendo `m_notSaved` — o
      defeito que este passo existe para pegar.

### H5.8. Confirmacao de abandono — os dois caminhos que perdem

> **Preparo (o do H5.4), e ele e a metade do trabalho.** Precisa de DUAS coisas ao
> mesmo tempo:
>
> 1. o perfil ATIVO tem de ser **incompativel com este grafico** — carregue, num
>    grafico de WIN, um perfil de outro ativo (lote `0.40`, por exemplo). O
>    cabecalho passa a mostrar `CONFIGURACAO INVALIDA`;
> 2. **so entao** mova o `.cfg` **dele** para fora da pasta. Em ate ~1 s o
>    cabecalho ganha `· arquivo do perfil nao encontrado`.
>
> **Conferencia antes de comecar:** a faixa tem de dizer
> `PERFIL SEM ARQUIVO E INVALIDO NESTE ATIVO — restaure o arquivo para preservar`.
> **Se ela disser `PERFIL EM USO SEM ARQUIVO — grave antes de iniciar...`, o
> preparo NAO esta certo** — a configuracao esta valida, a trava do H5.2 pegou, e
> nenhuma destas confirmacoes vai aparecer (nem deve). Este e o unico estado em
> que elas existem.
>
> ⚠️ Cada **SIM** confirmado troca o perfil ativo e desfaz o preparo. Os passos
> avisam onde refazer.

- [x] **H5.8.1.** Selecionar outro perfil e clicar **CARREGAR**.
      **Esperado:** nao carrega. No lugar do CARREGAR aparecem **SIM** e **NAO**,
      e o rodape explica que o perfil em uso esta sem arquivo, nao pode ser
      gravado aqui, e que a configuracao dele sera perdida — dizendo tambem que
      restaurar o arquivo preserva tudo. NOVO e DUPLICAR apagam enquanto a
      pergunta esta no ar.
- [x] **H5.8.2.** Clicar **NAO**.
      **Esperado:** volta ao normal, nada carregado, aviso some.
- [x] **H5.8.3.** Armar de novo e **trocar a selecao** de perfil.
      **Esperado:** a pergunta cai sozinha. (Ela guarda o alvo capturado no
      primeiro clique; sobrevivendo a uma troca, nomearia um perfil e executaria
      outro.)
- [x] **H5.8.5.** Armar de novo e, **sem confirmar**, restaurar o `.cfg` do
      perfil ativo na pasta.
      **Esperado:** a pergunta cai sozinha em ate ~1 s — o estado que a justifica
      passou, e mante-la anunciaria uma perda que ja nao aconteceria.
- [x] **H5.8.6.** ⚠️ **A que some e nao pode voltar.** Refazer o preparo, armar a
      confirmacao do CARREGAR e, **sem confirmar**, fazer o perfil selecionado
      ficar preso por outro grafico (bloco I) — ou simplesmente carrega-lo no
      outro grafico.
      **Esperado:** SIM/NAO somem **e a pergunta nao volta** quando a trava sair.
      **Se ela ressuscitar**, o desarme voltou a olhar so o estado e nao a
      disponibilidade da acao.
- [x] **H5.8.7.** ⚠️ **Refazer o preparo do H5.4** (o SIM anterior trocou o perfil
      ativo, entao o orfao ja nao e o ativo). Com o estado de volta, clicar
      **CARREGAR** em outro perfil e confirmar com **SIM**.
      **Esperado:** aí sim carrega, e a configuracao orfa e abandonada — que e o
      que voce confirmou.
- [x] **H5.8.8.** ⚠️ **A metade mais importante: CONCLUIR a copia.**
      Refazer o preparo do H5.4 e **DUPLICAR** um perfil **compativel** com o
      grafico.
      ⚠️ **O CRIAR COPIA comeca APAGADO, e isso e normal** — o campo Magic do
      formulario abre **VAZIO** (o Magic da origem fica no rascunho, nao no
      campo). **Digite um Magic livre**; so entao o botao acende. Sem isso o
      clique nao faz nada e parece que a confirmacao quebrou. Com o botao aceso,
      clicar **CRIAR COPIA**.
      **Esperado:** a copia **nao** e criada. No lugar do CRIAR COPIA aparecem
      **SIM** e **NAO**, com a mesma pergunta do rodape; DESCARTAR continua ao
      lado, intacto.
      **Por que a copia chega a acender** com o perfil ativo invalido: entrar no
      DUPLICAR semeia o rascunho com o perfil de ORIGEM, que pode valer neste
      grafico. **Foi exatamente isso que quebrou a primeira versao** — a
      confirmacao perguntava pela validade do RASCUNHO, que ali ja era o da
      origem, e por isso nunca aparecia. Se este passo nao mostrar SIM/NAO, o
      defeito voltou.
- [x] **H5.8.9.** ⚠️ **Tocar num campo derruba a pergunta.** Com o SIM/NAO da
      copia no ar, clicar dentro do campo **Nome** ou **Magic** do formulario.
      **Esperado:** a pergunta **cai** — SIM e NAO somem e o CRIAR COPIA volta.
      Nada e criado.
      **Por que:** digitar limpa o aviso do rodape, e a pergunta viva sem a frase
      que a explica deixaria dois botoes na tela sem ninguem dizendo o que o SIM
      faz. E o nome mostrado na pergunta poderia deixar de ser o que esta no
      campo — a pergunta nomearia um perfil e o SIM criaria outro.
      ⚠️ **Este e o unico lugar onde este teste e possivel.** Com a confirmacao do
      CARREGAR (H5.8.1) nao ha campo editavel ao alcance: com outro perfil
      selecionado o Magic do cartao e **so leitura**, e selecionar o ativo para
      chegar a um campo editavel ja derruba a pergunta pelo H5.8.3.
- [x] **H5.8.10.** ⚠️ **Onde a confirmacao de ABANDONO nao deve aparecer.** No
      mesmo estado, **um de cada vez, fechando o formulario entre eles**: abrir
      **NOVO** (e sair com DESCARTAR); depois clicar **EXCLUIR** em outro perfil;
      depois clicar **Atualizar lista**.
      ⚠️ **Com o formulario aberto a lista nao aceita clique** — e deliberado, para
      a selecao nao mudar no meio de uma criacao. Entao nao da para "abrir NOVO e
      depois selecionar outro perfil": sao tres verificacoes independentes.
      ⚠️ **O EXCLUIR tambem exige nada pendente.** Se voce corrigiu alguma coisa
      nas abas de configuracao, ha pendencia e ele fica apagado com razao — salve
      ou cancele antes.
      **Esperado:** nenhuma pergunta **de abandono** nos tres. Abrir o NOVO nao
      perde nada (o CRIAR PERFIL de dentro dele segue apagado pela configuracao
      invalida), EXCLUIR mexe em outro perfil, e Atualizar lista so relê a pasta.
      ⚠️ **O EXCLUIR mostra a confirmacao DELE** — `CONFIRMAR EXCLUSAO`, com SIM e
      NAO. Isso e correto e nao e o que este passo procura. O que nao pode
      aparecer e a pergunta sobre descartar a configuracao em uso.
      **Por que o teste existe:** confirmacao que aparece onde nao precisa ensina
      a clicar SIM sem ler, e ai ela deixa de proteger onde precisa.

### H6. Edicao em curso — o cabecalho e a coluna de perfis concordam

> Achado pelo usuario: com o cursor no campo Magic, SALVAR e CANCELAR acendiam
> (correto — e a edicao em curso) e **NOVO e DUPLICAR continuavam acesos**,
> sugerindo que criariam um perfil COM o Magic recem-digitado.
>
> Nao e so aparencia. Sair do campo por um clique passa por `ReleaseEditFocus`,
> que **le antes de destruir** e grava o valor no rascunho: o numero digitado
> vira pendencia do perfil **ATIVO** e so entao o botao age. O usuario terminaria
> dentro do formulario de criacao com uma alteracao pendente que nao quis, no
> perfil errado.

- [x] **H6.1.** Na aba Perfis, clicar dentro do campo **Magic Number** do perfil
      ativo, sem digitar nada.
      **Esperado:** SALVAR e CANCELAR acendem **e** CARREGAR, NOVO, DUPLICAR e
      EXCLUIR apagam, no mesmo quadro. A tela inteira passa a dizer a mesma coisa:
      ha uma edicao em curso, conclua-a.
- [x] **H6.2.** Clicar fora do campo (no fundo do painel).
      **Esperado:** tudo volta ao que era. Sem alteracao digitada, **nao** aparece
      pendencia — o cursor no campo nunca afirma uma mudanca que pode nao existir.
- [x] **H6.3.** ⚠️ **Exige o perfil ativo FORA da lista** (preparo do H5: mova o
      `.cfg` dele). So nesse estado o cartao `PERFIL ATIVO` aparece com o Magic
      **editavel** ao mesmo tempo que outro perfil pode estar selecionado.
      Selecionar outro perfil, clicar no Magic do **ativo** (o do cartao de cima)
      e olhar o cartao PERFIL SELECIONADO.
      **Esperado:** a nota diz `Ha um campo em edicao: conclua com SALVAR ou
      CANCELAR` — e nao "Use CARREGAR", que esta apagado.
      **Por que a pre-condicao:** com o ativo DENTRO da lista, os dois estados se
      excluem. Selecionado o ativo, o cartao e `PERFIL ATIVO` e a nota do "Use
      CARREGAR" nem existe; selecionado outro, o Magic do cartao e **so leitura**
      e nao aceita clique. Sem o ativo fora da lista este passo e impossivel — foi
      erro de quem escreveu, nao seu.
- [ ] **H6.4.** ⚠️ **O clique que so encerra a edicao nao executa.**
      ⚠️ **Selecione um perfil que NAO seja o ativo, e use o preparo do H6.3 (ativo
      fora da lista).** Com o ativo selecionado, CARREGAR e EXCLUIR ficam apagados
      por `isActive` — motivo independente da digitacao —, e testa-los ali da
      **falso positivo**: eles "nao fazem nada" por outra razao e nao provam nada
      sobre esta guarda.
      Clicar no campo Magic do **ativo** (cartao de cima) **sem alterar nada** e,
      com os quatro ja apagados, clicar **direto no NOVO apagado**.
      **Esperado:** o primeiro clique **so** encerra a edicao — os botoes
      reaparecem e **nada e criado**. O segundo clique e que abre o formulario.
      Repetir com DUPLICAR, CARREGAR e EXCLUIR.
      **Por que:** sair do campo apaga a edicao em curso e o painel repinta no
      mesmo evento para acender SALVAR e CANCELAR; nesse repinte os quatro voltam
      a publicar caixa de clique, e sem guarda um botao visivelmente APAGADO
      executava. So acontece quando a edicao **nao** virou pendencia — com o valor
      alterado eles seguem apagados por `HasPending()`.
      ⚠️ **Sao DOIS caminhos, e o segundo so foi descoberto medindo.** Alem da
      saida do campo pelo proprio clique, o terminal manda `OBJECT_ENDEDIT`
      **antes** da borda do mouse — 31 ms antes, no mesmo clique, conforme o log
      do usuario de 2026-08-15. A primeira versao da guarda so cobria o primeiro
      caminho, e por isso NOVO e DUPLICAR continuavam executando apagados. Se este
      passo falhar de novo, e a marca do ENDEDIT que parou de ser consumida.
- [x] **H6.4b.** No mesmo estado, clicar direto em **SALVAR** depois de digitar um
      valor novo.
      **Esperado:** grava no **primeiro** clique, como sempre. A guarda do H6.4 e
      so para os quatro de perfil — SALVAR e CANCELAR **sao** as saidas da edicao,
      e clicar neles ao sair do campo e o gesto esperado.
      Igualmente, **Atualizar lista** continua respondendo ao primeiro clique.
- [ ] **H6.4c.** ⚠️ **Tambem exige o ativo FORA da lista** (preparo do H6.3), pela
      mesma razao: armado o EXCLUIR, o perfil selecionado nao e o ativo, e o Magic
      do cartao `PERFIL SELECIONADO` e **so leitura** — nao ha onde clicar. O
      campo editavel e o do cartao `PERFIL ATIVO`, que so aparece com ele fora da
      lista.
      Armar o **EXCLUIR** e, com a confirmacao no ar, clicar no Magic do **ativo**.
      **Esperado:** a confirmacao se desarma junto com o botao (mesma fonte unica
      do H5.6).
- [ ] **H6.5.** Conferir que o **INICIAR nao** apaga com o cursor no campo.
      **Esperado:** segue como estava. Ele nao consome a edicao, e bloquear uma
      acao real so porque ha um cursor num campo seria pior que o problema —
      decisao antiga, mantida. Se a digitacao virar alteracao de verdade, e a
      pendencia que o bloqueia, pela escada.

### H7. Confirmacao de abandono com Magic repetido (P2 estreito)

- [ ] **H7.1.** Preparo: perfil ativo **orfao** (arquivo fora da pasta) e invalido
      **por Magic repetido** — nao por lote. Edite um `.cfg` por fora para outro
      perfil ficar com o mesmo Magic do ativo, e confira que a aba Perfis acende.
      Entao **DUPLICAR** um perfil compativel, digitar um Magic livre e clicar
      **CRIAR COPIA**.
      **Esperado:** a confirmacao de abandono aparece (SIM/NAO), como no H5.8.8.
      **Por que este caso e separado:** `ScreenErrorProfiles` **pula** a checagem
      de unicidade do Magic quando o formulario esta aberto — excecao correta, ali
      o Magic do rascunho e o da origem. Mas `CommittedConfigValid` consultava a
      validade do comprometido de DENTRO do formulario, herdava a excecao, e o
      perfil orfao invalido so por Magic passava por valido: sem confirmacao, a
      copia era criada e a configuracao em uso ia embora.
      **Se nao aparecer SIM/NAO**, a validacao do comprometido voltou a rodar em
      modo de formulario.

### I. Conflito entre graficos (exige dois graficos)

- [ ] **I1.** `FusionCanvas` em dois graficos, o segundo tentando carregar o
      perfil ativo do primeiro.
      **Esperado:** recusa nomeando o conflito. A trava e reconsultada **no
      instante do clique**, nao no desenho.
- [ ] **I2.** Perfil ativo preso pelo outro grafico: tentar **SALVAR**.
      **Esperado:** `NAO FOI POSSIVEL SALVAR` com o motivo do registro.
- [ ] **I3.** Nesse mesmo estado, abrir **NOVO**.
      **Esperado:** o formulario de criacao **e editavel** — criar perfil e a
      saida deliberadamente permitida desse bloqueio. Os campos do perfil
      **ativo**, esses, seguem trancados.
- [ ] **I4.** Dois perfis **em disco** com o mesmo Magic (edite um `.cfg`).
      **Esperado:** a aba Perfis acende, as linhas envolvidas sao pintadas
      nomeando quem colide, e CARREGAR e bloqueado nos dois. **EXCLUIR e
      DUPLICAR seguem liberados** — sao a saida.
- [ ] **I6.** ⚠️ **Posicao aberta com o perfil preso por outro grafico.**
      **Esperado:** **CARREGAR apagado**. A excecao que libera CARREGAR sob peer
      lock existe para dar saida ao bloqueio, mas com posicao aberta nao ha saida
      a oferecer — ha uma operacao a proteger. **Se ele acender, pare e
      reporte.**
      **Duas guardas, e as duas devem valer.** O painel recusa (a trava local
      vence a excecao do peer lock) e o motor tambem: o `LOAD_PROFILE` passou a
      recusar com posicao em gerenciamento. Para conferir a segunda, use o
      **painel 1.058** no mesmo estado — la o botao ainda acende, e o esperado e
      que o clique **nao faca nada** e o log registre "Perfil nao carregado
      enquanto existe posicao em gerenciamento".
> **I7 — o isolamento do DESFAZER. NAO e passo manual, e conferencia por
> leitura.** A guarda nova nao pode alcancar o
> `UI_COMMAND_RESTORE_ACTIVE_PROFILE`: ele e a saida de uma criacao que falhou ao
> gravar, e recusa-lo por posicao aberta transformaria protecao em armadilha.
>
> **Por que nao da para montar na mao:** entrar no formulario de criacao exige
> `AccCanCreateProfile` -> `AccRuntimeEditable` -> `!hasPosition`. Ou seja, com
> posicao aberta nao se comeca uma criacao. O estado so existiria falhando a
> criacao SEM posicao, mantendo o formulario aberto e fazendo uma posicao com o
> mesmo Magic aparecer por fora — o que exige um segundo grafico operando com o
> Magic deste, coisa que o registro de instancias recusa.
>
> **O que se confere, entao, no codigo:** `UI_COMMAND_RESTORE_ACTIVE_PROFILE`
> tem ramo PROPRIO em `EAApplicationCommands.mqh`, anterior ao do
> `UI_COMMAND_LOAD_PROFILE`, e nao passa por nenhuma das duas guardas novas. Ele
> so barra por reconciliacao pendente, que e outra coisa. Se algum dia a guarda
> de posicao for movida para dentro de `ApplySettings`, ela passa a alcancar
> este comando — e e exatamente isso que nao pode acontecer.
- [ ] **I5.** Ainda em I4: se o repetido for o do perfil **ativo**, o INICIAR
      tambem bloqueia. Se forem dois perfis parados colidindo entre si, o
      INICIAR **continua liberado** — nao afetam esta conta.

### I2. Cabecalho: por que a acao nao esta disponivel

O painel deixava o INICIAR apagado sem uma palavra na tela — a explicacao existia
so dentro do Status, e o usuario que esta em Perfis nao a alcanca. Agora **uma
faixa sob os botoes** diz o motivo, em qualquer aba, e ela sai da **mesma
funcao** que decide se o botao aceita clique (`ResolveHeaderActionState`).

Regras que valem em todos os passos abaixo:

- **o rotulo do botao nunca vira motivo.** Parado e `INICIAR` mesmo apagado;
  rodando e `PAUSAR` — com posicao aberta ele fica **apagado**, e quem diz
  `OPERANDO` e o distintivo;
- **a faixa nunca manda fazer o que a tela impede.** Se ela diz "salve ou
  cancele", pelo menos um dos dois tem de estar aceso;
- **o distintivo diz ESTADO, nunca causa**, no estado mais especifico
  verdadeiro: `BLOQUEADO` > `IMPEDIDO` > `OPERANDO` > `RODANDO` > `PAUSADO`.
  O mesmo texto aparece no bloco **ESTADO** da aba Status — sai da mesma
  funcao, entao os dois nunca discordam.

| # | Estado a montar | Botao | Distintivo | Faixa |
|---|---|---|---|---|
| I2.1 | Parado, tudo certo | `INICIAR` aceso | `PAUSADO` | nenhuma |
| I2.2 | AutoTrading desligado no MT5 | `INICIAR` apagado | `IMPEDIDO` | frase do EA, terminando em "Habilite para iniciar" |
| I2.3 | AutoTrading desligado **e** campo invalido | `INICIAR` apagado | `IMPEDIDO` | `CONFIGURACAO INVALIDA` — a acionavel vem primeiro |
| I2.4 | Formulario NOVO/DUPLICAR aberto | `INICIAR` apagado | inalterado | `FORMULARIO DE PERFIL ABERTO` |
| I2.5 | Perfil preso por outro grafico | `INICIAR` apagado | `PAUSADO` | motivo do registro, citando CARREGAR |
| I2.6 | Perfil preso **e** campo invalido | `INICIAR` apagado | `PAUSADO` | o do **perfil preso**, nunca "corrija" — os campos estao so-leitura |
| I2.7 | Alteracao pendente, config valida | `INICIAR` apagado | `PAUSADO` | `ALTERACOES PENDENTES — salve ou cancele`, com SALVAR aceso |
| I2.8 | Magic do perfil ativo repetido | `INICIAR` apagado | `PAUSADO` | `MAGIC DO PERFIL EM CONFLITO` |
| I2.9 | Rodando, sem posicao | `PAUSAR` **aceso** | `RODANDO` | nenhuma |
| I2.10 | ⚠ Rodando, sem posicao, AutoTrading desligado | `PAUSAR` **aceso** | `IMPEDIDO` | frase do EA, **dizendo o que fazer** ("Habilite...") |
| I2.11 | Rodando com posicao | `PAUSAR` apagado | **`OPERANDO`** | `POSICAO ABERTA — a saida e pela estrategia ou pela protecao` |
| I2.12 | ⚠ Posicao aberta **e** conexao/permissao perdida | `PAUSAR` apagado | `IMPEDIDO` | nenhuma — quem fala e o **card vermelho**, em qualquer aba |
| I2.15 | Parado, com posicao aberta e permissao perdida | `INICIAR` apagado | `IMPEDIDO` | nenhuma — card no ar, faixa cala **sempre** que ele aparece |
| I2.17 | ⚠ Parado, com posicao aberta, sem mais nada | `INICIAR` **aceso** | `PAUSADO` | `POSICAO EM GERENCIAMENTO — clique INICIAR...`, em ambar |
| I2.18 | ⚠ Fechamento em reconciliacao, EA parado | `INICIAR` **apagado** | `PAUSADO` | `FECHAMENTO EM RECONCILIACAO — aguarde...` |
| I2.19 | ⚠ Fechamento em reconciliacao, EA rodando | `PAUSAR` **apagado** | `RODANDO` | idem |

⚠️ **I2.18 e I2.19 sao a janela entre fechar a posicao e o historico confirmar** —
poucos segundos, e a unica forma de vê-la e olhar o painel logo apos um
fechamento. Nesse instante `hasPosition` continua verdadeiro (ele soma a
reconciliacao) mas a posicao **ja fechou**. O EA recusa INICIAR e PAUSAR ali, os
dois ramos do `TOGGLE_RUNNING` voltam sem executar — entao botao aceso seria
clique inerte, e o distintivo nao pode dizer `OPERANDO`.
| I2.16 | Bloqueio de runtime (troque o ativo do grafico com o EA anexado) | `INICIAR` apagado | `BLOQUEADO` | texto do motor **abreviado com `...`** se nao couber; integral no Status |

⚠️ **I2.8 mudou de ordem por um motivo que vale registrar.** O Magic repetido
tambem reprova `ConfigInputsValid()` — `ScreenErrorProfiles` cobra unicidade em
modo de visualizacao. Com a checagem generica antes, a faixa dizia
`CONFIGURACAO INVALIDA` para um problema que tem nome, e o ramo especifico era
inalcancavel. **Causa especifica vence a generica**, entao o Magic subiu para
logo depois do perfil preso.

⚠️ **I2.16 e o teste da abreviacao.** O bloqueio por troca de ativo passa de 130
caracteres e a faixa tem ~556 unidades: sem medir, o `CCanvas` escreveria alem da
borda e o fim da frase — onde mora a instrucao — sumiria sem deixar sinal.
Conferir que o texto termina em `...` e que a parte acionavel ("Volte para
&lt;ativo&gt;") aparece **antes** do corte.

⚠️ **I2.10 e o passo que nao pode falhar.** PAUSAR nao herda os bloqueios do
INICIAR: com o AutoTrading desligado o EA continua rodando de proposito, e tirar
o PAUSAR prenderia o Fusion ligado por uma condicao externa. Se o botao aparecer
apagado ali, **pare e reporte**.

⚠️ **A faixa sempre diz o que FAZER.** Uma versao anterior de I2.10 mostrava
"TRADING INDISPONIVEL — PAUSAR CONTINUA DISPONIVEL": era verdade e nao servia,
porque nao dizia a acao. Hoje a faixa mostra a frase do motor tambem no estado
rodando — ela nomeia a causa entre as cinco que o guard cobre **e** diz o que
fazer. Ao conferir este passo, leia a faixa perguntando "sei o que fazer agora?";
se a resposta for nao, e defeito mesmo que a frase esteja correta.

- [ ] **I2.13.** Marcador da aba **Status** nos casos I2.2, I2.10 e I2.12.
      **Esperado:** ponto **ambar** a direita do rotulo — **nao** o vermelho de
      validacao. O vermelho promete "ha campo a corrigir nesta tela", e
      AutoTrading nao se corrige em tela nenhuma do painel.

- [ ] **I2.14.** Geometria, com o cabecalho 16 unidades mais alto.
      **Esperado:** conferir nas **tres escalas** (Menor/Padrao/Maior) **e num
      grafico baixo**, onde o painel ja excede a altura disponivel. Percorrer
      todas as abas olhando: campos nativos no lugar, barra de rolagem
      aparecendo quando deve, e a faixa sem encostar nos botoes nem nas abas.

### J. Comparacao lado a lado

- [ ] **J1.** `Fusion` num grafico e `FusionCanvas` em outro, **mesmo simbolo,
      perfis e Magic diferentes**, os dois pausados.
      **Esperado:** as duas telas concordam sobre o que descrevem.
- [ ] **J2.** Trocar o EA de um grafico (remover um, anexar o outro).
      **Esperado:** nenhum objeto do painel anterior sobra na tela.
      **O que este passo prova, e o que nao prova:** remover o EA roda
      `Destroy()`, e e o `Destroy()` que limpa. Entao J2 exercita o caminho
      normal — que e o unico que a troca de painel usa —, e **nao** diz nada
      sobre sobras apos encerramento anormal. Para aquilo nao ha garantia
      cruzada: cada painel limpa os proprios objetos, e depois de um crash as
      sobras do outro podem permanecer. Ver a secao 3.
- [ ] **J3.** Reverter para producao: remover o `FusionCanvas` e anexar o
      `Fusion`.
      **Esperado:** tudo como antes, perfis intactos. **Esta e a reversao** — ela
      nao depende de recompilar nada.

---

## 3. O que NAO e defeito

Comportamentos corretos que ja foram reportados como bug, ou dividas aceitas e
registradas na secao 6 do plano:

- **Editar Estrategias nao muda o Status.** Status descreve o que o EA roda; a
  edicao so chega la pelo SALVAR.
- **SALVAR e CANCELAR acendem ao ENTRAR num campo**, antes de a digitacao ser
  confirmada. O texto de um `OBJ_EDIT` so e publicado no `ENDEDIT` — durante a
  digitacao a consulta devolve o valor anterior, e nao ha contorno. Entrar no
  campo e o unico sinal disponivel.
- **Criar perfil sempre ATIVA o perfil criado**, e perfil nao tem botao de
  ativar. Divida aceita: mudar a semantica so na 2.0 tornaria os dois paineis
  incomparaveis justamente no fluxo em teste.
- **Perfil com espaco no nome de arquivo nao abre nem apaga.**
  `FusionListProfiles` devolve o nome cru e `FusionLoadProfile` saneia antes de
  abrir. Vale para a 1.058 tambem — e item proprio, fora desta migracao.
  Contorno: renomear o arquivo.
- **Corrida de unicidade nome/Magic entre graficos.** Dois graficos gravando
  perfis no mesmo instante podem passar pela conferencia os dois. A 1.058 tem a
  mesma corrida; consertar exige mexer no EA em servico.
- **`ApplySettings` nao e transacional.** Ele muta a sessao e so depois pode
  devolver `false`. O painel contorna perguntando ao disco em vez de deduzir do
  sinal, mas a corrida em si continua.
- **A faixa de abas registra no log** quantos pixels usou a cada criacao do
  painel. E um guarda, nao um erro.
- **Sobras cruzadas apos encerramento anormal nao estao garantidas.** Cada painel
  limpa **os proprios** objetos, e nao os do outro. Na saida ordenada — remover o
  EA, fechar o terminal normalmente — o `Destroy()` roda e nao sobra nada, e e
  desse caminho que a troca de painel depende. Matando o processo do terminal com
  um painel no ar e anexando **o outro** em seguida, objetos do primeiro podem
  ficar na tela. Limpar removendo-os pela janela de objetos do MT5
  (`Ctrl`+`B`).
  Cobrir esse caso de verdade exigiria inventariar os 274 nomes fixos do painel
  classico, e um inventario incompleto vira uma limpeza ampla — que foi
  justamente o defeito removido nesta fase. Fica fora por decisao registrada no
  plano.

---

## 4. Se algo falhar

O painel novo nao esta em producao: o `Fusion.ex5` continua sendo o caminho
seguro, e trocar de volta e trocar o EA do grafico. Nenhum passo deste roteiro
altera o `Fusion.ex5` nem o formato dos perfis — os dois paineis leem e escrevem
o mesmo arquivo, no mesmo esquema.

Ao reportar, vale mais do que a tela: **qual passo**, o texto exato do aviso, e o
que o `.cfg` tinha depois. Metade dos defeitos desta migracao apareceu como
divergencia entre o que a tela dizia e o que o arquivo tinha.

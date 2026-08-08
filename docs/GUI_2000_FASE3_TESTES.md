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

- [ ] **A1.** Anexar `FusionCanvas` a um grafico com `inp_ShowPanel = true`.
      **Esperado:** o painel aparece; a linha `Painel: canvas...` no log.
- [ ] **A2.** Arrastar o painel pela barra de titulo.
      **Esperado:** o painel se move, o **grafico nao**. Se o grafico rolar
      junto, a supressao de `CHART_MOUSE_SCROLL` nao esta valendo.
- [ ] **A2b.** ⚠️ **Tentar arrastar o painel para fora, nos quatro sentidos.**
      **Esperado:** ele para. Para baixo, a barra de titulo inteira continua na
      tela; para a direita, sobra a faixa da esquerda com "EP Fusion" — e ela e
      area de arrasto, entao **sempre da para trazer o painel de volta**. Para
      cima e para a esquerda ele ja parava na borda.
- [ ] **A2c.** Com o painel encostado na borda de baixo ou da direita,
      **diminuir a janela do MT5** (ou o gráfico).
      **Esperado:** o painel e trazido de volta para dentro sozinho. E o caso
      que o limite do arrasto nao cobre: aqui ninguem arrastou nada — o que
      mudou foi o tamanho do grafico.
      **Nota:** a posicao **nao** e guardada entre sessoes; reanexar o EA
      sempre devolve o painel ao canto superior esquerdo. E a rede de seguranca,
      mantida de proposito enquanto a Fase 3 nao fecha.
- [ ] **A3.** Minimizar e restaurar.
      **Esperado:** os campos de digitacao **somem** ao minimizar. Um `OBJ_EDIT`
      apenas escondido continuaria aceitando clique.
- [ ] **A4.** Remover o EA do grafico.
      **Esperado:** nenhum objeto sobra — sem retangulo, sem campo de texto.
- [ ] **A5.** Trocar o timeframe do grafico com o painel aberto.
      **Esperado:** o painel se reconstroi inteiro e o distintivo do cabecalho
      mostra o **TF do grafico** (nao o resumo operacional, que e a linha de
      largura inteira do cartao SESSAO).
- [ ] **A7.** ⚠️ **Campos nativos durante a rolagem.** Numa aba com barra —
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
- [ ] **A6.** Fechar e reabrir o terminal com o EA anexado.
      **Esperado:** volta com o mesmo perfil ativo e a mesma aparencia (paleta,
      tema e escala escolhidas na aba Layout sobrevivem — ficam em variavel
      global do terminal).

### B. O EA alimentando a tela

Ate aqui todos os numeros vinham do harness. Agora sao reais.

- [ ] **B1.** Comparar a aba **Status** com a do `Fusion.ex5` no mesmo perfil.
      **Esperado:** mesmo estado (RODANDO / PAUSADO / BLOQUEADO), mesmos avisos,
      mesmo resumo de TFs operacionais.
- [ ] **B2.** Comparar a aba **Resultados**.
      **Esperado:** os mesmos numeros, com **ponto decimal**; lucro colorido pelo
      sinal com zero neutro; streak desligada aparece **OFF**, nao zero; sem base
      de drawdown os campos ficam `--`, nao zerados.
- [ ] **B3.** Clicar **INICIAR** e depois **PAUSAR**.
      **Esperado:** a capsula do cabecalho e o Status acompanham. Com posicao
      aberta o distintivo mostra **OPERANDO** e o botao fica em **PAUSAR
      apagado** — quem explica por que e a faixa. (Detalhado em I2.11.)
- [ ] **B4.** Editar um campo de Estrategias e observar o Status.
      **Esperado:** o Status **nao muda** — ele descreve o que o EA esta
      rodando, e a edicao so vale depois do SALVAR. **Isto e o correto**, e ja
      foi reportado como defeito uma vez.

### C. Pendencia e validacao

- [ ] **C1.** Alterar um campo qualquer.
      **Esperado:** SALVAR e CANCELAR acendem. Sem alteracao nenhuma eles ficam
      apagados — nao ha o que gravar nem o que descartar.
- [ ] **C2.** Clicar **CANCELAR**.
      **Esperado:** o campo volta ao valor comprometido e os dois botoes apagam.
- [ ] **C3.** Digitar texto invalido num campo numerico (`abc`) e sair do campo.
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
- [ ] **C4.** Digitar `0,30` num campo decimal.
      **Esperado:** aceito como `0.30`. A virgula e normalizada na entrada.
- [ ] **C5.** Deixar um campo reprovado na validacao e olhar o cabecalho.
      **Esperado:** INICIAR, SALVAR e CRIAR PERFIL apagam, e **a tela diz por
      que e em que aba** — botao apagado sem explicacao e a licao 1 da secao 8.

### D. SALVAR — o caminho critico

- [ ] **D1.** Alterar um campo e clicar **SALVAR**.
      **Esperado:** aviso `PERFIL SALVO` (some em 5 s). Conferir **no arquivo**
      `.cfg` que o valor mudou. O painel confere isso sozinho relendo o disco;
      este passo confere o conferidor.
- [ ] **D2.** ⚠️ **Com a gravacao bloqueada (1.5, `.tmp` do perfil ativo preso)**:
      alterar um campo e clicar **SALVAR**.
      **Esperado:** aviso `PERFIL NAO GRAVADO`, **sem prazo para sumir**, dizendo
      as duas metades — a configuracao **vale nesta sessao**, o arquivo **nao foi
      escrito**. O SALVAR **continua aceso**.
      **Se aparecer `PERFIL SALVO`, pare o teste e reporte**: e o defeito que a
      conferencia em disco existe para impedir, e o pior que este painel pode
      fazer.
- [ ] **D3.** Ainda bloqueado: navegar para outra aba e voltar.
      **Esperado:** a marca de gravacao pendente **permanece** — ela so cai na
      proxima gravacao bem-sucedida.
- [ ] **D4.** Soltar o `.tmp` (o `$fs.Close()` da secao 1.5) e clicar **SALVAR**
      de novo.
      **Esperado:** `PERFIL SALVO`, a marca some, o arquivo tem o valor novo.

### E. CRIAR PERFIL — o caminho com rollback

- [ ] **E1.** Aba Perfis > **NOVO**, nome e Magic livres, **CRIAR PERFIL**.
      **Esperado:** `PERFIL CRIADO`, o perfil aparece na lista **e fica ativo**
      neste grafico (criar sempre ativa — divida aceita, secao 6 do plano).
- [ ] **E2.** **NOVO** com um nome que ja existe.
      **Esperado:** `NOME JA EXISTE`. A conferencia e em **disco**: crie um
      `.cfg` a mao pela pasta com o formulario ja aberto e o nome ainda assim
      deve ser recusado.
- [ ] **E3.** **NOVO** com o Magic de outro perfil.
      **Esperado:** `MAGIC JA USADO`, **nomeando o perfil dono** do numero.
> **O marcador dos passos E4–E7 e o MAGIC, e nao um campo qualquer.** Entrar em
> NOVO exige **nao haver pendencia** (`profileCreateAllowed`), entao no instante
> da criacao o rascunho e, por construcao, identico a configuracao do perfil
> ativo. O unico campo que difere no perfil que esta nascendo e o **Magic** — e
> ele e justamente a identidade que impede dois graficos de colidirem. Anote o
> Magic do perfil ativo (chame de `M_ANT`) e escolha um bem diferente para o
> perfil novo (`M_NOVO`) antes de comecar.

- [ ] **E4.** ⚠️ **Com a gravacao bloqueada (1.5)**: prenda o `.tmp` do nome que
      vai digitar — se o perfil novo se chamara `X`, prenda `X.cfg.tmp` — e
      entao **NOVO**, nome `X`, Magic `M_NOVO`, **CRIAR PERFIL**.
      **Esperado:** `PERFIL NAO CRIADO`, **o formulario continua aberto**, e o
      texto manda clicar **CRIAR PERFIL** para tentar de novo — nunca SALVAR (o
      SALVAR grava no perfil **ativo**, que aqui e o anterior).
      **Estado real neste ponto, e e o que torna o resto perigoso:** o EA ja
      **aplicou** `M_NOVO`. A sessao roda o Magic do perfil que nao existe, sob o
      nome do perfil anterior.
- [ ] **E5.** Sem sair do formulario, soltar o `.tmp` e clicar **CRIAR PERFIL**
      de novo.
      **Esperado:** `PERFIL CRIADO`, com a configuracao **que estava no
      formulario** — nao a de antes da primeira tentativa.
- [ ] **E6.** Repetir E4 (prender, tentar, falhar) e entao clicar **DESCARTAR**.
      **Esperado:** aviso `CRIACAO ABANDONADA` dizendo que a configuracao
      anterior voltou a valer, e o Magic exibido volta a `M_ANT`. O formulario
      **so fecha quando a volta chega**; se o EA recusar, ele continua aberto com
      `NAO FOI POSSIVEL ABANDONAR`.
- [ ] **E7.** ⚠️ **A regressao que este mecanismo existe para impedir.**
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

- [ ] **F1.** Selecionar um perfil qualquer (nao o ativo) e clicar **EXCLUIR**.
      **Esperado:** o botao vermelho vira **SIM**, com **NAO** ao lado na mesma
      altura, e **todo o resto da coluna apaga**. A pergunta inteira aparece no
      aviso do rodape.
- [ ] **F2.** Clicar **NAO**.
      **Esperado:** volta ao normal, nada e apagado.
- [ ] **F3.** Armar de novo e, sem confirmar, **trocar de aba** (ou trocar a
      selecao).
      **Esperado:** a confirmacao **desarma sozinha**. Armada sobre um indice,
      ela apagaria o perfil errado.
- [ ] **F4.** Armar e clicar **SIM**.
      **Esperado:** `PERFIL EXCLUIDO`, o arquivo some do disco e da lista.
- [ ] **F5.** Selecionar o perfil **ativo**.
      **Esperado:** EXCLUIR apagado, **com o motivo escrito**.
- [ ] **F6.** Selecionar o perfil `default`.
      **Esperado:** EXCLUIR apagado — o `default` nao se exclui, como na 1.058.

### G. DUPLICAR — tambem nao passa pelo EA

- [ ] **G1.** Selecionar um perfil e clicar **DUPLICAR**.
      **Esperado:** o formulario abre com o nome sugerido `<nome>_copy` (ou
      `_copy_2`...) e os valores **lidos do arquivo de origem**, nao do perfil
      ativo.
- [ ] **G2.** Clicar **CRIAR COPIA**.
      **Esperado:** `PERFIL CRIADO`. O Magic da copia precisa ser trocado antes —
      dentro do formulario o Magic do rascunho **nao** e cobrado por unicidade
      (ele veio da origem, por definicao), mas a gravacao o cobra.
- [ ] **G3.** Entrar em NOVO, digitar um nome, sair sem criar, e voltar para a
      lista.
      **Esperado:** o texto digitado **nao reaparece** dentro do campo Magic da
      lista. (Foi um bug real de slot compartilhado entre modos da mesma tela.)

### H. CARREGAR — a politica de conflito

- [ ] **H1.** Com alteracoes pendentes, clicar **CARREGAR** em outro perfil.
      **Esperado:** o perfil novo entra e **o painel avisa que a digitacao foi
      descartada**. Na recarga deliberada o EA vence, com aviso — decisao
      registrada.
- [ ] **H2.** Carregar um perfil e conferir o cabecalho.
      **Esperado:** nome do perfil novo, SALVAR e CANCELAR apagados (nao ha
      pendencia recem-carregada).
- [ ] **H3.** Renomear um `.cfg` por fora para algo ilegivel e tentar carregar.
      **Esperado:** `PERFIL NAO CARREGADO`, **a configuracao atual preservada**.
- [ ] **H4.** Com protecao de drawdown em curso, carregar um perfil de
      parametros de DD diferentes.
      **Esperado:** recusa com a mensagem de drawdown. Trocar ali recomecaria a
      conta no meio.

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

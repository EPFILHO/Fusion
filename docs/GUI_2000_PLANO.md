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

A fronteira em si nao mudou na Fase 2, mas o **vocabulario** que passa por ela
ganhou um verbo: `UI_COMMAND_RESTORE_ACTIVE_PROFILE`. Foi a unica alteracao no EA
exigida pela migracao ate aqui, e ela e aditiva — a 1.058 nunca emite esse valor.
O motivo esta na Etapa 2c: sem um verbo proprio, "voltar ao que eu ja tinha" era
indistinguivel de "adotar outro perfil", e herdava recusas que existem so para o
segundo caso.

E essa fronteira estreita que permite construir o painel novo ao lado e troca-lo
sem alterar o EA.

---

## 6. Plano de execucao

**Fase 1 — Renderizador completo com dados falsos.** Todas as abas e subabas
desenhadas, com todos os estados visuais. Medir o custo de desenho cedo.

**Fase 2 — `CFusionCanvasPanel` com a mesma interface.** Implementa os 8 metodos da
secao 5.

> **Correcao (Etapa 2b).** A frase original dizia que os fragmentos de validacao,
> draft e acesso seriam "incluidos praticamente como estao, por serem fragmentos de
> corpo de classe". **Isso e falso e ja custou uma expectativa errada de esforco.**
> Eles sao metodos de `CFusionPanel` que referenciam um membro `CEdit` NOMEADO por
> campo (`m_cfgRiskLotEdit`, `m_cfgSystemMagicEdit`, dezenas deles). O renderizador
> em canvas e deliberadamente o oposto: modelo generico indexado por slot, e e isso
> que o deixa ~30% menor. O que se reaproveita de verdade sao as **funcoes de
> validacao em si** (`FusionIsIntegerText`, as faixas, as regras cruzadas), que ja
> sao livres de `CEdit`. O que precisa ser **reescrito** e a camada fina de leitura.
> E adaptador, nao reescrita grande — mas e trabalho real, nao `#include`.

A Fase 2 avanca em quatro etapas:

| Etapa | Entrega | Estado |
|---|---|---|
| **2a** | Esqueleto: os 8 metodos, ciclo de vida delegando ao renderizador | feita |
| **2b** | Telas lendo e escrevendo o rascunho de `SEASettings` | **feita** — as sete abas leem dados reais; nenhum valor fixo da Fase 1 sobrou |
| **2c** | Comandos saindo do painel: `ConsumeCommand` | **feita** |
| **2d** | Validacao, `configInputsValid` e politica de conflito | **feita** — fechada junto com a 2c, como o plano exigia |

Com a 2c e a 2d fechadas, **a Fase 2 esta completa**: `CFusionCanvasPanel` responde aos
oito metodos da secao 5 com comportamento real. O proximo passo e a Fase 3 — o
`#define` que escolhe qual classe o membro `m_panel` tem.

**O que a 2b entregou, por natureza de dado.** Nem tudo virou campo de
`SEASettings`, e a diferenca importa para quem for mexer:

- **Rascunho de `SEASettings`** — Estrategias, Filtros, Gestao (Risco e Protecao),
  o Magic em Perfis e os indicadores visuais em Layout. Passam por SALVAR.
- **Somente leitura do snapshot** — Status e Resultados.
- **Estado de DISCO** — a lista de perfis. Quem enumera e quem constroi o painel
  (`CFusionCanvasPanel` tem um `CSettingsStore`, como a 1.058); o renderizador
  recebe pronta e nao toca em `Persistence`.
- **Preferencia de exibicao** — paleta, tema e escala. Vivem em variavel global
  do terminal, valem para todo grafico e sao aplicadas no ato: **nao** entram no
  perfil e **nao** criam pendencia.

### Divida registrada para a 2c — quitada

Tres coisas ficaram prontas para receber comando na 2b. Como cada uma foi paga:

1. **Revalidar no instante da acao — feito em `CFusionCanvasPanel`.** O
   renderizador nao decide mais nada sozinho: ele publica uma **intencao**
   (`CanvasIntents.mqh`) e o painel reconfere contra o disco e os registros do
   terminal antes de traduzir para `SUICommand`. CARREGAR reconsulta as travas e
   a compatibilidade de drawdown; EXCLUIR reconfere trava e perfil ativo;
   DUPLICAR le o arquivo de origem na hora.
2. **Gravar perfil confere o disco de novo — feito.** `NameFreeOnDisk` e
   `MagicFreeOnDisk` perguntam ao disco, e nao a lista em memoria. E a unica
   forma de ver o arquivo que outro grafico criou desde a ultima releitura —
   inclusive um ilegivel, que nao aparece na lista e mesmo assim ocupa o nome.
3. **`m_dirty` foi REMOVIDO.** A 2c nao precisou dele: todo controle de producao
   esta ligado a um campo de `SEASettings`, e a pendencia sai da diferenca entre
   rascunho e comprometido. Mantido, teria virado risco de verdade — com a 2c,
   uma tecla de diagnostico da tela de estresse acenderia o SALVAR e faria o
   painel emitir gravacao de um rascunho que ninguem alterou.

⚠️ **2c e 2d fecharam juntas, como o plano exigia.** Ate a 2c existir, nao havia
caminho do rascunho ate o EA: nada era gravado, e por isso a ausencia de validacao
**nao era risco operacional** — era so uma tela que aceitava numero ruim. No instante
em que a 2c abriu esse caminho, a mesma ausencia passaria a permitir **gravar
configuracao invalida no perfil**. Era o unico ponto deste plano em que uma etapa
isolada pioraria o sistema; por isso `configInputsValid` entrou no mesmo passo, e e
ele que governa o SALVAR, o CRIAR PERFIL e o INICIAR.

### O caminho de volta, como ficou

```
clique -> intencao (renderizador)  -> revalidacao (painel) -> SUICommand -> EA
                                   \-> acao local (disco)  -> aviso na tela
```

O renderizador nao alcanca `Persistence` — decisao da Fase 1, e o que mantem o
desenho sem tocar em disco. Ele sabe o que o usuario **pediu**; nao sabe se ainda
cabe. Duas intencoes nunca chegam ao EA, porque sao operacoes de disco do proprio
painel (como na 1.058): **EXCLUIR** e **DUPLICAR**.

Toda resposta volta pela **caixa de aviso**, que ja crescia com o texto e estava
muda desde a 2b. Ela mostra, nesta ordem: a resposta ao ultimo clique, e depois o
erro **da tela aberta** — nunca o erro de outra aba, para o qual existe a cadeia de
vermelho.

O aviso morre quando o usuario volta a agir (navegar ou mexer em qualquer campo).
Alguns tambem tem **prazo**, e a distincao vale a regra:

- aviso que descreve um **evento passado** — texto recusado, perfil salvo, perfil
  excluido — expira em 5 s. Ficar na tela depois de deixar de ser novidade e
  sujeira.
- aviso que descreve um **estado em vigor** — exclusao armada — nao expira. Sumir
  enquanto os botoes continuam la deixaria a pergunta sem enunciado.
- **recusa nao expira**, mesmo sendo evento: ela pede uma decisao, e some quando o
  usuario a toma.

**EXCLUIR pede confirmacao no proprio cartao.** O botao vermelho vira **SIM**, com
**NAO** ao lado, na mesma altura — o segundo clique cai onde o primeiro caiu, entao
a saida precisa estar em outro lugar da linha. Nao e popup: popup teria de suprimir
os campos nativos sob ele (regra do modelo hibrido) e taparia justamente a linha do
perfil prestes a sumir. A pergunta inteira vive no aviso do rodape, e por isso o
botao so carrega a resposta: `CONFIRMAR` nao cabia na coluna de 124 px.

**Com a confirmacao armada, todo o resto da coluna e apagado.** Quatro botoes
preenchidos em cores fortes disputavam atencao no unico momento em que existe uma
pergunta so na tela. E a regra "um unico botao preenchido por vez" aplicada onde
ela mais vale.

A confirmacao cai sozinha em toda mudanca de contexto — trocar a selecao, navegar,
a lista mudar, ou a acao deixar de ser possivel. Armada sobre um indice, ela
apagaria o perfil errado.

**O EA nao responde "deu certo".** Ele chama `LoadSettings` quando deu, e apenas
retorna quando nao deu. O painel lembra que pediu (`m_echoKind`) para distinguir a
recarga que e resposta ao proprio SALVAR — que merece "perfil salvo" — da recarga
vinda de outro motivo, que merece o aviso de que a digitacao se perdeu. Sem isso,
uma gravacao bem-sucedida anunciava perda.

> ⚠️ **E chamar `LoadSettings` tambem nao significa que gravou.** O EA aplica e
> grava em passos separados, e o retorno de `SaveProfile` so governa a troca do
> nome ativo:
>
> ```
> if(!ApplySettings(...)) return;
> if(m_settingsStore.SaveProfile(...)) m_activeProfileName = profileName;
> ReloadPanelSettingsIfVisible();   // <- roda de todo jeito
> ```
>
> Disco cheio, arquivo somente-leitura, pasta sem permissao: a configuracao passa
> a valer nesta sessao e o painel era avisado do mesmo jeito — e anunciava "PERFIL
> SALVO". Na criacao chegava a dizer que o perfil novo estava ativo com o arquivo
> inexistente e o ativo ainda sendo o anterior. E a pior mentira que este painel
> pode contar: o usuario fecha o terminal confiando que gravou.
>
> Nao ha canal para o EA dizer "falhou" sem mexer no comando, que e producao
> compartilhada com a 1.058. Entao o painel **confere o resultado no disco** em vez
> de confiar no aviso (`AnnounceSaveOutcome`): relê o perfil e compara com o que o
> EA aplicou. E a licao 4 da secao 8 aplicada a ele mesmo. Custa uma leitura por
> clique em SALVAR — nunca por quadro.
>
> ⚠️ **E ABANDONAR tem de desfazer, nao so fechar a tela.** Manter o formulario
> aberto fechou o caminho principal, mas o DESCARTAR reabria: ele fechava o
> formulario sem desfazer o que o EA ja aplicara, o SALVAR do cabecalho reaparecia
> apontando para o perfil anterior, e `CRIAR X -> falha -> DESCARTAR -> SALVAR`
> voltava a sobrescrever `default` com a configuracao de X.
>
> Nao ha canal de rollback no EA — mas ha algo equivalente, e que ele ja sabe
> fazer: **recarregar o perfil ativo do disco**. Nesse estado o DESCARTAR emite
> `FCV_INTENT_RESTORE_ACTIVE`, que vira um `UI_COMMAND_LOAD_PROFILE` do proprio
> perfil ativo. O formulario so fecha quando a recarga volta; recusada, ele
> continua aberto e a saida perigosa segue fechada.
>
> ⚠️ **E a distincao tem de sobreviver a traducao.** A primeira versao virava um
> `UI_COMMAND_LOAD_PROFILE` do proprio perfil ativo — o painel pulava as SUAS
> conferencias, mas o EA aplica no LOAD as recusas que protegem contra ADOTAR
> outro perfil (drawdown ativo, perfil ou Magic em uso por outro grafico), e uma
> delas nega justamente o desfazer. O caso e concreto: com o perfil ativo preso
> por outro grafico, CRIAR PERFIL e uma saida deliberadamente permitida; falhando
> a gravacao, a MESMA trava que motivou a criacao recusaria a volta.
>
> Por isso existe `UI_COMMAND_RESTORE_ACTIVE_PROFILE`, acrescentado ao fim do
> enum. Ele nao troca de perfil, nao grava e nao mexe em `m_activeProfileName` —
> logo nao passa pelas recusas de CARGA. So a reconciliacao pendente continua
> barrando, e por outro motivo: ali o EA aguarda o historico confirmar um
> fechamento.
>
> **E o comando leva as CONFIGURACOES, nao so o nome.** Reler o perfil ativo do
> disco falha exatamente quando o arquivo dele e o que sumiu — o painel fotografa
> o estado ANTES de arriscar a criacao (`m_preCreateSettings`), que e o unico
> instante em que ele ainda existe. Assim o desfazer independe do disco.
>
> ⚠️ **A fotografia e da TRANSACAO, nao da tentativa.** Recapturada a cada clique
> em CRIAR, a segunda tentativa fotografava o que a primeira ja tinha aplicado: o
> desfazer "restaurava" exatamente o que devia descartar, e anunciava que o perfil
> anterior tinha voltado. Ela e tirada na primeira tentativa e liberada so quando a
> transacao acaba — criou, ou abandonou.
>
> **E o contexto inclui a divida de persistencia anterior.** Criar perfil e
> permitido com uma gravacao ja pendente; o rollback apagava essa divida junto, e o
> arquivo do perfil ativo seguia desatualizado sem o painel avisar. Ele restaura o
> que havia antes, porque desfaz a criacao — nao a gravacao que falhou antes dela.
>
> **Duas guardas para uma so regra.** Enquanto ha criacao falhada pendente, o
> SALVAR do cabecalho nao pode existir: ele gravaria no perfil ATIVO a configuracao
> do perfil que se tentou criar. Manter o formulario aberto ja fazia isso via
> `headerLive` — mas trocar de aba fechava o formulario e reabria a porta. Hoje a
> navegacao **nao fecha** o formulario nesse estado (voltar a Perfis reencontra o
> desfazer), e o SALVAR e negado pelo proprio `m_createFailed`. A condicao que
> importa e o estado, nao a tela que o mostra.
>
> ⚠️ **E a saida tem de apontar para o botao CERTO.** Numa CRIACAO que falha ao
> gravar, o perfil ativo continua sendo o anterior. Fechando o formulario ali, o
> nome do perfil novo se perdia — o painel so guardava "houve falha" — e o aviso
> mandava clicar SALVAR, **que grava no perfil ATIVO**. Seguindo a instrucao da
> tela, o usuario sobrescreveria o perfil anterior com a configuracao do perfil
> que tentou criar. Hoje o formulario **fica aberto** nesse caso: o alvo continua
> na tela, os botoes do cabecalho seguem apagados (`headerLive` exige modo de
> navegacao) e a retentativa e o proprio CRIAR PERFIL. O estado guarda a
> **operacao**, nao so o fato de ter falhado.
>
> **E avisar nao bastava: faltava a saida.** Quando a gravacao falha, o EA ja
> aplicou — rascunho e comprometido ficam iguais, "alteracoes nao salvas" some e os
> tres botoes do cabecalho apagam. O painel dizia "PERFIL NAO GRAVADO" e nao
> oferecia nenhuma forma de tentar de novo, que e a licao 2 da secao 8 sendo
> quebrada pelo proprio aviso.
>
> Por isso existe `m_notSaved`, e ele **nao e pendencia de rascunho**: nao ha o que
> descartar (o CANCELAR continua apagado, corretamente) nem motivo para travar o
> INICIAR (a configuracao esta valendo e e valida). O que ele faz e manter o SALVAR
> aceso, marcar o cabecalho com "· nao gravado no disco" e entrar em
> `HasUnsavedDraftChanges`, para o EA avisar ao fechar o grafico — porque ali as
> duas coisas se somam: nos dois casos o usuario perde a alteracao ao reiniciar.

### Pendencias da Etapa 2d (validacao / acesso / conflito) — todas fechadas

Tres coisas foram deixadas de fora de proposito ate a 2b. Nenhuma era
esquecimento; todas pertenciam a mesma camada e se resolveram juntas.

> **Nota da 2b.** A camada de acesso deu **quatro** furos achados em revisao, todos
> por um motivo so: **nao existe uma regra unica de "campo"**. Quem for mexer nela
> comece por aqui.
> - `activeProfileEditable` = `runtimeEditable && !peerLock` governa os campos do
>   perfil ativo, o SALVAR e a administracao de perfis. Ligar so `runtimeEditable`
>   deixava editar um perfil preso por outro grafico e nao poder salvar.
> - Mas os campos do formulario de **criar** seguem outra regra —
>   `profileCreateAllowed`, que **nao** exige `activeProfileEditable`, porque criar
>   nao mexe no que esta preso e e uma saida do bloqueio. Aplicar a regra do perfil
>   ativo ali trancava o formulario que o NOVO acabara de abrir.
> - E a pendencia so pesa para **entrar** no formulario, nao dentro dele
>   (`profileEditMode || !hasPendingChanges`).
> - O predicado estava **escrito por extenso em varios pontos**, e foi a copia
>   faltando num terceiro que abriu o furo. Hoje e uma funcao so.
>
> Licao para a 2d: auditar essa camada **inteira de uma vez**, e nao tela a tela —
> ela nao se deixa fechar por partes.

**1. A camada de acesso — FEITA.** Os predicados da 1.058 (`UIPanelAccessState.mqh`)
foram portados para `CanvasRendererChrome.mqh`: iniciar, pausar, salvar, cancelar,
carregar, criar e excluir perfil, alem do bloqueio dos campos com o EA rodando ou
com posicao aberta. **`configInputsValid` entrou na 2d** e governa INICIAR, SALVAR e
CRIAR PERFIL — o `true` provisorio saiu.

Uma regra nova ganhou funcao propria pela licao da 2b: `AccCanDeleteSelected()`. Ela
e consultada em **dois** lugares que precisam concordar — o desenho, que decide se
oferece EXCLUIR, e o pulso, que desarma a confirmacao quando a oferta some. Escrita
por extenso nos dois, divergiria; e foi exatamente uma copia divergente de predicado
de acesso que abriu o quarto furo achado na revisao da 2b.

**2. Validacao e regras cruzadas — FEITA** (`CanvasRendererValidate.mqh`). As regras
sao as da 1.058, extraidas uma a uma dos `Validate()` dos paineis de estrategia e
filtro, de `UIPanelRiskValidation` e de `UIPanelProtectionValidation` — nao
rededuzidas. Uma faixa "obvia" que discordasse faria os dois paineis aceitarem
perfis diferentes, e o arquivo gravado por um seria recusado pelo outro.

O que mudou foi so a camada de leitura, como a correcao da 2b antecipou. E uma
diferenca de fundo, que e melhoria: la o texto cru do controle e reparseado a cada
passada; aqui o parse acontece **uma vez**, no fim da edicao, e o que se guarda e o
veredito (`m_fldBadText`, por campo). O efeito para o usuario e o mesmo: texto
recusado mantem o ultimo valor bom e pinta o campo de vermelho.

E foi esse portao que matou o "digitar letra num campo numerico vira zero sem
reclamar". Ele fica **antes** de qualquer switch de proposito: um caso novo esquecido
la embaixo deixaria aquele campo sem veredito, e ele voltaria a aceitar lixo em
silencio. De quebra, a virgula passou a ser normalizada — `0,30` era convertido para
zero pelo `StringToDouble`.

> ⚠️ **Correcao, achada pelo usuario no primeiro teste: texto recusado NAO e erro de
> validacao — e evento.** A primeira versao guardava o veredito do parse por campo e
> o somava a validacao: campo vermelho, aviso e a cadeia acesa ate a aba. Mas quem
> digita letra num campo numerico ve o valor bom **voltar sozinho** — o `BuildEdits`
> reescreve o objeto no mesmo quadro, porque o rascunho nao mudou. Um instante
> depois nao existe mais texto ruim em lugar nenhum, e mesmo assim a marca ficava
> ligada: so entrar no campo e sair de novo a limpava. O painel apontava um erro
> que ele proprio ja tinha desfeito.
>
> **A regra que fica: a validacao responde sobre o RASCUNHO, que e o unico estado
> persistente.** Texto recusado nunca chega la, logo nao ha o que marcar. O que o
> usuario precisa e saber POR QUE o valor voltou, e isso e recado — vai para a
> caixa de aviso, com prazo.

⚠️ **O rascunho tem DUAS portas, e a validacao precisa cobrir as duas.** A porta do
teclado e estreita: o parse recusa o que nao e numero e `TimePartValue` recorta hora
e minuto na entrada. A porta do **arquivo de perfil** nao filtra nada — o
desserializador faz `StringToInteger(value)` direto. Confiar no que a digitacao nao
deixa passar e o erro; um perfil editado a mao, ou vindo de outra versao, entra com
o que quiser.

Foi assim que dois furos passaram na primeira volta da 2d, os dois recusados pela
1.058 e nao portados:

- **horario fora da faixa.** So a ORDEM era conferida, entao `25:00–26:00` era
  valido: SALVAR e INICIAR acesos, e uma janela de noticia que nunca dispararia.
- **modo de filtro inexistente.** `rsiFilterMode` e `bbFilterMode` vinham do arquivo
  sem conferencia. O combo ainda DISFARCA — ele limita o indice e mostra a primeira
  opcao —, enquanto o rascunho segue com o enum invalido e seria gravado assim.

Regra para quem for acrescentar campo: **se o valor pode vir do arquivo, a faixa
tem de ser cobrada mesmo que a tela nao consiga produzi-la.**

### Precisao: o rascunho e cortado na do arquivo, na entrada

Os nove `double` de `SEASettings` sao gravados com casas FIXAS — duas, menos o lote
com quatro. Um valor com mais casas nao sobrevive a ida e volta, e isso quebrava
duas coisas ao mesmo tempo: a **tela mentia** (o campo e desenhado com duas casas,
entao digitar `1,234` mostrava `1.23` enquanto o EA operava `1.234`) e a
**conferencia de gravacao acusava falso** — com 1e-7 de tolerancia, uma gravacao
correta virava "PERFIL NAO GRAVADO".

A resposta e cortar na **entrada** (`Core/SettingsPrecision.mqh`), nao afrouxar a
comparacao: o que nao cabe no arquivo nao deveria existir no rascunho, senao a tela
e o disco discordam para sempre. E o que a 1.058 faz sem querer — a validacao dela
relê o texto do controle a cada passada, e o texto ja esta com duas casas.

O corte acontece nas tres portas: no que se digita, no que chega do EA
(`SetSnapshot`) e no que se compara com o disco. O lote e a excecao deliberada —
cortado na precisao do ARQUIVO (quatro casas) e nao na de exibicao, porque cortar
na exibicao mascararia um lote desalinhado do passo do ativo: `0.125` com passo
`0.01` viraria `0.13`, valido, e o usuario gravaria um lote que nunca pediu.

⚠️ A tabela de casas **espelha `ProfileSettingsSerializer.mqh`**. Mudar a grafia de
um campo la sem mudar aqui traz o falso "nao gravado" de volta, e isso nao aparece
em compilacao nenhuma. Ha ponteiro nos dois arquivos.

⚠️ **O lote fica em QUATRO casas, e isso e decisao — nao limite esquecido.** Chegou
a ir para oito, porque `FusionVolumeDigits` conta digitos ate 8 e um ativo de passo
`0.00001` teria o lote zerado na gravacao. **Foi revertido**: o `8` daquela funcao e
teto de LACO, nao faixa suportada, e a gravacao mais fina passou a ser mais precisa
que tudo o que a le —

- `FusionSettingsEqual` compara lote com tolerancia de `1e-7`, e trataria
  `0.00000001` e `0.00000002` como o mesmo lote: sem pendencia, com SALVAR apagado,
  e uma gravacao que falhou parecendo bem-sucedida;
- as checagens de minimo, maximo e do plano de TP parcial usam a mesma tolerancia
  absoluta, que para um lote de `1e-8` e **maior que o proprio lote**.

Fechar de verdade exigiria derivar toda tolerancia de volume do `volumeStep`, em
codigo que a 1.058 tambem usa — e para atender um caso que nao existe no uso real:
nenhuma corretora opera abaixo de `0.01`, e quatro casas ja dao cem vezes essa
folga. A propria GUI exibe o lote com duas casas na maioria dos ativos
(`FusionFormatVolume` usa o passo, com minimo de duas).

**A licao e sobre o numero, nao sobre o lote:** quatro casas nao e um limite
arbitrario a ser "modernizado" — e o ponto em que gravacao, comparacao e validacao
de volume concordam. Mexer numa das tres sozinha desalinha as outras duas.

### Configuracao aplicada e nao gravada nao se perde calada

Depois de uma falha de gravacao o rascunho e o comprometido ficam iguais, entao
`HasPending()` e falso — e CARREGAR, que so consultava essa pergunta, trocava o
perfil e levava junto a configuracao que o proprio painel dizia ter por gravar.

**CARREGAR continua permitido**, e isso e escolha: bloquea-lo com o disco quebrado
deixaria o usuario sem saida, e o principio de que carregar outro perfil E a saida
ja vale aqui para o perfil preso por outro grafico. O que nao pode e a perda ser
silenciosa — o painel guarda o NOME do perfil cujo arquivo ficou para tras e
anuncia o que foi substituido. Mesma politica da recarga: o EA vence, com aviso.

A cadeia de erro (trilho -> subaba -> aba) so agora tem dado real do outro lado, e as
faixas de nivel 2 de **Estrategias e Filtros** passaram a marcar erro: ate a 2b so a
de Gestao marcava, e o vermelho parava no meio do caminho — a aba de cima acendia
sem que nenhuma subaba dissesse onde.

⚠️ `HasDuplicateMagic()` acende a aba Perfis mas **nao** entra em `configInputsValid`.
Sao perguntas diferentes: ele responde "ha Magic repetido em algum lugar do disco", e
dois perfis parados que colidem entre si nao atrapalham esta conta. Dentro do
predicado, ele passaria a impedir INICIAR e SALVAR por causa de arquivos que este
grafico nao usa. Quem cuida do caso que importa e `AccCanStart`, com
`ActiveMagicConflicts()`.

**Custo:** `ConfigInputsValid()` percorre as vinte e uma telas e e consultado tres
vezes por quadro (INICIAR, SALVAR, CRIAR). O rascunho nao muda no meio de um desenho,
entao a resposta e calculada **uma vez por quadro** — cache invalidado no inicio do
`DrawFrame`, e nao a cada escrita no rascunho: toda alteracao ja pede redesenho, e
depender de lembrar de invalidar em cada ponto de escrita seria criar a chance de
esquecer um.

**3. Politica de conflito durante a edicao — DECIDIDA: o EA vence, com aviso.**

Enquanto o usuario digita, o texto em andamento continua protegido pela
sincronizacao diferencial, que compara o valor de origem com **o que nos escrevemos
por ultimo no objeto** — nao com o que esta na caixa. Isso nao mudou.

O caso residual era o valor de origem **mudar de verdade** no meio da digitacao:
carga de perfil, restauracao. A decisao: **o valor do EA vence e o texto digitado e
descartado, com aviso na tela.** Carregar um perfil e um clique deliberado; manter
na tela o que foi digitado antes dele contradiria a acao que o usuario acabou de
pedir. E o aviso existe porque descartar em silencio faria o valor sumir sem
explicacao — a licao nº 1 da secao 8, na pratica.

O mecanismo ja existia na fronteira e estava sendo desperdicado: **`LoadSettings` e o
caminho de recarga**, distinto do `Update`. Ate a 2b ele era um apelido de `Update`;
agora e ele que solta o foco do campo, devolve o rascunho ao comprometido e escreve o
aviso. `Update` continua sendo a atualizacao periodica, que nunca sobrescreve
edicao pendente.

### Divida ACEITA, nao resolvida: `ApplySettings` nao e transacional

⚠️ **`false` de `ApplySettings` nao significa "nada aconteceu".** Ela atribui
`m_settings`, reconfigura o resolvedor, reinicia o logger, recarrega o servico de
execucao e o gerente de protecao — e **so entao** devolve o resultado do
`ReloadAll` dos sinais. Um indicador que nao consiga recriar seus handles a faz
responder `false` com a sessao ja alterada.

Todos os chamadores tratam esse `false` como "nao aplicado" e voltam sem tocar no
painel (`if(!ApplySettings(...)) return;`). Salvar, criar e restaurar dependem
dessa premissa — e sao exatamente os fluxos que a Fase 3 poe em producao.

**O que foi feito:** o painel parou de deduzir do sinal. No caminho de recusa ele
tambem **pergunta ao disco** (`SaveLandedOnDisk`), como ja fazia no caminho de
sucesso, e ajusta `m_notSaved`, o perfil desatualizado e o estado de criacao
falhada a partir do que o arquivo REALMENTE tem. O aviso e o estado ficam certos
independentemente do caminho que o EA tomou.

**O que NAO foi feito:** tornar `ApplySettings` transacional, ou fazer com que ela
distinga "nao aplicado" de "aplicado parcialmente". Isso e cirurgia no caminho por
onde passa toda ativacao de configuracao do EA — incluindo o boot e a 1.058 — para
um modo de falha que a GUI ja consegue relatar corretamente. **Item proprio, fora
desta migracao.**

### Divida ACEITA, nao resolvida: corrida de unicidade entre graficos

⚠️ **Nada nesta secao esta consertado.** Fica registrado para que ninguem leia a
2c/2d como se ela garantisse unicidade — ela nao garante, e a 1.058 tambem nao.

**Nome e Magic sao conferidos fora de secao critica.** O painel confere, emite o
comando, e a gravacao acontece depois — com `FILE_REWRITE`. Dois graficos rodam
concorrentemente e podem passar pela mesma conferencia.

Isso vale **tambem para o Magic**, e a distincao e so de tamanho de janela: o EA
reconfere a unicidade dele em `CanPersistProfile`, dentro do proprio
`HandleUICommand`, a poucas instrucoes da escrita. Isso **estreita** a janela; nao
a fecha. Descrever como "coberto" seria falso.

A conferencia de gravacao (`AnnounceSaveOutcome`) **nao serve de rede** aqui: um
grafico pode conferir o proprio arquivo, encontrar tudo certo, e ser sobrescrito um
instante depois. Ela reduz o caso silencioso, nao o elimina.

Fechar de verdade exige trava + reconferencia + escrita como **uma secao critica**,
e exige distinguir "criar" de "salvar existente" — hoje as duas coisas sao o mesmo
`UI_COMMAND_SAVE_PROFILE`. Isso e `Persistence` e vocabulario de comando: **codigo
de producao compartilhado com o painel 1.058**, que tem exatamente a mesma corrida.
Consertar de dentro da migracao da GUI seria mexer no EA em servico para resolver
um defeito que nao e da GUI, e que ja existia antes dela — mesma decisao tomada
para o "perfil fantasma" (nome de arquivo com espaco). **Item proprio, fora desta
migracao.**

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
- **Aviso cresce com o texto, mas nao encolhe abaixo de duas linhas.** O painel da
  1.058 tem tres `CLabel` fixos e corta em 174 caracteres; no canvas a caixa e
  dimensionada pelo texto medido. O que incomodava era ela ENCOLHER: a area util
  mudava de tamanho entre um aviso de uma linha e outro de duas, e o conteudo
  pulava de lugar sem o usuario ter feito nada. Com o piso em duas linhas e o
  texto centrado nelas, o caso comum tem altura constante — e as mensagens sao
  escritas para caber nesse espaco, em vez de a caixa se render a elas. Quando um
  motivo vem pronto do EA, ele **substitui** o texto do painel em vez de ser
  prefixado por ele: dizer a mesma coisa duas vezes era o que empurrava o aviso
  para a terceira linha.
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
   tres vezes: um bloqueio que desabilitava a aba que a propria mensagem mandava
   abrir, um aviso pedindo `SALVAR` que estava desabilitado, e — na 2d — a
   validacao acusando "Magic ja usado" com o campo Magic **fora de alcance**,
   porque o perfil ativo nao estava na lista e so o ativo SELECIONADO tinha o
   campo ligado ao rascunho. Acontece de verdade: arquivo do perfil ativo apagado
   por fora, ou entre os que nao abrem. Hoje, ativo fora da lista ganha cartao
   proprio com o Magic editavel — a saida existe pela propria GUI.
2. **Todo bloqueio precisa de saida pela propria GUI.**
3. **Medir a mensagem contra o espaco disponivel** antes de escreve-la. A faixa de
   abas conferia isso desde a Fase 1; os **botoes nao**, e o primeiro rotulo a
   estourar a caixa ("CONFIRMAR", na coluna de 124 px de Perfis) so foi descoberto
   por captura de tela. Hoje `PutButton` mede e avisa no log — uma vez por sessao,
   porque o desenho roda 5x por segundo.
4. **Conferir o binario deployado** antes de interpretar um teste. Um `.ex5`
   desatualizado ja invalidou uma rodada inteira.
5. **Correlacao nao e causa.** Uma troca de perfil foi atribuida a uma troca de
   conta com base em coincidencia temporal; o teste do usuario desmentiu. A causa
   real era um carregamento manual que nao era registrado em log.
6. **Dado inventado nao pode contradizer dado real.** O harness inventa tudo menos
   a lista de perfis, que vem do disco. O perfil ativo dele era um `BTCUSD` fixo
   com o Magic padrao `10001` — e maquinas com um `default` de Magic 10001 viam a
   aba Perfis acender e o SALVAR apagar, **corretamente**: gravar aquele nome com
   aquele numero colidiria mesmo. Apagar perfis duplicados nao resolvia, porque o
   dono do numero era o `default`. Pareceu defeito do painel por duas rodadas.
   Agora o perfil ativo do harness sai do primeiro perfil real do disco.

---

## 9. Compilacao

A partir do MetaEditor `5.0.0.6061`, `#resource` exige que o arquivo resolva dentro
da arvore `MQL5`. Com o projeto fora dela, usar `build-linked.ps1` (ver
`README.md`).

⚠️ **A partir do `5.0.0.6090`, NAO passar `/inc` ao MetaEditor.** Com ele, a
compilacao quebra em dois lugares, ambos dentro de arquivos da propria MetaQuotes —
o que faz o defeito parecer do ambiente e nao da linha de comando:

- `Include\Canvas\Canvas.mqh` acusa 6 erros dentro do proprio arquivo (`cannot
  convert parameter 'int' to 'uint&'`, `wrong parameters count` em `TextOut`, com o
  aviso *"due to new rules of method hiding"*)
- todo `#resource` e recusado com `invalid resource path`, inclusive os `res\*.bmp`
  que `Include\Controls` declara e que existem em disco

Sem `/inc` os mesmos arquivos compilam 0/0 — isolado com dois `.mq5` de tres linhas,
e reproduzido em arvore limpa para descartar o projeto como causa. Sem `/inc` o
compilador deduz a raiz da localizacao do fonte, que e o que o `build-linked.ps1` ja
garante. Segunda condicao: a raiz precisa ser **a do proprio MetaEditor**, porque e
contra a pasta de dados dele que os `#resource` iniciados por `\` resolvem;
`build-paths.ps1` faz esse pareamento por `origin.txt`.

O gate continua sendo **0 errors, 0 warnings** nos alvos — **cinco**
desde a Fase 1: os tres indicadores, o `Fusion.mq5` e o harness
`Prototype/FusionCanvasPhase1.mq5`, que compila os modulos de `UI/Canvas/` e
por isso entra no gate. O harness sai quando a Fase 4 remover o painel antigo.

O deploy e manual: copiar o `.ex5` para `<terminal>\MQL5\Experts\`.

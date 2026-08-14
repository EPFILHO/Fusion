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

⚠️ **Esta decisao vale para a gravacao FALHADA (`m_notSaved`) e NAO para o arquivo
AUSENTE (`activeProfileFileMissing`), que ganhou trava propria no aceite da Fase 3
— ver abaixo.** A distincao e o que separa a protecao do beco: `m_notSaved` so
existe depois de um SALVAR tentado e recusado, entao ele **e a prova de que o
SALVAR nao resolve**. O arquivo ausente nao diz nada sobre a gravacao funcionar.

A cadeia de erro (trilho -> subaba -> aba) so agora tem dado real do outro lado, e as
faixas de nivel 2 de **Estrategias e Filtros** passaram a marcar erro: ate a 2b so a
de Gestao marcava, e o vermelho parava no meio do caminho — a aba de cima acendia
sem que nenhuma subaba dissesse onde.

⚠️ `HasDuplicateMagic()` acende a aba Perfis mas **nao** entra em `configInputsValid`.
Sao perguntas diferentes: ele responde "ha Magic repetido em algum lugar do disco", e
dois perfis parados que colidem entre si nao atrapalham esta conta. Dentro do
predicado, ele passaria a impedir INICIAR e SALVAR por causa de arquivos que este
grafico nao usa. Quem cuida do caso que importa e a escada de
`ResolveHeaderActionState()` (Fase 3), com `ActiveMagicConflicts()` — e la o
motivo vira texto na faixa do cabecalho. Antes disso a funcao chamava-se
`AccCanStart()`; ela foi removida quando a escada virou a fonte unica.

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

### Divida ACEITA: criar perfil sempre ATIVA — e perfil nao tem ativo

⚠️ Nada nesta secao esta consertado, e ela e a unica das dividas registradas que
nasce de uma **decisao de produto**, nao de um defeito.

**Criar perfil = gravar + aplicar + ativar.** O `UI_COMMAND_SAVE_PROFILE` chama
`ApplySettings` antes do `SaveProfile` e depois troca o `m_activeProfileName`. Do
ponto de vista do EA nao existe "guarde uma copia": existe "adote esta
configuracao agora, sob este nome". A 1.058 faz igual — mesmo comando, mesma
ativacao.

**A consequencia aparece ao duplicar perfil de outro ativo.** Um lote de `0.40` e
legitimo no ouro e nao existe num indice cujo minimo e 1 contrato, entao
`configInputsValid` reprova e o CRIAR COPIA fica apagado. A recusa esta CERTA
dado o que criar significa: seria ativar um lote que a corretora rejeita. Mas o
usuario pediu uma copia, nao pediu para operar com ela — e a semantica de
duplicacao e de **biblioteca**.

Por tras ha uma tensao maior, anterior a esta migracao: **os perfis sao guardados
sem ativo, e so fazem sentido com um.** A lista oferece todos os perfis, de
qualquer grafico, com todas as acoes habilitadas. A trava do lote e so o primeiro
lugar em que isso encosta na tela.

**A forma da correcao**, para quando for a hora: um comando que grave SEM aplicar
— aditivo, como o `RESTORE_ACTIVE_PROFILE` —, e a divisao de `ConfigInputsValid`
em duas perguntas hoje misturadas: a **intrinseca** (faixas, regras cruzadas, vale
em qualquer ativo) e a **do grafico** (lote contra `volumeMin`/`volumeStep`,
distancias contra o `stopsLevel`, plano de TP parcial). So a segunda deveria pesar
sobre um perfil que esta sendo escrito para a biblioteca. O trabalho real nao e o
comando: e essa divisao.

**Por que nao agora:** a Fase 3 existe para os dois paineis conviverem
**comparaveis no mesmo grafico**. Mudar a semantica de criar so na 2.0 os torna
incomparaveis exatamente no fluxo em teste — e a comparacao e o que da confianca
para aposentar o painel antigo. Depois dela, a mudanca pode ser avaliada de uma
vez para os dois, que e onde ela pertence.

Enquanto isso, a tela **explica a cadeia** em vez de so acusar: a nota do
formulario diz que criar tambem ativa neste grafico, por isso a configuracao
precisa ser valida para o simbolo dele, e aponta a aba a corrigir.

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

⚠️ **Mas na CRIACAO o disco sozinho nao distingue nada.** O arquivo do perfil novo
nao existe tanto quando a escrita falhou quanto quando o EA recusou o comando
ANTES de aplicar — reconciliacao de fechamento pendente, ou nome/Magic tomado na
corrida. Tratar os dois como falha de escrita prendia o usuario num rollback
desnecessario; e, se a causa era a reconciliacao, ela recusa **tambem** o
rollback — um beco construido sobre um diagnostico errado.

Quem distingue e a **configuracao**: nao tendo o EA chegado a aplicar, o snapshot
ainda e o de antes da tentativa (`m_preCreateSettings`). A comparacao e confiavel
porque toda criacao carrega um Magic livre, logo diferente do que valia. Recusa
antes de aplicar encerra a transacao sem inventar divida nenhuma e deixa o
formulario aberto como uma tentativa comum.

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

### RESOLVIDA no motor: `LOAD_PROFILE` recusa com posicao aberta

Achada no aceite da Fase 3, e e a unica desta serie com consequencia de dinheiro.

**Antes da correcao**, `UI_COMMAND_LOAD_PROFILE` (`EAApplicationCommands.mqh`)
recusava por reconciliacao pendente, arquivo ilegivel, drawdown ativo e as duas
travas de concorrencia — e **nao havia guarda para posicao aberta**. Carregar
aplica `ApplySettings`, que troca a configuracao ativa inteira: nao mexe no
volume da posicao ja aberta, mas troca o **Magic** — e e por ele que o EA
reconhece as proprias ordens —, alem de protecoes, filtros e o lote das entradas
futuras, com uma operacao em curso.

Isso nunca aparecia porque o painel nao oferecia o botao... **exceto num caso.**
A permissao de carga tem uma excecao deliberada: com o perfil preso por outro
grafico, CARREGAR continua liberado, porque escolher outro perfil e a saida do
bloqueio. So que a excecao era avaliada ANTES da trava local:

```
if(hasPeerProfileLock) profileLoadAllowed = true;      // 1.058, UIPanelAccessState:97
else if(!hasLocalPositionLock) ...
```

Com posicao aberta **e** peer lock, CARREGAR acendia e o clique chegava ao motor.

**Corrigido na 2.0, no painel:** `AccCanLoadProfile` faz `started || hasPosition`
vencer antes da excecao. A excecao continua existindo — ela so deixa de valer
quando ha trava local, onde nao ha saida a oferecer e sim uma operacao a
proteger. **Divergencia deliberada da 1.058, no sentido seguro:** a 2.0 recusa
algo que a 1.058 permite.

**E o motor ganhou a guarda, no mesmo aceite.** Foi a unica divida tratada fora
da ordem que o plano previa, e por um criterio so: **contencao na interface nao e
correcao.** O painel 2.0 fechou o furo do lado dele, mas a autoridade e o motor —
sem a guarda, a 1.058 continuaria emitindo o comando na combinacao problematica,
e qualquer caminho futuro ate `UI_COMMAND_LOAD_PROFILE` nasceria desprotegido.

```
if(m_positionState.hasPosition)
  {
   m_logger.Warn("PROFILE", "Perfil nao carregado enquanto existe posicao em gerenciamento.");
   return;
  }
```

**Estreita de proposito.** Ficou no ramo do comando, e **nao** dentro de
`ApplySettings`: aquela funcao serve tambem a restauracao e ao boot, contextos
com semantica propria — recusar por posicao aberta ali quebraria o desfazer de
uma criacao que falhou ao gravar, que e justamente um mecanismo de seguranca.
Conferido que `UI_COMMAND_RESTORE_ACTIVE_PROFILE` tem ramo proprio e que o boot
usa `TryLoadProfileFromDisk`, ambos fora deste caminho.

> ⚠️ **E a guarda le estado FRESCO, nao cache.** `m_positionState` so e
> atualizado no `SyncPositionState()` do proximo `OnTick`/`OnTimer`: o
> `OnTradeTransaction` apenas chama `MarkNeedsSync()`. Entre a posicao aparecer e
> esse proximo passo havia uma janela em que a guarda leria `false` com posicao
> viva — e numa fronteira que protege dinheiro nao se depende de o cache ja ter
> sido atualizado. O comando sincroniza antes das duas guardas, e **antes da de
> reconciliacao**, porque essa mesma sincronizacao pode descobrir que uma posicao
> acabou de fechar e iniciar a reconciliacao naquele instante.
>
> So com o runtime livre, como os dois outros chamadores: bloqueado por troca de
> ativo do grafico, sincronizar leria posicoes do simbolo **errado**. Custa uma
> varredura por clique em CARREGAR — nao por quadro nem por tick.

**A 1.058 nao foi alterada**, e nao precisa ser: com a guarda no motor, o botao
que ela ainda acende indevidamente fica inerte e registra o motivo no log. A
incoerencia visual dela sobrevive documentada ate a Fase 4 remove-la.

### A 1.058 nao ficou literalmente congelada: dois textos do motor mudaram

Decisao consciente, tomada com o usuario durante o aceite da Fase 3 e registrada
aqui porque contraria a expectativa razoavel de que o painel antigo nao muda.
**Sao apenas textos**, os dois em codigo compartilhado, e os dois aparecem
tambem na 1.058:

1. **`TradePermissionGuard::FormatNotice`** — saiu o prefixo "Trading
   temporariamente indisponivel: " da forma sem posicao aberta. Era a unica das
   seis formas que estourava a faixa de uma linha do cabecalho da 2.0, e o corte
   com reticencias caia justamente antes de "Aguardando MT5/corretora liberar".
   O prefixo tambem ficou redundante na 2.0: o distintivo ja diz IMPEDIDO e o
   titulo do Status ja diz TRADING INDISPONIVEL.
2. **`CInstanceRegistry::HasActiveConflict`** — "em uso por outro Fusion
   **ativo**" virou "em outro Fusion **em execucao**". A palavra "ativo"
   significava duas coisas na mesma tela: o selo ATIVO marca o perfil que ESTE
   grafico usa, e o aviso falava de instancia rodando noutro grafico. Os dois
   apareciam juntos e liam-se como contradicao. "Em execucao" tambem descreve
   melhor o que `HasLivePeer` confere — registro com batida recente, dentro do
   TTL.

**O que foi conferido antes de mudar, nos dois casos:** nenhum codigo casa
contra esses literais. A classificacao do guard (`IsConnectionReason`,
`IsAccountPermissionReason`) compara o `reason`, nao o texto formatado; e
`startBlockedReason` so e atribuido, testado por vazio (`AccPeerLock`) e
comparado consigo mesmo para detectar mudanca.

**A regra que continua valendo:** o que nao se toca na 1.058 e **comportamento**.
Texto que a 2.0 precisa exibir corretamente pode ser ajustado, desde que
nenhuma logica dependa da frase — e essa verificacao e obrigatoria, nao
opcional, porque o guard ja classifica por comparacao de string internamente.

### Divida REGISTRADA no aceite da Fase 3: campo aceso com a chave desligada

Levantada pelo usuario testando o `FusionCanvas.ex5`. **Nada foi alterado** — o
que segue e a analise pronta para quando for a hora.

**O estado atual.** As regras de "parametro dependente" foram extraidas uma a uma
da 1.058 (`CanvasRendererFields.mqh`, secao "Gestao: quem apaga com o que"), e o
padrao **nao e uniforme**: em Risco e no filtro de Tendencia a chave APAGA os
parametros; em Sessao, Noticias, Limites Diarios, Drawdown, filtros RSI/BB e
Estrategias, nao apaga. O principio anotado na epoca era "parametro so apaga
quando o EA o ignora por causa de OUTRA escolha, e nao quando o pai esta
desligado — configurar antes de ligar e uso legitimo".

**Por que o principio e mais fraco do que parecia.** Nada no painel vale enquanto
o SALVAR nao acontece: o EA le o comprometido, nao o rascunho. Entao o risco nao
e ativar algo sem querer — e mais discreto e pior. Com a chave OFF e o campo
aceso, o usuario edita, **grava**, e fica com um numero em disco que o EA ignora,
achando que configurou uma protecao que continua desligada. O painel deixou
registrar uma intencao que nao vai valer.

Contra isso, "pre-configurar sem ativar" custa dois cliques a mais no outro
modelo (liga, edita, desliga) e e caso raro. **Decisao do usuario: uniformizar
para "chave OFF apaga os parametros"**, ganhando o invariante forte — *aceso =
participa do que o EA vai fazer*.

> ⚠️ **A armadilha, e ela dobra o trabalho.** A validacao **quase nao olha as
> chaves**: em todo o `CanvasRendererValidate.mqh` so ha dois pontos
> condicionados (a inclinacao do BB e a janela de sessao). `ScreenErrorRSIFilter`,
> por exemplo, cobra periodo e ordem dos niveis sem perguntar se o filtro esta
> ligado.
>
> Apagar o campo sem condicionar a validacao produz **aba vermelha, faixa
> mandando corrigir, e o campo a corrigir cinza** — a licao 1 da secao 8 pela
> quinta vez, desta vez desenhada de proposito. **Cada campo apagado exige duas
> linhas, nao uma**, e as duas tem de concordar para sempre. E o motivo de isto
> ser "item a item" e nao uma regra geral.
>
> Agravante: perfis sao compartilhados com a 1.058. Um campo apagado na 2.0 com
> validacao ainda disparando cria perfil que so se conserta no painel antigo.

**Inventario** (secao / campos / estado da validacao hoje):

| Secao | Campos | Validacao |
|---|---|---|
| Sessao | 2 horarios (4 campos) + Fechar no fim | **ja condicionada** |
| Noticias | 3 janelas x (2 horarios + acao) | nao |
| Limites Diarios | Max Trades, Max Perda, Max Ganho | nao |
| Drawdown | Max DD, Tipo, Base | nao |
| Filtro RSI | periodo, niveis, modo | nao |
| Filtro BB | periodo, desvio, largura | parcial (so a inclinacao) |
| Estrategias | parametros de MA, RSI, BB | nao |

**Fora do escopo, e por motivos diferentes:** Risco e filtro de Tendencia ja
apagam (e a 1.058 tambem — conferido em `TrendFilterPanel.mqh:173,181`); **Max
Spread** ja apaga o limite com a chave OFF (`SpreadLimitEditable()`), servindo de
precedente dentro da propria Protecao; e o **TP parcial** fica como esta, porque
"TP2 exige TP1" e dependencia de verdade, nao pai desligado.

**Decisao propria pendente:** a **Prioridade** da estrategia. Ela e do bloco da
estrategia, mas o modo Cancelar usa a prioridade para eleger a dona da posicao —
conferir esse caminho antes de decidir se apaga junto.

**Por que nao agora:** muda comportamento em quase todas as telas de
configuracao e diverge da 1.058 justamente onde os dois paineis estao sendo
comparados. O aceite em curso deve comparar igual com igual, e uma mudanca que
mexe em validacao de protecao merece a propria passada de teste — nao pegar
carona no meio de outras dez.

**Fase 3 — Troca por interruptor. FEITA** (fiacao; o aceite em execucao e do
usuario, ver `docs/GUI_2000_FASE3_TESTES.md`). Os dois paineis convivem,
comparaveis lado a lado, com reversao imediata.

> **Correcao (Fase 1).** A promessa original — "o EA nao muda uma linha" — estava
> errada. `m_panel` e um `CFusionPanel` concreto em `Core/EAApplication.mqh`, e
> escolher o painel em tempo de execucao exige uma indirecao que nao existe.
> **Decidido: troca em tempo de compilacao.** Um `#define` escolhe qual classe o
> membro `m_panel` tem. O fonte do EA realmente nao muda, o custo em codigo e
> nulo e nao existe indirecao para manter depois que a Fase 4 remover o painel
> antigo. O preco e nao poder alternar sem recompilar — aceitavel, porque quem
> compara os dois durante a transicao e quem desenvolve, e recompilar leva
> segundos com o `build-linked.ps1`.

**Como ficou.** `FUSION_USE_CANVAS_PANEL`, ausente por padrao, decide em
`Core/EAApplication.mqh` a classe de `m_panel` e o `#include` correspondente.
**O padrao e o painel ANTIGO**: reverter e compilar o alvo de sempre, sem editar
arquivo nenhum.

**Dois `.ex5`, e nao um.** Com um unico alvo, "comparaveis" viraria sequencial —
editar, recompilar, recarregar —, e a comparacao e justamente o que da confianca
para aposentar o painel antigo. `FusionCanvas.mq5` e um arquivo de 40 linhas sem
logica propria: `#property`, `#resource`, o `#define` e o include. Os dois alvos
rodam em graficos diferentes ao mesmo tempo, e trocar de volta e trocar o EA do
grafico.

Para que os dois `.mq5` nao carregassem duas copias dos handlers do terminal, o
corpo saiu para **`Core/EAEntryPoints.mqh`**. Duplicar `OnInit`/`OnTick`/... teria
um modo de falha silencioso: um handler acrescentado a um e esquecido no outro
compila `0/0` e simplesmente nao roda.

**O EA passou a dizer qual painel construiu** (`m_logger.Info("UI", "Painel: ...")`,
uma linha por inicializacao). E a licao 4 da secao 8 — "conferir o binario
deployado antes de interpretar um teste" — que com dois `.ex5` do mesmo EA passou
a valer em dobro: alem do `.ex5` velho, agora existe a chance de testar o outro
sem perceber.

**Os objetos do canvas ganharam namespace tecnico proprio: `Fusion2.Canvas.`.**
Antes eles nasciam do `name` que o EA passa — "EP Fusion" —, e a limpeza apaga
**por prefixo**: `ObjectsDeleteAll(chart,"EP Fusion")` alcancava qualquer objeto
do grafico comecando assim, **inclusive uma anotacao do usuario**. Improvavel, e
irreversivel; foi tratado pelo impacto, nao pela frequencia. Com um namespace que
ninguem digitaria, o escopo da exclusao passa a ser auditavel por leitura.

> ⚠️ **A primeira versao desta limpeza prometia o que nao entregava.** O
> comentario afirmava que ela varria as sobras dos **dois** paineis, por
> compartilharem o nome de base. **E falso.** O painel classico nao usa o `name`
> como prefixo de objeto: `CAppDialog::Create` gera `m_instance_id` —
> `IntegerToString(rand(),5,'0')` — e cria a casca do dialogo sob esse prefixo
> **numerico**. O `name` vira so o texto do `Caption`. E a prova esta no proprio
> codigo da 1.058: `IsFusionDialogCaption` existe justamente para **descobrir**
> esse prefixo lendo o texto da legenda — funcao que nao faria sentido se o
> prefixo fosse conhecido.

**Simetria de verdade seria cara, e por isso ficou fora.** Extrair a limpeza por
`Caption` do painel classico varreria apenas a **casca** do dialogo: os controles
dele sao criados com **274 nomes fixos** proprios (`Fusion_cfg_*`,
`Fusion_Strategy_*`, `Fusion_tabs_sep`...), que nao estao sob o prefixo numerico.
Prometer simetria exigiria inventariar todos — e um inventario incompleto vira
uma limpeza ampla, que e exatamente o defeito que acabamos de remover. **Decisao:
o canvas limpa o canvas.** A simetria so entra se resistencia a *crash seguido de
troca imediata de painel* virar requisito explicito de aceite, com auditoria
propria dos namespaces do classico.

⚠️ **O que a limpeza cobre, dito sem promessa a mais:** a troca normal de painel
nao depende dela — remover o EA do grafico roda `Destroy()`, que ja limpa. Ela
cobre a saida que **nao** roda `Destroy()`: terminal encerrado de forma anormal
com o painel no ar. E cobre **so os objetos do canvas**; sobras cruzadas depois de
um crash nao estao garantidas em nenhuma das duas direcoes.

Junto foi uma limpeza de compatibilidade estreita — o objeto de nome exato
`EP Fusioncanvas` e o prefixo `EP Fusionedit_` —, para as sobras que builds
anteriores do canvas deixaram na maquina de desenvolvimento. Sai na Fase 4.

> **Pendencia da Fase 2 FECHADA sem codigo: paleta/tema/escala nao viram input.**
> A 2c registrou que faltava um caminho do EA ate o `CreatePanel`. Faltava — mas
> conferido o mecanismo, ele nao e necessario: os tres sao escolhidos na aba
> Layout e ficam em variavel global do terminal (`CanvasRendererPrefs.mqh`),
> valendo para todo grafico e sobrevivendo a fechar o MT5. Um input governaria
> **so a primeira abertura de todas** — a partir da segunda a preferencia salva
> vence, de proposito, por ser a ultima escolha consciente do usuario. Input que
> deixa de valer depois do primeiro uso engana mais do que ajuda. Petroleo e
> Automatico ficam sendo o padrao de fabrica.

### CORRIGIDO no aceite da Fase 3: perfil ativo sem arquivo nao segurava nada

Achado pelo usuario executando o bloco H, e o unico defeito da Fase 3 com **perda
de dados de verdade** — nao um susto, uma configuracao que sumiu.

Movido o `.cfg` do perfil ATIVO para fora da pasta, a configuracao em uso passa a
existir so na memoria. `activeProfileFileMissing` era lido em tres lugares — o
subtitulo do cabecalho, o cartao que explica, e o SALVAR — e **em nenhum
predicado de acesso**. Ou seja: o estado acendia a saida e nao segurava nenhuma
das portas que levam para longe dela. As quatro levam:

- **CARREGAR** troca o perfil ativo e a configuracao some;
- **NOVO** e **DUPLICAR** criam, e criar tambem ATIVA (a divida da secao 6),
  entao abandonam o perfil sem arquivo do mesmo jeito — a configuracao sobrevive
  sob outro nome, a identidade nao. Foi por aqui que o usuario perdeu o perfil:
  clicou NOVO e o `WIN` deixou de existir;
- **DUPLICAR** ainda acendia sobre um perfil cujo arquivo o painel **ja sabia**
  ilegivel, falhando depois do clique com uma caixa vermelha — licao 1.

**Corrigido:** `AccSaveFirstLock()` apaga as quatro ate o perfil ser gravado, e
`FCV_HBLK_NOFILE` poe o motivo na faixa. EXCLUIR entra por decisao do usuario
(*"não deixe o EXCLUIR vivo não"*): ele nao abandona nada, mas primeiro gravar e
depois apagar com o perfil fora de risco e a ordem certa, e quatro botoes
apagados leem melhor que tres e um aceso.

⚠️ **A trava so vale enquanto o SALVAR e uma saida plausivel**, e isso e metade da
correcao. Ela exige as mesmas condicoes que acendem o SALVAR, e **exclui
`m_notSaved`** — que e a prova de que gravar nao resolve. Sem essa exclusao a
protecao viraria o beco que a decisao da 2c ja tinha evitado (secao "Configuracao
aplicada e nao gravada nao se perde calada"), e teria quebrado o D2 do roteiro.
De brinde, a saida sai de graca: preso na trava, o usuario clica SALVAR; falhando,
`m_notSaved` liga e a trava levanta sozinha.

**A licao de processo:** eu ia trancar pelos dois estados por serem "o mesmo
estado com duas portas". Nao sao — um descreve o disco, o outro descreve uma
TENTATIVA. Foi reler a decisao ja registrada aqui, e nao raciocinar de novo, que
pegou isso.

**A quinta trava, achada pela auditoria.** Estar na escada apaga tambem o
**INICIAR** — todo ramo dela retorna com `s.enabled` ainda falso. Nao foi
intencional e nao estava documentado. Conferido, **esta certo, e por um motivo
diferente do das outras quatro**: INICIAR nao abandona o perfil, ele *fecha a
porta da recuperacao*. O SALVAR exige `AccActiveProfileEditable`, que exige
`!started` — iniciar com o arquivo ausente deixaria a unica copia da configuracao
presa na memoria, sem forma de grava-la, a um reinicio de sumir. Mantido de
proposito, com a faixa nomeando as duas coisas ("grave antes de **iniciar** ou
trocar de perfil"), porque ela e a unica explicacao que o INICIAR apagado tem.
Testado no H5.2b.

### CORRIGIDO: o buraco da trava — faixa avisa, confirmacao protege

Achado pelo usuario executando o H5.1. `AccSaveFirstLock()` exige
`ConfigInputsValid()`, entao com um perfil ativo **de outro ativo** (lote `0.40`
num indice de 1 contrato) a trava **nao engata** — e o perfil orfao fica sem
protecao nenhuma. A metade que impede o beco tinha um custo que eu nao tinha
medido.

**Primeiro, o que eu exagerei**, corrigido pela auditoria e conferido: `INICIAR`
continua apagado pelo ramo da configuracao invalida; abrir `NOVO` nao perde nada,
porque o CRIAR PERFIL de dentro dele exige a mesma configuracao valida; `EXCLUIR`
de outro perfil nao abandona o ativo. **Os caminhos que perdem sao dois**:
CARREGAR e **concluir** uma duplicacao — esta porque `BeginDuplicate` semeia o
rascunho com o perfil de ORIGEM, que pode valer neste grafico enquanto o ativo
nao vale.

**Faixa.** O estado saiu da trava e virou `ActiveProfileOrphan()`;
`AccSaveFirstLock()` passou a ser ele **mais** `ConfigInputsValid()`. A faixa usa
o estado e subiu para cima do CONFIG — antes ela calava exatamente no pior caso,
mostrando "CONFIGURACAO INVALIDA" e nao dizendo uma palavra sobre o perfil estar
a um clique de sumir.

⚠️ **Faixa e trava deixaram de ter a mesma condicao, de proposito**, contra o que
eu tinha escrito um dia antes. Onde a trava se cala por nao ter saida a oferecer,
o risco continua existindo, e calar junto o esconde. O texto muda com o gatilho,
entao a faixa nunca promete uma trava que nao existe. E ele **nao manda
"corrigir"**: a incompatibilidade pode ser so com este ativo, e corrigir
descaracterizaria um perfil que esta certo para o ativo dele.

**Confirmacao.** So a faixa deixava a perda a um clique — critica correta da
auditoria, especialmente depois de termos tratado o caso como protecao contra
perda de dados. Nem trancar (beco) nem deixar passar: `AbandonNeedsConfirm()` =
`ActiveProfileOrphan() && !ConfigInputsValid()`, com SIM/NAO no lugar do proprio
botao, na coreografia do EXCLUIR.

O estado guarda **operacao e alvo** (`m_abandonOp`, `m_abandonTarget`) e nao um
booleano: o SIM precisa saber o que executar, e o alvo e capturado no primeiro
clique — lido de novo no segundo, a pergunta nomearia um perfil e executaria
outro. Cai sozinha ao trocar de selecao, ao navegar, e quando o estado que a
justifica passa.

⚠️ **So nos dois caminhos que perdem.** NOVO, EXCLUIR e Atualizar lista nao pedem
confirmacao — e o H5.8.10 existe para garantir isso, porque confirmacao que
aparece onde nao precisa ensina a clicar SIM sem ler, e ai ela deixa de proteger
onde precisa.

**A primeira versao nasceu com a metade importante morta**, e a auditoria pegou:
a confirmacao da copia era **inalcancavel**. `AbandonNeedsConfirm` perguntava se o
perfil ativo podia ser gravado usando `ConfigInputsValid()`, que le o RASCUNHO — e
entrar no DUPLICAR troca o rascunho pela ORIGEM. Como o CRIAR COPIA so acende com
o rascunho valido e a confirmacao so existia com ele invalido, **as duas condicoes
nunca podiam ser verdadeiras juntas**. Eu escrevi, no comentario dela, a
explicacao correta de por que a copia acende — e logo abaixo um predicado que a
contradizia.

O conserto e semantico e nao um remendo: a pergunta e sobre o **comprometido**, a
configuracao que o EA esta usando, que `BeginDuplicate` nao toca.
`CommittedConfigValid()` responde por ele, com cache proprio e a troca de rascunho
feita e desfeita internamente, salvando o cache do outro. A resposta fica estavel
do primeiro clique ate a conclusao, que e o que uma confirmacao precisa.

Junto vieram dois consertos do mesmo contrato:

- **o payload e mesmo usado.** O SIM da criacao relia `ProfileFormRawName()` e
  `ProfileFormMagic()` em vez do que fora capturado — e os campos seguem
  editaveis. A pergunta podia nomear um perfil e a execucao gravar outro. Agora o
  Magic viaja junto do nome, e o segundo clique nao consulta mais nada;
- **o desarme olha a DISPONIBILIDADE**, e nao so o estado. Com a pergunta armada e
  a acao ficando indisponivel (peer lock, por exemplo), SIM/NAO sumiam da tela e
  `m_abandonOp` sobrevivia — voltando o acesso, a pergunta RESSUSCITAVA. Foi
  preciso extrair `AccCanLoadSelected()` e `AccCanCreateCopy()`, exatamente pela
  razao que ja fizera `AccCanDeleteSelected` existir: quem desarma precisa da
  mesma resposta de quem ofereceu. E entrar em qualquer campo derruba as duas
  confirmacoes, porque a digitacao limpa o aviso e deixaria os botoes sem a frase
  que os explica.

**RETRATACAO: o "terceiro caminho" que eu anunciei nao existe.** Eu disse que,
com o rascunho semeado pela duplicacao, o SALVAR do cabecalho gravaria a
configuracao da origem sob o nome do perfil ativo. Nao grava: `headerLive` exige
`FCV_PROF_VIEW`, e **todas** as tres saidas para VIEW chamam `ReloadDraft()`
antes — `GoTo`, `FCV_BTN_CANCEL` e `ReloadFromEA`. Mais do que isso: o comentario
do `GoTo` **descreve exatamente esse perigo** como algo ja fechado de proposito.
Eu reportei como aberto um buraco que o proprio codigo documentava como tapado —
parei de ler cedo demais, o mesmo erro do falso alarme do historico diario.

### CORRIGIDO junto: a coluna de perfis nao via a edicao em curso

Achado pelo usuario na mesma sessao. `EditingNow()` (cursor num campo) acendia
SALVAR e CANCELAR no cabecalho, e a coluna de perfis so olhava `HasPending()` —
entao NOVO e DUPLICAR continuavam acesos, sugerindo que criariam um perfil **com
o Magic recem-digitado**.

A decisao registrada em `EditingNow` dizia "vale so para esses dois botoes", e
nomeava o INICIAR como excecao. As acoes de perfil nunca tinham sido consideradas.

**O criterio correto nao e "acao real", e se a acao CONSOME a edicao em curso.**
As quatro consomem, por um caminho que nao e obvio: sair do campo por um clique
passa por `ReleaseEditFocus`, que **le antes de destruir** e chama `FieldSetText`.
O numero digitado vira pendencia do perfil ATIVO e so entao o botao age — o
usuario terminaria dentro do formulario de criacao com uma alteracao pendente que
nao quis, no perfil errado. O INICIAR fica de fora com a razao de sempre, e nao
precisa da trava: a pendencia que nasce ali ja o bloqueia pela escada.

Bloco H6 no roteiro, sendo o H6.5 o que protege a decisao antiga.

**A brecha de clique que veio junto, achada pela auditoria.** Apagar os quatro nao
bastava: o registro de caixas de clique vem do desenho, e o desenho acontece
DENTRO do mesmo evento. Sair do campo apaga `EditingNow`, o `HandlePress` repinta
para acender SALVAR e CANCELAR — repinte que existe de proposito, para o SALVAR
aceitar o clique unico depois da digitacao — e nesse repinte os quatro voltam a
publicar caixa. Clicar num NOVO **visivelmente apagado** o executava.

So no caso inocente: entrar no campo e sair sem mudar nada. Alterado o valor,
`HasPending()` os mantem apagados e nao ha caixa a acertar.

Corrigido com uma guarda no `HandleButtonClick` — o clique que apenas encerrou uma
edicao **consome-se** quando o alvo e um dos quatro. Nao vale para SALVAR e
CANCELAR nem para `Atualizar lista`, e a distincao e de contrato: aqueles dois SAO
as saidas da edicao, entao clicar neles ao sair e o gesto esperado; os quatro a
consomem por efeito colateral. Engolir todo clique depois do `ReleaseEditFocus`
devolveria o defeito que o repinte veio consertar. H6.4 e H6.4b.

### CORRIGIDO: a terceira obrigacao do Pulse nunca rodava em producao

Achado meu ao conferir o que eu tinha escrito no roteiro — e e a mesma armadilha da
correcao do `m_viewDirty`, que ja tinha me pegado uma vez: **`Pulse()` so e chamado
pelo harness** (`FusionCanvasPhase1.mq5`). O EA chama `Render()` direto.

Duas das tres obrigacoes do Pulse ja tinham sido movidas para o `Render` na epoca
daquela correcao — `TouchProfileLocks()` e o prazo do aviso. A terceira ficou:
`if(m_delConfirm && !AccCanDeleteSelected()) CancelDeleteConfirm()`. Em producao a
confirmacao de exclusao **nunca** era desarmada por perda de acesso.

O efeito nao aparece na hora, e por isso passou: o SIM some junto com o botao (o
`armed` do desenho exige os dois) e **ressuscita** quando o acesso volta — uma
pergunta vermelha feita ha muito tempo, reaparecendo sozinha. Movida para o
`Render`, ao lado das outras duas.

⚠️ E o motivo de eu ter achado: escrevi H5.6 e H6.4c afirmando que a confirmacao se
desarma sozinha. Fui conferir se era verdade antes de deixar o passo no roteiro.

### CORRIGIDO junto: duas instrucoes para botoes apagados

Do mesmo teste, e a mesma licao 1 em dois lugares que ninguem tinha olhado:

- o cartao PERFIL SELECIONADO dizia *"Use CARREGAR para ativar o selecionado"*
  com o CARREGAR apagado — e o usuario chega ali **justamente** porque quer mexer
  no Magic de outro perfil. Agora `LoadBlockedWhy()` responde por que, lendo a
  MESMA composicao que apaga o botao, na mesma ordem: nota com ordem propria
  manda consertar o que nao e o impedimento;
- a lista vazia dizia *"Use NOVO para criar o primeiro"*, e com a trava nova o
  NOVO fica apagado. E o caso quase certo: pasta vazia com perfil ativo significa,
  por definicao, que o arquivo dele nao esta la.

### Divergencia DELIBERADA do motor, registrada: CARREGAR com pendencia

O passo H1 do roteiro mandava carregar outro perfil com alteracoes pendentes e
esperar que "o EA vence, com aviso". **O painel nao deixa chegar la**:
`AccCanLoadProfile` termina em `!HasPending()`. O passo descrevia o MOTOR, onde a
politica e verdadeira, e nunca tinha sido executado.

A politica do motor continua existindo e **e alcancavel sob peer lock** — ali
`AccCanLoadProfile` devolve `true` antes de olhar a pendencia, porque carregar
outro perfil e a saida daquele bloqueio. Fora dele o painel e mais rigido que o
EA de proposito: descartar digitacao por um clique noutro perfil e o tipo de
perda silenciosa que a 2.0 veio apertar. Roteiro corrigido (H1 e H1b).

### Divida REGISTRADA no aceite da Fase 3: "o motivo esta no log"

Levantada pelo usuario executando o bloco H. **Nada foi alterado** — decisao
consciente de adiar, com o porque escrito abaixo.

**O sintoma.** Perfil ativo sem arquivo, SALVAR recusado, e a caixa diz
*"O EA nao concluiu a gravacao do perfil WIN. O motivo esta no log."* O motivo
real era Magic ja usado por outro perfil — e o motor tinha a frase pronta, com o
nome do culpado: `CanPersistProfile` monta
`"Magic <n> ja esta em uso pelo perfil <X>."` e a manda para o log
(`EAApplicationInstanceGuard.mqh`). Sao tres avisos do painel com esse final.

**A causa nao e a mensagem, e a fronteira.** O `SUIPanelSnapshot` tem cerca de
quinze campos `*Reason`, e **todos descrevem ESTADO** — nenhum descreve resultado
de comando. O painel detecta a recusa por AUSENCIA (eco pendente que a recarga
nunca respondeu), entao ele realmente nao sabe por que. A mensagem e a descricao
honesta do que ele tem; o que falta e a faixa de rodagem.

**O conserto, quando for a hora — nesta ordem:**

1. **Campo de resultado no snapshot** (o conserto de verdade). ⚠️ O risco nao e
   escrever o campo: e uma das 13 recusas de PROFILE esquecer de preenche-lo e a
   explicacao da falha ANTERIOR ficar colada na nova — mensagem confiante e
   errada, pior que "esta no log". Por isso a disciplina tem de ser **limpar na
   entrada do comando**, e nunca confiar em quem recusa.
2. **Reler a lista quando `activeProfileFileMissing` liga** (complemento). Foi o
   que deixou este caso chegar ao clique: a lista mostrava `WIN` com o arquivo ja
   renomeado, entao o Magic 2026 parecia ser do proprio perfil ativo e
   `VMagicTakenByOther` o ignorava, por regra correta. `RefreshProfiles()` so roda
   ao trocar de perfil ativo ou no botao manual.

⚠️ **O item 2 NAO substitui o 1.** O painel nunca preve todas: arquivo ilegivel
nao tem Magic conferivel (ja documentado no cartao), e outro grafico pode criar o
conflito entre a leitura e o clique — a divida "corrida de unicidade" acima. O
motor e a autoridade porque rele o disco na hora, e sempre podera recusar por algo
que o painel nao tinha como saber.

**Por que adiar foi a decisao certa.** O que esta errado e a QUALIDADE DA
MENSAGEM, nao a seguranca: o painel nao mente, nao perde dado e nao instrui o
impossivel — anuncia a falha, marca o perfil como nao gravado, mantem o SALVAR
aceso para a retentativa e a configuracao segue valendo. Categoria diferente do
defeito corrigido no mesmo dia, que apagava um perfil para sempre. E o conserto
espalhado por 13 pontos, no meio de um aceite com o resto do codigo congelado, e
o cenario classico de o item 1 entrar pela metade.

**O gatilho para promover:** o D2 e o E4–E7 caem nestes caminhos. Se durante eles
nao der para correlacionar a linha do log com o clique que a causou, a divida
deixa de ser conforto e passa a atrapalhar o proprio diagnostico — e sobe de
prioridade.

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
- **Regra que liga duas telas pinta AS DUAS.** A cadeia acima e vertical e
  pressupoe que todo erro tem um dono; algumas regras nao tem — ligam telas irmas
  e se resolvem em qualquer uma delas. Acusando so uma, o vermelho nao chega onde
  se corrige: ligar o TP Final Livre acendia apenas TP Parcial enquanto o que
  faltava era ativar o Trailing, numa tela que continuava limpa. As duas telas
  consultam o mesmo predicado — nao precisou de mecanismo novo, o `RailHasError`
  so pergunta `ScreenError(tela)` —, e **o texto e de cada tela**, nomeando a
  outra. Sem isso o usuario chega na segunda, nao ve nada errado nos campos dela e
  fica pior do que antes.
- **A mensagem cita o que FALTA, nunca a lista de requisitos.** "TP Final Livre
  exige TP1 e Trailing ativos" com o TP1 ja ativo manda conferir o que esta certo —
  e e a mesma familia do botao apagado sem explicacao: a tela mandando corrigir o
  que nao precisa de correcao.
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

1. **Nao escrever mensagem que instrui acao que a interface impede.** Ja aconteceu
   **quatro** vezes, e nenhuma delas era descuido de texto — em todas o texto
   descrevia a intencao e o codigo tinha outra regra:
   - um bloqueio que desabilitava a aba que a propria mensagem mandava abrir;
   - um aviso pedindo `SALVAR` que estava desabilitado;
   - a validacao acusando "Magic ja usado" com o campo Magic **fora de alcance**,
     porque o perfil ativo nao estava na lista e so o ativo SELECIONADO tinha o
     campo ligado ao rascunho (arquivo apagado por fora, ou entre os que nao
     abrem). Hoje, ativo fora da lista ganha cartao proprio com o Magic editavel;
   - o formulario de criar dizendo "clique CRIAR COPIA" com o CRIAR COPIA
     apagado, porque `configInputsValid` — que pesa ali tanto quanto no SALVAR —
     e reprovado por uma tela que o usuario nao esta vendo. Acontece sem nada de
     errado: duplicar perfil de outro ativo. Um lote de `0.40`, legitimo no ouro,
     nao existe num indice cujo minimo e 1 contrato, e criar o perfil aqui
     tambem o ATIVA neste grafico. Hoje a nota do formulario diz o motivo e **em
     que aba** corrigi-lo.

   O padrao que emerge: **botao apagado precisa dizer por que**, e "a aba ficou
   vermelha" nao conta quando o usuario esta em outra aba.
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

O gate continua sendo **0 errors, 0 warnings** nos alvos — **seis** desde a
Fase 3: os tres indicadores, o harness `Prototype/FusionCanvasPhase1.mq5` (que
compila os modulos de `UI/Canvas/` e por isso entra no gate) e os **dois**
executaveis do EA, `Fusion.mq5` e `FusionCanvas.mq5`.

Os dois alvos do EA estao no gate porque o `#define` que os separa troca uma
**classe inteira**: um erro que so aparece do lado do canvas nao apareceria
compilando apenas o `Fusion.mq5`, e e exatamente esse o lado em avaliacao. A
ordem tambem e deliberada — o alvo de producao vem primeiro, entao uma falha do
experimental deixa o `Fusion.ex5` ja gravado e valido.

O harness e o `FusionCanvas.mq5` saem quando a Fase 4 remover o painel antigo:
naquele ponto o `Fusion.mq5` volta a ser o unico EA, ja com o painel novo.

⚠️ **Prova de que o interruptor faz o que diz.** Compilar `0/0` mostra que as
duas classes tem a mesma fronteira, nao que a escolha teve efeito — e o `.ex5` e
comprimido, entao procurar uma string dentro dele nao responde. O metodo que
responde: **compilar o mesmo fonte com e sem o `#define`** e comparar os
tamanhos. O alvo com o interruptor sai cerca de **230 KB menor** — a biblioteca
`Controls` e as 14 mil linhas do painel antigo, que so entram num dos dois —, e o
alvo **sem** ele sai do tamanho do `Fusion.ex5`.

> Os valores absolutos **nao** ficam registrados aqui de proposito: eles variam
> alguns milhares de bytes entre compilacoes do mesmo codigo, e um numero exato
> num documento vira uma constante que alguem vai conferir e achar que quebrou. O
> que e estavel e a **diferenca** e a **coincidencia com o `Fusion.ex5`**; e isso
> que se repete para conferir.

O deploy e manual: copiar o `.ex5` para `<terminal>\MQL5\Experts\`. **A partir da
Fase 3 sao dois**, e qual esta rodando se le no log, na primeira linha que o
painel escreve (`Painel: canvas...` ou `Painel: classico...`).

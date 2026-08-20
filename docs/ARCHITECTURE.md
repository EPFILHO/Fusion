# Arquitetura do Fusion

Este documento descreve a arquitetura atual do Fusion e serve como guia para manutencao humana ou assistida por IA.

## Objetivo

O Fusion e um EA modular para MT5. A meta e permitir que estrategias, filtros, protecoes e regras de risco sejam adicionados sem transformar o projeto em um bloco unico dificil de testar e manter.

O projeto deve permanecer simples, mas nao simplista: cada modulo precisa ter responsabilidade clara, poucas dependencias e um ponto previsivel de integracao.

## Convencao de Nomes e Organizacao

A convencao principal do projeto e `Dominio + Responsabilidade`.

O nome do arquivo deve ajudar alguem novo no projeto a responder duas perguntas rapidamente:

- qual parte do sistema este arquivo atende;
- qual responsabilidade concreta ele concentra.

Exemplos atuais:

- `CanvasRendererChrome`: UI / Canvas / cabecalho, abas, trilho e camada de acesso.
- `CanvasRendererValidate`: UI / Canvas / validacao por tela e cache do veredito.
- `CanvasRendererEdits`: UI / Canvas / sincronizacao dos campos nativos por diferenca.
- `ChartIndicatorVisualizer`: UI / Grafico / linhas dos indicadores no chart.
- `ProtectionModuleBase`: Protecao runtime / estado e reload comuns dos modulos.
- `ProfileNameUtils`: Core / regra compartilhada para nomes de perfil.

Evite criar arquivos com nomes genericos como `Helpers`, `Utils2` ou `Common` quando houver um dominio claro. Use um helper generico apenas quando a regra for realmente transversal e estavel.

Arquivos novos devem nascer pequenos. Se uma tela ou modulo exigir varias responsabilidades, prefira partials com nomes explicitos em vez de crescer um arquivo unico.

## Fluxo Principal

1. `Fusion.mq5` cria uma instancia de `CFusionApplication`.
2. `CFusionApplication` carrega inputs, estado salvo do grafico e modulos principais.
3. Estrategias e filtros sao registrados no `CSignalManager`.
4. A cada tick, o EA sincroniza a posicao, gerencia posicao aberta e, se permitido, avalia novo sinal.
5. Sinais simultaneos passam primeiro pelo resolvedor de conflito; a decisao vencedora passa por todos os filtros ativos.
6. O plano de risco e calculado por `CRiskManager`.
7. A ordem e enviada por `CExecutionService`.
8. Protecoes podem bloquear entrada ou forcar saida.
9. A GUI envia comandos para a aplicacao, mas a aplicacao continua sendo dona do estado operacional.

## Indicadores Visuais

`CChartIndicatorVisualizer` e uma camada apenas de apresentacao. Ela cria handles proprios para MA, RSI e Bollinger ativos e nunca reutiliza os handles das estrategias ou filtros. Assim, adicionar, remover ou recriar uma linha no grafico nao altera a avaliacao de sinais.

O MT5 atualiza os indicadores adicionados ao grafico. O Fusion os reconcilia quando o perfil/configuracao ou o timeframe visual muda, faz uma verificacao leve de integridade a cada cinco segundos e limpa seus handles no desligamento. Configuracoes identicas, inclusive o timeframe, sao deduplicadas.

Cada MA visual aparece somente quando o timeframe atual do grafico coincide com o timeframe configurado para aquela curva. Rapida, lenta, Trend MA1 e Trend MA2 podem coexistir quando compartilham o mesmo TF; curvas configuradas em outro TF sao omitidas. Nao existe projecao visual MTF. Essa decisao mantem a camada grafica simples e independente; o alinhamento multi-timeframe da estrategia MA Cross continua sendo responsabilidade exclusiva do motor operacional.

RSI e Bollinger nao usam projecao MTF: cada um aparece somente quando o timeframe do grafico coincide com o configurado na estrategia ou filtro correspondente. O RSI visual recebe somente os niveis usados pelo modo ativo: Zona/Cruzamento usa sobrevenda e sobrecompra; Linha Media ou saida pela media inclui a linha media; o filtro Direcao usa uma linha e Neutro/Extremos usam duas. Estrategia e filtro com a mesma curva compartilham um unico indicador e a uniao deduplicada de ate cinco niveis. A subjanela RSI recebe altura inicial de 100 px somente quando criada; depois permanece redimensionavel pelo usuario.

Como as operacoes de grafico do MT5 sao assincronas, a reconciliacao visual usa duas fases. Ao mudar configuracao ou timeframe, o primeiro ciclo libera os handles e faz um unico passe de remocao por prefixo. Ciclos posteriores confirmam a ausencia dos indicadores antigos antes de criar o conjunto desejado. A verificacao periodica entre indicadores rastreados e encontrados detecta duplicatas e orfaos sem executar loops de limpeza dentro de um unico evento.

As quatro MAs visuais sao reunidas em `VisualIndicators/FusionVisualMA.mq5`, embutido como recurso no executavel principal. Cores e estilos de rapida, lenta, Trend MA1, Trend MA2 e Bollinger sao preferencias visuais persistidas no perfil e selecionadas na aba `Layout` (era `CONFIG > VISUAL` na 1.x; a aba `CONFIG` deixou de existir na GUI 2.0). Perfis sem essas chaves recebem cores e estilos default. As bandas visuais usam `VisualIndicators/FusionVisualBands.mq5`; o RSI visual usa `VisualIndicators/FusionVisualRSI.mq5`. Para um build limpo, compile primeiro os tres indicadores visuais e depois `Fusion.mq5`; em execucao, basta distribuir o `Fusion.ex5`, que ja contem os recursos.

O visualizador mantem uma legenda independente chamada `Legenda Medias`, com papel, periodo, timeframe e estado visual das MAs. Enquanto a visualizacao global estiver ativa, cada linha permanece presente: `OFF` significa realmente desligada; uma MA configurada em outro timeframe informa `outro TF`; durante a segunda fase aparece `aguardando`; uma curva exibida informa `ATIVA`. A legenda nao chama `CopyBuffer` nem qualquer leitura potencialmente bloqueante pelo timer do EA. Ela usa `OBJ_RECTANGLE_LABEL` e `OBJ_LABEL`, fica fixa no canto superior direito, acompanha o redimensionamento do grafico e usa largura normal de 180 px, expandindo apenas para acomodar textos maiores. Nao se usa um segundo `CAppDialog`: o MT5 possui um bug confirmado em que `ChartIndicatorDelete()` fecha esse tipo de janela ao trocar indicadores no grafico (https://www.mql5.com/en/forum/376106).

No timer, conexao, protecoes, persistencia operacional e atualizacao da GUI sempre precedem a sincronizacao visual. Uma falha ou demora de apresentacao nunca deve bloquear sinais, gerenciamento de posicao ou comandos do painel. E proibido consultar buffers visuais de forma sincrona a partir dos eventos do EA.

MA, BB e RSI visuais recebem short names que incluem `ChartID`. A limpeza procura esses prefixos em todas as subjanela e pode remover repetidamente nomes duplicados porque a propriedade e inequivoca; indicadores manuais sem o prefixo do Fusion nao sao tocados.

## Responsabilidades dos Modulos

### `Core`

Contem o ciclo de vida do EA, tipos compartilhados, inputs, logger, registro de instancia e a classe `CFusionApplication`.

`CFusionApplication` e o orquestrador. Ele nao deve virar um deposito de regras especificas de estrategia. Sempre que uma regra puder pertencer a risco, protecao, execucao, persistencia ou sinal, ela deve sair do core.

### `Signals`

Coordena estrategias, filtros e resolvedores.

As estrategias produzem sinais. Os filtros aprovam ou bloqueiam sinais. O resolvedor decide o que fazer quando mais de uma estrategia produz sinal ao mesmo tempo.

Na inicializacao, o `SignalManager` deve aplicar as configuracoes do perfil antes de criar indicadores. Modulos desabilitados nao devem abrir handles desnecessarios nem consumir tempo de troca de timeframe.

O `SignalManager` nao deve impor um timeframe unico ao conjunto de modulos. A direcao do Fusion e carregar timeframes operacionais explicitos por estrategia e por filtro.

Sinais de entrada que aparecem enquanto outro bloqueio esta ativo sao descartados por definicao. Isso evita que um cruzamento ou toque antigo seja executado quando sessao, news, spread, permissao de trading ou outro guard deixar de bloquear.

### `Strategies`

Cada estrategia herda de `CStrategyBase`.

Uma estrategia deve:

- carregar seus proprios parametros;
- inicializar e liberar indicadores;
- produzir sinal de entrada;
- produzir sinal de saida apenas para posicoes que ela abriu.

Uma estrategia nao deve abrir ordem diretamente, alterar lote, nem fazer gestao financeira. Isso fica em `Risk`, `Protection` e `Execution`.

Na MA Cross, o timeframe rapido e o relogio operacional. Quando as medias usam timeframes diferentes, cada valor da MA lenta deve ser o da ultima barra que ja estava fechada no horario de fechamento da barra rapida correspondente. Comparar indices nativos iguais entre timeframes diferentes e proibido, pois esses indices nao representam necessariamente o mesmo instante.

O modo de saida `VM` fecha a posicao pelo sinal contrario da estrategia dona e agenda uma entrada direta na mao oposta apos a sincronizacao do fechamento. Essa reversao nao passa novamente por filtros, resolvedor de entrada, regra de prioridade ou `tradeDirection`; ela ainda respeita guards operacionais como permissao de trading, conflito netting, protecoes globais, risco e execucao. Quando a VM esta armada, o painel deve mostrar essa condicao no `STATUS`/rodape.

### `Filters`

Cada filtro herda de `CFilterBase`.

Um filtro deve responder se um sinal pode seguir adiante. Ele nao deve gerar entrada por conta propria. Filtros sao camadas de validacao, nao donos da posicao.

### `Risk`

Calcula plano de entrada e gestao de posicao:

- lote fixo;
- stop loss;
- take profit;
- TP parcial;
- breakeven;
- trailing stop.

Este modulo nao envia ordens. Ele calcula o que deve ser feito.

Na 1.053, o risco global basico ja estava exposto na GUI em subtabs proprias de `CONFIG > RISK`: `LOTE`, `SL/TP`, `TP PARCIAL`, `BREAKEVEN` e `TRAILING`. **Hoje o caminho e `Gestao > Risco`**, com os mesmos itens num trilho lateral — a aba `CONFIG` deixou de existir na GUI 2.0, e Risco e Protecao foram reunidos em `Gestao`.

`TP PARCIAL`, `BREAKEVEN` e `TRAILING` gerenciam apenas posicao aberta; nenhum deles gera entrada. O fluxo atual em posicao aberta executa TP parcial antes dos ajustes de SL. Depois disso, o BE pode mover o SL para entrada ou lucro minimo, e o trailing pode continuar melhorando o SL conforme o preco anda.

O BE nao deve piorar um SL ja protegido pelo trailing. Para compra, novo SL precisa ser maior que o SL atual. Para venda, novo SL precisa ser menor que o SL atual.

No trailing atual, `Passo` significa distancia entre o preco atual e o novo SL, nao incremento minimo entre uma modificacao e outra.

SL/TP fixos de entrada respeitam `stopsLevel` quando o ativo/corretora informa esse minimo. A defesa final do motor usa Bid/Ask e spread atual do tick antes de enviar a entrada. `Compensar Spread SL` soma o spread ao SL e aumenta o risco nominal; `Compensar Spread TP` subtrai o spread do TP e diminui o alvo nominal. Modificacoes de SL/TP em posicao aberta respeitam `freezeLevel`: BE, trailing e remocao de TP Final Livre apenas aguardam nova tentativa quando o SL/TP atual ou desejado esta na zona congelada.

### `Protection`

Bloqueia entradas ou forca saidas com base em regras de seguranca:

- spread;
- janela de sessao;
- janelas internas de news;
- limites diarios;
- drawdown;
- streak de ganho ou perda.

O `ProtectionManager` e o orquestrador. A direcao do projeto e manter cada protecao em seu proprio modulo, para que regras diferentes evoluam sem virar um unico arquivo monolitico.

Nesta fase, a camada de `Protection` passou a ser organizada em submodulos:

- `SpreadProtection`
- `SessionProtection`
- `NewsProtection`
- `DailyLimitsProtection`
- `DrawdownProtection`
- `StreakProtection`

`Drawdown` tem dependencia funcional de `DAY.maxDailyGain`: ele deve ser armado a partir da meta diaria, nao desde qualquer pico minimo de lucro. Isso evita travas por oscilacoes irrelevantes do dia.

Bloqueios operacionais dessas protecoes devem subir para a aba `STATUS` como aviso persistente enquanto a condicao estiver ativa. O log pode acompanhar, mas o painel precisa deixar claro por que novas entradas estao sendo bloqueadas.

### `Execution`

Centraliza envio, fechamento parcial, fechamento total, modificacao de stops e sincronizacao de posicao.

Este e o unico lugar que deve conversar diretamente com operacoes de trade de baixo nivel, salvo excecoes justificadas.

A 1.054 registra o resultado bruto das requisicoes de entrada, fechamento total e fechamento parcial em CSV. Esse registro e somente diagnostico: serve para observar retcodes reais da corretora e nao participa de nenhuma decisao operacional. Detalhes em `docs/TRADE_REQUEST_DIAGNOSTICS_1054.md`.

Fechamentos parciais usam uma reconciliacao propria. `OrderSend` aceito apenas cria uma pendencia persistente; TP1/TP2 e o P/L realizado somente mudam depois que o historico da posicao confirma novo volume de saida. `DEAL_PROFIT` e a fonte de verdade e a diferenca contra o total ja contabilizado impede dupla contagem. `PLACED` e `DONE_PARTIAL` permanecem pendentes enquanto a ordem estiver ativa. Se houver execucao menor que a solicitada, o nivel e encerrado de forma conservadora, sem reenviar automaticamente o restante.

Se a posicao ja refletir o volume menor mas o deal ainda nao estiver disponivel, DAY/DD nao recebem lucro estimado. O projetado mantem a ultima base confirmada e acompanha a variacao do `POSITION_PROFIT` restante ate a chegada do historico. Uma saida forcada nao concorre com ordem parcial ainda ativa, evitando reversao acidental em netting. Detalhes em `docs/PARTIAL_RECONCILIATION_1055.md`.

Quando uma posicao desaparece, o fechamento entra em reconciliacao antes de atualizar DAY/DD/STREAK. `ExecutionService` seleciona o historico pelo identificador da posicao e considera o resumo completo somente quando o volume acumulado de saida cobre o volume acumulado de entrada. Enquanto isso, `EAApplication` preserva o estado anterior, bloqueia novas entradas e repete a consulta pelo tick, timer e eventos de trade. O horario do ultimo deal define se o fechamento pertence ao dia operacional atual.

Na inicializacao, uma auditoria adicional compara o chart state com os deals de saida do dia para o ativo/magic carregado. Ela corrige P/L bruto e contadores legados que ja haviam sido persistidos incorretamente antes da reconciliacao existir. A leitura aguarda conexao e nao substitui o estado por um historico ainda incompleto.

Enquanto a auditoria estiver pendente, entradas e viradas de mao aguardam. Uma leitura vazia ou com menos trades que o estado confirmado e tratada como incompleta. Mudanca de magic reinicia o estado operacional ligado a identidade anterior e rearma a auditoria para o novo magic; DD diario ativo impede essa troca.

Esse reinicio por identidade e explicito: DAY, DD, STREAK e o pico projetado da posicao sao zerados antes da leitura do historico do novo magic. Recarregar configuracoes com o mesmo magic continua preservando o runtime corrente.

Os resultados operacionais do Fusion sao P/L bruto de preco (`DEAL_PROFIT` e `POSITION_PROFIT`). Comissao, swap, fee, emolumentos e despesas cobradas fora desses campos nao sao estimados pelo EA e devem ser consultados no extrato da corretora.

### `Persistence`

Salva e carrega perfis nomeados e estado automatico por grafico.

Perfis sao configuracoes operacionais. Estado de grafico e restauracao local da instancia. Esses dois conceitos nao devem ser misturados.

O chart state operacional e gravado primeiro em arquivo temporario e promovido sobre o arquivo anterior somente depois de todas as linhas serem escritas e descarregadas. Fluxos que exigem durabilidade antes de enviar trade, como a intencao de parcial, devem verificar o retorno dessa gravacao e falhar fechado.

A leitura do chart state tambem e transacional: contexto, settings e blocos de runtime sao montados em candidatos isolados. O estado somente e publicado depois da validacao de schema, `chartId` e de cada chave obrigatoria de contexto, posicao, STREAK, DAY e DRAWDOWN. Chaves operacionais duplicadas, desconhecidas ou ausentes rejeitam o arquivo por inteiro; o boot corrente permanece ativo para ressincronizacao conservadora com posicao e historico.

Perfis usam a mesma promocao atomica. O carregamento sempre ocorre em uma estrutura candidata inicializada com defaults e so substitui a configuracao corrente depois que schema, campos essenciais e marcadores de completude forem confirmados. Perfis legados completos podem ser migrados; arquivos truncados ou de schema futuro falham sem aplicar defaults silenciosamente.

No schema 14, o `Trend Filter` possui MA1 e MA2 independentes. Cada MA ativa aprova BUY somente quando o preco atual esta estritamente acima do valor corrente da media e aprova SELL somente quando esta estritamente abaixo. Com ambas ON, todas as barreiras precisam aprovar o sinal e a MA1 deve ter horizonte efetivo maior que a MA2. Perfis do schema 13 sao migrados preservando a MA principal e a antiga barreira secundaria. O `Bollinger Filter` pode adicionar ao anti-squeeze uma regra direcional pela inclinacao media da linha central, sempre calculada entre candles fechados.

Os parametros direcionais do `Bollinger Filter` preservam seus valores no perfil quando o filtro principal esta OFF, mas ficam inativos na GUI e nao participam do runtime ate que o filtro principal seja reativado.

Em grafico real ou demo, a restauracao de estado nunca religa novas entradas automaticamente. O EA volta pausado, mas continua apto a gerenciar uma posicao aberta sincronizada ou restaurada.

O estado por grafico guarda tambem o contexto visual do chart. Esse contexto serve para restauracao segura e para alertas ao usuario, nao para redefinir os timeframes operacionais dos modulos.

### `Normalization`

Centraliza detalhes de simbolo e corretora:

- volume minimo;
- volume maximo;
- step de volume;
- digits;
- point;
- tick size;
- tick value;
- stops level;
- freeze level.

Qualquer regra que dependa de especificacao do ativo deve preferir este modulo.

### `UI`

A GUI e parte do projeto porque concentra operacao em grafico, perfis e validacoes visuais.

A UI nao deve executar trade diretamente. Ela monta comandos e envia para `CFusionApplication`.

> ⚠️ **Esta secao foi reescrita na Fase 4 da migracao da GUI (2026-08-16).** Ate ali ela descrevia `CFusionPanel` e os ~60 includes `UIPanel*` do painel classico, construido sobre a biblioteca `Controls` do MT5. **Aquele painel foi removido**; o que sobrevive daquele desenho esta registrado no fim da secao, porque parte das regras continua valendo por motivo proprio. O historico completo esta em `GUI_2000_PLANO.md` e `GUI_2000_FASE4.md`.

`CFusionCanvasPanel` (`UI/Canvas/CanvasPanel.mqh`) e o orquestrador da janela. Ele nao herda de `CAppDialog`: e uma **composicao** sobre `CFusionCanvasRenderer`, que desenha o painel inteiro num unico bitmap `CCanvas`.

A divisao de responsabilidades entre os dois e a peca central do desenho:

- **o renderizador decide o que OFERECER** — desenha, publica as caixas de clique e resolve o estado visual a partir do snapshot. Ele **nao alcanca `Persistence`**: a lista de perfis chega pronta, em vetores primitivos. Os registros de concorrencia (`CInstanceRegistry`, `CActiveProfileRegistry`) ele **tambem consulta**, para desenhar — mas a leitura dele pode ter ate um segundo de idade, e por isso nao decide nada;
- **o painel decide o que ACONTECE** — e o unico lado que alcanca `Persistence`, e reconfere **no instante do clique** as condicoes externas **pertinentes a cada operacao**, nao no instante do desenho.

⚠️ **"Reconferir" nao e uniforme, e supor que fosse leva a erro nas duas direcoes.** Gravar, criar, carregar e excluir perfil dependem do disco e das travas, e sao reconferidos contra os dois. **Iniciar/pausar nao consulta nada** — e alternancia de estado do motor, e a autoridade e o EA. E o **desfazer de criacao falhada** (`FCV_INTENT_RESTORE_ACTIVE`) e deliberadamente **independente do disco**: ele carrega as configuracoes anteriores em maos porque o caso em que existe e justamente aquele em que o arquivo do perfil ativo nao esta la.

Entre os dois circulam **intencoes** (`UI/Canvas/CanvasIntents.mqh`), nao comandos: o renderizador publica "o usuario pediu X", e o painel traduz para `SUICommand` — ou executa sozinho. **Excluir e duplicar perfil nunca chegam ao EA**: sao operacoes de disco do proprio painel, como na 1.058, onde o EA nao tem comando de excluir.

Modulos de `UI/Canvas/`:

- `CanvasTheme.mqh`, `CanvasLayout.mqh`: cores, geometria e constantes. Sem estado, prefixo `FCV_` em tudo.
- `CanvasFields.mqh`, `CanvasForm.mqh`: identificadores de campo e o construtor declarativo de formulario (cada tela empilha linhas; a altura do cartao deriva das linhas).
- `CanvasIntents.mqh`: os tipos de intencao que atravessam a fronteira renderizador -> painel. A lista esta no proprio arquivo; nao repetir a contagem aqui, que ja envelheceu uma vez (`FCV_INTENT_RESTORE_ACTIVE` entrou depois e virou a setima).
- `CanvasRenderer.mqh`: a classe, com os fragmentos abaixo incluidos no corpo — idioma de UI do projeto.
- `CanvasRendererPrimitives.mqh`: desenho basico e a conversao logico -> pixel (`S()`/`L()`).
- `CanvasRendererChrome.mqh`: cabecalho, abas, trilho e a **camada de acesso** (quem pode iniciar, salvar, carregar, criar, excluir).
- `CanvasRendererScreens.mqh`, `CanvasRendererForm.mqh`, `CanvasRendererFields.mqh`: as telas, os controles e o mapeamento campo <-> `SEASettings`. As identidades de tela sao os `FCV_SCREEN_*` de `CanvasLayout.mqh`, e algumas sao **base + indice** (`FCV_SCREEN_PROT0` mais o item do trilho, por exemplo) — quem precisa do numero conta de lá, porque e ele que indexa o estado dos controles.
- `CanvasRendererEdits.mqh`: sincronizacao dos `OBJ_EDIT` nativos **por diferenca**, nunca apagando em massa.
- `CanvasRendererInput.mqh`: clique, rolagem, arrasto e foco.
- `CanvasRendererValidate.mqh`: validacao por tela, com cache invalidado por quadro.
- `CanvasRendererCommands.mqh`, `CanvasRendererPrefs.mqh`, `CanvasRendererStress.mqh`, `CanvasRendererPerf.mqh`.

Fora de `Canvas/`, `UI/` guarda apenas o que desenha no **grafico**, e nunca foi painel:

- `ChartIndicatorVisualizer.mqh` — anexa os indicadores visuais ao grafico por `ChartIndicatorAdd()`, com os nomes curtos `Fusion Visual MA <chartId>`, `Fusion Visual BB <chartId>` e `Fusion Visual RSI <chartId>`. ⚠️ **Sao indicadores, nao objetos de grafico**: aparecem na lista de indicadores (`Ctrl+I`), nao na de objetos (`Ctrl+B`);
- `IndicatorLegendOverlay.mqh` — a legenda das medias, e esta sim em **objetos**: seis, um `OBJ_RECTANGLE_LABEL` de fundo e cinco `OBJ_LABEL`, sob o prefixo `Fusion_indicator_legend_`.

`Platform/FolderLauncher.mqh` segue como integracao opcional com o shell do Windows, fora do core operacional.

#### Regras de objeto de grafico

⚠️ **A limpeza automatica do painel usa exclusivamente o namespace exato `Fusion2.Canvas.`** (`FCV_OBJ_NAMESPACE`), e nao deve ser alargada. As duas tentacoes, e por que cada uma e errada:

- **`Fusion_`** apagaria `Fusion_indicator_legend_*` — a legenda das medias, viva e do **grafico**, nao do painel;
- **`EP Fusion`** alcancaria anotacoes do usuario, porque e prefixo e nao nome exato. Foi o defeito corrigido no P1 da auditoria da Fase 3.

O escopo da exclusao precisa ser **auditavel por leitura**.

> ⚠️ **Um prefixo `Fusion_` que engana:** `Fusion_visual_ma_*` aparece no codigo, mas **nada o cria**. E o nome ANTIGO da legenda, e sobrevive apenas dentro de `DeleteLegacyLegend()`, que o apaga por compatibilidade — as funcoes `LegacyLegendName()`/`DeleteLegacyLegend()` em `ChartIndicatorVisualizer.mqh` sao os unicos usos, todos `ObjectDelete`. Registrado aqui porque induziu erro duas vezes na revisao desta fase. **A regra: um nome que so aparece sendo APAGADO nao prova que esteja vivo. Antes de classificar um prefixo de objeto, localize quem o CRIA** — `ObjectCreate`, `ObjectSetString`, qualquer escrita. So o `ObjectDelete` nao responde.

⚠️ **Objeto nativo em foco nao pode ser destruido.** Os campos de texto continuam sendo `OBJ_EDIT` do terminal sobrepostos ao bitmap, e sao sincronizados por diferenca: sai so o que saiu da tela, nasce so o que entrou, o que permanece e **movido**.

#### Regras que sobreviveram ao painel antigo

Continuam valendo, agora por motivo proprio e nao por heranca:

**O `Status` e dono do DETALHE operacional**, inclusive em formato multilinha: a escada completa de alertas, os cartoes de sessao e posicao, o motivo de cada bloqueio. A aba `Resultados` permanece voltada a leitura de estado e resultados, sem acumular alertas de contexto.

⚠️ **Mas o `Status` nao e o unico lugar onde um aviso aparece, e nao deve ser.** Um aviso que so existe dentro de uma aba nao e lido por quem esta em outra — foi um achado do aceite da Fase 3, com a formulacao "a aba ficou vermelha nao conta quando o usuario esta em outra aba". A GUI 2.0 tem tres niveis, com papeis distintos:

- **faixa de motivo no cabecalho** — resumo global, sempre visivel, resolvido uma vez por quadro em `ResolveHeaderActionState()`. Carrega **dois tipos de conteudo, e a ordem entre eles importa**:
  1. **acao**, quando ha uma ("Habilite para iniciar") — tem prioridade, porque responde algo que o usuario acabou de perguntar com o cursor;
  2. **informacao**, quando a faixa estaria vazia — a causa da restricao de entradas, ou o aviso de DD armado. ⚠️ Informacao **nao empurra instrucao para fora da tela**: com posicao aberta, por exemplo, a faixa fica com `POSICAO ABERTA` e a causa da restricao **nao aparece nela** — vai para o `Status`, apontada pelo marcador;
- **distintivo** ao lado — diz o **estado** (`BLOQUEADO`/`IMPEDIDO`/`OPERANDO`/`SEM ENTRADAS`/`RODANDO`/`PAUSADO`), nunca a causa;
- **card critico** — o que nao pode esperar a navegacao;
- **duas marcacoes de aba, com significados diferentes e que nao se misturam**:
  - **vermelho** na aba e na subaba — a **cadeia de validacao**, que leva do topo ate o campo invalido;
  - **ambar** na aba `Status`, em forma propria — **marcador operacional**: ha algo acontecendo cujo detalhe esta la. Nao e erro de configuracao, e nao aponta para campo nenhum.

A regra que liga tudo: **a faixa responde "sei o que fazer agora?"**, o `Status` responde "por que exatamente?". Texto neutro que descreve a condicao sem dizer o que fazer foi corrigido tres vezes na migracao, e uma delas eu tinha introduzido ao consertar uma contradicao — joguei fora a acao junto com o erro.

Fonte unica obrigatoria: botao, faixa, distintivo, marcador da aba `Status` e card critico leem **uma** resposta, do mesmo resolvedor. Predicados paralelos para a mesma pergunta divergem — foi por isso que `AccCanStart()` e `AccCanPause()` foram removidos, e a escada do resolvedor passou a **ser** o predicado.

⚠️ **Todo bloqueio precisa de caminho de volta, e botao apagado precisa dizer por que.** Mensagem que instrui uma acao que a interface impede foi o defeito mais reincidente da migracao — apareceu quatro vezes na Fase 2 e mais duas no aceite da Fase 3.

⚠️ **Predicado de acesso e funcao unica, nunca copiado.** Desenho e pulso precisam concordar, e a mesma regra escrita por extenso em dois lugares diverge. Foi assim que `activeProfileEditable` abriu um furo na 2b.

Troca de timeframe do grafico, por si so, nao deve mais ser tratada como erro operacional na UI. Como os timeframes operacionais pertencem aos modulos, o chart pode ser usado apenas para inspecao visual. O estado confirmado e restaurado, mas drafts e pending changes da GUI nunca sao salvos ou aplicados implicitamente; se existiam, `STATUS` avisa claramente que foram descartados. Alertas persistentes tambem permanecem para troca de ativo e ausencia ou invalidade do perfil esperado.

No bootstrap da GUI, o painel nasce com um unico pass de hidratacao. O estado completo necessario para criar o painel vem no `SUIPanelSnapshot`, evitando uma segunda carga manual logo apos `CreatePanel()`.

As paginas de estrategias e filtros usam campos fechados para selecao de timeframe, com valores explicitos do MT5. Isso evita erro de digitacao, simplifica validacao e preserva a coerencia entre GUI, perfil salvo e motor operacional.

#### O que a GUI 2.0 tornou obsoleto

Ate a Fase 4, esta secao descrevia tres regras que existiam para contornar a Standard Library do MT5, e **nenhuma delas se aplica a um painel desenhado em bitmap**:

- **`CFusionHitGroup` e a pre-criacao controlada de paginas** (desde a `1.046`) resolviam que controles escondidos com `Hide()` ainda recebiam `OnMouseEvent()` como filhos diretos do `CAppDialog`, e que controles criados depois de `Run()` podiam exigir rebinding de IDs. O canvas nao tem arvore de controles: quem publica caixa de clique e o proprio desenho, e **controle bloqueado simplesmente nao publica caixa** — nao basta parecer desligado.
- **Isolar cada aba em grupos independentes por causa dos `CComboBox`** — os dropdowns ficavam presos ao ultimo combo usado. O combo do canvas e desenhado, e o estado dos controles vive indexado por tela (`m_screen*FCV_SLOT_MAX+seq`), o que impede um controle de vazar de uma subaba para outra.
- **Nao reaplicar `Show/Hide` estrutural em todo timer, e atualizar so a aba ativa.** O canvas redesenha o quadro **inteiro** a cada atualizacao, decisao tomada com medicao na Fase 1: `TextOut` custa ~1 us, o quadro cheio fica em 0,35 ms de media (2,2 ms em VPS), e a margem contra o limiar de interacao e de ~60x. Repintura parcial por regiao suja ficou arquivada como plano B, nao implementado.

O que sobrou dessas tres, e vale por si: **quem altera estado exibido marca a tela como suja**. O pulso repinta, o `Render` limpa. Sem isso, dado novo aparece sob desenho velho — que e pior que erro visivel.

## Prioridade Atual de Arquitetura

A linha 1.050/1.051 fechou um ciclo de saneamento conservador da GUI. A 1.052 completou a expansao funcional principal de estrategias/filtros, a 1.053 avancou para risco e protecoes na GUI, e as versoes 1.054 a 1.057 endureceram reconciliacao, persistencia, filtros direcionais, restore e build.

O foco arquitetural atual e preservar e documentar o conjunto estabilizado antes de abrir uma nova frente:

- preservar o padrao de GUI estabilizado na migracao 2.0 (renderizador desenha e oferece; painel reconfere e decide);
- manter filtros como validadores de sinal, nunca como geradores de entrada;
- manter `Risk` calculando plano/ajustes e `Execution` enviando/modificando ordens;
- manter o manual do usuario sincronizado com o codigo e com a GUI;
- concluir testes operacionais e capturas reais sem mexer no comportamento validado;
- tratar novas estrategias, filtros ou inteligencia artificial como projetos separados ate haver especificacao e evidencia de vantagem.

O modelo multi-timeframe por modulo ja foi incorporado ao fluxo principal de configuracao, restore, save/load de perfil e defaults internos. O timeframe atual do grafico continua sendo contexto visual do chart, nao regra operacional global.

Refactors em `EAApplication.mqh` continuam desejaveis, mas devem esperar casos claros. A regra atual e simples: primeiro estabilizar o comportamento validado, depois mover codigo em fatias pequenas e compiladas.

## Hot Reload

O projeto ja possui `RELOAD_HOT`, `RELOAD_WARM` e `RELOAD_COLD`, e os modulos principais tem pontos de recarga.

Mesmo assim, a politica atual e conservadora: a GUI bloqueia edicao enquanto o EA esta rodando ou existe posicao aberta. Isso evita alteracoes ambiguas em producao e reduz risco operacional.

No futuro, hot reload pode ser reabilitado por categorias de alteracao, desde que cada modulo declare claramente o que pode ser alterado com seguranca em runtime.

## Proximas Evolucoes Arquiteturais

- Adicionar capturas reais da GUI ao manual depois do smoke test da versao distribuida.
- Melhorar telemetria de `STATUS` somente quando uma necessidade operacional concreta for confirmada.
- Avaliar reducao/rate limit dos logs de trailing se virarem ruido em mercado rapido.
- Ampliar validacoes de corretora apenas quando novos fluxos de ordem exigirem.
- Manter qualquer laboratorio de aprendizado de maquina/IA isolado do Fusion estavel, inicialmente em modo de observacao.

## Nota de Persistencia por Grafico

Na arquitetura atual, o estado automatico do Fusion por grafico deve ser restaurado pelo `chart_id`, e nao por `symbol + timeframe + magic`.

O arquivo salvo por grafico tambem registra metadados do chart, principalmente simbolo e timeframe visuais. Isso permite manter o vinculo do ultimo perfil do grafico quando o usuario muda apenas o timeframe.

O chart state tambem registra o `deinitReason` do ultimo encerramento daquela instancia. Isso e usado para diferenciar:

- `REASON_CHARTCHANGE`: o mesmo grafico mudou de simbolo ou timeframe e o Fusion deve tentar preservar o contexto operacional com aviso ou bloqueio seguro;
- `REASON_CHARTCLOSE`: o grafico foi fechado de fato, entao um `chart_id` reaproveitado nao deve reviver automaticamente aquele contexto;
- outros motivos de reinicializacao, como recompilacao ou restart, onde a restauracao continua valida.

Se o mesmo `chart_id` reaparecer com simbolo diferente do simbolo salvo e o ultimo motivo foi `REASON_CHARTCHANGE`, o Fusion entra em bloqueio seguro. Nesse modo ele nao sincroniza posicao nem abre novas entradas ate o usuario voltar ao ativo anterior.

# Decisoes do Projeto

Este arquivo registra decisoes estruturais do Fusion. A intencao e evitar que o projeto perca contexto com o tempo.

## 1. Implementacao Clean-Room

O Fusion pode se inspirar em boas ideias do Matrix, mas nao deve copiar cegamente estrutura, nomes ou comportamento.

O codigo e a fonte da verdade. Documentos externos ajudam a entender intencao, mas nao substituem analise do que esta implementado.

## 2. Operacao por Grafico

Cada instancia do EA continua vinculada ao simbolo do grafico onde esta anexada.

O timeframe do grafico e contexto visual. O timeframe operacional deve vir do perfil e, progressivamente, de cada modulo individual.

Isso permite ter multiplos graficos com o Fusion rodando ao mesmo tempo, desde que cada setup use Magic Number adequado para separacao operacional.

## 3. Uma Posicao Liquida por EA

Cada instancia do Fusion deve gerenciar apenas uma posicao liquida por vez.

Essa regra vale como politica operacional mesmo em contas hedge. Em contas netting ou exchange, o EA ainda precisa respeitar a limitacao natural da conta e evitar interferencia com posicoes de outro magic.

## 4. Magic Number Pertence ao Perfil

O Magic Number pertence ao perfil/EA, nao a estrategias individuais.

Motivos:

- comentarios de ordem nao sao fonte confiavel;
- comentarios podem sumir em TP parcial;
- algumas corretoras nao permitem alterar comentario;
- multiplas estrategias dentro do mesmo EA compartilham a mesma posicao operacional;
- perfis de mercados diferentes nao devem ser reutilizados por acidente.

Perfis salvos devem ter Magic Numbers unicos.

Enquanto houver outra instancia ativa do Fusion usando o mesmo `Magic`, a GUI deve bloquear apenas o `INICIAR` da instancia atual. Isso evita interferencia operacional sem impedir leitura, troca de perfil ou ajuste de configuracao.

## 5. Estrategia Dona da Entrada Dona da Saida por Sinal

A estrategia que abriu a posicao e a unica autorizada a gerar saida por sinal daquela posicao.

Protecoes de risco continuam podendo forcar saida, porque elas sao regras superiores de seguranca.

## 6. Filtros Nao Geram Entrada

Filtros apenas aprovam ou bloqueiam sinais antes da entrada.

Eles nao devem disputar propriedade de posicao, nao devem emitir ordem e nao devem substituir a estrategia.

## 6.1. Ordem de Ataque Importa

O Fusion deve priorizar primeiro as mudancas que definem o comportamento operacional do EA. Refactors de limpeza estrutural importantes, mas nao diretamente operacionais, ficam em segundo plano quando competem com uma mudanca de motor.

Hoje a ordem correta e:

- consolidar o modelo multi-timeframe por modulo;
- depois reduzir ainda mais `EAApplication.mqh` e `UIPanel.mqh`.

Isso evita refatorar a casca antes de fechar a regra de negocio principal.

## 6.2. Multi-Timeframe Deve Ser Operacional, Nao Visual

O Fusion deve operar com timeframe explicito por modulo e nao depender de `Period()` ou `PERIOD_CURRENT` na logica operacional.

Isso significa:

- cada estrategia e filtro tera timeframe proprio salvo no perfil;
- mudar o timeframe do grafico nao deve redefinir o timeframe operacional do EA;
- o grafico continua sendo o host visual, mas nao a fonte da verdade para calculo de sinais.

No `MA Cross`, o modelo-alvo deve prever dois timeframes independentes:

- `fastTF`
- `slowTF`

A primeira fase dessa virada entrou no motor, e a segunda ja chegou na GUI: `SEASettings`, `Inputs`, persistencia, modulos atuais e as abas `STRATS` e `FILTERS` passaram a trabalhar com timeframes explicitos por modulo.

Como regra adicional, configuracoes novas e defaults internos nao devem mais usar `PERIOD_CURRENT` como sentinela operacional. O Fusion agora nasce com timeframe padrao explicito e usa o contexto salvo do grafico apenas como fallback de migracao ou seguranca.

Esse passo tem prioridade acima de novos refactors cosmeticos em arquivos grandes.

## 7. Hot Reload Seguro Antes de Hot Reload Conveniente

O Fusion foi desenhado com pontos de reload, mas a GUI nao permite edicao enquanto o EA esta rodando ou gerenciando posicao.

Essa escolha evita confusao operacional e reduz risco de mau uso. No futuro, alteracoes podem ser classificadas em:

- hot: seguras sem reinicializar indicadores;
- warm: exigem recriar indicadores, mas nao mexem em posicao aberta;
- cold: exigem reaplicacao completa e devem ocorrer com EA parado.

## 8. Strategy Tester Usa Inputs

Perfis da GUI sao voltados a operacao em grafico.

No Strategy Tester, a fonte principal de parametros deve ser a lista de `input`, porque isso permite otimizacao e backtest nativo do MT5.

## 9. GUI e Parte do Produto

A GUI nao e um acessorio descartavel.

Ela sera o centro de operacao visual, perfis, validacao e feedback de bloqueios. Por isso deve evoluir com estrutura clara, abas e subpaginas desde cedo.

Avisos operacionais persistentes, como troca indevida de ativo ou mudanca relevante de contexto do grafico, devem ficar concentrados na aba `STATUS`.

Como o Fusion esta migrando para operacao multi-timeframe por modulo, troca de timeframe do grafico nao deve gerar alerta persistente por si so. O chart pode ser usado para leitura visual sem que isso seja tratado como falha do usuario.

Alteracoes pendentes do perfil carregado devem poder ser descartadas sem obrigar `SALVAR`. Por isso a GUI deve expor uma acao global de cancelamento/reversao do rascunho atual.

## 10. Persistencia Separada por Conceito

Perfis nomeados guardam configuracoes de setup.

Estado automatico por grafico guarda restauracao local daquela instancia, como perfil ativo, estado anterior e dados de posicao em gerenciamento.

Por seguranca, o Fusion nao restaura `started=true` em grafico real ou demo. Ao anexar, recompilar ou reinicializar o EA, a operacao volta pausada e exige clique manual em `INICIAR`.

## 11. Protection Deve Crescer por Modulo

As protecoes do Fusion nao devem ficar amontoadas em um unico bloco logico ou em uma unica subpagina sem separacao conceitual.

No motor, a direcao e:

- um orquestrador central (`ProtectionManager`);
- submodulos dedicados para `Spread`, `Session`, `News`, `Day`, `Drawdown` e `Streak`.

Na GUI, a mesma separacao deve aparecer na subaba `PROTECT`, com subpaginas internas em vez de um formulario gigante. Isso reduz acoplamento, facilita validacao e evita repetir o problema historico de crescimento desordenado visto em outros projetos.

No runtime, bloqueios de protecao devem aparecer na aba `STATUS` enquanto estiverem ativos, com mensagens persistentes e log rate-limited. Isso evita depender apenas do Journal para entender por que o EA nao abriu uma nova operacao.

## 12. Drawdown Diario Depende de Meta de Ganho

No Fusion, `Drawdown` nao deve ser armado a partir de qualquer pequeno pico projetado do dia. Isso pode bloquear o EA por oscilacoes irrelevantes.

A regra escolhida e:

- `DAY.maxDailyGain` continua sendo o gatilho de ativacao;
- se `Drawdown` estiver desligado, atingir `maxDailyGain` bloqueia/fecha pela propria regra diaria;
- se `Drawdown` estiver ligado, atingir `maxDailyGain` arma a protecao de drawdown em vez de encerrar imediatamente a operacao.

Por isso a GUI deve validar `Drawdown` como dependente de `DAY` ativo com `Max Ganho > 0`.

Excecoes e limites:

- no Strategy Tester, o EA continua iniciando automaticamente para preservar backtests via `input`;
- se uma posicao aberta for sincronizada ou restaurada, ela continua sendo gerenciada mesmo com o EA pausado;
- pausar significa bloquear novas entradas, nao abandonar uma operacao ja aberta.

Perfis nomeados e estado automatico por grafico tem propositos diferentes e nao devem ser misturados.

Na restauracao por grafico, `chart_id` continua sendo a chave principal, mas o Fusion nao deve tratar um grafico fechado como se fosse o mesmo contexto visual para sempre. Por isso o estado salvo tambem registra o `deinitReason`:

- `REASON_CHARTCHANGE` preserva contexto e permite aviso/bloqueio quando o usuario muda simbolo ou timeframe;
- `REASON_CHARTCLOSE` nao deve ser usado para ressuscitar contexto em um grafico novo com `chart_id` reaproveitado.

Quando nao houver chart state valido, o Fusion deve tentar carregar o perfil nomeado em `defaultProfileName` de verdade. So na falta desse perfil e que os `inputs` atuais permanecem ativos.

## 11. Normalizacao Centralizada

Regras que dependem de especificacao do ativo ou corretora devem passar por normalizacao.

Isso evita espalhar logica de volume, step, digits, stops level e freeze level por varios modulos.

## 12. Changelog Desde o Inicio

Toda mudanca relevante deve entrar no `CHANGELOG.md`.

O historico ajuda humanos e IAs a entender por que o projeto esta como esta, especialmente quando decisoes anteriores sao revertidas ou refinadas.

## 13. GUI Pesada Deve Ser Isolada por Grupos de Hit-Test

A investigacao da regressao dos `CComboBox` em `STRATS > MA` mostrou que a Standard Library do MT5 nao trata `Hide()` de controles simples como isolamento suficiente de mouse quando esses controles sao filhos diretos de um container visivel.

O que nao resolveu de forma confiavel:

- chamar `SyncStrategyPanels()` imediatamente apos `ON_CHANGE`;
- alternar `Enable()` e `Disable()` nos wrappers de `CComboBox`;
- criar todos os controles diretamente no `CAppDialog` e apenas esconder os inativos;
- depender de z-order, redraw ou eventos sinteticos como solucao principal.

O que resolveu na versao `1.046`:

- pre-criar paginas e subpaginas antes de `CAppDialog::Run()`;
- adicionar cada pagina/subpagina a um `CFusionHitGroup`, derivado de `CWndContainer`;
- fazer o grupo invisivel retornar `false` no roteamento de mouse antes de consultar seus filhos;
- manter `STRATS > MA`, `RSI`, `BB`, `CONFIG > PROTECT` e demais blocos em grupos separados.

Regra de manutencao: novos blocos de conteudo da GUI nao devem ser adicionados diretamente ao `CAppDialog`. Eles devem entrar no grupo logico da pagina/subpagina correspondente. Se um controle estiver escondido visualmente, ele tambem precisa estar isolado por um container invisivel para nao interceptar cliques.

## 14. Integracao com o Sistema Operacional Deve Ficar Fora do Core

Recursos de conveniencia da GUI que dependem do sistema operacional, como abrir a pasta de perfis no Windows, nao devem ser colocados dentro de `EAApplication.mqh`.

Essas integracoes devem viver em helpers pequenos e isolados, como `Platform/FolderLauncher.mqh`, para manter o core focado em operacao, persistencia e seguranca de trade.

Isso tambem facilita tratar restricoes do MT5, como `DLL imports` desabilitadas, sem misturar regra operacional com perfumaria da interface.

## 14. Estado do Grafico Deve Ser Restaurado pelo `chart_id`

A restauracao automatica do Fusion por grafico deve ser vinculada ao `chart_id`.

Motivos:

- `magic number` identifica o perfil, nao o grafico;
- `symbol + timeframe + magic` falha quando o usuario muda o timeframe;
- o objetivo da restauracao e devolver o contexto daquele grafico, nao adivinhar um setup por combinacao de campos.

O estado salvo por grafico tambem deve carregar metadados do chart, principalmente simbolo e timeframe visuais.

## 15. Troca de Ativo do Grafico Deve Bloquear o Fusion

Se o `chart_id` restaurado apontar para um contexto salvo com simbolo diferente do simbolo atual do grafico, o Fusion nao deve tentar se adaptar automaticamente.

Nesse caso, o EA entra em bloqueio seguro:

- nao sincroniza posicao com o simbolo errado;
- nao abre novas entradas;
- nao permite iniciar a operacao pela GUI;
- orienta o usuario a voltar ao ativo anterior para recuperar o contexto.

Essa escolha e deliberadamente conservadora. Mudar timeframe e toleravel. Mudar o ativo do grafico nao e.

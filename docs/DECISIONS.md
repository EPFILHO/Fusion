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

## 10. Persistencia Separada por Conceito

Perfis nomeados guardam configuracoes de setup.

Estado automatico por grafico guarda restauracao local daquela instancia, como perfil ativo, estado anterior e dados de posicao em gerenciamento.

Por seguranca, o Fusion nao restaura `started=true` em grafico real ou demo. Ao anexar, recompilar ou reinicializar o EA, a operacao volta pausada e exige clique manual em `INICIAR`.

Excecoes e limites:

- no Strategy Tester, o EA continua iniciando automaticamente para preservar backtests via `input`;
- se uma posicao aberta for sincronizada ou restaurada, ela continua sendo gerenciada mesmo com o EA pausado;
- pausar significa bloquear novas entradas, nao abandonar uma operacao ja aberta.

Perfis nomeados e estado automatico por grafico tem propositos diferentes e nao devem ser misturados.

## 11. Normalizacao Centralizada

Regras que dependem de especificacao do ativo ou corretora devem passar por normalizacao.

Isso evita espalhar logica de volume, step, digits, stops level e freeze level por varios modulos.

## 12. Changelog Desde o Inicio

Toda mudanca relevante deve entrar no `CHANGELOG.md`.

O historico ajuda humanos e IAs a entender por que o projeto esta como esta, especialmente quando decisoes anteriores sao revertidas ou refinadas.

## 13. GUI Pesada Deve Nascer Sob Demanda

Quando o custo de inicializacao ou de eventos crescer, a preferencia estrutural e mover abas pesadas para criacao lazy ou on-demand, em vez de manter todos os controles vivos desde o boot.

O shell da aba pode nascer antes, mas o conteudo interno deve preferir subpaginas independentes. Isso reduz carga de eventos, evita uma GUI monolitica e facilita encaixar novos blocos sem refatorar tudo.

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

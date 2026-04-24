# Decisões do Projeto

Este arquivo registra decisões estruturais do Fusion. A intenção é evitar que o projeto perca contexto com o tempo.

## 1. Implementação Clean-Room

O Fusion pode se inspirar em boas ideias do Matrix, mas não deve copiar cegamente estrutura, nomes ou comportamento.

O código é a fonte da verdade. Documentos externos ajudam a entender intenção, mas não substituem análise do que está implementado.

## 2. Operação por Gráfico

Cada instância do EA opera somente o símbolo e timeframe do gráfico onde está anexada.

Isso permite ter múltiplos gráficos com o Fusion rodando ao mesmo tempo, desde que cada setup use Magic Number adequado para separação operacional.

## 3. Uma Posição Líquida por EA

Cada instância do Fusion deve gerenciar apenas uma posição líquida por vez.

Essa regra vale como política operacional mesmo em contas hedge. Em contas netting/exchange, o EA ainda precisa respeitar a limitação natural da conta e evitar interferência com posições de outro magic.

## 4. Magic Number Pertence ao Perfil

O Magic Number pertence ao perfil/EA, não a estratégias individuais.

Motivo:

- comentários de ordem não são fonte confiável;
- comentários podem sumir em TP parcial;
- algumas corretoras não permitem alterar comentário;
- múltiplas estratégias dentro do mesmo EA compartilham a mesma posição operacional;
- perfis de mercados diferentes não devem ser reutilizados por acidente.

Perfis salvos devem ter Magic Numbers únicos.

## 5. Estratégia Dona da Entrada Dona da Saída por Sinal

A estratégia que abriu a posição é a única autorizada a gerar saída por sinal daquela posição.

Proteções de risco continuam podendo forçar saída, porque elas são regras superiores de segurança.

## 6. Filtros Não Geram Entrada

Filtros apenas aprovam ou bloqueiam sinais antes da entrada.

Eles não devem disputar propriedade de posição, não devem emitir ordem e não devem substituir a estratégia.

## 6.1. Ordem de Ataque Importa

O Fusion deve priorizar primeiro as mudancas que definem o comportamento operacional do EA. Refactors de limpeza estrutural importantes, mas nao diretamente operacionais, ficam em segundo plano quando competem com uma mudanca de motor.

Hoje a ordem correta e:

- consolidar a restauracao segura por grafico;
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

Esse passo tem prioridade acima de novos refactors cosmeticos em arquivos grandes.

## 7. Hot Reload Seguro Antes de Hot Reload Conveniente

O Fusion foi desenhado com pontos de reload, mas a GUI não permite edição enquanto o EA está rodando ou gerenciando posição.

Essa escolha evita confusão operacional e reduz risco de mau uso. No futuro, alterações podem ser classificadas em:

- hot: seguras sem reinicializar indicadores;
- warm: exigem recriar indicadores, mas não mexem em posição aberta;
- cold: exigem reaplicação completa e devem ocorrer com EA parado.

## 8. Strategy Tester Usa Inputs

Perfis da GUI são voltados à operação em gráfico.

No Strategy Tester, a fonte principal de parâmetros deve ser a lista de `input`, porque isso permite otimização e backtest nativo do MT5.

## 9. GUI É Parte do Produto

A GUI não é um acessório descartável.

Ela será o centro de operação visual, perfis, validação e feedback de bloqueios. Por isso deve evoluir com estrutura clara, abas e subpáginas desde cedo.

## 10. Persistência Separada por Conceito

Perfis nomeados guardam configurações de setups.

Estado automático por gráfico guarda restauração local daquela instância, como perfil ativo, estado anterior e dados de posição em gerenciamento.

Por segurança, o Fusion não restaura `started=true` em gráfico real/demo. Ao anexar, recompilar ou reinicializar o EA, a operação volta pausada e exige clique manual em `INICIAR`.

Exceções e limites:

- no Strategy Tester, o EA continua iniciando automaticamente para preservar backtests via `input`;
- se uma posição aberta for sincronizada/restaurada, ela continua sendo gerenciada mesmo com o EA pausado;
- pausar significa bloquear novas entradas, não abandonar uma operação já aberta.

Esses dois arquivos têm propósitos diferentes e não devem ser misturados.

## 11. Normalização Centralizada

Regras que dependem de especificação do ativo/corretora devem passar por normalização.

Isso evita espalhar lógica de volume, step, digits, stops level e freeze level por vários módulos.

## 12. Changelog Desde o Início

Toda mudança relevante deve entrar no `CHANGELOG.md`.

O histórico ajuda humanos e IAs a entender por que o projeto está como está, especialmente quando decisões anteriores são revertidas ou refinadas.
## 13. GUI Pesada Deve Nascer Sob Demanda

Quando o custo de inicializacao ou de eventos crescer, a preferencia estrutural e mover abas pesadas para criacao lazy/on-demand em vez de manter todos os controles vivos desde o boot.

O shell da aba pode nascer antes, mas o conteudo interno deve preferir subpaginas independentes. Isso reduz carga de eventos, evita uma GUI monolitica e facilita encaixar novos blocos sem refatorar tudo.

## 14. Estado do GrÃ¡fico Deve Ser Restaurado pelo `chart_id`

A restauraÃ§Ã£o automÃ¡tica do Fusion por grÃ¡fico deve ser vinculada ao `chart_id`.

Motivos:

- `magic number` identifica o perfil, nÃ£o o grÃ¡fico;
- `symbol + timeframe + magic` falha quando o usuÃ¡rio muda o timeframe;
- o objetivo da restauraÃ§Ã£o Ã© devolver o contexto daquele grÃ¡fico, nÃ£o adivinhar um setup por combinaÃ§Ã£o de campos.

O estado salvo por grÃ¡fico tambÃ©m deve carregar metadados do chart, principalmente sÃ­mbolo e timeframe visuais.

## 15. Troca de Ativo do GrÃ¡fico Deve Bloquear o Fusion

Se o `chart_id` restaurado apontar para um contexto salvo com sÃ­mbolo diferente do sÃ­mbolo atual do grÃ¡fico, o Fusion nÃ£o deve tentar se adaptar automaticamente.

Nesse caso, o EA entra em bloqueio seguro:

- nÃ£o sincroniza posiÃ§Ã£o com o sÃ­mbolo errado;
- nÃ£o abre novas entradas;
- nÃ£o permite iniciar a operaÃ§Ã£o pela GUI;
- orienta o usuÃ¡rio a voltar ao ativo anterior para recuperar o contexto.

Essa escolha Ã© deliberadamente conservadora. Mudar timeframe Ã© tolerÃ¡vel. Mudar o ativo do grÃ¡fico nÃ£o Ã©.

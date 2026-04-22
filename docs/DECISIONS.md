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

Estado automático por gráfico guarda restauração local daquela instância, como perfil ativo, estado ligado/desligado e dados de posição em gerenciamento.

Esses dois arquivos têm propósitos diferentes e não devem ser misturados.

## 11. Normalização Centralizada

Regras que dependem de especificação do ativo/corretora devem passar por normalização.

Isso evita espalhar lógica de volume, step, digits, stops level e freeze level por vários módulos.

## 12. Changelog Desde o Início

Toda mudança relevante deve entrar no `CHANGELOG.md`.

O histórico ajuda humanos e IAs a entender por que o projeto está como está, especialmente quando decisões anteriores são revertidas ou refinadas.

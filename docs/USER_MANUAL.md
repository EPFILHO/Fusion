# Manual do Usuário - EP Fusion 2.000 (GUI 2.0)

## 1. Escopo

Este manual descreve o comportamento efetivamente implementado no EP Fusion 2.000, cuja interface é a **GUI 2.0**, desenhada em canvas. Ele cobre a interface, os perfis e os parâmetros disponíveis nos `input` do MetaTrader 5.

A GUI 2.0 substituiu por completo o painel clássico das versões 1.x. A navegação passou a ser `Status · Resultados · Estratégias · Filtros · Gestão · Perfis · Layout`. Nomes antigos como `CONFIG`, `STRATS`, `FILTERS` ou `RISK` não existem mais; quando aparecem neste manual, é sempre identificados como nomenclatura histórica.

O motor operacional — estratégias, filtros, risco, proteções, execução e persistência — é o da 1.058, com as correções listadas no `CHANGELOG.md`.

O Fusion é um Expert Advisor. Ele automatiza regras, mas não garante resultado, não avalia se o lote é financeiramente adequado para a conta e não substitui testes em conta demo. Os valores em pontos, volume e dinheiro têm impactos muito diferentes conforme ativo, corretora, contrato e alavancagem.

## 2. Instalação e distribuição

Para o usuário final, basta o arquivo `Fusion.ex5` produzido pelo build completo:

1. No MT5, abra `Arquivo > Abrir Pasta de Dados`.
2. Copie `Fusion.ex5` para `MQL5/Experts`.
3. Atualize o Navegador ou reinicie o terminal.
4. Anexe o Fusion ao gráfico do ativo que será operado.
5. Mantenha a negociação algorítmica habilitada no terminal e nas propriedades do EA.

Os três indicadores auxiliares já ficam incorporados no `Fusion.ex5`. Eles não precisam ser enviados nem instalados separadamente.

Para compilar o código-fonte, use o repositório completo e o `build.ps1`, conforme o README. Compilar somente `Fusion.mq5` em um clone ainda sem os EX5 auxiliares pode falhar na incorporação dos recursos.

## 3. Conceitos essenciais

### 3.1. Ativo e posição

- Cada instância opera o símbolo do gráfico no qual está anexada.
- Cada instância administra no máximo uma posição líquida do Fusion por vez.
- O Fusion não deve compartilhar perfil ou Magic Number com outra instância.
- Em conta netting/exchange, uma posição estrangeira no mesmo ativo pode bloquear a operação para evitar interferência.

### 3.2. Timeframe visual e timeframes operacionais

São duas coisas diferentes, e confundi-las é a origem da maioria das dúvidas:

- o **timeframe do gráfico** é visual. Ele decide o que você enxerga e quais curvas o Fusion desenha;
- cada **estratégia e filtro** tem o **seu** timeframe operacional, salvo no perfil. É ele que o motor usa para calcular.

Trocar o timeframe do gráfico **não altera** nenhum cálculo. Uma curva configurada em outro timeframe deixa de ser desenhada naquele gráfico, mas o módulo continua trabalhando no timeframe salvo. O cabeçalho mostra o timeframe do gráfico ao lado do ativo; os timeframes operacionais aparecem em cada estratégia e filtro.

O que acontece ao trocar o timeframe do gráfico está detalhado na seção 15.

### 3.3. Candle fechado

As estratégias RSI e Bollinger, o cruzamento da MA e os filtros RSI/BB tomam suas decisões com candles fechados. O Trend Filter é a exceção: compara o preço atual com o valor atual das médias ativas.

### 3.4. Pontos do MT5

Campos com `pts` usam `SYMBOL_POINT`, isto é, pontos do MT5, e não uma unidade financeira universal. Use a mesma contagem da régua do gráfico e confirme as especificações do símbolo.

### 3.5. Pausado não significa abandonado

`PAUSADO` bloqueia novas entradas. Uma posição já aberta continua sendo gerenciada, inclusive depois de reinicialização, desde que a negociação algorítmica e as permissões de trade continuem disponíveis.

### 3.6. Descarte de sinais

Sinais detectados durante bloqueio por proteção, permissão, direção, filtro, conflito ou outra guarda são consumidos e descartados. O Fusion não executa posteriormente um sinal antigo apenas porque o bloqueio terminou.

## 4. Primeiro uso recomendado

1. Anexe o EA em conta demo e confirme o símbolo do gráfico.
2. Abra `Perfis` e confirme o perfil carregado.
3. Com o EA pausado e sem posição, configure risco, estratégias, filtros e proteções.
4. Mantenha pelo menos uma estratégia ativa.
5. Corrija todas as abas ou subabas marcadas em vermelho.
6. Clique em `SALVAR`.
7. Confira lote, SL, TP, Magic, direção global e janela de sessão.
8. Habilite a negociação algorítmica.
9. Clique em `INICIAR`.
10. Acompanhe bloqueios e avisos pela aba `Status`.

O perfil inicial criado a partir dos `input` usa lote `0.10`. Esse valor não é universalmente seguro. Antes de iniciar, adapte o lote ao ativo e à conta; o mesmo volume pode representar exposições muito diferentes em WIN, XAUUSD, XAGUSD, índices, Forex ou cripto.

## 5. Cabeçalho da GUI 2.0

O cabeçalho fica acima das abas e é o mesmo em todas elas. Ele reúne o ativo, o timeframe do gráfico, o perfil em uso, o distintivo de estado e os três botões globais.

| Controle | Função |
|---|---|
| `INICIAR` | Libera novas entradas quando a configuração e o contexto permitem. Fica disponível também com posição aberta, para rearmar o EA sem esperar a operação fechar. |
| `PAUSAR` | Interrompe novas entradas. Só fica disponível sem posição ou reconciliação pendente. |
| `SALVAR` | Valida e grava as alterações do perfil carregado. |
| `CANCELAR` | Descarta o rascunho e restaura a última configuração confirmada. No editor de novo perfil, cancela aquele fluxo. |
| Nome do perfil | Mostra o perfil associado ao gráfico. Se aparecer `nome (sem arquivo)` em amarelo, veja a seção 5.5. |

### 5.1. Distintivo de estado e faixas de aviso

O distintivo à direita resume, em uma palavra, o que o EA está fazendo:

| Distintivo | Significado |
|---|---|
| `OPERANDO` | Armado, com posição em gerenciamento. |
| `RODANDO` | Armado, sem posição, aguardando sinal. |
| `PAUSADO` | Novas entradas suspensas. Posição aberta continua gerenciada. |
| `BLOQUEADO` | Bloqueio estrutural ou de contexto. Consulte `Status`. |
| `IMPEDIDO` | Sem permissão de negociação no MT5 ou na conta. |
| `SEM ENTRADAS` | Alguma proteção está impedindo entradas. |
| `CONFIGURACAO INVALIDA` | Há erro de configuração a corrigir antes de iniciar. |
| `SESSAO`, `NOTICIAS`, `LIMITE DIARIO`, `DRAWDOWN`, `SEQUENCIA`, `DD ATIVO`, `DD ATINGIDO` | Qual proteção está em curso. |

Abaixo do cabeçalho aparecem faixas que explicam o estado quando ele não é óbvio:

- `POSICAO ABERTA — a saida e pela estrategia ou pela protecao`: o EA está armado e a operação em curso sairá pela regra da estratégia dona ou por uma proteção;
- `POSICAO EM GERENCIAMENTO — clique INICIAR para liberar novas entradas futuras`: o EA está pausado, mas a posição continua administrada;
- `TRADING INDISPONIVEL` e `TRADING INDISPONIVEL COM POSICAO ABERTA`: falta permissão de negociação;
- na aba `Status`, o campo `Alerta` mostra `Sem alertas` ou o motivo do momento, por exemplo `ENTRADAS SUSPENSAS`.

### 5.2. Quando a configuração pode ser editada

A configuração só pode ser editada com o Fusion **pausado e sem posição gerenciada**. Alterações não salvas são um rascunho; trocar o timeframe do gráfico descarta esse rascunho e preserva apenas o estado confirmado.

`INICIAR` continua disponível com posição aberta. Editar configuração e rearmar o EA são coisas diferentes: a edição fica travada durante a operação, mas autorizar novas entradas não altera nada da configuração e por isso não depende dessa trava.

As preferências de **aparência** do painel (paleta, tema e tamanho do texto, na aba `Layout`) são exceção: valem para todos os gráficos, são aplicadas no ato e continuam disponíveis mesmo com a configuração bloqueada, porque não pertencem ao perfil.

### 5.3. Retomada após fechar o MetaTrader

Se você fechar o MetaTrader com o Fusion operando, ao reabrir ele volta como `INICIAR`, não como `OPERANDO`. Isso é intencional.

Uma posição que estava aberta **continua sendo gerenciada normalmente** — breakeven, trailing, TP parcial e fechamento por proteção seguem ativos independentemente de o EA estar armado. O que fica suspenso é apenas a abertura de **novas** entradas, até você clicar em `INICIAR`.

O motivo é que o EA não tem como saber por que o terminal foi fechado — encerramento planejado, queda de energia, atualização do Windows, travamento — nem há garantia de quanto tempo ficou fora. Retomar sozinho significaria voltar a assumir risco sem que ninguém tenha confirmado que o contexto ainda faz sentido.

Ao clicar `INICIAR`, o Fusion revalida permissão de negociação, conflito de perfil e registro de instância, e descarta sinais antigos para não entrar por um cruzamento que já estava valendo antes do reinício. Com posição aberta, o botão passa a exibir `OPERANDO`; sem posição, exibe `PAUSAR`.

Trocar o timeframe do gráfico é o único caso que preserva o estado operacional automaticamente, porque acontece dentro de uma sessão em andamento e leva segundos.

### 5.4. Qual perfil o gráfico usa ao reiniciar

Cada gráfico lembra qual perfil estava usando. Esse vínculo é preservado mesmo quando o estado operacional salvo é descartado — por exemplo após uma troca de conta, que faz o MetaTrader reiniciar o EA e desligar a negociação algorítmica.

O motivo é direto: perfis diferentes têm lote e Magic Number diferentes. Um perfil com lote `0.06` e outro com `6.00` são a mesma operação com cem vezes o risco. O Fusion nunca troca de perfil por conta própria.

O estado salvo do gráfico guarda uma cópia completa da configuração, e não apenas o nome do perfil. Por isso o EA continua com os valores certos mesmo que o arquivo do perfil seja apagado — veja a seção 5.5.

O bloqueio acontece num caso específico: quando o estado salvo **não pode ser aplicado** (arquivo corrompido, ou descartado por contexto) **e** o perfil que ele nomeia também não pode ser carregado. Aí o EA não tem de onde tirar a configuração correta e entra em `BLOQUEADO`, em vez de assumir outro perfil. Escolher um perfil na aba `Perfis` libera a operação.

O input `Perfil carregado/criado na inicializacao` define apenas o ponto de partida de um gráfico que ainda não tem estado próprio. Ele não substitui o perfil que o gráfico já estava usando.

Toda decisão de perfil na inicialização é registrada no log com `[PROFILE]`, incluindo o Magic e o lote ativos. Se algo diferente de uma restauração direta acontecer, a linha sai como aviso. Carregar um perfil pelo painel também é registrado. Confira essas linhas sempre que o gráfico reiniciar em circunstâncias fora do comum.

### 5.5. Perfil sem arquivo em disco

Se o arquivo `.cfg` do perfil ativo for apagado ou renomeado enquanto o EA roda, o cabeçalho passa a mostrar `nome (sem arquivo)` em amarelo e a aba `Status` exibe `PERFIL SEM ARQUIVO`.

Isso **não** é um erro operacional. O EA continua com a configuração correta, porque ela vem do estado salvo do gráfico, não do arquivo. O arquivo é o molde usado para carregar o perfil em outros gráficos; o estado do gráfico é o registro do que este gráfico está usando.

Duas saídas, conforme a intenção:

- clique `SALVAR` para recriar o arquivo a partir da configuração em uso;
- ou carregue outro perfil na aba `Perfis`, se a intenção era mesmo trocar.

O aviso existe porque, sem ele, o cabeçalho mostraria um perfil que não aparece na lista de perfis, sem nenhuma explicação.

## 6. Abas de acompanhamento

### 6.1. Status

Mostra:

- estado `RODANDO`, `PAUSADO` ou `BLOQUEADO`;
- ativo e contexto operacional;
- quantidade de estratégias e filtros ativos;
- existência e estratégia responsável pela posição;
- modo de conflito;
- aviso prioritário de contexto, permissão, risco, proteção, perfil, reversão ou entrada bloqueada.

`Status` é a referência principal para entender por que o EA não iniciou ou não abriu uma operação.

### 6.2. Resultados

Mostra os resultados do dia operacional:

- P/L bruto fechado;
- P/L bruto flutuante;
- P/L bruto projetado;
- trades, Loss, Win e BE do dia;
- streak atual;
- estado, pico/base, piso e folga do drawdown.

Os valores são P/L bruto de preço, construídos com `DEAL_PROFIT` e `POSITION_PROFIT`. Comissão, swap, fee, emolumentos e despesas externas não são estimados pelo Fusion.

Durante reconciliação de parcial, o valor fechado confirmado permanece visível e o projetado informa `RECONCILIANDO PARCIAL`.

## 7. Estratégias

A aba `Estratégias` tem quatro subabas: **`Geral`**, **`Médias`**, **`IFR / RSI`** e **`Bollinger`**.

`Geral` é um panorama somente-leitura de quais estratégias estão ligadas, mais o campo `Resolver Conflito`. Ligar e desligar cada estratégia é feito na subaba dela, junto dos parâmetros — decidir com os parâmetros fora de vista é decidir no escuro.

Pelo menos uma estratégia precisa permanecer ativa. Toda estratégia possui uma prioridade entre `0` e `1000`; números maiores têm precedência quando o resolvedor usa prioridade.

### 7.1. Campos comuns

**Timeframes disponíveis:** M1, M2, M3, M4, M5, M6, M10, M12, M15, M20, M30, H1, H2, H3, H4, H6, H8, H12, D1, W1 e MN1.

**Preços aplicados:** Close, Open, High, Low, Median, Typical e Weighted.

**Métodos de média:** SMA, EMA, SMMA e LWMA.

**Saídas comuns:**

- `TP/SL`: a estratégia não fecha por sinal. SL/TP, parciais, BE, trailing e proteções globais continuam válidos.
- `Sinal Oposto`: fecha quando a estratégia dona produzir sinal contrário. SL/TP e proteções continuam válidos.
- `Virar Mão (VM)`: fecha pelo sinal contrário e, depois da confirmação do fechamento, agenda entrada direta no lado oposto.

Na VM, a reversão não passa novamente pelos filtros, resolvedor de entrada nem direção global. Ela ainda exige Fusion iniciado e respeita permissão de trade, conflito netting, proteções globais, risco e execução. A condição aparece em `Status`.

### 7.2. MA Cross

Configurações:

| Campo | Descrição |
|---|---|
| `ON/OFF` | Ativa a estratégia. |
| `Prioridade` | `0..1000`. Default `10`. |
| `Média Rápida` | Período, timeframe, método e preço próprios. Default EMA 9, M15, Close. |
| `Média Lenta` | Período, timeframe, método e preço próprios. Default EMA 21, M15, Close. |
| `Dist. Min` | Distância mínima entre as médias no candle do cruzamento, em pontos. `0` desliga. |
| `Entrada` | `Candle seguinte` ou `2º Candle (E2C)`. |
| `Saída` | TP/SL, Sinal Oposto ou VM. |

Regras em candles fechados:

- BUY: diferença rápida-lenta passa estritamente de negativa em `[2]` para positiva em `[1]`.
- SELL: diferença rápida-lenta passa estritamente de positiva em `[2]` para negativa em `[1]`.
- Igualdade não caracteriza cruzamento.
- Se `Dist. Min > 0`, a distância no candle `[1]` precisa atingir o mínimo.

`Candle seguinte` libera o sinal no primeiro candle após o cruzamento confirmado. `2º Candle (E2C)` aguarda mais um candle operacional antes de liberar o mesmo sentido.

A validade da configuração das duas médias é decidida pelo **horizonte efetivo** de cada uma (`período × duração do timeframe`), não pelo período isolado. A MA rápida deve ter horizonte menor que o da lenta. Horizontes iguais são aceitos desde que as curvas difiram em pelo menos um campo — período, timeframe, método ou preço aplicado; por exemplo, `SMA 9` contra `EMA 9` no mesmo timeframe, ou `EMA 10 M1` contra `EMA 5 M2`. É rejeitada apenas a configuração em que os quatro campos coincidem, porque aí as duas curvas são a mesma linha e não existe cruzamento possível. Os períodos continuam entre `1` e `1000`. Quando os timeframes diferem, a MA rápida é o relógio da estratégia e cada valor da lenta é alinhado à última barra lenta que já estava fechada no fechamento da barra rápida correspondente.

**A mesma validação vale na tela e no motor.** A GUI recusa salvar uma configuração inválida, apontando a causa: `MA Rapida e MA Lenta precisam diferir em periodo, timeframe, metodo ou preco` ou `Horizonte da MA Rapida nao pode ser maior que o da MA Lenta (periodo x TF)`. Se mesmo assim uma configuração inválida alcançar o motor — por `input`, por um perfil salvo em versão anterior ou por outro caminho que contorne a tela —, a MA Cross **suspende as próprias entradas** e registra uma linha no log. O EA, o painel, as demais estratégias, os filtros, as proteções e o gerenciamento da posição aberta seguem funcionando normalmente; corrigida a configuração, a estratégia volta sozinha.

> ⚠️ **Exceção a registrar.** Se o EA **iniciar** já com configuração inválida da MA Cross, ele nunca chegou a criar um par de médias ativo, e nesse caso a **saída por cruzamento** fica indisponível até a correção. SL, TP, trailing, breakeven e TP parcial continuam funcionando. Quando a configuração era válida e só depois ficou inválida, o par que estava em uso é preservado e a saída por cruzamento continua sendo avaliada pelas médias com que a posição foi montada.

### 7.3. RSI

Configurações:

| Campo | Descrição |
|---|---|
| `ON/OFF` | Ativa a estratégia. |
| `Prioridade` | `0..1000`. Default `8`. |
| `Período` | `1..1000`. Default `14`. |
| `Timeframe` | Timeframe operacional. Default M15. |
| `Sobrevenda` | Nível `0..100`. Default `30`. |
| `Sobrecompra` | Nível `0..100`. Default `70`; deve superar Sobrevenda. |
| `Linha média` | Nível `0..100`. Default `50`. |
| `Preço` | Preço aplicado ao RSI. Default Close. |
| `Modo` | Saída da Zona, Dentro da Zona ou Cruz. Média. |
| `Saída` | TP/SL, Sinal Oposto, VM ou Cruz. Média. |

Modos de entrada, usando RSI fechado `[1]` e anterior `[2]`:

- `Saída da Zona`: BUY quando `[2] <= sobrevenda` e `[1] > sobrevenda`; SELL quando `[2] >= sobrecompra` e `[1] < sobrecompra`.
- `Dentro da Zona`: BUY enquanto `[1] <= sobrevenda`; SELL enquanto `[1] >= sobrecompra`. Pode gerar um novo sinal em cada candle fechado que permaneça no extremo.
- `Cruz. Média`: BUY quando `[2] < média` e `[1] >= média`; SELL quando `[2] > média` e `[1] <= média`.

Saída `Cruz. Média`:

- compra fecha quando RSI fechado alcança ou supera a média;
- venda fecha quando RSI fechado alcança ou fica abaixo da média.

Entrada `Cruz. Média` combinada com saída `Cruz. Média` é inválida, pois entrada e alvo usariam a mesma linha. Quando a saída pela média é usada com níveis de zona, a ordem obrigatória é `sobrevenda < média < sobrecompra`.

### 7.4. Bollinger

Configurações:

| Campo | Descrição |
|---|---|
| `ON/OFF` | Ativa a estratégia. |
| `Prioridade` | `0..1000`. Default `6`. |
| `Período` | `1..1000`. Default `20`. |
| `Timeframe` | Timeframe operacional. Default M15. |
| `Desvio` | Maior que `0` e até `10`. Default `2.00`. |
| `Preço` | Preço aplicado às bandas. Default Close. |
| `Modo` | FFFD, Toque/Rejeição ou Rompimento. |
| `Saída` | TP/SL, Sinal Oposto ou VM. |

Modos em candles fechados:

- `FFFD`: BUY quando o candle `[2]` fechou abaixo da banda inferior e `[1]` fechou novamente dentro; SELL no movimento simétrico da banda superior.
- `Toque/Rejeição`: BUY quando a mínima `[1]` toca/fura a banda inferior e o fechamento fica acima dela; SELL quando a máxima toca/fura a superior e fecha abaixo.
- `Rompimento`: BUY quando o fechamento `[1]` fica acima da banda superior; SELL quando fica abaixo da inferior. Pode repetir sinal em novos candles que continuem fechando fora.

## 8. Resolução de sinais e direção global

Quando mais de uma estratégia sinaliza no mesmo ciclo:

- `PRIORIDADE`: escolhe o maior número. Se estratégias empatadas na maior prioridade apontarem lados opostos, não há entrada.
- `CANCELAR`: sinais simultâneos em lados opostos cancelam a entrada; se todos apontarem o mesmo lado, a maior prioridade identifica a estratégia dona.

Depois da resolução, todos os filtros ativos precisam aprovar a decisão. Em seguida, a direção global permite `Ambas`, `Só Compra` ou `Só Venda`.

## 9. Filtros

A aba `Filtros` tem quatro subabas: **`Geral`**, **`Tendência`**, **`IFR / RSI`** e **`Bollinger`**. Como nas estratégias, `Geral` é panorama e o liga/desliga fica em cada subaba.

Filtros nunca abrem posições. Eles apenas aprovam ou bloqueiam uma entrada já escolhida. Se um filtro ativo não puder obter os dados necessários, a entrada é bloqueada de forma conservadora.

### 9.1. Trend Filter

Possui duas médias independentes:

| Campo | Descrição |
|---|---|
| `Média 1` | ON/OFF, período, timeframe, método e preço. Default SMA 50, M15, Close. |
| `Média 2` | ON/OFF, período, timeframe, método e preço. Default SMA 21, M15, Close. |

Cada média ativa funciona como barreira completa:

- BUY exige preço atual estritamente acima de todas as médias ON.
- SELL exige preço atual estritamente abaixo de todas as médias ON.
- Preço igual à média bloqueia os dois lados.

As duas médias são chamadas **`MA1`** e **`MA2`** na tela, na legenda do gráfico e nas mensagens. **`MA1` é a barreira longa e `MA2` a curta.** Com ambas ON, o horizonte efetivo da `MA1` (`período x duração do timeframe`) deve ser **estritamente maior** que o da `MA2` — horizontes iguais não servem aqui, porque as duas barreiras coincidiriam.

Essa regra é **estrita e independente da MA Cross**. Na MA Cross, horizontes iguais com curvas diferentes são válidos (seção 7.2); no Trend Filter, não. São propósitos diferentes: lá as curvas precisam se cruzar, aqui precisam ser duas barreiras distintas.

O filtro usa preço atual e valor atual da média, não candle fechado.

### 9.2. RSI Filter

Campos: ON/OFF, modo, período `1..1000`, timeframe, preço e um ou dois níveis entre `0` e `100`.

- `Direção`: BUY permitido com RSI fechado `>= Linha`; SELL permitido com RSI `<= Linha`. Na igualdade, ambos os lados passam por este filtro.
- `Neutro`: BUY somente com RSI `>= Compra`; SELL somente com RSI `<= Venda`. Exige `Venda < Compra`; a faixa intermediária bloqueia os dois lados.
- `Extremos`: bloqueia qualquer BUY ou SELL quando RSI `<= Sobrevenda` ou `>= Sobrecompra`. Exige `Sobrevenda < Sobrecompra`.

Ao trocar o modo pela GUI, os níveis sugeridos são: Direção `50`; Neutro `Compra 60/Venda 40`; Extremos `30/70`.

### 9.3. Bollinger Filter

É independente da estratégia Bollinger e funciona primeiro como anti-squeeze.

| Campo | Descrição |
|---|---|
| `Modo Absoluto` | Mede `banda superior - banda inferior` em pontos. |
| `Modo Relativo %` | Mede a largura como percentual absoluto da linha central. |
| `Período` | `1..1000`. Default `20`. |
| `Timeframe` | Default M15. |
| `Desvio` | Maior que `0` e até `10`. Default `2.00`. |
| `Preço` | Default Close. |
| `Min Pts` | `1..100000`, usado no modo Absoluto. Default `100`. |
| `Min %` | Maior que `0` e até `100`, usado no modo Relativo. Default `0.20`. |
| `Direção` | Opcional; filtra pelo sentido da linha central. |
| `Candles` | Lookback fechado `1..100`. Default `3`. |
| `Incl. mín.` | Tolerância `0..100000` pontos por candle. Default `0`. |

A largura é medida no candle fechado `[1]`. Valor abaixo do mínimo bloqueia; igualdade com o mínimo é permitida.

Com `Direção ON`, a inclinação média é:

```text
(linhaCentral[1] - linhaCentral[1 + Candles]) / Candles / point
```

- SELL é bloqueado quando a inclinação é maior que a tolerância positiva.
- BUY é bloqueado quando a inclinação é menor que a tolerância negativa.
- Inclinação horizontal ou dentro da tolerância permite os dois lados.

Quando o Bollinger Filter fica OFF, `Direção` e seus parâmetros ficam inativos. O valor ON/OFF salvo da Direção é preservado e volta a valer se o filtro principal for reativado.

## 10. Gestão > Risco

A aba `Gestão` tem duas subabas: **`Risco`** e **`Proteção`**. Cada uma abre um trilho lateral com os grupos de campos.

O trilho de `Risco` tem: `Lote`, `SL/TP`, `TP Parcial`, `BreakEven` e `Trailing`.

### 10.1. Lote

| Campo | Regra |
|---|---|
| `Lote Fixo` | Volume base das novas entradas. Deve ser positivo, respeitar mínimo, máximo e step do símbolo. |
| `Slippage (pts)` | Tolerância máxima enviada na requisição, entre `0` e `100000`. Não garante o preço de execução. |

### 10.2. SL/TP

| Campo | Regra |
|---|---|
| `SL Fixo` | Distância em pontos, `0..100000`; `0` desliga. |
| `TP Fixo` | Distância em pontos, `0..100000`; `0` desliga. |
| `Compensar Spread SL` | Soma o spread atual à distância do SL, aumentando o risco nominal. |
| `Compensar Spread TP` | Subtrai o spread atual da distância do TP, reduzindo o alvo nominal. Se o resultado não for positivo, a entrada é bloqueada. |

Antes de enviar a ordem, o Fusion recalcula os níveis com Bid/Ask atuais e valida lado correto, spread e `stopsLevel` da corretora. Um valor aceito visualmente pode ser bloqueado no momento da entrada se o mercado tornar o nível incompatível.

### 10.3. TP Parcial

| Campo | Regra |
|---|---|
| `TP1 Ativo` | Liga o sistema de parcial. |
| `TP1 Volume %` | Maior que `0` e até `100`. |
| `TP1 Dist pts` | Maior que `0`. |
| `TP2 Ativo` | Só pode funcionar com TP1 ativo. |
| `TP2 Volume %` | Maior que `0` e até `100`. |
| `TP2 Dist pts` | Maior que `0`. |
| `TP Final Livre` | Depois do último parcial, remove o TP final e deixa o restante sob trailing. Exige TP1 e trailing ativos. |

A soma dos percentuais ativos não pode exceder `100%`. O plano também precisa gerar volumes válidos segundo mínimo e step do símbolo e deixar volume remanescente operável.

O preço usa Bid para compra e Ask para venda. O parcial só é considerado executado depois da confirmação pelo histórico; uma aceitação de requisição não credita lucro estimado.

### 10.4. BreakEven

| Campo | Regra |
|---|---|
| `Ativo` | Liga o BE. |
| `Gatilho` | Lucro em pontos necessário; `1..100000`. |
| `Offset` | Distância a favor além da entrada; `0..100000` e não maior que o gatilho. |

Offset zero move o SL para a entrada. O BE não piora um SL que já esteja mais protegido.

### 10.5. Trailing

| Campo | Regra |
|---|---|
| `Ativo` | Liga o trailing. |
| `Início` | Lucro em pontos necessário; `1..100000`. |
| `Passo` | Distância entre o preço atual e o novo SL; `1..100000`. |

`Passo` não é o incremento mínimo entre modificações. O trailing só melhora o SL. Modificações de BE, trailing e TP Final Livre aguardam quando `freezeLevel` ou `stopsLevel` impedirem a alteração.

## 11. Gestão > Proteção

O trilho de `Proteção` tem: `Geral`, `Spread/Lado`, `Sessão`, `Notícias`, `Limites Diários`, `Drawdown` e `Sequências`.

### 11.1. Geral

Resumo dos estados de Entrada, Sessão, News, DAY, DD e Streak.

### 11.2. Spread/Lado

| Campo | Regra |
|---|---|
| `Max Spread` | Quando ON, bloqueia entrada se o spread atual superar o limite positivo em pontos. Não força fechamento. |
| `Direção` | `Ambas`, `Só Compra` ou `Só Venda`. Aplica-se às entradas normais; VM direta é exceção documentada. |

### 11.3. Sessão

| Campo | Regra |
|---|---|
| `Ativo` | Restringe entradas à janela. |
| `Início/Fim` | Horário do servidor, com início inclusivo e fim exclusivo. |
| `Fechar no fim` | Fora da janela, força fechamento da posição. |
| `Overnight` | Permite janela que cruza meia-noite; nesse modo, Início deve ser posterior ao Fim. |

Sem Overnight, o Fim deve ser posterior ao Início.

### 11.4. Notícias

Existem três janelas manuais independentes. O Fusion não consulta calendário econômico nem notícias externas.

Para cada janela:

- `Ativo`: habilita a janela;
- `Início/Fim`: horário do servidor; Fim deve ser posterior ao Início;
- `BLOQUEAR`: impede novas entradas durante a janela;
- `FECHAR+BLOQ`: força fechamento e bloqueia novas entradas.

As janelas de News não possuem modo Overnight.

### 11.5. Limites Diários

| Campo | Regra |
|---|---|
| `Ativo` | Liga os limites diários. |
| `Max Trades` | `0` desliga; ao atingir, bloqueia novas entradas, mas não fecha posição apenas por esse limite. |
| `Max Perda` | `0` desliga; considera P/L bruto fechado e projetado. Pode forçar fechamento. |
| `Max Ganho` | `0` desliga; considera P/L bruto fechado e projetado. |
| `Ação Parar` | Atingir Max Ganho fecha/bloqueia pela regra diária. |
| `Ação Ativar DD` | Atingir Max Ganho arma o drawdown, sem encerrar imediatamente. |

Contadores e P/L persistem no estado do gráfico e são auditados contra o histórico. Eles resetam no novo dia do servidor.

### 11.6. Drawdown

O DD protege lucro diário depois que `Max Ganho` é atingido. Para ficar ON, exige simultaneamente:

- DAY ON;
- Max Ganho maior que zero;
- ação `ATIVAR DD`;
- Max DD maior que zero.

Tipos:

- `Financeiro`: o limite é um valor de P/L bruto.
- `Percentual`: o limite é um percentual da base, maior que `0` e até `100`.

Bases:

- `Meta Max.Ganho`: usa o Max Ganho configurado como base fixa.
- `Pico Ganho`: acompanha o maior P/L bruto projetado depois da ativação.

O piso é `base - limite`. Assim que o DD é ativado, sua configuração fica travada até o novo dia, mas novas entradas continuam permitidas enquanto o piso não for violado. Ao atingir o limite, a posição é forçada a fechar e novas entradas ficam bloqueadas.

### 11.7. Sequências

Loss e Win são independentes:

| Campo | Regra |
|---|---|
| `Ativo` | Habilita o lado correspondente. |
| `Max Loss/Max Win` | Inteiro maior que zero quando ativo. |
| `Pausar` | Bloqueia novas entradas pelo número de minutos configurado. |
| `Parar dia` | Bloqueia novas entradas até o próximo dia. |
| `Pausa min` | Inteiro maior que zero quando a ação for Pausar. |

Streak é atualizado depois do fechamento completo da posição, usando o P/L total. Win zera Loss; Loss zera Win. Um fechamento exatamente em zero não incrementa nem zera as sequências atuais. Streak não força o fechamento de uma posição aberta.

## 12. Magic, conflito e diagnóstico

Na GUI 2.0 estes três itens **não moram mais numa aba de sistema**. Cada um foi para o lugar onde é lido junto do que ele afeta:

| Campo | Onde fica | Descrição |
|---|---|---|
| `Magic Number` | aba `Perfis`, ao lado do nome | Inteiro positivo que identifica as operações e o perfil. Deve ser único entre perfis salvos. |
| `Resolver Conflito` | `Estratégias > Geral` | Alterna entre `PRIORIDADE` e `CANCELAR`. É uma regra **entre** estratégias, e por isso fica ao lado de quais estão ligadas. |
| Logs detalhados de debug | apenas nos `input` do EA (F7) | Acrescenta registros detalhados; use somente em diagnóstico. Não pertence ao perfil: é uma escolha da sessão. |

*(Na nomenclatura histórica das versões 1.x, os três ficavam em `CONFIG > SYSTEM`.)*

O Fusion usa dois bloqueios complementares:

- o mesmo perfil não pode ficar carregado em dois gráficos;
- o mesmo Magic não pode identificar duas instâncias operacionais.

## 13. Layout

A aba `Layout` tem duas naturezas, e a divisão decide o comportamento:

- **Indicadores visuais** são configuração do **perfil**: entram no rascunho e passam por `SALVAR`;
- **Aparência do painel** (`Paleta`, `Tema`, `Tamanho do texto`) é preferência de quem opera: vale para todo gráfico, é aplicada no ato, não entra no perfil e não cria pendência. Por isso continua disponível mesmo com a configuração bloqueada.

*(Na nomenclatura histórica das versões 1.x, estes controles ficavam em `CONFIG > VISUAL`.)*

`Indicadores no Gráfico` liga uma camada estritamente visual. Ela não altera sinais, filtros nem execução.

É possível escolher cor e estilo para:

- MA rápida;
- MA lenta;
- Trend MA1;
- Trend MA2;
- bandas de Bollinger.

Estilos: Cheia, Tracejada e Pontilhada. A paleta percorre lime, verde-escuro, vermelho, vermelho-escuro, magenta, azul, azul-marinho, amarelo, gold, ciano, laranja e branco.

Regras visuais:

- uma curva só é desenhada quando seu timeframe coincide com o timeframe atual do gráfico;
- configurações idênticas são deduplicadas;
- RSI de estratégia e filtro pode compartilhar a mesma subjanela e reunir níveis;
- a legenda das médias informa OFF, outro TF, aguardando ou ativa;
- os handles visuais são separados dos handles operacionais.

## 14. Perfis

### 14.1. Ações

| Ação | Função |
|---|---|
| `Atualizar lista` | Relê os arquivos disponíveis. |
| `NOVO` | Cria um perfil a partir do rascunho atual, exigindo novo nome e Magic livre. |
| `CARREGAR` | Carrega o perfil selecionado. |
| `DUPLICAR` | Cria uma cópia com novo nome e Magic livre. |
| `EXCLUIR` | Remove perfil que não seja default, ativo ou bloqueado por outro gráfico. |

Espaços e caracteres inválidos de arquivo no nome são substituídos por `_`.

### 14.2. Perfil default e inputs

Em conta real/demo:

- se o perfil indicado por `inp_DefaultProfileName` existir e for válido, ele prevalece sobre os demais inputs operacionais;
- se não existir, o Fusion cria esse perfil com os inputs atuais;
- se existir mas estiver inválido/incompleto, a configuração corrente é preservada e a GUI avisa.

No Strategy Tester, os `input` são a fonte principal e o EA inicia automaticamente para permitir backtest/otimização.

### 14.3. Localização

Perfis:

```text
Arquivo > Abrir Pasta de Dados > MQL5 > Files > Fusion > Profiles
```

Estado automático por gráfico:

```text
MQL5 > Files > Fusion > ChartState
```

Perfil e chart state são conceitos diferentes. O perfil guarda configuração; o chart state guarda contexto e runtime necessário para restauração segura. As gravações usam arquivo temporário e promoção atômica.

## 15. Reinício, troca de timeframe e troca de ativo

- Anexar, recompilar ou reiniciar em conta real/demo volta com novas entradas pausadas.
- Uma posição restaurada continua sendo gerenciada.
- Estado truncado, incompatível ou incompleto é rejeitado integralmente; o Fusion tenta ressincronizar posição e histórico de forma conservadora.
- Trocar o símbolo do gráfico provoca bloqueio seguro; volte ao ativo anterior para recuperar o contexto.

### 15.1. Troca do timeframe do gráfico

Quatro fatos, e só estes:

1. **Os timeframes operacionais não mudam.** Nenhuma estratégia e nenhum filtro passa a calcular em outro timeframe por causa disso.
2. **O estado confirmado pode ser restaurado**, inclusive o estado iniciado — a troca acontece dentro de uma sessão em andamento e leva segundos.
3. **Rascunhos não salvos são descartados.** Se havia alteração pendente na tela, ela não é salva nem aplicada, e o Fusion avisa explicitamente que foi descartada.
4. **Os estados de entrada anteriores são consumidos**, e o Fusion aguarda um sinal novo. Um cruzamento que já valia antes da troca não vira ordem depois dela.

O que muda de visível é apenas o desenho: curvas cujo timeframe não coincide com o novo timeframe do gráfico deixam de ser exibidas.

## 16. Diagnóstico e arquivos gerados

### 16.1. Journal/Experts

Use `Logs Debug ON` apenas quando precisar de detalhes adicionais. Bloqueios importantes também aparecem em `Status`.

### 16.2. CSV de requisições

Em conta demo/real, entrada, fechamento total e parcial são registrados em:

```text
MQL5 > Files > Fusion_trade_requests_<servidor>_<conta>_<ativo>_<magic>.csv
```

O CSV é diagnóstico e não participa das decisões. Modificações de SL/TP e testes no Strategy Tester não são gravados nesse arquivo.

## 17. Configuração default dos inputs

Resumo do primeiro perfil criado a partir dos inputs padrão:

- conflito por Prioridade e direção Ambas;
- lote `0.10`, slippage `20`, SL `200` e TP `400` pontos;
- MA Cross ON: EMA 9/21, M15, Close, Candle seguinte, Sinal Oposto;
- RSI e Bollinger Strategy OFF;
- todos os filtros e proteções OFF;
- indicadores visuais OFF;
- Magic `10001` e perfil `default`.

Esse conjunto é um default técnico, não uma recomendação de risco nem uma parametrização validada para qualquer ativo.

## 18. Referência completa dos inputs

### 18.1. Geral e painel

| Input | Default | Descrição |
|---|---:|---|
| `inp_MagicNumber` | `10001` | Magic do perfil/EA. |
| `inp_SlippagePoints` | `20` | Tolerância de execução em pontos. |
| `inp_EnableDebugLogs` | `false` | Logs detalhados. |
| `inp_ShowPanel` | `true` | Exibe a GUI **no Strategy Tester visual**. No gráfico ela aparece sempre, independentemente deste input — para liberar espaço, minimize o painel pela barra de título. |
| `inp_DefaultProfileName` | `default` | Perfil carregado ou criado na inicialização. |
| `inp_ConflictMode` | `CONFLICT_PRIORITY` | Prioridade ou cancelamento. |
| `inp_TradeDirection` | `DIRECTION_BOTH` | Ambas, somente BUY ou somente SELL. |

### 18.2. Proteção de entrada e sessão

| Input | Default | Descrição |
|---|---:|---|
| `inp_EnableSpreadProtection` | `false` | Liga Max Spread. |
| `inp_MaxSpreadPoints` | `0` | Limite em pontos; valor positivo também ativa a proteção ao carregar inputs. |
| `inp_EnableSessionFilter` | `false` | Liga a janela de sessão. |
| `inp_SessionStartHour` | `9` | Hora de início. |
| `inp_SessionStartMinute` | `0` | Minuto de início. |
| `inp_SessionEndHour` | `17` | Hora de fim. |
| `inp_SessionEndMinute` | `0` | Minuto de fim. |
| `inp_SessionOvernight` | `false` | Janela cruza meia-noite. |
| `inp_CloseOnSessionEnd` | `false` | Fecha fora da sessão. |

### 18.3. News 1, 2 e 3

As três janelas começam OFF e com `00:00` a `00:00`:

| Janela | Ativação | Início | Fim | Fechar posição |
|---|---|---|---|---|
| News 1 | `inp_EnableNewsWindow1=false` | `inp_News1StartHour=0`, `inp_News1StartMinute=0` | `inp_News1EndHour=0`, `inp_News1EndMinute=0` | `inp_News1ClosePositions=false` |
| News 2 | `inp_EnableNewsWindow2=false` | `inp_News2StartHour=0`, `inp_News2StartMinute=0` | `inp_News2EndHour=0`, `inp_News2EndMinute=0` | `inp_News2ClosePositions=false` |
| News 3 | `inp_EnableNewsWindow3=false` | `inp_News3StartHour=0`, `inp_News3StartMinute=0` | `inp_News3EndHour=0`, `inp_News3EndMinute=0` | `inp_News3ClosePositions=false` |

Em `inp_News1ClosePositions`, `inp_News2ClosePositions` e `inp_News3ClosePositions`, `false` apenas bloqueia entradas e `true` fecha a posição e bloqueia.

### 18.4. DAY, DD e Streak

| Input | Default | Descrição |
|---|---:|---|
| `inp_EnableDailyLimits` | `false` | Liga DAY. |
| `inp_MaxDailyTrades` | `0` | Limite de trades; zero desliga. |
| `inp_MaxDailyLoss` | `0.0` | Perda bruta máxima; zero desliga. |
| `inp_MaxDailyGain` | `0.0` | Meta bruta; zero desliga. |
| `inp_ProfitTargetAction` | `PROFIT_ACTION_PARAR` | Parar ou ativar DD. |
| `inp_EnableDrawdown` | `false` | Liga DD. |
| `inp_MaxDrawdown` | `0.0` | Limite financeiro ou percentual. |
| `inp_DrawdownType` | `DD_TIPO_FINANCEIRO` | Financeiro ou percentual. |
| `inp_DrawdownPeakMode` | `DD_PICO_FLUTUANTE` | Pico Ganho; a alternativa é Meta Max.Ganho. |
| `inp_EnableLossStreak` | `false` | Liga Loss Streak. |
| `inp_MaxLossStreak` | `0` | Limite de perdas. |
| `inp_LossStreakAction` | `STREAK_ACTION_PAUSE` | Pausar ou parar dia. |
| `inp_LossStreakPauseMinutes` | `30` | Minutos da pausa. |
| `inp_EnableWinStreak` | `false` | Liga Win Streak. |
| `inp_MaxWinStreak` | `0` | Limite de ganhos. |
| `inp_WinStreakAction` | `STREAK_ACTION_STOP_DAY` | Pausar ou parar dia. |
| `inp_WinStreakPauseMinutes` | `30` | Minutos da pausa. |

### 18.5. Risco global

| Input | Default | Descrição |
|---|---:|---|
| `inp_FixedLot` | `0.10` | Lote fixo. |
| `inp_FixedSLPoints` | `200` | SL em pontos; zero desliga. |
| `inp_FixedTPPoints` | `400` | TP em pontos; zero desliga. |
| `inp_CompensateSLSpread` | `false` | Soma spread à distância do SL. |
| `inp_CompensateTPSpread` | `false` | Subtrai spread da distância do TP. |
| `inp_EnableTP1` | `false` | Liga TP1 e o sistema parcial. |
| `inp_TP1Percent` | `50.0` | Percentual do TP1. |
| `inp_TP1DistancePoints` | `150` | Distância do TP1. |
| `inp_EnableTP2` | `false` | Liga TP2; depende de TP1. |
| `inp_TP2Percent` | `25.0` | Percentual do TP2. |
| `inp_TP2DistancePoints` | `300` | Distância do TP2. |
| `inp_FreeFinalTP` | `false` | Remove TP final depois do último parcial; depende de TP1 e trailing. |
| `inp_UseTrailing` | `false` | Liga trailing. |
| `inp_TrailingStartPoints` | `150` | Início do trailing. |
| `inp_TrailingStepPoints` | `80` | Distância do novo SL ao preço. |
| `inp_UseBreakeven` | `false` | Liga BE. |
| `inp_BreakevenTriggerPoints` | `120` | Gatilho do BE. |
| `inp_BreakevenOffsetPoints` | `10` | Offset do BE. |

### 18.6. MA Cross

| Input | Default |
|---|---:|
| `inp_UseMACross` | `true` |
| `inp_MACrossPriority` | `10` |
| `inp_MAFastPeriod` / `inp_MASlowPeriod` | `9` / `21` |
| `inp_MAMinDistancePoints` | `0` |
| `inp_MAFastTF` / `inp_MASlowTF` | `TIMEFRAME_M15` / `TIMEFRAME_M15` |
| `inp_MAFastMethod` / `inp_MASlowMethod` | `MODE_EMA` / `MODE_EMA` |
| `inp_MAFastPrice` / `inp_MASlowPrice` | `PRICE_CLOSE` / `PRICE_CLOSE` |
| `inp_MAEntryMode` | `ENTRY_NEXT_CANDLE` |
| `inp_MAExitMode` | `EXIT_OPPOSITE_SIGNAL` |

### 18.7. RSI Strategy

| Input | Default |
|---|---:|
| `inp_UseRSI` | `false` |
| `inp_RSIPriority` | `8` |
| `inp_RSIPeriod` | `14` |
| `inp_RSITF` | `TIMEFRAME_M15` |
| `inp_RSIOversold` / `inp_RSIOverbought` / `inp_RSIMiddle` | `30` / `70` / `50` |
| `inp_RSIMode` | `RSI_SIGNAL_CROSSOVER` |
| `inp_RSIPrice` | `PRICE_CLOSE` |
| `inp_RSIExitMode` | `RSI_EXIT_OPPOSITE_SIGNAL` |

### 18.8. Bollinger Strategy

| Input | Default |
|---|---:|
| `inp_UseBollinger` | `false` |
| `inp_BollingerPriority` | `6` |
| `inp_BollingerPeriod` | `20` |
| `inp_BollingerTF` | `TIMEFRAME_M15` |
| `inp_BollingerDeviation` | `2.0` |
| `inp_BollingerPrice` | `PRICE_CLOSE` |
| `inp_BollingerMode` | `BB_SIGNAL_REENTRY` (FFFD) |
| `inp_BollingerExitMode` | `EXIT_OPPOSITE_SIGNAL` |

### 18.9. Trend Filter

| Input | Default |
|---|---:|
| `inp_TrendMA1Enabled` | `false` |
| `inp_TrendMAPeriod` | `50` |
| `inp_TrendMATF` | `TIMEFRAME_M15` |
| `inp_TrendMAMethod` | `MODE_SMA` |
| `inp_TrendMAPrice` | `PRICE_CLOSE` |
| `inp_TrendMA2Enabled` | `false` |
| `inp_TrendSellMAPeriod` | `21` |
| `inp_TrendSellMATF` | `TIMEFRAME_M15` |
| `inp_TrendSellMAMethod` | `MODE_SMA` |
| `inp_TrendSellMAPrice` | `PRICE_CLOSE` |

### 18.10. RSI Filter

| Input | Default |
|---|---:|
| `inp_UseRSIFilter` | `false` |
| `inp_RSIFilterMode` | `RSI_FILTER_DIRECTION` |
| `inp_RSIFilterPeriod` | `14` |
| `inp_RSIFilterTF` | `TIMEFRAME_M15` |
| `inp_RSIFilterBuyMin` / `inp_RSIFilterSellMax` | `50` / `50` |
| `inp_RSIFilterPrice` | `PRICE_CLOSE` |

### 18.11. Bollinger Filter

| Input | Default |
|---|---:|
| `inp_UseBBFilter` | `false` |
| `inp_BBFilterMode` | `BB_FILTER_WIDTH_ABSOLUTE` |
| `inp_BBFilterPeriod` | `20` |
| `inp_BBFilterTF` | `TIMEFRAME_M15` |
| `inp_BBFilterDeviation` | `2.0` |
| `inp_BBFilterPrice` | `PRICE_CLOSE` |
| `inp_BBFilterMinWidthPoints` | `100` |
| `inp_BBFilterMinWidthPercent` | `0.20` |
| `inp_BBFilterSlopeDirection` | `false` |
| `inp_BBFilterSlopeLookback` | `3` |
| `inp_BBFilterMinSlopePoints` | `0` |

Os `input` do Tester não recebem todas as proteções visuais da GUI. Valores inválidos podem impedir handles, bloquear entradas ou invalidar o teste; configure-os com a mesma disciplina das faixas descritas neste manual.

# Registro Diagnostico de Execucao - Fusion 1.054

## Finalidade

Este registro existe para descobrir como as corretoras realmente respondem as requisicoes de trade do Fusion antes de implementar uma maquina de estados para `PLACED` e `DONE_PARTIAL`.

A coleta permite distinguir cenarios reais de riscos apenas teoricos. Ela registra o resultado bruto retornado pelo `OrderSend`, mas nao muda:

- a decisao de entrar ou sair;
- a interpretacao atual dos retcodes;
- o estado da posicao;
- os parciais;
- os sinais;
- a GUI.

## Eventos Registrados

Uma linha e gravada somente depois de uma requisicao efetiva de:

- `ENTRY`: entrada;
- `FULL_CLOSE`: fechamento total;
- `PARTIAL_CLOSE`: fechamento parcial.

Modificacoes de SL/TP nao entram nesta coleta para evitar volume excessivo causado por breakeven e trailing. O Strategy Tester tambem nao grava estes arquivos, pois o objetivo e observar respostas reais de contas demo ou reais.

## Localizacao

No MT5, abrir:

```text
Arquivo > Abrir Pasta de Dados > MQL5 > Files
```

O nome segue este formato:

```text
Fusion_trade_requests_<servidor>_<conta>_<ativo>_<magic>.csv
```

A separacao por servidor, conta, ativo e Magic evita que instancias operacionais diferentes disputem o mesmo arquivo. Cada requisicao e anexada, descarregada e fechada imediatamente.

## Campos Principais

O CSV usa ponto e virgula como separador e contem:

- horario do servidor e tipo do evento;
- conta, servidor, ativo e Magic;
- acao, tipo de ordem e modo de preenchimento;
- ticket da posicao;
- volume, preco, SL, TP e desvio solicitados;
- resultado booleano do `OrderSend` e erro local do terminal;
- `retcode`, nome resumido e comentario do servidor;
- order, deal, volume e preco executados;
- Bid, Ask, request ID e retcode externo.

Os nomes resumidos de retcode usados nesta coleta sao:

- `DONE`: requisicao concluida;
- `PLACED`: ordem colocada, sem afirmar que o deal ja foi concluido;
- `DONE_PARTIAL`: somente parte da requisicao foi concluida;
- `OTHER`: outro retcode, identificado pelo numero e comentario do servidor;
- `NO_RETCODE`: nenhum retcode foi devolvido.

## Procedimento De Coleta

1. Usar normalmente o EA em conta demo ou real.
2. Deixar os arquivos acumularem entradas, fechamentos e parciais por alguns dias.
3. Depois do periodo escolhido, enviar todos os arquivos `Fusion_trade_requests_*.csv` para analise conjunta.
4. Nao interpretar isoladamente `PLACED` como posicao confirmada nem `DONE_PARTIAL` como falha total.

Os arquivos crescem apenas quando o Fusion envia uma das tres requisicoes monitoradas. Eles podem ser copiados para analise enquanto o EA esta rodando, pois o arquivo permanece fechado entre as operacoes.

## Decisao Posterior

A maquina de estados somente deve ser desenhada depois da coleta:

- se aparecer apenas `DONE`, o risco pode continuar documentado e adiado;
- se aparecer `PLACED`, sera necessario acompanhar confirmacao, cancelamento ou expiracao;
- se aparecer `DONE_PARTIAL`, sera necessario reconciliar o volume realmente executado;
- rejeicoes recorrentes devem ser agrupadas por retcode, ativo e corretora.

O registro e observabilidade temporaria da 1.054. Ele nao e persistencia operacional nem fonte de verdade para DAY, DD, STREAK ou estado da posicao.

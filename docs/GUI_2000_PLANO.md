# Fusion 2.0 — Plano da nova GUI em canvas

Este documento e o ponto de partida da versao 2.0. Ele existe para que o projeto
nao dependa da memoria de uma conversa: tudo que foi decidido, medido ou
descoberto sobre a migracao da interface esta aqui.

A 1.058 fica congelada como a ultima versao da linha 1.x, e como referencia de
comparacao durante a transicao.

---

## 1. Por que 2.0

A mudanca nao quebra compatibilidade: formato de perfil, estado de grafico e toda
a logica operacional continuam identicos. O numero maior comunica outra coisa —
quem atualiza vai encontrar uma interface diferente. `1.x` e o EA funcional,
`2.0` e o EA moderno.

O painel atual usa objetos nativos do MetaTrader (`CAppDialog`, `CButton`,
`CLabel`, `CEdit`, `CPanel`). A 2.0 desenha a interface em `CCanvas`, mantendo
apenas os campos de digitacao como objetos nativos.

---

## 2. O que o prototipo provou

O arquivo `Prototype/FusionCanvasPrototype.mq5` e descartavel e nao faz parte do
EA. Ele foi anexado a um grafico real e respondeu:

| Pergunta | Resposta |
|---|---|
| O conceito visual sobrevive ao renderizador do terminal? | Sim. Cantos arredondados, pills, cartoes e faixas de severidade, usando so preenchimentos, circulos e texto. |
| `OBJ_EDIT` fica acima do canvas e aceita digitacao? | Sim. Valores digitados chegam por `CHARTEVENT_OBJECT_ENDEDIT`. |
| Alvo desenhado recebe clique? | Sim. Abas, subabas e toggles sao pixels; o clique chega por `CHARTEVENT_MOUSE_MOVE` e e resolvido por coordenada. |
| Arrastar e minimizar? | Sim, mas precisam ser implementados — ver secao 4. |

### Regras tecnicas confirmadas

- **Ordem de desenho e a ordem de criacao.** `OBJPROP_ZORDER` so roteia eventos de
  mouse. Os `OBJ_EDIT` devem ser criados **depois** do `OBJ_BITMAP_LABEL`.
  `CCanvas.Update()` reescreve os pixels do recurso sem recriar o objeto, entao a
  ordem se mantem; ainda assim o prototipo recria os campos a cada render, que e
  a garantia explicita.
- **A abordagem hibrida e o que as bibliotecas MQL5 maduras ja fazem.** O
  `CTextEdit` da serie *Graphical Interfaces* combina retangulo, icone, label e um
  `CEdit` nativo. Limite conhecido: 63 caracteres por campo, irrelevante para
  valores numericos.
- **`CCanvas` nao antialiasa.** Cantos arredondados sao suavizados a mao,
  misturando com a cor de fundo conhecida (`RoundRect` no prototipo).
- **`color` do MQL5 e BGR; o canvas trabalha em ARGB.** Converter explicitamente
  ao configurar objetos nativos, senao vermelho vira azul.

---

## 3. O tamanho real do trabalho

Medicao sobre a 1.058 (`UI/`, 14.469 linhas):

| Camada | Linhas | Destino |
|---|---|---|
| Desenho (cria e posiciona controles) | 1.608 | reescrever em canvas |
| Visibilidade (mostra/esconde) | 1.079 | **desaparece** — no canvas nao se esconde, se redesenha |
| Logica (validacao, draft, acesso, comandos) | 3.131 | **preservar** |

O restante sao definicoes de painel, subpaineis de estrategia/filtro, paginas e
widgets de campo.

**O achado que torna isso viavel:** a logica de validacao le direto dos campos de
edicao (`LiveEditText(m_cfgRiskLotEdit)` e similares, 26 ocorrencias). Como a
abordagem hibrida mantem os 34 campos como objetos nativos, esse codigo continua
funcionando sem alteracao.

Nao e reescrever 14 mil linhas. E trocar cerca de 2.700 de renderizacao e
preservar as 3.131 que contem as regras.

---

## 4. O que o `CAppDialog` dava de graca e agora e nosso

Custo que so apareceu ao anexar o prototipo a um grafico:

- **Arrastar** — captura de mouse mais supressao de `CHART_MOUSE_SCROLL` enquanto
  o cursor esta sobre o painel. Sem isso o grafico se move no lugar do painel. A
  configuracao original precisa ser restaurada ao sair e ao remover o EA.
- **Minimizar** — redimensionar o canvas e **destruir os campos de digitacao**; um
  `OBJ_EDIT` escondido continuaria aceitando clique.
- **Hit-testing** — abas, subabas e toggles nao sao objetos. Cada alvo desenhado
  precisa publicar sua caixa de clique no momento do desenho, para que alvo e
  pintura nao possam divergir.

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

E essa fronteira estreita que permite construir o painel novo ao lado e troca-lo
sem alterar o EA.

---

## 6. Plano de execucao

**Fase 1 — Renderizador completo com dados falsos.**
Todas as 6 abas e subabas desenhadas, com todos os estados visuais: erro,
desabilitado, bloqueado, perfil sem arquivo, posicao aberta. Avaliacao puramente
visual, risco zero. E onde mora o trabalho de design.

**Fase 2 — `CFusionCanvasPanel` com a mesma interface.**
Implementa os 8 metodos da secao 5. Os fragmentos de validacao, draft e acesso
sao incluidos praticamente como estao — sao fragmentos de corpo de classe.

**Fase 3 — Troca por interruptor.**
Um input escolhe qual painel construir. Os dois convivem, comparaveis no mesmo
grafico, com reversao imediata. **O EA nao muda uma linha.**

**Fase 4 — Remocao do painel antigo**, somente depois de confianca no novo.

A integracao acontece na fase 3, cedo e reversivel — nao no fim. Integrar tudo de
uma vez concentraria todos os problemas no pior momento.

---

## 7. Linguagem visual aprovada

Paleta, tipografia e layout estao no prototipo e foram validados em grafico claro
e escuro.

- Fontes: `Segoe UI` para interface, `Consolas` para numeros. Ambas ja existem no
  Windows — nao inventar fonte que o MetaTrader nao consiga renderizar.
- Dois temas completos, claro e escuro, com escolha automatica pela luminancia do
  fundo do grafico e alternador manual no cabecalho. A escolha manual desliga a
  automatica na sessao.
- Contorno de 1px no painel: sem ele, um painel escuro sobre grafico escuro perde
  a silhueta.
- No tema escuro, tons medios precisam ser mais claros do que a simetria com o
  tema claro sugeriria.
- Estado codificado em forma alem de texto: pills, cartao de destaque, blocos
  escaneaveis, faixa de severidade nos avisos.

### Regras de estado que o painel atual erra

- **Erro prevalece sobre selecao.** Uma subaba com problema continua vermelha
  quando aberta. Se a selecao apagasse o vermelho, o problema sumiria da tela
  justamente ao ir resolve-lo. O `ApplyRiskTabStyles` da 1.058 tem esse defeito.
- **Aba herda o erro das subabas.** Quem esta em `STATUS` precisa enxergar que
  existe problema em `CONFIG` sem abrir `CONFIG`.
- **Aviso cresce com o texto.** O painel da 1.058 tem tres `CLabel` fixos e corta
  em 174 caracteres — uma mensagem de 193 caracteres teve sua instrucao acionavel
  cortada em producao. No canvas a caixa e dimensionada pelo texto medido.

---

## 8. Licoes que devem sobreviver a esta versao

Erros cometidos durante a 1.058, encontrados pelo usuario testando:

1. **Nao escrever mensagem que instrui acao que a interface impede.** Aconteceu
   duas vezes: um bloqueio que desabilitava a aba `PERFIS` que a propria mensagem
   mandava abrir, e um aviso pedindo `SALVAR` que estava desabilitado. Ao escrever
   qualquer texto que instrui, verificar antes se o controle correspondente esta
   habilitado naquele estado.
2. **Todo bloqueio precisa de saida pela propria GUI.**
3. **Medir a mensagem contra o espaco disponivel** antes de escreve-la.
4. **Conferir o binario deployado** antes de interpretar um teste. Um `.ex5`
   desatualizado ja invalidou uma rodada inteira de testes.

---

## 9. Compilacao

A partir do MetaEditor `5.0.0.6061`, `#resource` exige que o arquivo resolva
dentro da arvore `MQL5`. Com o projeto fora dela, usar `build-linked.ps1`
(ver `README.md`). O gate continua sendo **0 errors, 0 warnings** nos 4 alvos.

# Índice da Documentação

## Vigente para a versão 2.000

- `ARCHITECTURE.md`: arquitetura técnica atual. A seção `UI` foi reescrita na Fase 4 da migração da GUI e descreve o painel em canvas.
- `DECISIONS.md`: decisões estruturais vigentes. ⚠️ A **decisão 15** está marcada como **superada** — ela descreve o isolamento por grupos de hit-test do painel clássico, que não existe mais.
- `SAFE_FILTER_EXPANSION_1056.md`: regras ainda vigentes de persistência e filtros direcionais entregues na 1.056.
- `PARTIAL_RECONCILIATION_1055.md`: invariantes vigentes da reconciliação de parciais.
- `TRADE_REQUEST_DIAGNOSTICS_1054.md`: coleta diagnóstica ainda presente.
- `CLOSURE_RECONCILIATION_PLAN_1054.md`: desenho implementado da reconciliação de fechamentos; a seção de validação preserva o estado histórico daquele checkpoint.

### A GUI 2.0

A 2.000 **preserva a arquitetura operacional da 1.058**, tendo a GUI como mudança principal — migrada da biblioteca `Controls` para desenho em `CCanvas` ao longo de quatro fases. Não é uma reescrita do motor: a distribuição medida na Fase 2 mostrou que a GUI antiga tinha 18.094 linhas contra ~11.000 de todo o resto, e o motor carrega dezenas de correções achadas em operação real.

⚠️ **Mas o motor compartilhado não ficou intocado.** A **auditoria da migração revelou vulnerabilidades** nele — os caminhos já eram alcançáveis pela GUI antiga; o que a migração fez foi encontrá-los, ao obrigar a reler cada regra para portá-la:

- **guarda de posição aberta no `UI_COMMAND_LOAD_PROFILE`**, com a leitura de posição sincronizada **antes** de decidir (o cache `m_positionState` pode estar atrasado). Sem ela, carregar um perfil com operação em gerenciamento trocava a configuração ativa — inclusive o `Magic`, que é como o EA reconhece as próprias ordens;
- **`UI_COMMAND_RESTORE_ACTIVE_PROFILE`**, verbo novo e aditivo: "voltar ao que eu já tinha" era indistinguível de "adotar outro perfil" e herdava recusas que existem só para o segundo caso;
- `debugLogs` saiu do arquivo de perfil e voltou a ser governado pelo `input`.

- `GUI_2000_PLANO.md`: o plano da migração — o porquê, as regras técnicas descobertas na prática, as dívidas aceitas (seção 6) e as lições (seção 8). **É a fonte; os demais são recortes.**
- `GUI_2000_FASE3_TESTES.md`: o roteiro de aceite do painel novo, **89 de 89 passos executados** (88 no encerramento da fase, mais o `H4` em 2026-08-17). Documento histórico — descreve o ambiente de dois `.ex5`, que a Fase 4 desfez.
- `GUI_2000_FASE3_PENDENTES.md`: fechamento da Fase 3.
- `GUI_2000_FASE4.md`: fechamento da Fase 4 — a remoção do painel clássico, e as pendências que atravessaram.

⚠️ **`USER_MANUAL.md` ainda descreve a GUI da 1.057, que o EA não constrói mais.** A organização das abas mudou na migração (a aba `CONFIG` deixou de existir; `Gestão` e `Layout` nasceram; o `Magic Number` foi para `Perfis`). O manual **precisa ser reescrito antes de a 2.000 ser apresentada como pronta para usuário**; enquanto o uso é interno, vale como referência do motor e das configurações, não da tela. O raciocínio de cada divergência está na seção 6 do `GUI_2000_PLANO.md`.

- `DOCUMENTATION_AUDIT_1057.md`: escopo e resultado da revisão documental da 1.057.

## Histórico de desenvolvimento

Estes arquivos preservam planos, auditorias e handoffs de versões anteriores. Itens marcados como próximos ou pendentes refletem o momento em que foram escritos e podem já ter sido entregues, substituídos ou descartados:

- `FUNCTIONAL_EXPANSION_PLAN_1052.md`;
- `GUI_CLEANUP_PLAN.md`;
- `NEXT_SESSION_HANDOFF_1050.md`;
- `NEXT_SESSION_HANDOFF_1053.md`;
- `NEXT_SESSION_HANDOFF_1054.md`;
- `DD_AUDIT_CHECKPOINT_1054.md`.

Em caso de dúvida sobre o produto atual, a ordem de autoridade é:

1. código da versão 2.000;
2. `ARCHITECTURE.md`, `DECISIONS.md` e `GUI_2000_PLANO.md`;
3. `CHANGELOG.md` na raiz;
4. `USER_MANUAL.md` — para motor e configurações, **não** para a tela, enquanto não for reescrito para a 2.0;
5. documentos históricos.

⚠️ **A regra que vale acima de todas: o código é a primeira autoridade, e texto que eu escrevo de cabeça sobre comportamento erra com frequência alta.** Rótulo, dica e nota explicativa saem do módulo correspondente, nunca da memória de quem escreve — é a lição mais reincidente da migração da GUI, e erro nesse tipo de texto é invisível para quem não conhece o sistema.

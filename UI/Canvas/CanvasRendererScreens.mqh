//+------------------------------------------------------------------+
//| CanvasRendererScreens.mqh                                         |
//| Fragmento do corpo de CFusionCanvasRenderer — navegacao, telas da |
//| Fase 1 com dados falsos e popups.                                 |
//|                                                                   |
//| Cada tela declara suas linhas; o construtor de formulario mede,   |
//| desenha e publica as caixas de clique. Os rotulos seguem o        |
//| vocabulario real da 1.058 para que densidade e comprimento de     |
//| texto sejam representativos do painel final.                      |
//+------------------------------------------------------------------+

//--- Navegacao -----------------------------------------------------
//--- Tres abas de nivel 1 tem nivel 2, e cada uma guarda a propria
//--- posicao: voltar a uma aba deve devolver onde o usuario estava.
bool HasLevel2(const int tab) { return (tab==2 || tab==3 || tab==FCV_TAB_GESTAO); }
int  Sub(void)                { return m_sub[m_tab]; }
//--- As duas subabas de Gestao tem trilho; nenhuma outra tela tem.
bool HasRail(void)            { return (m_tab==FCV_TAB_GESTAO); }
int  RailIdx(void)            { return m_railSel[Sub()]; }

int Level2Count(const int tab) { return (tab==FCV_TAB_GESTAO) ? 2 : 4; }

int Level2Names(const int tab,string &out[])
  {
   if(tab==2) { ArrayResize(out,4); string a[4]={"Geral","Medias","IFR / RSI","Bollinger"};    ArrayCopy(out,a); return 4; }
   if(tab==3) { ArrayResize(out,4); string a[4]={"Geral","Tendencia","IFR / RSI","Bollinger"}; ArrayCopy(out,a); return 4; }
   ArrayResize(out,2); string a[2]={"Risco","Protecao"}; ArrayCopy(out,a); return 2;
  }

//--- Identidade da tela: cada combinacao de abas tem um id proprio, e o
//--- estado dos controles vive indexado por ele. Sem isso um toggle de uma
//--- subaba reapareceria ligado em outra, que e a classe de erro que o
//--- plano manda evitar.
int ScreenId(void)
  {
   if(m_tab==0)              return FCV_SCREEN_STATUS;
   if(m_tab==1)              return FCV_SCREEN_RESULTS;
   if(m_tab==2)              return FCV_SCREEN_STRAT0 +m_sub[2];
   if(m_tab==3)              return FCV_SCREEN_FILTER0+m_sub[3];
   if(m_tab==FCV_TAB_PERFIS)
      return (m_profEdit==FCV_PROF_VIEW) ? FCV_SCREEN_PROFILES : FCV_SCREEN_PROFILE_EDIT;
   if(m_tab==FCV_TAB_VISUAL) return FCV_SCREEN_VISUAL;
   return (m_sub[FCV_TAB_GESTAO]==0) ? FCV_SCREEN_RISK0+m_railSel[0]
                                     : FCV_SCREEN_PROT0+m_railSel[1];
  }

int NextSlot(void)
  {
   int slot=m_screen*FCV_SLOT_MAX+m_slotSeq;
   if(m_slotSeq<FCV_SLOT_MAX-1) m_slotSeq++;
   if(slot<0 || slot>=FCV_SCREEN_MAX*FCV_SLOT_MAX) slot=0;
   return slot;
  }

//--- Zerados no inicio de cada passada: um contador herdado da tela anterior
//--- faz aparecer controle de outra subaba, em posicao velha.
void ResetControls(void)
  {
   m_editCount=0; m_toggleCount=0; m_comboCount=0; m_colorCount=0;
   m_btnCount=0;
   m_rowCount=0; m_slotSeq=0;
  }

//--- Aviso da tela: medido antes do conteudo para que a area util ja nasca
//--- com a altura certa. Medir depois faria o conteudo usar a altura do
//--- quadro anterior.
//--- Nao ha aviso de tela enquanto a validacao nao existir.
//---
//--- Ate a Etapa 2b esta funcao devolvia dois avisos FIXOS, herdados da Fase 1:
//--- um no Status e outro em Noticias, ambos anunciando que a janela 1 tinha
//--- horarios invertidos. Eram dados de demonstracao, e faziam sentido enquanto
//--- a tela mostrava valores inventados. Com Noticias lendo o rascunho real,
//--- passariam a ACUSAR UM ERRO QUE NAO EXISTE — e mandariam corrigir uma
//--- janela que esta correta.
//---
//--- O aviso volta na Etapa 2d, alimentado pela validacao, que e quem sabe se
//--- ha erro e onde. Ate la o silencio e a resposta honesta: a moldura de
//--- medida e desenho continua pronta (MeasureAlert/DrawAlert), so nao ha o que
//--- afirmar. Os bloqueios operacionais em curso ja se explicam dentro do
//--- proprio cartao da secao suspensa, com o texto que o EA informou.
bool ScreenAlert(string &title,string &body,int &sem)
  {
   //--- Preenchidos mesmo devolvendo false: quem chama declara as tres
   //--- variaveis sem valor e so as usa no true. Deixa-las intactas seria
   //--- correto e ainda assim renderia aviso de variavel nao inicializada — e o
   //--- portao exige zero avisos.
   title=""; body=""; sem=FCV_SEM_NEUTRAL;
   return false;
  }

void MeasureAlert(void)
  {
   string title,body; int sem;
   m_alertH=0;
   if(m_minimized || !ScreenAlert(title,body,sem)) return;
   int x1=FCV_PAD, x2=FCV_PANEL_W-FCV_PAD;
   int textX=x1+24, maxW=(x2-14)-textX;
   int lines=WrapText(textX,0,maxW,15,body,m_t.fg,FCV_FS_SM,false);
   m_alertH=16+4+lines*15+2*14;
  }

void DrawAlert(void)
  {
   string title,body; int sem;
   if(!ScreenAlert(title,body,sem)) return;
   AlertBottom(FCV_PAD,FCV_PANEL_W-FCV_PAD,m_ph-FCV_PAD,title,body,
               SemColor(sem),SemDim(sem),SemColor(sem));
  }

//+------------------------------------------------------------------+
//| Popups — desenhados por ultimo, e cada um suprime os campos       |
//| nativos que cobre.                                                |
//+------------------------------------------------------------------+
//--- Quantos itens a lista mostra de uma vez: no maximo a janela, e nunca
//--- mais do que a lista tem.
int ComboVisibleCount(const int n)
  { return (n<FCV_COMBO_WINDOW) ? n : FCV_COMBO_WINDOW; }

int ComboMaxScroll(const int n)
  {
   int max=n-ComboVisibleCount(n);
   return (max>0) ? max : 0;
  }

void ComboPopupBox(const int idx,int &x,int &y,int &w,int &h,int &n)
  {
   string items[];
   n=ComboItems(m_comboKind[idx],items);
   w=m_comboW[idx];
   h=ComboVisibleCount(n)*FCV_COMBO_ITEM_H+8;
   x=m_comboX[idx];
   y=m_comboY[idx]+FCV_EDIT_H+3;
   //--- abre para cima quando nao cabe embaixo; se nao couber dos dois lados,
   //--- encosta no topo da area util em vez de sair do painel
   if(y+h>m_ph-FCV_PAD)
     {
      int up=m_comboY[idx]-h-3;
      y=(up>=ContentTop()) ? up : ContentTop();
     }
  }

void DrawComboPopup(void)
  {
   if(m_comboOpen<0 || m_comboOpen>=m_comboCount) return;
   int x,y,w,h,n;
   ComboPopupBox(m_comboOpen,x,y,w,h,n);
   string items[];
   ComboItems(m_comboKind[m_comboOpen],items);
   int sel=(m_comboFid[m_comboOpen]!=FCV_FLD_NONE)
           ? FieldGetIndex(m_comboFid[m_comboOpen])
           : m_stCombo[m_comboSlot[m_comboOpen]];
   if(sel<0 || sel>=n) sel=0;

   int vis=ComboVisibleCount(n);
   int maxS=ComboMaxScroll(n);
   if(m_comboScroll>maxS) m_comboScroll=maxS;
   if(m_comboScroll<0)    m_comboScroll=0;

   PublishPopup(x,y,x+w,y+h);
   RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.acc,m_t.surface,m_t.ground);

   bool bar=(maxS>0);
   int textRight=bar ? w-14 : w-4;
   for(int k=0;k<vis;++k)
     {
      int i=m_comboScroll+k;
      if(i>=n) break;
      int iy=y+4+k*FCV_COMBO_ITEM_H;
      if(i==sel) RoundRect(x+4,iy,x+textRight,iy+FCV_COMBO_ITEM_H,FCV_RADIUS_SM,m_t.accd,m_t.surface);
      //--- mesma fonte do combo fechado: a lista aberta mostra as mesmas
      //--- palavras, e trocar de familia ao abrir seria uma quebra visivel
      Txt(x+12,iy+FCV_COMBO_ITEM_H/2,items[i],(i==sel)?m_t.accs:m_t.fg,
          FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
     }

   if(!bar) return;
   //--- barra de rolagem do proprio popup
   int tx=x+w-9, t1=y+5, t2=y+h-5;
   RoundRect(tx,t1,tx+4,t2,2,m_t.soft,m_t.surface);
   int track=t2-t1;
   int th=(int)MathMax(20,(double)track*vis/n);
   int ty=t1+(int)((double)(track-th)*m_comboScroll/maxS);
   RoundRect(tx,ty,tx+4,ty+th,2,m_t.faint,m_t.soft);
  }

//--- Y da celula dentro da grade, JA com o vao que separa a faixa das puras.
//--- Uma funcao so, usada pelo desenho e pelo hit-test: e a aritmetica que os
//--- dois precisam concordar, e foi divergencia desse tipo que ja escondeu as
//--- setas de Perfis atras dos botoes.
int SwatchCellY(const int row)
  { return row*FCV_SWATCH_CELL + ((row>=FCV_SWATCH_ROWS-1) ? FCV_SWATCH_GAP : 0); }

void ColorPopupBox(const int idx,int &x,int &y,int &w,int &h)
  {
   w=FCV_SWATCH_COLS*FCV_SWATCH_CELL+10;
   h=SwatchCellY(FCV_SWATCH_ROWS-1)+FCV_SWATCH_CELL+10;
   x=m_colorX[idx]+m_colorW[idx]-w;
   y=m_colorY[idx]+24;
   if(y+h>m_ph-FCV_PAD) y=m_colorY[idx]-h-2;
  }

void DrawColorPopup(void)
  {
   if(m_colorOpen<0 || m_colorOpen>=m_colorCount) return;
   int x,y,w,h;
   ColorPopupBox(m_colorOpen,x,y,w,h);
   //--- Qual celula esta marcada. Ligada a um campo, a marca sai da COR atual:
   //--- procura-se a celula que tem exatamente aquela cor, e nao havendo — cor
   //--- vinda de perfil antigo ou da lista da 1.058 — nenhuma e marcada.
   //--- Fingir uma aproximada faria a grade afirmar uma escolha que nao foi
   //--- feita, e o proximo SALVAR gravaria essa mentira.
   int fid=m_colorFid[m_colorOpen];
   int sel=-1;
   if(fid!=FCV_FLD_NONE)
     {
      uint cur=FieldGetColor(fid);
      for(int k=0;k<FCV_SWATCH_COUNT;++k)
         if(m_swatches[k]==cur) { sel=k; break; }
     }
   else sel=m_stColor[m_colorSlot[m_colorOpen]];

   PublishPopup(x,y,x+w,y+h);
   RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.acc,m_t.surface,m_t.ground);
   //--- Filete no vao: marca que a ultima faixa e outra categoria, e nao mais um
   //--- degrau da rampa.
   int sepY=y+5+SwatchCellY(FCV_SWATCH_ROWS-1)-FCV_SWATCH_GAP/2;
   HLine(x+8,x+w-8,sepY,m_t.line);

   for(int i=0;i<FCV_SWATCH_COUNT;++i)
     {
      int cxx=x+5+(i%FCV_SWATCH_COLS)*FCV_SWATCH_CELL;
      int cyy=y+5+SwatchCellY(i/FCV_SWATCH_COLS);
      RoundFrame(cxx+1,cyy+1,cxx+23,cyy+23,4,
                 (i==sel)?m_t.fg:m_t.line,m_swatches[i],m_t.surface);
     }
  }

//+------------------------------------------------------------------+
//| Telas de nivel 1 sem formulario                                   |
//+------------------------------------------------------------------+
//--- A linha de aviso da Sessao mostra o motivo mais grave que existir. A
//--- ordem e deliberada: o que impede de operar vem antes do que apenas
//--- suspende entradas, que vem antes de recado informativo. Mostrar o menos
//--- grave enquanto existe um pior seria esconder o que importa.
//--- A escada completa da 1.058 (UI/Pages/StatusPage.mqh), na mesma ordem.
//--- A ordem E a regra: o primeiro ramo que casar vence, entao inverter dois
//--- degraus faz o painel anunciar o problema menor e calar o maior.
//--- A versao anterior cobria 6 dos 14 casos e, nos outros 8, dizia
//--- "Sem alertas." durante bloqueio real — a pior mentira que esta tela pode
//--- contar.
bool StatusNotice(string &title,string &body,int &sem)
  {
   sem=FCV_SEM_WARN;
   if(m_snap.runtimeBlocked)
     { title="ATENCAO OPERACIONAL"; body=m_snap.runtimeBlockReason; sem=FCV_SEM_BAD; return true; }
   if(HasText(m_snap.startBlockedReason))
     { title="INICIO BLOQUEADO"; body=m_snap.startBlockedReason; return true; }
   //--- Logo apos os bloqueios que o EA informa, porque ele tambem impede
   //--- INICIAR — e um botao apagado sem motivo escrito e pior que o problema
   //--- que ele evita: manda procurar sem dizer onde.
   if(ActiveMagicConflicts())
     {
      title="MAGIC EM CONFLITO";
      body="O Magic do perfil ativo esta repetido em disco. E por ele que o EA "
           "reconhece as proprias ordens, entao operar assim e operar sem saber "
           "quais ordens sao suas. Resolva em Perfis antes de iniciar.";
      sem=FCV_SEM_BAD;
      return true;
     }
   if(HasText(m_snap.activeProfileBlockedReason))
     { title="PERFIL BLOQUEADO"; body=m_snap.activeProfileBlockedReason; return true; }
   if(m_snap.tradePermissionBlocked)
     { title="AUTOTRADING OFF"; body=m_snap.tradePermissionReason; return true; }
   if(m_snap.pendingReverseExit)
     {
      title="VIRADA DE MAO";
      body="VM armada: reversao direta sem filtros/direcao; guards operacionais ativos.";
      return true;
     }
   if(m_snap.activeProfileFileMissing)
     {
      title="PERFIL SEM ARQUIVO";
      body="Perfil "+m_snap.activeProfileName+" sem arquivo em disco. O EA segue com os "
           "valores do estado do grafico. Salve para recriar o arquivo.";
      return true;
     }
   if(m_snap.hasPosition && !m_snap.started)
     {
      title="ENTRADAS SUSPENSAS";
      body="Posicao aberta segue em gerenciamento. Clique INICIAR para liberar novas entradas futuras.";
      return true;
     }
   if(m_snap.entryBlockIsRiskStops)
     {
      title="RISCO SL/TP";
      body=m_snap.entryBlockReason+" "+m_snap.entryBlockDetail;
      sem=FCV_SEM_BAD; return true;
     }
   if(HasText(m_snap.entryBlockReason))
     { title="ENTRADA BLOQUEADA"; body=m_snap.entryBlockReason; return true; }
   if(m_snap.dailyLimitsBlocked)
     { title="LIMITE DIARIO"; body=m_snap.dailyLimitsBlockReason; return true; }
   if(m_snap.drawdownLimitReached)
     { title="DRAWDOWN"; body=m_snap.drawdownConfigLockReason; return true; }
   //--- Os dois filtros so falam quando estao ligados: anunciar bloqueio de
   //--- sessao com o filtro desligado seria acusar quem nao agiu.
   if(m_snap.settings.enableSessionFilter && m_snap.sessionProtectionBlocked)
     { title="SESSAO"; body=m_snap.sessionProtectionBlockReason; return true; }
   if(FusionHasEnabledNewsWindow(m_snap.settings) && m_snap.newsProtectionBlocked)
     { title="NEWS"; body=m_snap.newsProtectionBlockReason; return true; }
   if(HasText(m_snap.runtimeNotice))
     {
      title=m_snap.started ? "AVISO OPERACIONAL" : "AVISO DE CONTEXTO";
      body=m_snap.runtimeNotice; return true;
     }
   string tpsl=FusionTPSLExitZeroNotice(m_snap.settings);
   if(HasText(tpsl))
     { title="RISCO TP/SL"; body=tpsl; return true; }

   //--- Sem ponto final: o titulo vira SELO, e selo e rotulo, nao frase. Os
   //--- outros titulos da escada ("ENTRADA BLOQUEADA", "DRAWDOWN") tambem nao
   //--- tem. O corpo, esse sim, e frase e mantem a pontuacao.
   title="Sem alertas"; body="Contexto do grafico estavel."; sem=FCV_SEM_NEUTRAL;
   return false;
  }

void ScreenStatus(void)
  {
   int x1=m_fx1, x2=m_fx2, y=m_fy;

   RoundRect(x1,y,x2,y+56,FCV_RADIUS_CARD,m_t.surface,m_t.ground);
   Txt(x1+14,y+18,"ESTADO",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   //--- O estado grande usa a cor do proprio estado: e a primeira coisa que se
   //--- olha ao abrir o painel, e cor informa mais rapido que leitura.
   Txt(x1+14,y+38,RunStateText(),RunStateColor(),FCV_FONT_UI,FCV_FS_HERO,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   Txt(x2-14,y+18,"POSICAO",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
   Txt(x2-14,y+38,m_snap.hasPosition ? "Aberta" : "Nenhuma",
       m_snap.hasPosition ? m_t.fg : m_t.muted,
       FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
   y+=66;

   //--- Tres blocos, nao quatro: o TF operacional saiu daqui. Ele e um resumo
   //--- por estrategia ("MA M1/M5 | RSI M15") e nao cabe num bloco estreito —
   //--- foi para uma linha de largura inteira no cartao abaixo.
   string tk[3]={"ESTRATEGIAS","FILTROS","MAGIC"};
   string tv[3]={IntegerToString(m_snap.activeStrategies),
                 IntegerToString(m_snap.activeFilters),
                 IntegerToString(m_snap.magicNumber)};
   int tw=(x2-x1-16)/3;
   for(int i=0;i<3;++i)
     {
      int bx=x1+i*(tw+8);
      RoundRect(bx,y,bx+tw,y+54,FCV_RADIUS_CARD,m_t.surface,m_t.ground);
      Txt(bx+11,y+17,tk[i],m_t.faint,FCV_FONT_UI,FCV_FS_CAP,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
      //--- Os quatro blocos sao o mesmo componente e recebem o mesmo
      //--- tratamento. Antes dois saiam na fonte de interface e dois em
      //--- Consolas, em tamanhos diferentes — lado a lado, isso le como
      //--- desalinho. Todos sao valor de maquina, entao todos em Consolas,
      //--- que ainda tem digito de largura fixa: o numero muda de 1 para 10
      //--- sem o bloco inteiro se mexer.
      Txt(bx+11,y+37,tv[i],(i==1)?m_t.faint:m_t.fg,
          FCV_FONT_MONO,FCV_FS_LG,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
     }
   m_fy=y+54+FCV_CARD_GAP;

   //--- "Resultado do dia" e "Trades hoje" nao existem aqui: sao da aba
   //--- Resultados. Repetir numero em duas telas cria duas fontes da mesma
   //--- verdade, e uma delas fatalmente atrasa em relacao a outra.
   RowsReset();
   RowStatic("Ativo Operacional",m_snap.symbol);
   //--- Resumo dos timeframes de cada estrategia ligada. Sem estrategia
   //--- nenhuma o EA manda string vazia; travessao diz "nao ha", vazio parece
   //--- campo que nao carregou.
   RowStatic("TF Operacional",m_snap.timeframe=="" ? "—" : m_snap.timeframe);
   //--- Sem responsavel definido o campo mostra travessao, nao vazio: espaco em
   //--- branco parece falha de desenho, travessao diz "nao ha".
   RowStatic("Responsavel",m_snap.ownerStrategyName=="" ? "—" : m_snap.ownerStrategyName);
   RowStatic("Conflito",m_snap.conflictMode==CONFLICT_PRIORITY ? "PRIORIDADE" : "CANCELAR");
   //--- Titulo em selo colorido pela gravidade, corpo em nota. A 1.058 pinta os
   //--- dois com a cor do aviso; aqui a cor fica no selo, que e o que se le
   //--- primeiro, e o corpo permanece legivel.
   string ntTitle,ntBody; int ntSem;
   StatusNotice(ntTitle,ntBody,ntSem);
   RowBadge("Alerta",ntTitle,ntSem);
   RowNote (ntBody);
   Card("SESSAO");
  }

//--- Lucro colore pelo sinal, igual ao ResultColor da 1.058. O zero fica
//--- neutro de proposito: pintar zero de verde sugeriria ganho onde nao ha.
int ProfitSem(const double v)
  {
   if(v >  0.0000001) return FCV_SEM_GOOD;
   if(v < -0.0000001) return FCV_SEM_BAD;
   return FCV_SEM_NEUTRAL;
  }

void ScreenResults(void)
  {
   //--- Mapeamento e formatos conferidos contra UI/Pages/ResultsPage.mqh.
   //--- Ponto decimal, nao virgula: e o que a 1.058 mostra (DoubleToString).
   bool pend=m_snap.partialReconciliationPending;

   RowsReset();
   //--- Com parcial em reconciliacao o fechado ainda nao e final; a 1.058
   //--- marca "(confirmado)" na parte que ja fechou e pinta de atencao.
   RowStatic("P/L Bruto Fechado",
             DoubleToString(m_snap.dailyClosedProfit,2)+(pend ? " (confirmado)" : ""),
             pend ? FCV_SEM_WARN : ProfitSem(m_snap.dailyClosedProfit));
   RowStatic("P/L Bruto Flutuante",
             DoubleToString(m_snap.dailyFloatingProfit,2),
             ProfitSem(m_snap.dailyFloatingProfit));
   //--- O projetado nao existe enquanto a parcial nao reconcilia: mostrar um
   //--- numero ali seria mostrar um valor que vai mudar.
   RowStatic("P/L Bruto Projetado",
             pend ? "RECONCILIANDO PARCIAL" : DoubleToString(m_snap.dailyProjectedProfit,2),
             pend ? FCV_SEM_WARN : ProfitSem(m_snap.dailyProjectedProfit));
   Card("RESULTADO DO DIA");

   string trades=IntegerToString(m_snap.dailyTradeCount);
   if(m_snap.dailyOutcomeCountsKnown)
     {
      trades+=StringFormat(" (%d Loss / %d Win",m_snap.dailyLossCount,m_snap.dailyWinCount);
      if(m_snap.dailyBreakevenCount>0) trades+=StringFormat(" / %d BE",m_snap.dailyBreakevenCount);
      trades+=")";
     }
   //--- Streak desligada mostra OFF, nao zero: zero diria "nenhuma perda
   //--- seguida", quando na verdade ninguem esta contando.
   string ls=m_snap.settings.lossStreakEnabled ? IntegerToString(m_snap.lossStreak) : "OFF";
   string ws=m_snap.settings.winStreakEnabled  ? IntegerToString(m_snap.winStreak)  : "OFF";

   RowsReset();
   RowStatic("Trades do Dia",trades);
   RowStatic("Streak Loss/Win Atual","Loss "+ls+" | Win "+ws);
   Card("CONTAGEM");

   //--- Sem base de drawdown os numeros nao significam nada ainda: a 1.058
   //--- mostra "--" em vez de zeros que pareceriam medidos.
   //--- Mesma pergunta que Gestao > Protecao > Drawdown faz antes de mostrar os
   //--- numeros; uma funcao so, para as duas telas nao passarem a discordar
   //--- sobre quando o "--" vira valor.
   bool hasBase=DrawdownRuntimeKnown();
   //--- MESMA ordem do resumo em Gestao > Protecao > Geral: estado antes da
   //--- chave. As duas telas calculavam este estado com prioridades opostas —
   //--- aqui a chave vinha primeiro, la o runtime — e com DD desligado durante
   //--- uma protecao em curso uma dizia OFF e a outra ATIVO, no mesmo painel.
   //--- Vieram de dois arquivos da 1.058 que discordam entre si (ResultsPage e
   //--- SyncProtectionOverview); unificado no lado seguro, porque protecao em
   //--- vigor nao pode sumir da tela por causa de uma chave desligada depois.
   //--- Aqui a chave lida e a COMPROMETIDA (m_snap.settings): esta tela conta o
   //--- dia que o EA operou, nao o que esta sendo editado.
   string ddState = m_snap.drawdownLimitReached ? "ATINGIDO"
                    : (m_snap.drawdownProtectionActive ? "ATIVO"
                       : (!m_snap.settings.enableDrawdown ? "OFF" : "AGUARDANDO META"));
   int ddSem = m_snap.drawdownLimitReached ? FCV_SEM_BAD
               : (m_snap.settings.enableDrawdown ? FCV_SEM_GOOD : FCV_SEM_NEUTRAL);

   RowsReset();
   RowBadge ("Estado DD",ddState,ddSem);
   RowStatic("Pico / Piso DD",
             hasBase ? StringFormat("%.2f / %.2f",m_snap.drawdownPeakProfit,m_snap.drawdownFloorProfit)
                     : "--");
   //--- Folga zerada ou negativa e o aviso de que o bloqueio esta na porta.
   RowStatic("Folga DD",
             hasBase ? DoubleToString(m_snap.drawdownBufferProfit,2) : "--",
             (hasBase && m_snap.drawdownBufferProfit<=0.0) ? FCV_SEM_WARN : FCV_SEM_NEUTRAL);
   Card("DRAWDOWN");
  }

//+------------------------------------------------------------------+
//| Perfis. Nao e uma lista com botoes: e um formulario com modo.     |
//|                                                                   |
//| Em repouso mostra a lista e o Magic do perfil ativo. Em NOVO ou   |
//| DUPLICAR abre os campos de nome e Magic, o botao de acao troca de |
//| rotulo e aparece CANCELAR — que e a saida exigida pela regra de   |
//| que todo bloqueio precisa de caminho de volta pela propria GUI.   |
//+------------------------------------------------------------------+
void ScreenProfiles(void)
  {
   //--- A lista desce um respiro: encostada em ContentTop() a moldura perdia a
   //--- borda de cima para a faixa que o desenho repinta ao recortar o conteudo
   //--- rolavel, e os controles da primeira linha ficavam com o canto
   //--- exatamente sobre esse limite.
   int x1=m_fx1, x2=m_fx2, y=m_fy+FCV_PROF_TOP_PAD;
   //--- Tres colunas, medidas da DIREITA para a esquerda: acoes encostadas na
   //--- borda, setas de rolagem ao lado, e a lista ocupando o que sobra. A
   //--- coluna das setas e reservada SEMPRE, mesmo com poucos perfis — se ela
   //--- aparecesse so quando a lista transborda, a largura das linhas mudaria
   //--- ao criar um perfil.
   //---
   //--- Derivar as tres de x2 e nao somar deslocamentos a partir da lista: era
   //--- assim que as setas e os botoes de acao acabaram desenhados um sobre o
   //--- outro, o que aparecia como "sombra" nos botoes e sumia com as setas.
   int aw=FCV_PROF_ACT_W, navw=FCV_PROF_NAV_W;
   int ax  =ProfileActionsLeft();
   int navx=ProfileNavLeft();
   int lx2 =ProfileListRight();
   bool editing=(m_profEdit!=FCV_PROF_VIEW);

   //--- Lista real, enumerada por quem constroi o painel. Nao ha mais nomes
   //--- inventados aqui; se ela vier vazia, e porque nao ha perfil em disco.
   int activeIdx=ActiveProfileIndex();
   //--- O atalho de lista vazia vale so no modo de NAVEGACAO. Sem o !editing,
   //--- clicar em NOVO com a pasta vazia trocava o modo, redesenhava, caia neste
   //--- mesmo retorno e o formulario nunca aparecia — o unico botao oferecido
   //--- era tambem o unico que nao levava a lugar nenhum.
   if(m_profCount<=0 && !editing)
     {
      //--- Lista vazia ainda precisa das duas saidas: NOVO (que o proprio texto
      //--- manda usar) e Atualizar lista. A versao anterior devolvia antes de
      //--- desenhar qualquer botao — recomendava uma acao que nao estava na
      //--- tela — e engolia junto o aviso de arquivos ilegiveis, justamente o
      //--- caso em que a lista fica vazia sem a pasta estar vazia.
      PutButton(ax,y,aw,30,"NOVO",true,m_t.good,m_t.onGood,
                FCV_BTN_NEW,AccCanCreateProfile());
      PutButton(ax,y+34+14,aw,30,"Atualizar lista",false,m_t.acc,m_t.onAcc,
                FCV_BTN_PROFREFRESH,true);
      m_fy=y+FCV_PROF_ROWS*34+FCV_CARD_GAP;

      RowsReset();
      if(m_profSkipped>0)
        {
         RowNoteSem(IntegerToString(m_profSkipped)+
                    " arquivo(s) de perfil em disco nao puderam ser lidos.",FCV_SEM_BAD);
         RowNote("A pasta nao esta vazia: os arquivos existem, mas nenhum abriu.");
        }
      else
         RowNote("Nenhum perfil em disco. Use NOVO para criar o primeiro.");
      Card("PERFIS");
      return;
     }

   //--- Janela de FCV_PROF_ROWS linhas deslizando sobre a lista inteira. O
   //--- indice desenhado (r) e o indice real (i) sao coisas diferentes daqui
   //--- para baixo: confundi-los faria a selecao e o clique mirarem outro perfil
   //--- assim que a lista rolasse.
   ClampProfileOffset();
   //--- Moldura em volta da lista. Sem ela as linhas ficam soltas e leem-se como
   //--- seis botoes empilhados; com ela, como uma lista — que e o que sao.
   //--- Desenhada ANTES das linhas, e do tamanho FIXO da janela, para a borda
   //--- nao subir e descer conforme a quantidade de perfis.
   RoundFrame(x1-6,y-6,ProfileNavLeft()+FCV_PROF_NAV_W+6,y+FCV_PROF_ROWS*34+2,
              FCV_RADIUS_CARD,m_t.line,m_t.surface,m_t.surface);

   int shown=m_profCount-m_profOffset;
   if(shown>FCV_PROF_ROWS) shown=FCV_PROF_ROWS;
   for(int r=0;r<shown;++r)
     {
      int i=m_profOffset+r;
      int ry=y+r*34;
      bool sel=(i==m_profSel);
      //--- Durante a edicao a lista fica apagada: o que esta em jogo e o perfil
      //--- que esta sendo criado, e trocar de selecao no meio nao faria sentido.
      uint rowLine = editing ? m_t.soft : (sel ? m_t.acc : m_t.soft);
      uint rowFill = (sel && !editing) ? m_t.accd : m_t.ground;
      uint nameClr = editing ? m_t.disabled : m_t.fg;
      RoundFrame(x1,ry,lx2,ry+30,FCV_RADIUS_CTRL,rowLine,rowFill,m_t.surface);
      Txt(x1+11,ry+15,m_profName[i],nameClr,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);

      //--- O badge define o limite direito. Sem ele, o limite e a borda da
      //--- linha. Assim os numeros ficam numa coluna so, legiveis de cima a
      //--- baixo, em vez de flutuarem conforme o comprimento de cada nome.
      int metaRight=lx2-11;
      //--- O selo vai no perfil que o EA carregou, e nao no primeiro da lista.
      if(i==activeIdx)
        {
         int tw2=TxtW("ATIVO",FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD)+18;
         RoundRect(lx2-tw2-9,ry+7,lx2-9,ry+23,FCV_RADIUS_PILL,
                   editing?m_t.soft:m_t.gdim,rowFill);
         Txt(lx2-tw2/2-9,ry+15,"ATIVO",editing?m_t.disabled:m_t.good,
             FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
         metaRight=lx2-tw2-20;
        }
      //--- Magic e lote na mesma coluna. O lote sai de graca — o arquivo ja foi
      //--- aberto para ler o Magic — e evita o erro caro: carregar o perfil
      //--- errado dói na proporcao do lote dele.
      //--- As casas decimais vem do ativo do GRAFICO ATUAL, nao do ativo em que
      //--- aquele perfil costuma rodar; nao ha como saber o segundo daqui.
      //--- "lote" por extenso: sem a palavra, o segundo numero e so um numero.
      //--- O "#" ja diz que o primeiro e identificador; o volume nao tem simbolo
      //--- proprio que se reconheca sozinho.
      string meta="#"+IntegerToString(m_profMagic[i])+" · lote "+
                  FusionFormatVolume(m_profLot[i],m_snap.symbolSpec);
      //--- Magic repetido em vermelho, na propria linha: quem tem o problema e
      //--- o perfil, e apontar o culpado vale mais que descrever o sintoma.
      uint metaClr = editing ? m_t.disabled
                     : (m_profDup[i] ? m_t.bad : m_t.muted);
      Txt(metaRight,ry+15,meta,metaClr,
          FCV_FONT_MONO,FCV_FS_BODY,FCV_FW_NORMAL,TA_RIGHT|TA_VCENTER);
     }

   //--- Barra de rolagem: seta no topo, trilho no meio, seta no fim. E a forma
   //--- convencional, e ela diz o que duas setas coladas nao dizem — QUANTO de
   //--- lista existe e onde voce esta nela.
   bool canUp  =(!editing && m_profOffset>0);
   bool canDown=(!editing && m_profOffset<ProfileMaxOffset());
   int listH=FCV_PROF_ROWS*34-4;
   int navBtn=26;
   PutButton(navx,y,navw,navBtn,ShortToString(0x25B2),false,
             m_t.acc,m_t.onAcc,FCV_BTN_PROFUP,canUp);
   PutButton(navx,y+listH-navBtn,navw,navBtn,ShortToString(0x25BC),false,
             m_t.acc,m_t.onAcc,FCV_BTN_PROFDN,canDown);

   //--- Trilho e polegar. O polegar SE MOVE e tem tamanho proporcional: parado,
   //--- ele pareceria indicar posicao e mentiria — pior que nao existir. Nao
   //--- arrasta (ainda): as setas e a roda ja cobrem o movimento, e arrasto e
   //--- acrescimo, nao refacao.
   int trkY1=y+navBtn+4, trkY2=y+listH-navBtn-4;
   if(trkY2>trkY1)
     {
      RoundRect(navx+navw/2-3,trkY1,navx+navw/2+3,trkY2,3,m_t.inset,m_t.surface);
      if(m_profCount>FCV_PROF_ROWS)
        {
         int trkH=trkY2-trkY1;
         int thumbH=(trkH*FCV_PROF_ROWS)/m_profCount;
         if(thumbH<18) thumbH=18;
         int maxOff=ProfileMaxOffset();
         int thumbY=trkY1+((trkH-thumbH)*m_profOffset)/((maxOff>0)?maxOff:1);
         RoundRect(navx+navw/2-3,thumbY,navx+navw/2+3,thumbY+thumbH,3,
                   editing?m_t.disabled:m_t.muted,m_t.surface);
        }
     }

   //--- Cada acao acende conforme o que e possivel agora. Um unico preenchido:
   //--- em repouso o proximo passo e CARREGAR o selecionado; em edicao, SALVAR.
   bool isActive =(m_profSel>=0 && m_profSel==activeIdx);
   //--- Perfil com Magic repetido NAO CARREGA. Carrega-lo poria dois graficos
   //--- reconhecendo as mesmas ordens como suas, que e o estrago que o Magic
   //--- existe para impedir. Bloqueia os DOIS lados do conflito, nao um: nao ha
   //--- como saber qual deles e o "certo".
   bool selDup   =(m_profSel>=0 && m_profDup[m_profSel]);
   //--- Travas vindas dos registros do terminal: outro grafico rodando com este
   //--- Magic, ou ja usando este perfil. Sao conflito AO VIVO, diferente do
   //--- Magic repetido em disco — e a 1.058 usa as duas em BuildProfileActionState.
   bool selLocked=(m_selRuntimeLocked || m_selProfileLocked);
   bool canLoad  =(!editing && !isActive && !selDup && !selLocked && AccCanLoadProfile());
   //--- Nem o ativo nem o DEFAULT se apagam. A regra do default vinha faltando:
   //--- a 1.058 a aplica em BuildProfileActionState e o proprio painel avisa por
   //--- escrito ("Nao apague o perfil default"). Sem ela a 2.0 oferecia EXCLUIR
   //--- no perfil que o EA usa como base de tudo.
   bool isDefault=ProfileIsDefault(m_profSel);
   //--- ⚠ EXCLUIR e DUPLICAR seguem liberados em perfil conflitante, DE
   //--- PROPOSITO. Sao a saida do bloqueio: sem elas, um perfil com Magic
   //--- repetido nao carrega (regra acima) e o Magic so e editavel no perfil
   //--- ativo — entao o unico conserto seria mexer nos arquivos por fora, que e
   //--- exatamente como o problema apareceu. Com as duas, ha caminho pela
   //--- propria GUI: duplicar com outro Magic e apagar o antigo, ou apagar a
   //--- copia sobrando. E a regra de que todo bloqueio precisa de volta.
   bool canDelete=(!editing && !isActive && !isDefault && !selLocked && AccCanAdminProfile());
   //--- NOVO nao depende da selecao: cria do zero. DUPLICAR depende, e olha so a
   //--- trava de RUNTIME — nao a de perfil ativo em outro grafico. A assimetria
   //--- e da 1.058 e faz sentido: duplicar nao toca no original.
   bool canCreate=(!editing && AccCanCreateProfile());
   bool canDup   =(canCreate && !m_selRuntimeLocked);
   //--- Cada acao com a propria cor, como no painel 1.058: azul para as que
   //--- movem perfil, verde para criar, vermelho para destruir. A cor diz o
   //--- que a acao FAZ; estar habilitado diz se ela cabe agora.
   PutButton(ax,y+0*34,aw,30,"CARREGAR",true,m_t.acc, m_t.onAcc, FCV_BTN_LOAD,canLoad);
   PutButton(ax,y+1*34,aw,30,"NOVO",    true,m_t.good,m_t.onGood,FCV_BTN_NEW, canCreate);
   PutButton(ax,y+2*34,aw,30,"DUPLICAR",true,m_t.warn,m_t.onAcc, FCV_BTN_DUP, canDup);
   PutButton(ax,y+3*34,aw,30,"EXCLUIR", true,m_t.bad, m_t.onAcc, FCV_BTN_DEL, canDelete);
   //--- "Atualizar lista" sempre habilitado, como na 1.058: reler o disco nao
   //--- altera nada e e a unica forma de ver arquivo criado por fora com o
   //--- painel aberto. Nao depende de perfil selecionado nem de EA parado.
   //---
   //--- Afastado dos quatro acima e em caixa mista de proposito: os outros agem
   //--- SOBRE UM PERFIL e podem destruir; este so relê a pasta. Separar no
   //--- espaco e na grafia evita que ele seja lido como quinta acao de perfil.
   PutButton(ax,y+4*34+14,aw,30,"Atualizar lista",false,m_t.acc,m_t.onAcc,
             FCV_BTN_PROFREFRESH,!editing);

   m_fy=y+FCV_PROF_ROWS*34+FCV_CARD_GAP;   // y ja inclui o respiro do topo

   if(editing)
     {
      //--- Nome e Magic sao os dois campos que definem um perfil novo. O Magic
      //--- vem preenchido na duplicacao porque copiar exige troca-lo: dois
      //--- perfis com o mesmo Magic fariam o EA confundir as proprias ordens.
      //--- Os quatro criterios da 1.058, conferidos contra a lista ja lida:
      //--- nome preenchido, nome livre, Magic valido e Magic livre.
      bool nameBad=false, magicBad=false;
      string formError="";
      bool formReady=ProfileFormReady(nameBad,magicBad,formError);

      RowsReset();
      RowField("Nome","Como o perfil aparece na lista","",!nameBad);
      //--- O Magic da criacao ainda e local: ele nao pode escrever no rascunho,
      //--- que descreve o perfil ATIVO, e nao o que esta sendo criado. Quem o
      //--- transporta para o perfil novo e o comando de gravar, na Etapa 2c.
      RowField("Magic","Precisa ser diferente de todos os outros","",!magicBad);
      if(StringLen(formError)>0)
         RowNoteSem(formError,FCV_SEM_BAD);
      else
         RowNote (m_profEdit==FCV_PROF_DUP
                  ? "Copia de "+((m_profSel>=0) ? m_profName[m_profSel] : "")+
                    ". Ajuste o Magic e clique CRIAR COPIA."
                  : "Informe um nome e um Magic livre, e clique CRIAR PERFIL.");
      //--- Assimetria honesta com arquivo ilegivel: o NOME dele e conhecido pela
      //--- enumeracao e entra na conferencia; o MAGIC esta dentro do arquivo que
      //--- nao abriu, e portanto nao ha como conferir. Dizer isso e melhor que
      //--- deixar o usuario supor que a checagem cobre tudo — ou que bloquear a
      //--- criacao ate ele consertar um arquivo que a GUI nem sabe apagar.
      if(m_profSkipped>0)
         RowNoteSem(IntegerToString(m_profSkipped)+
                    " arquivo(s) ilegivel(is): o nome deles e respeitado, mas o "+
                    "Magic nao pode ser conferido enquanto nao abrirem.",FCV_SEM_WARN);
      Card(m_profEdit==FCV_PROF_DUP ? "DUPLICAR COMO" : "NOVO PERFIL");

      //--- Os rotulos nomeiam a acao, nao a categoria. "SALVAR" e "CANCELAR"
      //--- ja existem no cabecalho e significam outra coisa la — gravar
      //--- alteracoes do perfil ativo. Repetir a palavra faria o usuario
      //--- decidir qual dos dois e o certo em vez de simplesmente ler.
      int bw=(m_fx2-m_fx1-8)/2;
      //--- So acende com os quatro criterios satisfeitos. Antes acendia sempre,
      //--- e um botao que promete gravar sem ter o que gravar so descobre o
      //--- problema depois do clique.
      //--- Falta ainda o configInputsValid da 1.058 — a validade da configuracao
      //--- INTEIRA, que e a Etapa 2d. Por ora vale true, o que AFROUXA.
      PutButton(m_fx1,m_fy,bw,30,
                m_profEdit==FCV_PROF_DUP ? "CRIAR COPIA" : "CRIAR PERFIL",
                true,m_t.good,m_t.onGood,FCV_BTN_SAVE,formReady);
      PutButton(m_fx1+bw+8,m_fy,bw,30,"DESCARTAR",
                false,m_t.warn,m_t.onAcc,FCV_BTN_CANCEL,true);
      m_fy+=30+FCV_CARD_GAP;
      return;
     }

   //--- O Magic identifica o perfil, nao o sistema, e a lista acima ja mostra o
   //--- de cada um — por isso ele mora aqui e nao em Config.
   //---
   //--- Editavel SO quando o selecionado e o perfil ativo, e so com o EA
   //--- parado. A 1.058 nao tem comando para gravar um perfil sem carrega-lo,
   //--- entao um campo editavel sobre um perfil qualquer prometeria uma acao
   //--- que o EA nao sabe executar. Para trocar o Magic de outro: CARREGAR.
   //--- Ligado ao rascunho SO quando o selecionado e o ativo. Nos demais o
   //--- campo mostra o Magic gravado no arquivo daquele perfil (a lista acima
   //--- ja o leu) e nao aceita edicao — escrever ali mexeria no perfil ativo,
   //--- que nao e o que a tela esta mostrando.
   RowsReset();
   if(isActive)
     {
      RowFieldF("Magic Number","Identifica as ordens deste perfil no grafico",
                FCV_FLD_MAGIC);
      RowNote  ("Dois perfis nao podem dividir o mesmo Magic: e por ele que o EA reconhece as proprias ordens.");
     }
   else
     {
      RowField("Magic Number","Identifica as ordens deste perfil no grafico",
               (m_profSel>=0) ? IntegerToString(m_profMagic[m_profSel]) : "--",
               true,false);
      RowNote ("Somente o perfil ativo tem o Magic editavel, e so com o EA parado. Use CARREGAR para ativar o selecionado.");
     }
   if(isDefault)
      RowNote("Perfil default: ele e a base do EA e nao pode ser excluido.");
   //--- O aviso nomeia quem colide e diz o caminho de volta. Um alerta que so
   //--- acusa deixa o usuario preso: aqui CARREGAR esta desligado, e sem a
   //--- instrucao ele nao tem como adivinhar que a saida e DUPLICAR/EXCLUIR.
   //--- Trava ao vivo: o motivo vem do proprio registro, com o texto que o EA
   //--- usaria. Sem ele o botao apagaria sem dizer que a causa esta em OUTRO
   //--- grafico — coisa que nao se descobre olhando esta tela.
   if(selLocked)
      RowNoteSem(m_selLockReason,FCV_SEM_WARN);
   if(selDup)
     {
      RowNoteSem(DuplicateMagicNote(m_profSel),FCV_SEM_BAD);
      RowNoteSem("Por isso CARREGAR esta bloqueado nos dois. Para resolver: "
                 "DUPLICAR com outro Magic e EXCLUIR o antigo, ou apagar a copia sobrando.",
                 FCV_SEM_BAD);
     }
   //--- Arquivo de perfil que existe e nao abriu. Dizer que ele existe e o
   //--- minimo: sem isto a lista parece completa e o perfil que sumiu e
   //--- justamente o que esta com problema.
   if(m_profSkipped>0)
      RowNoteSem(IntegerToString(m_profSkipped)+
                 " arquivo(s) de perfil em disco nao puderam ser lidos e ficaram fora da lista.",
                 FCV_SEM_BAD);
   Card(isActive ? "PERFIL ATIVO" : "PERFIL SELECIONADO");
  }

//+------------------------------------------------------------------+
//| Estrategias                                                       |
//+------------------------------------------------------------------+
void ScreenStrategies(void)
  {
   int s=m_sub[2];
   if(s==0)
     {
      //--- As mesmas chaves aparecem aqui e no cabecalho de cada subaba. Ligadas
      //--- ao mesmo campo, andam juntas sem codigo de sincronizacao.
      //--- Somente leitura: o Geral e um panorama, nao um controle. Quem liga e
      //--- desliga e o "Ativo" de cada subaba, onde os parametros daquela
      //--- estrategia estao a vista — decidir com eles fora de campo e decidir
      //--- no escuro.
      RowsReset();
      RowState("MA Cross" ,FCV_FLD_USE_MACROSS);
      RowState("IFR / RSI",FCV_FLD_USE_RSI);
      RowState("Bollinger",FCV_FLD_USE_BB);
      RowNote ("Ligue ou desligue em cada subaba, junto dos parametros.");
      Card("ESTRATEGIAS");

      //--- Resolver Conflito mora aqui, e nao em Config > Sistema como na
      //--- 1.058: e uma regra entre estrategias, e le-se junto de quais estao
      //--- ligadas e com que prioridade. O campo continua sendo o mesmo.
      RowsReset();
      RowComboF("Resolver Conflito",FCV_COMBO_CONFLICT,FCV_FLD_CONFLICT);
      //--- A nota vai alem do texto da 1.058 em dois pontos verificados no
      //--- codigo dos resolvedores, e ambos surpreendem quem le so o rotulo:
      //--- em PRIORIDADE, opostos de MESMA prioridade tambem cancelam; e em
      //--- CANCELAR a prioridade continua valendo entre sinais que CONCORDAM,
      //--- para eleger a estrategia dona — que e quem manda na saida.
      RowNote ("PRIORIDADE: em sinais opostos, o maior numero vence; empate na maior prioridade cancela.");
      RowNote ("CANCELAR: sinais opostos cancelam a entrada. A prioridade segue valendo quando os sinais concordam: ela elege a estrategia dona da posicao, e e a saida dela que vale.");
      Card("CONFLITO");
      return;
     }
   if(s==1)
     {
      RowsReset();
      RowNote   ("Cruza medias rapida e lenta com parametros independentes.");
      RowToggleF("Ativo",FCV_FLD_USE_MACROSS);
      RowFieldF ("Prioridade","Em sinais opostos, o maior numero vence",FCV_FLD_MA_PRIORITY);
      Card("MA CROSS");

      RowsReset();
      RowFieldF("Periodo","Numero de velas",FCV_FLD_MA_FAST_PERIOD);
      RowComboF("Timeframe",FCV_COMBO_TF    ,FCV_FLD_MA_FAST_TF);
      RowComboF("Tipo"     ,FCV_COMBO_METHOD,FCV_FLD_MA_FAST_METHOD);
      RowComboF("Preco"    ,FCV_COMBO_PRICE ,FCV_FLD_MA_FAST_PRICE);
      Card("MEDIA RAPIDA");

      RowsReset();
      RowFieldF("Periodo","Numero de velas",FCV_FLD_MA_SLOW_PERIOD);
      RowComboF("Timeframe",FCV_COMBO_TF    ,FCV_FLD_MA_SLOW_TF);
      RowComboF("Tipo"     ,FCV_COMBO_METHOD,FCV_FLD_MA_SLOW_METHOD);
      RowComboF("Preco"    ,FCV_COMBO_PRICE ,FCV_FLD_MA_SLOW_PRICE);
      Card("MEDIA LENTA");

      RowsReset();
      RowFieldF("Dist. Min","Distancia minima entre as medias, em pontos",FCV_FLD_MA_MIN_DIST);
      RowComboF("Modo",FCV_COMBO_ENTRY,FCV_FLD_MA_ENTRY_MODE);
      Card("ENTRADA");

      RowsReset();
      RowComboF("Modo",FCV_COMBO_EXIT,FCV_FLD_MA_EXIT_MODE);
      RowNote  ("Saida usa SL/TP globais; 0 desliga cada nivel.");
      Card("SAIDA");
      return;
     }
   if(s==2)
     {
      RowsReset();
      RowNote   ("Sinais: Saida da Zona, Dentro da Zona ou Cruz. Media.");
      RowToggleF("Ativo",FCV_FLD_USE_RSI);
      RowFieldF ("Prioridade","Em sinais opostos, o maior numero vence",FCV_FLD_RSI_PRIORITY);
      Card("RSI");

      RowsReset();
      RowFieldF("Periodo","Numero de velas",FCV_FLD_RSI_PERIOD);
      RowComboF("Timeframe",FCV_COMBO_TF   ,FCV_FLD_RSI_TF);
      RowComboF("Preco"    ,FCV_COMBO_PRICE,FCV_FLD_RSI_PRICE);
      Card("PARAMETROS");

      //--- Sobrevenda antes de sobrecompra, como na 1.058: a ordem segue a
      //--- escala do indicador, de baixo para cima.
      RowsReset();
      //--- As zonas so valem nos modos que as usam; a linha media, quando o
      //--- sinal ou a saida dependem dela. Editar o que o EA vai ignorar e
      //--- trabalho perdido sem aviso.
      RowComboF("Modo",FCV_COMBO_RSIMODE,FCV_FLD_RSI_MODE);
      RowFieldF("Sobrevenda" ,"Abaixo disso, procura compra",FCV_FLD_RSI_OVERSOLD  ,true,RsiUsesZones());
      RowFieldF("Sobrecompra","Acima disso, procura venda"  ,FCV_FLD_RSI_OVERBOUGHT,true,RsiUsesZones());
      RowFieldF("Linha media","Referencia para cruzamento"  ,FCV_FLD_RSI_MIDDLE    ,true,RsiUsesMiddle());
      Card("SINAL");

      RowsReset();
      RowComboF("Modo",FCV_COMBO_RSIEXIT,FCV_FLD_RSI_EXIT_MODE);
      Card("SAIDA");
      return;
     }
   //--- A descricao existe nas outras duas e faltava aqui; e ela que diz de
   //--- saida quais sao os tres modos de sinal.
   RowsReset();
   RowNote   ("Sinais: FFFD, Toque/Rejeicao ou Rompimento.");
   RowToggleF("Ativo",FCV_FLD_USE_BB);
   RowFieldF ("Prioridade","Em sinais opostos, o maior numero vence",FCV_FLD_BB_PRIORITY);
   Card("BOLLINGER");

   RowsReset();
   RowFieldF("Periodo","Numero de velas",FCV_FLD_BB_PERIOD);
   RowFieldF("Desvio" ,"Multiplicador do desvio padrao",FCV_FLD_BB_DEVIATION);
   RowComboF("Timeframe",FCV_COMBO_TF   ,FCV_FLD_BB_TF);
   RowComboF("Preco"    ,FCV_COMBO_PRICE,FCV_FLD_BB_PRICE);
   Card("PARAMETROS");

   RowsReset();
   RowComboF("Modo",FCV_COMBO_BBMODE,FCV_FLD_BB_MODE);
   RowNote  ("Recomenda-se usar filtro TREND.");
   Card("SINAL");

   RowsReset();
   RowComboF("Modo",FCV_COMBO_EXIT,FCV_FLD_BB_EXIT_MODE);
   Card("SAIDA");
  }

//+------------------------------------------------------------------+
//| Filtros                                                           |
//+------------------------------------------------------------------+
void ScreenFilters(void)
  {
   int s=m_sub[3];
   if(s==0)
     {
      //--- Somente leitura, como em Estrategias > Geral. "Tendencia" e ainda um
      //--- caso especial: e resumo das duas medias (ligado com qualquer uma
      //--- delas ligada), nao uma chave — nem existe o que clicar.
      RowsReset();
      RowState("Tendencia",FCV_FLD_USE_TREND);
      RowState("IFR / RSI",FCV_FLD_USE_RSIF);
      RowState("Bollinger",FCV_FLD_USE_BBF);
      RowNote ("Ligue ou desligue em cada subaba. Tendencia fica ligado quando ao menos uma das duas medias esta ligada.");
      Card("FILTROS");

      RowsReset();
      RowNote("Um filtro desligado nao bloqueia nada. Com todos desligados, a estrategia entra sempre que der sinal.");
      Card("COMO FUNCIONA");
      return;
     }
   if(s==1)
     {
      //--- Cada media tem a propria chave: a 1.058 permite usar so a M1, e
      //--- uma chave unica no topo esconderia isso.
      RowsReset();
      //--- Cada media governa os proprios parametros: com ela desligada, o EA
      //--- nao a consulta. E o unico caso em que uma chave apaga o bloco dela.
      bool ma1=m_draft.trendMA1Enabled, ma2=m_draft.trendMA2Enabled;
      RowNote   ("BUY: acima de todas as MAs ON. SELL: abaixo de todas.");
      RowToggleF("Ativo",FCV_FLD_TR_MA1_ON);
      RowFieldF ("Periodo","Numero de velas",FCV_FLD_TR_MA1_PERIOD,true,ma1);
      RowComboF ("Timeframe",FCV_COMBO_TF    ,FCV_FLD_TR_MA1_TF    ,ma1);
      RowComboF ("Metodo"   ,FCV_COMBO_METHOD,FCV_FLD_TR_MA1_METHOD,ma1);
      RowComboF ("Preco"    ,FCV_COMBO_PRICE ,FCV_FLD_TR_MA1_PRICE ,ma1);
      Card("MEDIA 1");

      RowsReset();
      RowToggleF("Ativo",FCV_FLD_TR_MA2_ON);
      RowFieldF ("Periodo","Numero de velas",FCV_FLD_TR_MA2_PERIOD,true,ma2);
      RowComboF ("Timeframe",FCV_COMBO_TF    ,FCV_FLD_TR_MA2_TF    ,ma2);
      RowComboF ("Metodo"   ,FCV_COMBO_METHOD,FCV_FLD_TR_MA2_METHOD,ma2);
      RowComboF ("Preco"    ,FCV_COMBO_PRICE ,FCV_FLD_TR_MA2_PRICE ,ma2);
      RowNote   ("Com ambas ON, M1 deve ser mais longa que M2 (periodo x TF).");
      Card("MEDIA 2");
      return;
     }
   if(s==2)
     {
      RowsReset();
      RowNote   ("Filtra entradas por faixa operacional do RSI.");
      RowToggleF("Ativo",FCV_FLD_USE_RSIF);
      Card("RSI FILTER");

      RowsReset();
      RowFieldF("Periodo","Numero de velas",FCV_FLD_RF_PERIOD);
      RowComboF("Timeframe",FCV_COMBO_TF   ,FCV_FLD_RF_TF);
      RowComboF("Preco"    ,FCV_COMBO_PRICE,FCV_FLD_RF_PRICE);
      Card("PARAMETROS");

      //--- Sao dois limites, nao quatro: sobrecompra e sobrevenda aparecem na
      //--- 1.058 como legenda que muda com o modo, nao como campo proprio.
      RowsReset();
      //--- Os dois campos sao os MESMOS em todos os modos, mas significam
      //--- coisas diferentes — e em Extremos o papel ate se inverte (o primeiro
      //--- passa a ser o nivel BAIXO). Por isso a 1.058 renomeia os rotulos:
      //--- um nome fixo estaria errado nos tres modos. Era o caso de
      //--- "Min Compra", que nao existe no modo Direcao nem em Extremos.
      string rfLbl1="Linha", rfLbl2="Nao usado";
      string rfHint1="Acima dela so compra; abaixo so venda";
      string rfHint2="O modo Direcao usa uma linha so";
      if(m_draft.rsiFilterMode==RSI_FILTER_NEUTRAL)
        {
         rfLbl1="Compra >="; rfHint1="RSI minimo para liberar compra";
         rfLbl2="Venda <=";  rfHint2="RSI maximo para liberar venda";
        }
      else if(m_draft.rsiFilterMode==RSI_FILTER_EXTREMES)
        {
         rfLbl1="Sobrevenda";  rfHint1="Abaixo disso, nenhuma entrada";
         rfLbl2="Sobrecompra"; rfHint2="Acima disso, nenhuma entrada";
        }
      RowComboF("Modo",FCV_COMBO_RSIFILTER,FCV_FLD_RF_MODE);
      RowFieldF(rfLbl1,rfHint1,FCV_FLD_RF_BUYMIN);
      RowFieldF(rfLbl2,rfHint2,FCV_FLD_RF_SELLMAX,true,RsiFilterUsesSecondLevel());
      RowNote  ("Filtro nao abre ordem; apenas aprova ou bloqueia entradas.");
      Card("FAIXA");
      return;
     }
   RowsReset();
   RowNote   ("Anti-squeeze: nao abre trade; apenas bloqueia sinais.");
   RowToggleF("Ativo",FCV_FLD_USE_BBF);
   Card("BOLLINGER FILTER");

   RowsReset();
   RowFieldF("Periodo","Numero de velas",FCV_FLD_BF_PERIOD);
   RowFieldF("Desvio" ,"Multiplicador do desvio padrao",FCV_FLD_BF_DEV);
   RowComboF("Timeframe",FCV_COMBO_TF   ,FCV_FLD_BF_TF);
   RowComboF("Preco"    ,FCV_COMBO_PRICE,FCV_FLD_BF_PRICE);
   Card("PARAMETROS");

   RowsReset();
   //--- A largura minima e medida em pontos OU em porcento, nunca nos dois: o
   //--- modo escolhe qual dos campos vale, e o outro fica apagado.
   RowComboF("Modo",FCV_COMBO_BBWIDTH,FCV_FLD_BF_MODE);
   RowFieldF("Min Pts","Largura minima em pontos do simbolo",FCV_FLD_BF_MINPTS,
             true, BbFilterAbsolute());
   RowFieldF("Min %"  ,"Largura minima como % da linha media",FCV_FLD_BF_MINPCT,
             true,!BbFilterAbsolute());
   Card("LARGURA");

   //--- Direcao aqui e a inclinacao das bandas, e e uma chave — nao a escolha
   //--- de lado da operacao. Eram coisas diferentes com o mesmo nome.
   RowsReset();
   //--- A inclinacao pertence ao filtro: sem ele ligado nao ha o que inclinar.
   //--- E seus parametros so valem com a propria chave de direcao ligada.
   RowToggleF("Nao operar contra a inclinacao",FCV_FLD_BF_SLOPE_ON,BbFilterSlopeEditable());
   RowFieldF ("Candles","Velas fechadas usadas para medir a inclinacao",FCV_FLD_BF_SLOPE_BACK,
              true,BbFilterSlopeParams());
   RowFieldF ("Incl. min.","Pontos por candle a partir dos quais bloqueia; zero bloqueia a qualquer inclinacao",
              FCV_FLD_BF_SLOPE_MINPTS,true,BbFilterSlopeParams());
   RowNote   ("Mede para onde aponta a linha central das bandas. Subindo, bloqueia venda; descendo, bloqueia compra.");
   Card("INCLINACAO");
  }

//+------------------------------------------------------------------+
//| Gestao — textos derivados.                                        |
//|                                                                   |
//| Portados de UIPanelProtectionSync.mqh e UIPanelRiskValidation.mqh.|
//| Nenhum e escrito de cabeca: sao as mesmas contas e as mesmas       |
//| palavras que o painel 1.058 mostra, e divergir aqui faria a 2.0    |
//| descrever o mesmo estado de outro jeito.                           |
//+------------------------------------------------------------------+
//--- O nome da direcao sai da lista do proprio combo, e nao de uma copia:
//--- indice e valor do enum coincidem, entao a lista ja e a traducao.
string DirectionName(void)
  {
   string items[];
   int n=ComboItems(FCV_COMBO_SIDE,items);
   int idx=(int)m_draft.tradeDirection;
   return (idx>=0 && idx<n) ? items[idx] : "";
  }

//--- Spread do momento, em pontos. E leitura ao vivo dentro de uma tela de
//--- configuracao, e e util justamente ali: o SL e digitado em pontos, e sem
//--- saber quanto o spread ja consome nao da para escolher a distancia.
string SpreadPointsText(void)
  {
   if(!HasText(m_snap.symbolSpec.symbol) || m_snap.symbolSpec.point<=0.0) return "--";
   MqlTick tick;
   if(!SymbolInfoTick(m_snap.symbolSpec.symbol,tick) ||
      tick.bid<=0.0 || tick.ask<=0.0 || tick.ask<tick.bid) return "--";
   long pts=(long)MathRound((tick.ask-tick.bid)/m_snap.symbolSpec.point);
   return StringFormat("%I64d",pts);
  }

//--- O que a compensacao de spread faz com as distancias escolhidas. Cada
//--- combinacao tem sua frase porque o efeito muda de lado: no SL aumenta o
//--- risco, no TP diminui o alvo.
string SpreadCompensationNote(void)
  {
   string prefix="Spread atual: "+SpreadPointsText()+" pts. ";
   if(m_draft.compensateSLSpread && m_draft.compensateTPSpread)
      return prefix+"SL soma; TP subtrai.";
   if(m_draft.compensateSLSpread) return prefix+"SL ON soma; risco aumenta.";
   if(m_draft.compensateTPSpread) return prefix+"TP ON subtrai; alvo diminui.";
   return prefix+"EA valida o minimo da corretora.";
  }

//--- Panorama de protecao: os seis resumos da subaba GERAL da 1.058.
//--- Sem o "| Descarta sinais" que a 1.058 concatena aqui. Aquele trecho e
//--- CONSTANTE — nao muda com configuracao nenhuma —, entao nao informava nada
//--- por linha e so consumia largura: com o trilho ocupando a esquerda, a
//--- coluna do valor e estreita e o texto passava por cima do rotulo. A regra
//--- que ele expressa virou nota no rodape do cartao, que e onde a propria
//--- 1.058 a escreve ("Sinais surgidos durante bloqueios sao descartados.").
string ProtEntryText(void)
  {
   string spread=!m_draft.enableSpreadProtection ? "Spread OFF"
                 : "Spread max "+IntegerToString(m_draft.maxSpreadPoints)+" pts";
   return DirectionName()+" | "+spread;
  }

string ProtSessionText(void)
  {
   if(!m_draft.enableSessionFilter) return "OFF";
   string t=StringFormat("%02d:%02d - %02d:%02d",
                         m_draft.sessionStartHour,m_draft.sessionStartMinute,
                         m_draft.sessionEndHour,m_draft.sessionEndMinute);
   if(m_draft.sessionOvernight) t+=" +1d";
   return t;
  }

string ProtNewsText(void)
  {
   int on=0;
   for(int i=0;i<FUSION_NEWS_WINDOW_COUNT;++i)
      if(m_draft.newsWindows[i].enabled) on++;
   return IntegerToString(on)+"/"+IntegerToString(FUSION_NEWS_WINDOW_COUNT)+" janelas ativas";
  }

string ProtDayText(int &sem)
  {
   if(!m_draft.enableDailyLimits) { sem=FCV_SEM_NEUTRAL; return "OFF"; }
   if(m_snap.dailyLimitsBlocked)  { sem=FCV_SEM_BAD;     return "BLOQUEADO"; }
   sem=FCV_SEM_GOOD;
   return "ATIVO";
  }

//--- A ordem importa e e a da 1.058: atingido e ativo sao verificados ANTES da
//--- chave. Um DD que ja disparou continua valendo mesmo que a chave tenha sido
//--- desligada depois — dizer "OFF" ali esconderia um bloqueio em vigor.
string ProtDrawdownText(int &sem)
  {
   if(m_snap.drawdownLimitReached)      { sem=FCV_SEM_WARN;    return "ATINGIDO"; }
   if(m_snap.drawdownProtectionActive)  { sem=FCV_SEM_GOOD;    return "ATIVO"; }
   if(!m_draft.enableDrawdown)          { sem=FCV_SEM_NEUTRAL; return "OFF"; }
   sem=FCV_SEM_NEUTRAL;
   return "AGUARDANDO META";
  }

string ProtStreakText(int &sem)
  {
   bool on=(m_draft.lossStreakEnabled || m_draft.winStreakEnabled);
   if(!on) { sem=FCV_SEM_NEUTRAL; return "OFF"; }
   if(m_snap.streakProtectionBlocked)
     {
      //--- Pausa e bloqueio se distinguem so pelo texto do motivo; e o unico
      //--- sinal que o snapshot oferece, e a 1.058 usa o mesmo.
      bool paused=(StringFind(m_snap.streakProtectionBlockReason,"em pausa")>=0);
      sem=paused ? FCV_SEM_WARN : FCV_SEM_BAD;
      return paused ? "EM PAUSA" : "BLOQUEADO";
     }
   sem=FCV_SEM_GOOD;
   return "ATIVO";
  }

//--- Leituras do drawdown. Sem base medida elas viram "--": zeros pareceriam
//--- medicao feita, e "0,00 de folga" diria exatamente o oposto da verdade.
bool DrawdownRuntimeKnown(void)
  {
   return (m_snap.drawdownProtectionActive || m_snap.drawdownLimitReached ||
           m_snap.drawdownPeakProfit>0.0);
  }
string DrawdownRuntimeText(const double v)
  { return DrawdownRuntimeKnown() ? DoubleToString(v,2) : "--"; }

//+------------------------------------------------------------------+
//| Gestao > Risco                                                    |
//+------------------------------------------------------------------+
void ScreenRisk(void)
  {
   switch(m_railSel[0])
     {
      case 0:
         RowsReset();
         RowNote  ("Define o volume base usado nas novas entradas.");
         RowFieldF("Lote Fixo","",FCV_FLD_FIXED_LOT);
         RowFieldF("Slippage (pts)","Tolerancia de execucao, nao garantia de preco",
                   FCV_FLD_SLIPPAGE);
         RowNote  ("Use 0 para enviar sem desvio; valido de 0 a 100000 pontos.");
         Card("TAMANHO DO LOTE");
         return;

      case 1:
         RowsReset();
         RowNote   ("Distancias fixas aplicadas no envio da ordem.");
         RowFieldF ("SL Fixo (pts MT5)","Zero desliga o stop fixo",FCV_FLD_SL_POINTS);
         RowFieldF ("TP Fixo (pts MT5)","Zero desliga o alvo fixo",FCV_FLD_TP_POINTS);
         RowToggleF("Compensar Spread SL",FCV_FLD_COMP_SL);
         RowToggleF("Compensar Spread TP",FCV_FLD_COMP_TP);
         //--- O aviso de operar sem stop e da 1.058 e vem em vermelho. Ele
         //--- substitui a instrucao normal, e nao se soma a ela: sem SL, o que
         //--- precisa ser dito nao e como preencher o campo.
         if(m_draft.fixedSLPoints<=0)
            RowNoteSem("ATENCAO: operar sem SL e ARRISCADO.",FCV_SEM_BAD);
         else
            RowNote   ("Informe SL/TP em pontos do MT5; 0 desliga.");
         RowNote   ("Use a mesma contagem exibida pela regua do grafico.");
         RowNote   (SpreadCompensationNote());
         Card("STOP LOSS E TAKE PROFIT");
         return;

      //--- TP parcial: TP1 comanda. A 1.058 poe TP1 e TP2 lado a lado em duas
      //--- colunas; aqui viram dois cartoes, porque a coluna estreita nao cabe
      //--- na largura do painel sem encolher os campos.
      case 2:
         RowsReset();
         RowNote   ("Fecha partes da posicao em alvos globais antes do TP final.");
         RowToggleF("Ativo",FCV_FLD_TP1_ON);
         RowFieldF ("Volume %","Fracao da posicao encerrada",FCV_FLD_TP1_PCT,true,Tp1Params());
         RowFieldF ("Dist pts","Distancia do preco de entrada",FCV_FLD_TP1_DIST,true,Tp1Params());
         Card("TP1");

         RowsReset();
         RowToggleF("Ativo",FCV_FLD_TP2_ON,Tp2Editable());
         RowFieldF ("Volume %","Fracao da posicao encerrada",FCV_FLD_TP2_PCT,true,Tp2Params());
         RowFieldF ("Dist pts","Distancia do preco de entrada",FCV_FLD_TP2_DIST,true,Tp2Params());
         RowNote   ("TP1 ON ativa o TP parcial; TP2 depende dele.");
         Card("TP2");

         RowsReset();
         RowToggleF("TP Final Livre",FCV_FLD_FREE_TP,FreeTpEditable());
         RowNote   ("Remove o TP final apos o ultimo parcial. Requer trailing ativo; "
                    "o restante passa a sair pelo trailing.");
         RowNote   ("Volumes sao ajustados ao lote minimo e passo do ativo.");
         Card("TP FINAL");
         return;

      case 3:
         RowsReset();
         RowNote   ("Ajusta o SL apos a posicao atingir o gatilho em lucro.");
         RowToggleF("Ativo",FCV_FLD_BE_ON);
         RowFieldF ("Gatilho (pts)","Lucro necessario para mover o stop",
                    FCV_FLD_BE_TRIGGER,true,BreakevenParams());
         RowFieldF ("Offset (pts)","Onde o stop fica em relacao a entrada",
                    FCV_FLD_BE_OFFSET,true,BreakevenParams());
         RowNote   ("BE apenas ajusta o SL da posicao aberta.");
         RowNote   ("Offset 0 move o SL para a entrada; offset maior protege lucro.");
         Card("BREAKEVEN");
         return;

      default:
         RowsReset();
         RowNote   ("Move o SL acompanhando o preco apos atingir o inicio em lucro.");
         RowToggleF("Ativo",FCV_FLD_TRAIL_ON);
         RowFieldF ("Inicio (pts)","Lucro a partir do qual o trailing liga",
                    FCV_FLD_TRAIL_START,true,TrailingParams());
         RowFieldF ("Passo (pts)","Distancia entre preco atual e novo SL",
                    FCV_FLD_TRAIL_STEP,true,TrailingParams());
         RowNote   ("Trailing apenas ajusta o SL da posicao aberta.");
         Card("TRAILING");
         return;
     }
  }

//+------------------------------------------------------------------+
//| Gestao > Protecao                                                 |
//|                                                                   |
//| Tres secoes podem estar sob BLOQUEIO OPERACIONAL — limites        |
//| diarios, drawdown e sequencias. Enquanto vale, a secao inteira    |
//| fica somente-leitura e os rodapes explicam por que. Nao e o mesmo |
//| bloqueio do EA rodando: este sobrevive a pausa, de proposito.     |
//+------------------------------------------------------------------+
void ScreenProtection(void)
  {
   switch(m_railSel[1])
     {
      //--- Panorama: os seis resumos, com as mesmas contas da 1.058. Repetir
      //--- aqui o que as outras subabas mostram e o proposito de um panorama —
      //--- ao contrario do numero repetido entre Status e Resultados, que era
      //--- duas telas afirmando a mesma coisa sem ser resumo de nada.
      case 0:
        {
         int semDay,semDD,semStreak;
         string day=ProtDayText(semDay);
         string dd =ProtDrawdownText(semDD);
         string st =ProtStreakText(semStreak);
         //--- Cada linha leva o nome do ITEM DO TRILHO que resume, e nao o da
         //--- 1.058 (Entrada/News/DAY/DD/Streak). O panorama existe para
         //--- apontar aonde ir; com nomes diferentes dos do trilho, ele
         //--- descreveria secoes que o usuario nao encontra na lista ao lado.
         //--- O vocabulario e o que a propria 2.0 ja usa para navegar.
         //---
         //--- Duas formas de valor, e a escolha nao e estetica:
         //---   SELO  para as tres secoes cujo valor e um ESTADO — uma palavra
         //---         de um conjunto fechado (OFF/ATIVO/BLOQUEADO/ATINGIDO...).
         //---         E o mesmo tratamento que o Status da a estado, e a cor do
         //---         selo passa a severidade sem precisar de legenda.
         //---   TEXTO para as tres cujo valor e ECO DA CONFIGURACAO — direcao,
         //---         horario, contagem. Num selo, um horario pareceria estado.
         RowsReset();
         RowStatic("Spread/Lado",ProtEntryText());
         RowStatic("Sessao",ProtSessionText());
         RowStatic("Noticias",ProtNewsText());
         RowBadge ("Limites Diarios",day,semDay);
         RowBadge ("Drawdown",dd,semDD);
         RowBadge ("Sequencias",st,semStreak);
         RowNote  ("Sinais surgidos durante bloqueios sao descartados.");
         Card("RESUMO DE PROTECAO");
         return;
        }

      case 1:
         RowsReset();
         RowNote   ("Regras globais aplicadas antes de enviar uma nova ordem.");
         RowToggleF("Max Spread",FCV_FLD_SPREAD_ON);
         RowFieldF ("Limite (pts)","Acima disso a entrada e recusada",
                    FCV_FLD_SPREAD_MAX,true,SpreadLimitEditable());
         RowComboF ("Direcao",FCV_COMBO_SIDE,FCV_FLD_DIRECTION);
         RowNote   ("Sinais surgidos durante bloqueios sao descartados.");
         RowNote   ("Direcao nao bloqueia estrategia em VM; guards continuam ativos.");
         Card("PROTECAO DE ENTRADA");
         return;

      //--- Horarios seguem editaveis com o filtro desligado: configurar a
      //--- janela antes de liga-la e uso legitimo, e a 1.058 tambem nao os
      //--- apaga (so o `editable` geral alcanca esses campos).
      case 2:
         RowsReset();
         RowNote   ("Controla horario de operacao do EA no mercado.");
         RowToggleF("Ativo",FCV_FLD_SESSION_ON);
         RowTimeF  ("Inicio","Hora e minuto de abertura",
                    FCV_FLD_SESS_START_H,FCV_FLD_SESS_START_M);
         RowTimeF  ("Fim","Hora e minuto de fechamento",
                    FCV_FLD_SESS_END_H,FCV_FLD_SESS_END_M);
         RowToggleF("Fechar no fim",FCV_FLD_SESS_CLOSE);
         RowToggleF("Overnight",FCV_FLD_SESS_OVERNIGHT);
         //--- As duas primeiras notas mudam com a escolha: dizem a regra que
         //--- VALE agora, e nao as duas possiveis. Textos da 1.058.
         RowNote   (m_draft.sessionOvernight
                    ? "Overnight ON: Inicio > Fim e cruza meia-noite."
                    : "Overnight OFF: Fim > Inicio no mesmo dia.");
         RowNote   (m_draft.closeOnSessionEnd
                    ? "Fechar no fim ON: fecha posicoes ao termino da sessao."
                    : "Fechar no fim OFF: nao fecha posicoes pelo fim da sessao.");
         RowNote   ("Fora da janela, novas entradas ficam bloqueadas.");
         Card("PROTECAO DE SESSAO");
         return;

      //--- Sao tres janelas (FUSION_NEWS_WINDOW_COUNT), iguais entre si. O laco
      //--- garante que acrescentar uma quarta no EA a faca aparecer aqui — a
      //--- versao anterior tinha os tres cartoes copiados a mao.
      case 3:
        {
         RowsReset();
         RowNote("Cada janela pode so bloquear entradas ou fechar posicoes abertas.");
         Card("JANELAS DE NOTICIAS");
         for(int w=0;w<FUSION_NEWS_WINDOW_COUNT;++w)
           {
            RowsReset();
            RowToggleF("Ativo",FCV_FLD_NEWS(w,FCV_FLD_NEWS_ON));
            RowTimeF  ("Inicio","Hora e minuto de abertura",
                       FCV_FLD_NEWS(w,FCV_FLD_NEWS_START_H),
                       FCV_FLD_NEWS(w,FCV_FLD_NEWS_START_M));
            RowTimeF  ("Fim","Hora e minuto de fechamento",
                       FCV_FLD_NEWS(w,FCV_FLD_NEWS_END_H),
                       FCV_FLD_NEWS(w,FCV_FLD_NEWS_END_M));
            RowComboF ("Modo",FCV_COMBO_NEWS,FCV_FLD_NEWS(w,FCV_FLD_NEWS_MODE));
            Card("JANELA "+IntegerToString(w+1));
           }
         return;
        }

      //--- Limites Diarios. ⚠ A chave NAO apaga os numeros: Max Trades, Max
      //--- Perda e Max Ganho seguem editaveis com a protecao desligada, e so a
      //--- Acao Ganho depende dela. E o que a 1.058 faz, conferido campo a
      //--- campo — supor o contrario apagaria tres campos sem motivo.
      case 4:
        {
         bool dayOpen=!DailyConfigLocked();
         RowsReset();
         RowNote   ("Controla trades, perda diaria e meta diaria de ganho.");
         RowToggleF("Ativo",FCV_FLD_DAY_ON,dayOpen);
         RowFieldF ("Max Trades","Quantidade de operacoes no dia",
                    FCV_FLD_DAY_TRADES,true,dayOpen);
         RowFieldF ("Max Perda","Perda acumulada que encerra o dia",
                    FCV_FLD_DAY_LOSS,true,dayOpen);
         RowFieldF ("Max Ganho","Ganho acumulado que encerra o dia",
                    FCV_FLD_DAY_GAIN,true,dayOpen);
         RowComboF ("Acao Ganho",FCV_COMBO_TARGET,FCV_FLD_DAY_ACTION,
                    dayOpen && DayActionEditable());
         if(dayOpen)
           {
            RowNote("Campos em zero ficam sem limite.");
            RowNote("ATIVAR DD exige DRAWDOWN ON com Max DD > 0.");
            RowNote("Contadores e P/L bruto persistem e resetam no novo dia.");
           }
         else
           {
            RowNoteSem("DAY em bloqueio: edicao suspensa ate o novo dia.",FCV_SEM_WARN);
            RowNoteSem("Pausar o EA nao remove nem permite alterar este bloqueio.",FCV_SEM_WARN);
            if(HasText(m_snap.dailyLimitsBlockReason))
               RowNoteSem(m_snap.dailyLimitsBlockReason,FCV_SEM_WARN);
           }
         Card("LIMITES DIARIOS");
         return;
        }

      //--- Drawdown. Mesma assimetria: Max DD segue editavel com a chave
      //--- desligada; so os dois combos dependem dela.
      case 5:
        {
         bool ddOpen=!DrawdownConfigLocked();
         RowsReset();
         RowNote   ("Protege o lucro do dia depois que a meta diaria e atingida.");
         RowToggleF("Ativo",FCV_FLD_DD_ON,ddOpen);
         RowFieldF ("Max DD","Recuo maximo aceito a partir da base",
                    FCV_FLD_DD_MAX,true,ddOpen);
         RowComboF ("Tipo DD",FCV_COMBO_DDTYPE,FCV_FLD_DD_TYPE,
                    ddOpen && DrawdownCombosEditable());
         RowComboF ("Base DD",FCV_COMBO_DDPEAK,FCV_FLD_DD_PEAK,
                    ddOpen && DrawdownCombosEditable());
         if(ddOpen)
           {
            RowNoteSem("Requer DAY ON, Max Ganho > 0 e Acao ATIVAR DD.",FCV_SEM_WARN);
            RowNote   ("Financeiro: valor; Percentual: % da base.");
           }
         else if(m_snap.drawdownLimitReached)
           {
            RowNoteSem(HasText(m_snap.drawdownConfigLockReason)
                       ? m_snap.drawdownConfigLockReason
                       : "DD atingido: edicao suspensa ate o novo dia.",FCV_SEM_WARN);
           }
         else
           {
            RowNote("DD ativo: protecao de lucro ligada.");
            RowNote("Novas entradas seguem permitidas ate tocar o Piso DD.");
            RowNote("Edicao do DD fica suspensa ate o novo dia.");
           }
         Card("PROTECAO DE DRAWDOWN (DD)");

         //--- Leitura ao vivo dentro de uma tela de configuracao: sao os
         //--- numeros que o EA calcula, nao campos. Ficam em cartao proprio
         //--- para nao parecerem editaveis por vizinhanca.
         //--- Os dois rotulos moveis sao da 1.058: a base muda de nome com o
         //--- modo de pico, e a folga passa a "atual" depois do gatilho.
         RowsReset();
         RowStatic(m_draft.drawdownPeakMode==DD_PICO_FLUTUANTE ? "Pico atual" : "Base atual",
                   DrawdownRuntimeText(m_snap.drawdownPeakProfit));
         RowStatic("Piso DD",DrawdownRuntimeText(m_snap.drawdownFloorProfit));
         RowStatic(m_snap.drawdownLimitReached ? "Folga atual" : "Folga DD",
                   DrawdownRuntimeText(m_snap.drawdownBufferProfit),
                   //--- Folga zerada ou negativa e o gatilho encostando: vermelho.
                   (DrawdownRuntimeKnown() && m_snap.drawdownBufferProfit<=0.0)
                      ? FCV_SEM_BAD : FCV_SEM_NEUTRAL);
         //--- Sem repetir aqui a explicacao do modo de pico: ela ja e a dica do
         //--- combo Base DD, tres linhas acima, e sair duas vezes na mesma tela
         //--- fazia parecer que uma delas falava de outra coisa.
         Card("ESTADO ATUAL");
         return;
        }

      //--- Duas sequencias independentes, perda e ganho, cada uma com limite,
      //--- acao e pausa proprios. Aqui a chave APAGA o lado inteiro, e a Pausa
      //--- min exige ainda que a acao seja Pausar — com "Parar dia" nao ha
      //--- pausa a configurar.
      default:
        {
         bool stOpen=!StreakConfigLocked();
         RowsReset();
         RowNote   ("Bloqueia novas entradas apos sequencias configuradas.");
         RowToggleF("Ativo",FCV_FLD_LOSS_STREAK_ON,stOpen);
         RowFieldF ("Max Loss","Perdas seguidas ate agir",
                    FCV_FLD_LOSS_STREAK_MAX,true,stOpen && LossStreakParams());
         RowComboF ("Acao",FCV_COMBO_STREAK,FCV_FLD_LOSS_STREAK_ACT,
                    stOpen && LossStreakParams());
         RowFieldF ("Pausa min","Minutos parado apos a sequencia",
                    FCV_FLD_LOSS_STREAK_PAUSE,true,stOpen && LossStreakPauseEditable());
         Card("SEQUENCIA DE LOSS");

         RowsReset();
         RowToggleF("Ativo",FCV_FLD_WIN_STREAK_ON,stOpen);
         RowFieldF ("Max Win","Ganhos seguidos ate agir",
                    FCV_FLD_WIN_STREAK_MAX,true,stOpen && WinStreakParams());
         RowComboF ("Acao",FCV_COMBO_STREAK,FCV_FLD_WIN_STREAK_ACT,
                    stOpen && WinStreakParams());
         RowFieldF ("Pausa min","Minutos parado apos a sequencia",
                    FCV_FLD_WIN_STREAK_PAUSE,true,stOpen && WinStreakPauseEditable());
         if(stOpen)
           {
            RowNote("Loss e Win sao independentes; cada lado pode ficar OFF.");
            RowNote("PAUSAR bloqueia por minutos; PARAR DIA libera no proximo dia.");
           }
         else
           {
            RowNoteSem("Streak em bloqueio: edicao suspensa ate liberar.",FCV_SEM_WARN);
            RowNoteSem("Pausar o EA nao remove nem permite alterar este bloqueio.",FCV_SEM_WARN);
           }
         Card("SEQUENCIA DE WIN");
         return;
        }
     }
  }

//--- Gestao: as duas telas que decidem dinheiro.
void ScreenGestao(void)
  {
   if(m_sub[FCV_TAB_GESTAO]==0) ScreenRisk();
   else                         ScreenProtection();
  }

void ScreenVisual(void)
  {
   //--- Visual: cinco indicadores, cada um com cor E estilo de linha
   //--- ⚠ Esta tela tem DUAS naturezas, e a divisao decide o comportamento:
   //---   INDICADORES sao configuracao do PERFIL — o EA desenha as linhas com
   //---     elas —, entao vao para o rascunho e passam por SALVAR.
   //---   APARENCIA (paleta, tema, tamanho) e preferencia de quem opera, vale
   //---     para todo grafico, vive em variavel global do terminal e e aplicada
   //---     no ato. Nao entra no perfil e nao cria pendencia.
   RowsReset();
   RowToggleF("Indicadores no Grafico",FCV_FLD_SHOW_INDICATORS);
   RowNote   ("Desenha as medias e as bandas no grafico. Nao altera nenhuma decisao do EA.");
   Card("INDICADORES VISUAIS");

   //--- Cor e estilo seguem editaveis com os indicadores desligados: configurar
   //--- antes de ligar e uso legitimo, a mesma regra das Estrategias.
   RowsReset();
   RowColorStyleF("MA Rapida",FCV_FLD_VIS_MAFAST_COLOR,FCV_FLD_VIS_MAFAST_STYLE);
   RowColorStyleF("MA Lenta", FCV_FLD_VIS_MASLOW_COLOR,FCV_FLD_VIS_MASLOW_STYLE);
   RowColorStyleF("Trend M1", FCV_FLD_VIS_TREND1_COLOR,FCV_FLD_VIS_TREND1_STYLE);
   RowColorStyleF("Trend M2", FCV_FLD_VIS_TREND2_COLOR,FCV_FLD_VIS_TREND2_STYLE);
   RowColorStyleF("Bandas",   FCV_FLD_VIS_BB_COLOR,    FCV_FLD_VIS_BB_STYLE);
   Card("CORES E ESTILOS");

   //--- Aparencia do painel: preferencia de exibicao, aplicada no ato da
   //--- escolha. Nao passa por SALVAR porque nao pertence ao perfil.
   //--- Aparencia do painel: preferencia de exibicao, aplicada no ato da
   //--- escolha. Nao passa por SALVAR porque nao pertence ao perfil — e por
   //--- isso continua disponivel mesmo com o perfil bloqueado.
   RowsReset();
   RowComboFree("Paleta",FCV_COMBO_PALETTE);
   RowComboFree("Tema",FCV_COMBO_THEMEMODE);
   RowComboFree("Tamanho do texto",FCV_COMBO_SCALE);
   RowNote ("Valem para o painel inteiro e mudam assim que voce escolhe.");
   Card("APARENCIA DO PAINEL");
  }

//+------------------------------------------------------------------+
//| Despacho do conteudo rolavel                                      |
//+------------------------------------------------------------------+
void DrawScreenContent(void)
  {
   ResetControls();
   m_screen=ScreenId();

   int top=ContentTop();
   if(HasRail())
     {
      int h=ContentBottom()-top;
      if(Sub()==0) DrawRail(FCV_PAD,top,h,m_railRisco,5,RailIdx(),0);
      else         DrawRail(FCV_PAD,top,h,m_railProt,FCV_RAIL_MAX,RailIdx(),1);
      m_fx1=FCV_PAD+FCV_RAIL_W+2;
     }
   else m_fx1=FCV_PAD;


   m_fx2=FCV_PANEL_W-FCV_PAD;
   m_fy =top-m_scroll;

   if(m_stress)      DrawStressContent();
   else switch(m_tab)
     {
      case 0:               ScreenStatus();     break;
      case 1:               ScreenResults();    break;
      case 2:               ScreenStrategies(); break;
      case 3:               ScreenFilters();    break;
      case FCV_TAB_GESTAO:  ScreenGestao();     break;
      case FCV_TAB_PERFIS:  ScreenProfiles();   break;
      default:              ScreenVisual();     break;
     }

   m_contentH=(m_fy+m_scroll)-top;
  }

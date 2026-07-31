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
   if(tab==2) { ArrayResize(out,4); string a[4]={"Geral","Medias","RSI","Bollinger"};    ArrayCopy(out,a); return 4; }
   if(tab==3) { ArrayResize(out,4); string a[4]={"Geral","Tendencia","RSI","Bollinger"}; ArrayCopy(out,a); return 4; }
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
   if(m_tab==FCV_TAB_PERFIS) return FCV_SCREEN_PROFILES;
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
bool ScreenAlert(string &title,string &body,int &sem)
  {
   if(m_tab==0)
     {
      title="GESTAO";
      body="Notificacoes tem uma janela invalida. Corrija em Gestao > Protecao > Noticias.";
      sem=FCV_SEM_BAD;
      return true;
     }
   if(m_tab==FCV_TAB_GESTAO && Sub()==1 && m_railSel[1]==3)
     {
      title="JANELA INVALIDA";
      body="O fim da janela 1 e anterior ao inicio. Ajuste os horarios para que a janela feche depois de abrir.";
      sem=FCV_SEM_BAD;
      return true;
     }
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
   int sel=m_stCombo[m_comboSlot[m_comboOpen]];
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

void ColorPopupBox(const int idx,int &x,int &y,int &w,int &h)
  {
   int cell=26, rows=FCV_SWATCH_COUNT/FCV_SWATCH_COLS;
   w=FCV_SWATCH_COLS*cell+10;
   h=rows*cell+10;
   x=m_colorX[idx]+m_colorW[idx]-w;
   y=m_colorY[idx]+24;
   if(y+h>m_ph-FCV_PAD) y=m_colorY[idx]-h-2;
  }

void DrawColorPopup(void)
  {
   if(m_colorOpen<0 || m_colorOpen>=m_colorCount) return;
   int x,y,w,h;
   ColorPopupBox(m_colorOpen,x,y,w,h);
   int sel=m_stColor[m_colorSlot[m_colorOpen]];
   PublishPopup(x,y,x+w,y+h);
   RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.acc,m_t.surface,m_t.ground);
   for(int i=0;i<FCV_SWATCH_COUNT;++i)
     {
      int cxx=x+5+(i%FCV_SWATCH_COLS)*26, cyy=y+5+(i/FCV_SWATCH_COLS)*26;
      RoundFrame(cxx+1,cyy+1,cxx+23,cyy+23,4,
                 (i==sel)?m_t.fg:m_t.line,m_swatches[i],m_t.surface);
     }
  }

//+------------------------------------------------------------------+
//| Telas de nivel 1 sem formulario                                   |
//+------------------------------------------------------------------+
void ScreenStatus(void)
  {
   int x1=m_fx1, x2=m_fx2, y=m_fy;

   RoundRect(x1,y,x2,y+56,FCV_RADIUS_CARD,m_t.surface,m_t.ground);
   Txt(x1+14,y+18,"ESTADO",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   Txt(x1+14,y+38,"Pausado",m_t.fg,FCV_FONT_UI,FCV_FS_HERO,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   Txt(x2-14,y+18,"POSICAO",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
   Txt(x2-14,y+38,"Nenhuma",m_t.muted,FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
   y+=66;

   string tk[4]={"ESTRATEGIAS","FILTROS","MAGIC","TF OPERACIONAL"};
   string tv[4]={"1","0","1","M1"};
   int tw=(x2-x1-24)/4;
   for(int i=0;i<4;++i)
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
   RowStatic("Ativo Operacional","BTCUSD");
   RowStatic("Responsavel","—");
   RowStatic("Conflito","PRIORIDADE");
   RowNote  ("Sem alertas.");
   Card("SESSAO");
  }

void ScreenResults(void)
  {
   //--- Campos reais da 1.058 (UI/Pages/ResultsPage.mqh). Numeros com virgula,
   //--- como o resto do painel — trocar o separador so nesta tela obrigaria o
   //--- usuario a ler dois formatos.
   RowsReset();
   RowStatic("P/L Bruto Fechado","0,00");
   RowStatic("P/L Bruto Flutuante","0,00");
   RowStatic("P/L Bruto Projetado","0,00");
   Card("RESULTADO DO DIA");

   RowsReset();
   RowStatic("Trades do Dia","0");
   RowStatic("Streak Loss/Win Atual","0 / 0");
   Card("CONTAGEM");

   RowsReset();
   RowBadge ("Estado DD","AGUARDANDO META",FCV_SEM_WARN);
   RowStatic("Pico / Piso DD","0,00 / 0,00");
   RowStatic("Folga DD","0,00");
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
   int x1=m_fx1, x2=m_fx2, y=m_fy;
   int aw=124, lx2=x2-aw-11;
   bool editing=(m_profEdit!=FCV_PROF_VIEW);

   string nm[6]={"BTCUSD","GOLD","JP225","US500","default","WIN scalp"};
   string mg[6]={"#1 · lote 0.01","#20 · lote 0.10","#31 · lote 1.00",
                 "#42 · lote 0.50","#1000 · lote 6.00","#77 · lote 2.00"};
   for(int i=0;i<6;++i)
     {
      int ry=y+i*34;
      bool sel=(i==m_profSel);
      //--- Durante a edicao a lista fica apagada: o que esta em jogo e o perfil
      //--- que esta sendo criado, e trocar de selecao no meio nao faria sentido.
      uint rowLine = editing ? m_t.soft : (sel ? m_t.acc : m_t.soft);
      uint rowFill = (sel && !editing) ? m_t.accd : m_t.ground;
      uint nameClr = editing ? m_t.disabled : m_t.fg;
      RoundFrame(x1,ry,lx2,ry+30,FCV_RADIUS_CTRL,rowLine,rowFill,m_t.surface);
      Txt(x1+11,ry+15,nm[i],nameClr,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);

      //--- O badge define o limite direito. Sem ele, o limite e a borda da
      //--- linha. Assim os numeros ficam numa coluna so, legiveis de cima a
      //--- baixo, em vez de flutuarem conforme o comprimento de cada nome.
      int metaRight=lx2-11;
      if(i==0)
        {
         int tw2=TxtW("ATIVO",FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD)+18;
         RoundRect(lx2-tw2-9,ry+7,lx2-9,ry+23,FCV_RADIUS_PILL,
                   editing?m_t.soft:m_t.gdim,rowFill);
         Txt(lx2-tw2/2-9,ry+15,"ATIVO",editing?m_t.disabled:m_t.good,
             FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
         metaRight=lx2-tw2-20;
        }
      Txt(metaRight,ry+15,mg[i],editing?m_t.disabled:m_t.muted,
          FCV_FONT_MONO,FCV_FS_BODY,FCV_FW_NORMAL,TA_RIGHT|TA_VCENTER);
     }

   //--- Cada acao acende conforme o que e possivel agora. Um unico preenchido:
   //--- em repouso o proximo passo e CARREGAR o selecionado; em edicao, SALVAR.
   bool isActive =(m_profSel==0);          // fake: o primeiro da lista e o ativo
   bool canLoad  =(!editing && !isActive);
   bool canDelete=(!editing && !isActive); // o ativo nao se apaga sozinho
   PutButton(lx2+11,y+0*34,aw,30,"CARREGAR",canLoad,m_t.acc,m_t.onAcc,FCV_BTN_LOAD,canLoad);
   PutButton(lx2+11,y+1*34,aw,30,"NOVO",    false,  m_t.acc,m_t.onAcc,FCV_BTN_NEW, !editing);
   PutButton(lx2+11,y+2*34,aw,30,"DUPLICAR",false,  m_t.acc,m_t.onAcc,FCV_BTN_DUP, !editing);
   PutButton(lx2+11,y+3*34,aw,30,"EXCLUIR", false,  m_t.bad,m_t.onAcc,FCV_BTN_DEL, canDelete);

   m_fy=y+6*34+FCV_CARD_GAP;

   if(editing)
     {
      //--- Nome e Magic sao os dois campos que definem um perfil novo. O Magic
      //--- vem preenchido na duplicacao porque copiar exige troca-lo: dois
      //--- perfis com o mesmo Magic fariam o EA confundir as proprias ordens.
      RowsReset();
      RowField("Nome","Como o perfil aparece na lista","");
      RowField("Magic","Precisa ser diferente de todos os outros",
               (m_profEdit==FCV_PROF_DUP) ? "2" : "");
      RowNote (m_profEdit==FCV_PROF_DUP
               ? "Copia de " + nm[m_profSel] + ". Ajuste o Magic e clique CRIAR COPIA."
               : "Informe um nome e clique CRIAR PERFIL.");
      Card(m_profEdit==FCV_PROF_DUP ? "DUPLICAR COMO" : "NOVO PERFIL");

      //--- Os rotulos nomeiam a acao, nao a categoria. "SALVAR" e "CANCELAR"
      //--- ja existem no cabecalho e significam outra coisa la — gravar
      //--- alteracoes do perfil ativo. Repetir a palavra faria o usuario
      //--- decidir qual dos dois e o certo em vez de simplesmente ler.
      int bw=(m_fx2-m_fx1-8)/2;
      PutButton(m_fx1,m_fy,bw,30,
                m_profEdit==FCV_PROF_DUP ? "CRIAR COPIA" : "CRIAR PERFIL",
                true,m_t.good,m_t.onGood,FCV_BTN_SAVE,true);
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
   RowsReset();
   RowField("Magic Number","Identifica as ordens deste perfil no grafico","1",
            true,isActive);
   if(isActive)
      RowNote("Dois perfis nao podem dividir o mesmo Magic: e por ele que o EA reconhece as proprias ordens.");
   else
      RowNote("Somente o perfil ativo tem o Magic editavel, e so com o EA parado. Use CARREGAR para ativar o selecionado.");
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
      RowsReset();
      RowToggle("MA Cross");
      RowToggle("RSI");
      RowToggle("Bollinger");
      Card("ESTRATEGIAS");

      //--- Resolver Conflito mora aqui, e nao em Config > Sistema como na
      //--- 1.058: e uma regra entre estrategias, e le-se junto de quais estao
      //--- ligadas e com que prioridade. O campo continua sendo o mesmo.
      RowsReset();
      RowCombo("Resolver Conflito",FCV_COMBO_CONFLICT);
      RowNote ("PRIORIDADE: em sinais opostos, o maior numero vence. CANCELAR: sinais opostos cancelam a entrada.");
      Card("CONFLITO");
      return;
     }
   if(s==1)
     {
      RowsReset();
      RowNote  ("Cruza medias rapida e lenta com parametros independentes.");
      RowToggle("Ativo");
      RowField ("Prioridade","Em sinais opostos, o maior numero vence","1");
      Card("MA CROSS");

      RowsReset();
      RowField("Periodo","Numero de velas","9");
      RowCombo("Timeframe",FCV_COMBO_TF);
      RowCombo("Tipo",FCV_COMBO_METHOD);
      RowCombo("Preco",FCV_COMBO_PRICE);
      Card("MEDIA RAPIDA");

      RowsReset();
      RowField("Periodo","Numero de velas","21");
      RowCombo("Timeframe",FCV_COMBO_TF);
      RowCombo("Tipo",FCV_COMBO_METHOD);
      RowCombo("Preco",FCV_COMBO_PRICE);
      Card("MEDIA LENTA");

      RowsReset();
      RowField("Dist. Min","Distancia minima entre as medias, em pontos","0");
      RowCombo("Modo",FCV_COMBO_ENTRY);
      Card("ENTRADA");

      RowsReset();
      RowCombo("Modo",FCV_COMBO_EXIT);
      RowNote ("Saida usa SL/TP globais; 0 desliga cada nivel.");
      Card("SAIDA");
      return;
     }
   if(s==2)
     {
      RowsReset();
      RowNote  ("Sinais: Saida da Zona, Dentro da Zona ou Cruz. Media.");
      RowToggle("Ativo");
      RowField ("Prioridade","Em sinais opostos, o maior numero vence","2");
      Card("RSI");

      RowsReset();
      RowField("Periodo","Numero de velas","14");
      RowCombo("Timeframe",FCV_COMBO_TF);
      RowCombo("Preco",FCV_COMBO_PRICE);
      Card("PARAMETROS");

      //--- Sobrevenda antes de sobrecompra, como na 1.058: a ordem segue a
      //--- escala do indicador, de baixo para cima.
      RowsReset();
      RowCombo("Modo",FCV_COMBO_RSIMODE);
      RowField("Sobrevenda","Abaixo disso, procura compra","30");
      RowField("Sobrecompra","Acima disso, procura venda","70");
      RowField("Linha media","Referencia para cruzamento","50");
      Card("SINAL");

      RowsReset();
      RowCombo("Modo",FCV_COMBO_RSIEXIT);
      Card("SAIDA");
      return;
     }
   RowsReset();
   RowToggle("Ativo");
   RowField ("Prioridade","Em sinais opostos, o maior numero vence","3");
   Card("BOLLINGER");

   RowsReset();
   RowField("Periodo","Numero de velas","20");
   RowField("Desvio","Multiplicador do desvio padrao","2.0");
   RowCombo("Timeframe",FCV_COMBO_TF);
   RowCombo("Preco",FCV_COMBO_PRICE);
   Card("PARAMETROS");

   RowsReset();
   RowCombo("Modo",FCV_COMBO_BBMODE);
   RowNote ("Recomenda-se usar filtro TREND.");
   Card("SINAL");

   RowsReset();
   RowCombo("Modo",FCV_COMBO_EXIT);
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
      RowsReset();
      RowToggle("Tendencia");
      RowToggle("RSI");
      RowToggle("Bollinger");
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
      RowNote  ("BUY: acima de todas as MAs ON. SELL: abaixo de todas.");
      RowToggle("Ativo");
      RowField ("Periodo","Numero de velas","50");
      RowCombo ("Timeframe",FCV_COMBO_TF);
      RowCombo ("Metodo",FCV_COMBO_METHOD);
      RowCombo ("Preco",FCV_COMBO_PRICE);
      Card("MEDIA 1");

      RowsReset();
      RowToggle("Ativo");
      RowField ("Periodo","Numero de velas","200");
      RowCombo ("Timeframe",FCV_COMBO_TF);
      RowCombo ("Metodo",FCV_COMBO_METHOD);
      RowCombo ("Preco",FCV_COMBO_PRICE);
      RowNote  ("Com ambas ON, M1 deve ser mais longa que M2 (periodo x TF).");
      Card("MEDIA 2");
      return;
     }
   if(s==2)
     {
      RowsReset();
      RowNote  ("Filtra entradas por faixa operacional do RSI.");
      RowToggle("Ativo");
      Card("RSI FILTER");

      RowsReset();
      RowField("Periodo","Numero de velas","14");
      RowCombo("Timeframe",FCV_COMBO_TF);
      RowCombo("Preco",FCV_COMBO_PRICE);
      Card("PARAMETROS");

      //--- Sao dois limites, nao quatro: sobrecompra e sobrevenda aparecem na
      //--- 1.058 como legenda que muda com o modo, nao como campo proprio.
      RowsReset();
      RowCombo("Modo",FCV_COMBO_RSIFILTER);
      RowField("Min Compra","RSI minimo para liberar compra","50");
      RowField("Max Venda","RSI maximo para liberar venda","50");
      RowNote ("Filtro nao abre ordem; apenas aprova ou bloqueia entradas.");
      Card("FAIXA");
      return;
     }
   RowsReset();
   RowNote  ("Anti-squeeze: nao abre trade; apenas bloqueia sinais.");
   RowToggle("Ativo");
   Card("BOLLINGER FILTER");

   RowsReset();
   RowField("Periodo","Numero de velas","20");
   RowField("Desvio","Multiplicador do desvio padrao","2.0");
   RowCombo("Timeframe",FCV_COMBO_TF);
   RowCombo("Preco",FCV_COMBO_PRICE);
   Card("PARAMETROS");

   RowsReset();
   RowCombo("Modo",FCV_COMBO_BBWIDTH);
   RowField("Min Pts","Largura minima em pontos do simbolo","0");
   RowField("Min %","Largura minima como % da linha media","0.0");
   Card("LARGURA");

   //--- Direcao aqui e a inclinacao das bandas, e e uma chave — nao a escolha
   //--- de lado da operacao. Eram coisas diferentes com o mesmo nome.
   RowsReset();
   RowToggle("Direcao");
   RowField ("Candles","Velas usadas para medir a inclinacao","1");
   RowField ("Incl. min.","Pontos por candle; zero deixa mais sensivel","0");
   Card("INCLINACAO");
  }

//+------------------------------------------------------------------+
//| Config                                                            |
//+------------------------------------------------------------------+
void ScreenRisk(void)
  {
   switch(m_railSel[0])
     {
      case 0:
         RowsReset();
         RowNote ("Define o volume base usado nas novas entradas.");
         RowField("Lote Fixo","Volume enviado em cada ordem","0.10");
         RowField("Slippage (pts)","Tolerancia de execucao, nao garantia de preco","20");
         RowNote ("Use 0 para enviar sem desvio; valido de 0 a 100000 pontos.");
         Card("TAMANHO DO LOTE");
         return;
      case 1:
         RowsReset();
         RowNote  ("Distancias fixas aplicadas no envio da ordem.");
         RowField ("SL Fixo (pts MT5)","Zero desliga o stop fixo","0");
         RowField ("TP Fixo (pts MT5)","Zero desliga o alvo fixo","0");
         RowToggle("Compensar Spread SL");
         RowToggle("Compensar Spread TP");
         RowNote  ("Use a mesma contagem exibida pela regua do grafico. O EA valida o minimo da corretora.");
         Card("STOP LOSS E TAKE PROFIT");
         return;
      case 2:
         RowsReset();
         RowNote  ("Fecha partes da posicao em alvos globais antes do TP final.");
         RowToggle("Ativo");
         RowField ("Volume %","Fracao da posicao encerrada","50.00");
         RowField ("Dist pts","Distancia do preco de entrada","150");
         Card("TP1");

         RowsReset();
         RowToggle("Ativo");
         RowField ("Volume %","Fracao da posicao encerrada","25.00");
         RowField ("Dist pts","Distancia do preco de entrada","300");
         RowNote  ("TP1 ON ativa o TP parcial; TP2 depende dele.");
         Card("TP2");

         RowsReset();
         RowToggle("TP Final Livre");
         RowNote  ("Remove o TP final apos o ultimo parcial. Requer trailing ativo; o restante passa a sair pelo trailing.");
         Card("TP FINAL");
         return;
      case 3:
         RowsReset();
         RowNote  ("Ajusta o SL apos a posicao atingir o gatilho em lucro.");
         RowToggle("Ativo");
         RowField ("Gatilho (pts)","Lucro necessario para mover o stop","120");
         RowField ("Offset (pts)","Onde o stop fica em relacao a entrada","10");
         RowNote  ("Offset 0 move o SL para a entrada; offset maior protege lucro.");
         Card("BREAKEVEN");
         return;
      default:
         RowsReset();
         RowNote  ("Move o SL acompanhando o preco apos atingir o inicio em lucro.");
         RowToggle("Ativo");
         RowField ("Inicio (pts)","Lucro a partir do qual o trailing liga","150");
         RowField ("Passo (pts)","Distancia entre preco atual e novo SL","80");
         Card("TRAILING");
         return;
     }
  }

void ScreenProtection(void)
  {
   switch(m_railSel[1])
     {
      case 0:
         RowsReset();
         RowBadge("Entrada","LIVRE",FCV_SEM_GOOD);
         RowBadge("Sessao","LIVRE",FCV_SEM_GOOD);
         RowBadge("Noticias","INVALIDO",FCV_SEM_BAD);
         RowBadge("Limites Diarios","LIVRE",FCV_SEM_GOOD);
         RowBadge("Drawdown","AGUARDANDO",FCV_SEM_WARN);
         RowBadge("Streak","LIVRE",FCV_SEM_GOOD);
         Card("RESUMO DE PROTECAO");
         return;
      case 1:
         RowsReset();
         RowToggle("Max Spread");
         RowField ("Limite (pts)","Acima disso a entrada e recusada","0");
         RowCombo ("Direcao",FCV_COMBO_SIDE);
         Card("PROTECAO DE ENTRADA");
         return;
      case 2:
         RowsReset();
         RowToggle("Ativo");
         RowField ("Inicio","Hora e minuto de abertura","09:00");
         RowField ("Fim","Hora e minuto de fechamento","17:30");
         RowToggle("Fechar no fim");
         RowToggle("Overnight");
         Card("PROTECAO DE SESSAO");
         return;
      case 3:
         //--- Sao tres janelas (FUSION_NEWS_WINDOW_COUNT), nao duas.
         //--- O "Fim" da janela 1 esta marcado invalido de proposito: e a folha
         //--- da cadeia de erro que pinta o trilho, a subaba e a aba Config.
         RowsReset();
         RowToggle("Ativo");
         RowField ("Inicio","Hora e minuto de abertura","14:30");
         RowField ("Fim","Hora e minuto de fechamento","14:00",false);
         RowCombo ("Modo",FCV_COMBO_NEWS);
         Card("JANELA 1");

         RowsReset();
         RowToggle("Ativo");
         RowField ("Inicio","Hora e minuto de abertura","00:00");
         RowField ("Fim","Hora e minuto de fechamento","00:00");
         RowCombo ("Modo",FCV_COMBO_NEWS);
         Card("JANELA 2");

         RowsReset();
         RowToggle("Ativo");
         RowField ("Inicio","Hora e minuto de abertura","00:00");
         RowField ("Fim","Hora e minuto de fechamento","00:00");
         RowCombo ("Modo",FCV_COMBO_NEWS);
         Card("JANELA 3");
         return;
      case 4:
         RowsReset();
         RowToggle("Ativo");
         RowField ("Max Trades","Quantidade de operacoes no dia","0");
         RowField ("Max Perda","Perda acumulada que encerra o dia","0.00");
         RowField ("Max Ganho","Ganho acumulado que encerra o dia","0.00");
         RowCombo ("Acao Ganho",FCV_COMBO_TARGET);
         RowNote  ("Campos em zero ficam sem limite. ATIVAR DD exige DRAWDOWN ON com Max DD > 0.");
         Card("LIMITES DIARIOS");
         return;
      case 5:
         RowsReset();
         RowToggle("Ativo");
         RowField ("Max DD","Recuo maximo aceito a partir da base","0.00");
         RowCombo ("Tipo DD",FCV_COMBO_DDTYPE);
         RowCombo ("Base DD",FCV_COMBO_DDPEAK);
         RowNote  ("Requer DAY ON, Max Ganho > 0 e Acao ATIVAR DD.");
         Card("PROTECAO DE DRAWDOWN (DD)");

         //--- Leitura ao vivo dentro de uma tela de configuracao: sao os
         //--- numeros que o EA calcula, nao campos. Ficam em cartao proprio
         //--- para nao parecerem editaveis por vizinhanca.
         RowsReset();
         RowStatic("Base atual","0,00");
         RowStatic("Piso DD","0,00");
         RowStatic("Folga DD","0,00");
         Card("ESTADO ATUAL");
         return;
      default:
         //--- Sao duas sequencias independentes, perda e ganho, cada uma com
         //--- limite, acao e pausa proprios.
         RowsReset();
         RowToggle("Ativo");
         RowField ("Max Loss","Perdas seguidas ate agir","0");
         RowCombo ("Acao",FCV_COMBO_STREAK);
         RowField ("Pausa min","Minutos parado apos a sequencia","0");
         Card("LOSS STREAK");

         RowsReset();
         RowToggle("Ativo");
         RowField ("Max Win","Ganhos seguidos ate agir","0");
         RowCombo ("Acao",FCV_COMBO_STREAK);
         RowField ("Pausa min","Minutos parado apos a sequencia","0");
         Card("WIN STREAK");
         return;
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
   RowsReset();
   RowToggle("Indicadores no Grafico");
   Card("INDICADORES VISUAIS");

   RowsReset();
   RowColorStyle("MA Rapida");
   RowColorStyle("MA Lenta");
   RowColorStyle("Trend M1");
   RowColorStyle("Trend M2");
   RowColorStyle("Bandas");
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

//+------------------------------------------------------------------+
//| CanvasRendererForm.mqh                                            |
//| Fragmento do corpo de CFusionCanvasRenderer — construtor de       |
//| formulario. As telas declaram linhas; este codigo mede, desenha   |
//| e publica a caixa de clique de cada controle.                     |
//|                                                                   |
//| A caixa publicada aqui e a mesma usada pelo hit-testing: alvo e   |
//| pintura nao podem divergir, e assim o alvo acompanha a rolagem    |
//| sem aritmetica extra.                                             |
//+------------------------------------------------------------------+

//--- pilha de linhas da carta em construcao
void RowsReset(void) { m_rowCount=0; }

void RowPush(const int kind,const string label,const string hint,
             const string value,const int aux,
             const bool enabled,const bool valid,
             const int fid=FCV_FLD_NONE)
  {
   if(m_rowCount>=FCV_ROWS_MAX) return;
   m_rows[m_rowCount].kind   =kind;
   m_rows[m_rowCount].label  =label;
   m_rows[m_rowCount].hint   =hint;
   m_rows[m_rowCount].value  =value;
   m_rows[m_rowCount].aux    =aux;
   m_rows[m_rowCount].fid    =fid;
   m_rows[m_rowCount].fid2   =FCV_FLD_NONE;   // so a linha de horario usa
   //--- Editavel so quando o perfil aceita edicao. E a camada de acesso da
   //--- 1.058: com o EA operando, os campos ficam bloqueados.
   //--- A trava so alcanca o que aceita interacao. Estatico, selo e nota sao
   //--- informacao operacional — apaga-los com o EA rodando tiraria a leitura
   //--- justamente quando ela mais importa, e "desabilitado" nem significa
   //--- nada para um texto que nunca respondeu a clique.
   bool interactive=(kind==FCV_ROW_FIELD  || kind==FCV_ROW_TOGGLE ||
                     kind==FCV_ROW_COMBO  || kind==FCV_ROW_COLOR  ||
                     kind==FCV_ROW_COLORSTYLE || kind==FCV_ROW_TIME);
   m_rows[m_rowCount].enabled=enabled && (!interactive || !FieldsLocked());
   m_rows[m_rowCount].valid  =valid;
   m_rowCount++;
  }

//--- Variantes ligadas a um campo de SEASettings: o valor exibido vem do
//--- rascunho e o clique/digitacao volta para ele. Nenhum valor padrao aqui —
//--- o padrao e o proprio rascunho.
void RowFieldF (const string label,const string hint,const int fid,
                const bool valid=true,const bool enabled=true)
  { RowPush(FCV_ROW_FIELD,label,hint,"",0,enabled,valid,fid); }
void RowToggleF(const string label,const int fid,const bool enabled=true)
  { RowPush(FCV_ROW_TOGGLE,label,"","",0,enabled,true,fid); }
void RowComboF (const string label,const int kind,const int fid,const bool enabled=true)
  { RowPush(FCV_ROW_COMBO,label,"","",kind,enabled,true,fid); }
//--- Horario: duas chaves numa linha so. fid recebe a hora e fid2 o minuto.
void RowTimeF  (const string label,const string hint,const int fidHour,const int fidMinute,
                const bool valid=true,const bool enabled=true)
  {
   RowPush(FCV_ROW_TIME,label,hint,"",0,enabled,valid,fidHour);
   if(m_rowCount>0) m_rows[m_rowCount-1].fid2=fidMinute;
  }

void RowField (const string label,const string hint,const string def,
               const bool valid=true,const bool enabled=true)
  { RowPush(FCV_ROW_FIELD,label,hint,def,0,enabled,valid); }
void RowToggle(const string label,const bool enabled=true)
  { RowPush(FCV_ROW_TOGGLE,label,"","",0,enabled,true); }
void RowCombo (const string label,const int kind,const bool enabled=true)
  { RowPush(FCV_ROW_COMBO,label,"","",kind,enabled,true); }
void RowColor (const string label,const bool enabled=true)
  { RowPush(FCV_ROW_COLOR,label,"","",0,enabled,true); }
void RowColorStyle(const string label,const bool enabled=true)
  { RowPush(FCV_ROW_COLORSTYLE,label,"","",FCV_COMBO_LINESTYLE,enabled,true); }
//--- Combo que nao obedece ao bloqueio do perfil: aparencia do painel nao e
//--- configuracao operacional, entao continua ajustavel com o EA rodando.
void RowComboFree(const string label,const int kind)
  {
   RowPush(FCV_ROW_COMBO,label,"","",kind,true,true);
   if(m_rowCount>0) m_rows[m_rowCount-1].enabled=true;
  }
void RowStatic(const string label,const string value,const int sem=FCV_SEM_NEUTRAL)
  { RowPush(FCV_ROW_STATIC,label,"",value,sem,true,true); }
void RowBadge (const string label,const string value,const int sem)
  { RowPush(FCV_ROW_BADGE,label,"",value,sem,true,true); }

//--- Estado de uma chave como SELO, para as telas de panorama. Chave apagada
//--- ali seria um controle que nao responde — o classico convite ao clique que
//--- nao faz nada. O selo diz a mesma coisa sem prometer interacao.
void RowState (const string label,const int fid)
  {
   bool on=FieldGetBool(fid);
   RowBadge(label,on ? "LIGADO" : "DESLIGADO",on ? FCV_SEM_GOOD : FCV_SEM_BAD);
  }
void RowNote  (const string text)
  { RowPush(FCV_ROW_NOTE,"",text,"",FCV_SEM_NEUTRAL,true,true); }
//--- Nota que carrega severidade. A 1.058 pinta de vermelho o rodape que avisa
//--- "operar sem SL e ARRISCADO" e de ambar o que explica um bloqueio em curso.
//--- Sem isso o aviso sai no mesmo cinza das notas comuns — um alerta que nao
//--- alerta e pior que nenhum, porque ocupa o lugar de um.
void RowNoteSem(const string text,const int sem)
  { RowPush(FCV_ROW_NOTE,"",text,"",sem,true,true); }

//--- altura de uma linha; a nota e a unica que depende do texto
int RowHeight(const int i)
  {
   switch(m_rows[i].kind)
     {
      case FCV_ROW_FIELD:  return FCV_ROW_FIELD_H;
      case FCV_ROW_TIME:   return FCV_ROW_TIME_H;
      case FCV_ROW_TOGGLE: return FCV_ROW_TOGGLE_H;
      //--- Combo com explicacao reserva a linha da dica SEMPRE, mesmo que o
      //--- texto mude com a escolha: a altura da carta e medida antes de
      //--- saber qual opcao esta ativa, e um cartao que muda de tamanho a
      //--- cada troca faria o resto da tela pular de lugar.
      case FCV_ROW_COMBO:  return ComboHasHint(m_rows[i].aux) ? FCV_ROW_FIELD_H : FCV_ROW_COMBO_H;
      case FCV_ROW_COLOR:  return FCV_ROW_COLOR_H;
      case FCV_ROW_STATIC: return FCV_ROW_STATIC_H;
      case FCV_ROW_BADGE:  return FCV_ROW_BADGE_H;
      case FCV_ROW_COLORSTYLE: return FCV_ROW_CSTYLE_H;
      case FCV_ROW_NOTE:
        {
         int lines=WrapText(m_fx1+12,0,m_fx2-m_fx1-24,15,m_rows[i].hint,m_t.faint,FCV_FS_CAP,false);
         return lines*15+6;
        }
     }
   return 0;
  }

uint SemColor(const int sem)
  {
   if(sem==FCV_SEM_GOOD) return m_t.good;
   if(sem==FCV_SEM_BAD)  return m_t.bad;
   if(sem==FCV_SEM_WARN) return m_t.warn;
   return m_t.fg;
  }

//--- Trilho da chave. Desligado em vermelho, nao em cinza: cinza e a cor de
//--- "indisponivel", e usa-la para "escolhi desligar" confundia as duas coisas.
//--- O vermelho e suavizado contra o fundo — o vermelho cheio e da paleta de
//--- ERRO, e um filtro desligado nao e defeito, e decisao.
uint ToggleTrack(const bool on,const bool en)
  {
   if(!en) return m_t.disabled;
   return on ? m_t.good : Blend(m_t.bad,m_t.surface,0.68);
  }

uint SemDim(const int sem)
  {
   if(sem==FCV_SEM_GOOD) return m_t.gdim;
   if(sem==FCV_SEM_BAD)  return m_t.bdim;
   if(sem==FCV_SEM_WARN) return m_t.wdim;
   return m_t.soft;
  }

//--- opcoes de cada tipo de combo
int ComboItems(const int kind,string &out[])
  {
   if(kind==FCV_COMBO_METHOD)
     { string a[4]={"SMA","EMA","SMMA","LWMA"}; ArrayResize(out,4); ArrayCopy(out,a); return 4; }
   if(kind==FCV_COMBO_PRICE)
     { string a[7]={"Close","Open","High","Low","Median","Typical","Weighted"};
       ArrayResize(out,7); ArrayCopy(out,a); return 7; }
   if(kind==FCV_COMBO_SIDE)
     { string a[3]={"Ambas","So Compra","So Venda"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   //--- Ordem do ENUM_NEWS_WINDOW_ACTION: BLOCK_ENTRIES=0, CLOSE_AND_BLOCK=1.
   //--- Abreviado porque a caixa do combo e estreita: "Fechar + Bloquear" por
   //--- extenso vazava para fora dela. Quem explica a acao inteira e a dica
   //--- logo abaixo — o rotulo so precisa distinguir as duas opcoes.
   if(kind==FCV_COMBO_NEWS)
     { string a[2]={"Bloquear","Fech. + Bloq."}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_ENTRY)
     { string a[2]={"Proxima Vela","2a Vela"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_EXIT)
     { string a[3]={"TP/SL","Sinal Oposto","Virar Mao (VM)"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   if(kind==FCV_COMBO_RSIEXIT)
     { string a[4]={"TP/SL","Sinal Oposto","Virar Mao (VM)","Cruz. Media"};
       ArrayResize(out,4); ArrayCopy(out,a); return 4; }
   if(kind==FCV_COMBO_RSIMODE)
     { string a[3]={"Saida da Zona","Dentro da Zona","Cruz. Media"};
       ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   if(kind==FCV_COMBO_RSIFILTER)
     { string a[3]={"Direcao","Neutro","Extremos"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   //--- Ordem do ENUM_BB_SIGNAL_MODE: FFFD e o indice 0 e o padrao do EA.
   if(kind==FCV_COMBO_BBMODE)
     { string a[3]={"FFFD","Toque/Rejeicao","Rompimento"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   if(kind==FCV_COMBO_BBWIDTH)
     { string a[2]={"Absoluto","Relativo %"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_STREAK)
     { string a[2]={"Pausar","Parar dia"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   //--- ⚠ As tres listas abaixo estavam na ORDEM INVERTIDA ate a Etapa 2b.
   //--- Enquanto nada as lia, o erro era so cosmetico; ligadas ao rascunho, o
   //--- indice E o valor do enum, e cada uma gravaria o oposto do escolhido:
   //--- "Parar" viraria ATIVAR_DD, "Financeiro" viraria PERCENTUAL. Ordem
   //--- conferida em Core/Types.mqh e nos FusionPopulate*Combo de PanelUtils.
   if(kind==FCV_COMBO_TARGET)     // PROFIT_ACTION_PARAR=0, ATIVAR_DD=1
     { string a[2]={"Parar","Ativar DD"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_DDTYPE)     // DD_TIPO_FINANCEIRO=0, PERCENTUAL=1
     { string a[2]={"Financeiro","Percentual"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   //--- "Meta Max.Ganho" (nome da 1.058) tambem vazava do combo. Encurtado para
   //--- "Max.Ganho", que e o nome do campo de onde a meta vem; a dica diz de
   //--- qual tela ele sai, que era a informacao que faltava mesmo no nome longo.
   if(kind==FCV_COMBO_DDPEAK)     // DD_PICO_REALIZADO=0, FLUTUANTE=1
     { string a[2]={"Max.Ganho","Pico Ganho"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_PALETTE)
     {
      //--- Nomes vindos da propria paleta, nao de uma copia. Com a lista
      //--- duplicada aqui, acrescentar uma paleta e esquecer esta linha faria
      //--- a nova existir sem aparecer no combo — ou aparecer com o nome de
      //--- outra. Assim, acrescentar paleta e mexer so no CanvasTheme.mqh.
      ArrayResize(out,FCV_PALETTE_COUNT);
      for(int p=0;p<FCV_PALETTE_COUNT;++p)
         out[p]=FusionCanvasPaletteName((ENUM_FUSION_CANVAS_PALETTE)p);
      return FCV_PALETTE_COUNT;
     }
   if(kind==FCV_COMBO_THEMEMODE)
     { string a[3]={"Automatico","Escuro","Claro"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   if(kind==FCV_COMBO_SCALE)
     { string a[FCV_SCALE_COUNT]={"Menor","Padrao","Maior"};
       ArrayResize(out,FCV_SCALE_COUNT); ArrayCopy(out,a); return FCV_SCALE_COUNT; }
   if(kind==FCV_COMBO_CONFLICT)
     { string a[2]={"Prioridade","Cancelar"}; ArrayResize(out,2); ArrayCopy(out,a); return 2; }
   if(kind==FCV_COMBO_LINESTYLE)
     { string a[3]={"Cheia","Tracejada","Pontilhada"}; ArrayResize(out,3); ArrayCopy(out,a); return 3; }
   //--- Os 21 timeframes da 1.058. A lista nao cabe aberta no painel: o popup
   //--- mostra uma janela de FCV_COMBO_WINDOW itens e rola.
   string a[21]={"M1","M2","M3","M4","M5","M6","M10","M12","M15","M20","M30",
                 "H1","H2","H3","H4","H6","H8","H12","D1","W1","MN1"};
   ArrayResize(out,21); ArrayCopy(out,a); return 21;
  }

//+------------------------------------------------------------------+
//| Explicacao da opcao escolhida num combo de modo.                  |
//|                                                                   |
//| A dica descreve o que esta SELECIONADO, nao o combo: "Modo" nao   |
//| diz nada, e uma legenda fixa obrigaria a abrir a lista para       |
//| descobrir o que a escolha atual faz. Mesma funcao da dica sob o   |
//| rotulo de um campo, aplicada a uma escolha.                       |
//+------------------------------------------------------------------+
bool ComboHasHint(const int kind)
  {
   switch(kind)
     {
      case FCV_COMBO_ENTRY:
      case FCV_COMBO_EXIT:
      case FCV_COMBO_RSIEXIT:
      case FCV_COMBO_RSIMODE:
      case FCV_COMBO_RSIFILTER:
      case FCV_COMBO_BBMODE:
      case FCV_COMBO_BBWIDTH:
      case FCV_COMBO_STREAK:
      case FCV_COMBO_TARGET:
      case FCV_COMBO_DDTYPE:
      case FCV_COMBO_DDPEAK:
      case FCV_COMBO_CONFLICT:
      case FCV_COMBO_NEWS:
      case FCV_COMBO_SIDE:
         return true;
     }
   return false;
  }

string ComboOptionHint(const int kind,const int idx)
  {
   switch(kind)
     {
      case FCV_COMBO_ENTRY:
         if(idx==0) return "Entra na abertura da vela seguinte ao sinal.";
         return "Espera mais uma vela antes de entrar.";
      case FCV_COMBO_EXIT:
         if(idx==0) return "Sai apenas no alvo ou no stop.";
         if(idx==1) return "Sai quando a estrategia sinaliza o lado contrario.";
         return "Sai e ja abre no lado contrario.";
      case FCV_COMBO_RSIEXIT:
         if(idx==0) return "Sai apenas no alvo ou no stop.";
         if(idx==1) return "Sai quando a estrategia sinaliza o lado contrario.";
         if(idx==2) return "Sai e ja abre no lado contrario.";
         return "Sai quando o RSI cruza a linha media.";
      case FCV_COMBO_RSIMODE:
         if(idx==0) return "Sinal quando o RSI deixa a zona extrema.";
         if(idx==1) return "Sinal enquanto o RSI permanece na zona.";
         return "Sinal quando o RSI cruza a linha media.";
      //--- Textos da 1.058 (UI/RSIFilterPanel.mqh). Os meus estavam errados nos
      //--- modos Neutro e Extremos, e o de Extremos dizia o INVERSO do que o
      //--- filtro faz — ele bloqueia nas zonas extremas, nao libera.
      case FCV_COMBO_RSIFILTER:
         if(idx==0) return "Direcao: BUY so acima da linha; SELL so abaixo.";
         if(idx==1) return "Neutro: bloqueia o meio; BUY so acima, SELL so abaixo.";
         return "Extremos: bloqueia qualquer entrada nas zonas extremas.";
      case FCV_COMBO_BBMODE:
         if(idx==0) return "Fechou fora, fechou dentro: entra no retorno para dentro das bandas.";
         if(idx==1) return "Entra quando o preco toca a banda e e rejeitado.";
         return "Entra quando o preco fecha fora da banda.";
      case FCV_COMBO_BBWIDTH:
         if(idx==0) return "Absoluto: mede largura das bandas em pontos do simbolo.";
         return "Relativo: mede largura das bandas como % da linha media.";
      case FCV_COMBO_STREAK:
         if(idx==0) return "Para por alguns minutos e volta sozinho.";
         return "Encerra o dia; so volta no proximo.";
      case FCV_COMBO_TARGET:
         if(idx==0) return "Ao bater a meta, encerra o dia.";
         return "Ao bater a meta, liga a protecao de drawdown.";
      //--- "Financeiro: valor; Percentual: % da base." (UIPanelProtectionSync).
      case FCV_COMBO_DDTYPE:
         if(idx==0) return "Limite medido em dinheiro.";
         return "Limite medido como % da base.";
      //--- A dica diz de ONDE vem a base, que e o que o nome curto nao cabe:
      //--- Max.Ganho e o campo da tela Limites Diarios.
      case FCV_COMBO_DDPEAK:
         if(idx==0) return "Base fixa: o Max.Ganho definido em Limites Diarios.";
         return "Pico Ganho acompanha o maior P/L bruto projetado.";
      case FCV_COMBO_CONFLICT:
         if(idx==0) return "Em sinais opostos, o maior numero vence.";
         return "Sinais opostos cancelam a entrada.";
      case FCV_COMBO_NEWS:
         if(idx==0) return "Impede novas entradas durante a janela.";
         return "Fecha posicoes abertas e impede novas entradas.";
      case FCV_COMBO_SIDE:
         if(idx==0) return "Aceita compra e venda.";
         if(idx==1) return "Recusa vendas.";
         return "Recusa compras.";
     }
   return "";
  }

//+------------------------------------------------------------------+
//| Controles compostos: desenham e publicam a caixa de clique.       |
//|                                                                   |
//| Existem porque duas linhas diferentes precisam do mesmo controle: |
//| a amostra de cor aparece sozinha e ao lado do estilo, e o combo   |
//| aparece na linha de modo e na de estilo de linha. Enquanto o      |
//| desenho estava copiado nos dois lugares, as copias divergiram —   |
//| um combo saiu com 26 px de altura e o outro com 22, em telas      |
//| vizinhas.                                                         |
//+------------------------------------------------------------------+
void PutSwatch(const int cx,const int cy,const int w,const int slot,const bool en)
  {
   int idx=m_stColor[slot];
   if(idx<0 || idx>=FCV_SWATCH_COUNT) idx=0;
   bool open=(en && m_colorOpen>=0 && m_colorOpen==m_colorCount);
   uint border= !en ? m_t.disabled : (open ? m_t.acc : m_t.line);
   //--- Bloqueada, a amostra e misturada ao fundo: cor viva num controle
   //--- morto passa a impressao de que aceita clique.
   uint fill  = !en ? Blend(m_swatches[idx],m_t.surface,0.35) : m_swatches[idx];
   RoundFrame(cx,cy,cx+w,cy+FCV_EDIT_H,FCV_RADIUS_CTRL-1,border,fill,m_t.surface);

   if(!en || m_colorCount>=FCV_CTRL_MAX) return;
   m_colorX[m_colorCount]=cx;
   m_colorY[m_colorCount]=cy;
   m_colorW[m_colorCount]=w;
   m_colorSlot[m_colorCount]=slot;
   m_colorCount++;
  }

//--- Registro de um campo nativo. O desenho em si e do BuildEdits — aqui so
//--- publicamos onde ele fica e o que deve mostrar. Ao contrario do combo e da
//--- chave, o campo BLOQUEADO tambem e registrado: ele continua existindo,
//--- apagado e somente-leitura, porque sumir com o valor esconderia justamente
//--- a informacao que explica por que a linha esta bloqueada.
void PutEdit(const int cx,const int cy,const int w,const int slot,const int fid,
             const string value,const bool en,const bool ok)
  {
   if(m_editCount>=FCV_CTRL_MAX) return;
   m_editX[m_editCount]=cx;
   m_editY[m_editCount]=cy;
   m_editW[m_editCount]=w;
   m_editSlot[m_editCount]=slot;
   m_editFid[m_editCount]=fid;
   m_editVal[m_editCount]=value;
   m_editEnabled[m_editCount]=en;
   m_editValid[m_editCount]=ok;
   m_editCount++;
  }

//--- Valor que o campo deve mostrar: do rascunho quando a linha declara um
//--- campo de SEASettings, do estado local da tela quando nao declara.
string EditValueFor(const int slot,const int fid,const string fallback)
  {
   if(fid!=FCV_FLD_NONE) return FieldGetText(fid);
   return (m_stEdit[slot]=="") ? fallback : m_stEdit[slot];
  }

void PutCombo(const int cx,const int cy,const int w,const int kind,
              const int slot,const bool en,const int fid=FCV_FLD_NONE)
  {
   string items[];
   int n=ComboItems(kind,items);
   int idx=(fid!=FCV_FLD_NONE) ? FieldGetIndex(fid) : m_stCombo[slot];
   if(idx<0 || idx>=n) idx=0;

   bool open=(en && m_comboOpen>=0 && m_comboOpen==m_comboCount);
   uint border= !en ? m_t.disabled : (open ? m_t.acc : m_t.line);
   uint fill  = !en ? m_t.fieldDim : m_t.inset;
   uint text  = !en ? m_t.disabled : m_t.fg;
   uint arrow = !en ? m_t.disabled : m_t.muted;
   RoundFrame(cx,cy,cx+w,cy+FCV_EDIT_H,FCV_RADIUS_CTRL-1,border,fill,m_t.surface);
   //--- Valor de combo e palavra, nao numero: vai na fonte de interface.
   //--- Consolas fica reservada ao que precisa alinhar em coluna.
   Txt(cx+10,cy+FCV_EDIT_H/2,items[idx],text,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   int ax=cx+w-15, ay=cy+FCV_EDIT_H/2-2;
   for(int k=0;k<4;++k) Rect(ax-3+k,ay+k,ax+3-k,ay+k,arrow);

   if(!en || m_comboCount>=FCV_CTRL_MAX) return;
   m_comboX[m_comboCount]=cx;
   m_comboY[m_comboCount]=cy;
   m_comboW[m_comboCount]=w;
   m_comboKind[m_comboCount]=kind;
   m_comboSlot[m_comboCount]=slot;
   m_comboFid[m_comboCount]=fid;
   m_comboCount++;
  }

//+------------------------------------------------------------------+
//| Desenha a carta acumulada e avanca o cursor vertical.             |
//+------------------------------------------------------------------+
void Card(const string title)
  {
   int inner=0;
   for(int i=0;i<m_rowCount;++i) inner+=RowHeight(i);
   int h=FCV_CARD_HEAD_H+inner+FCV_CARD_FOOT_H;
   int y=m_fy;

   RoundRect(m_fx1,y,m_fx2,y+h,FCV_RADIUS_CARD,m_t.surface,m_t.ground);
   Txt(m_fx1+12,y+18,title,m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);

   int ry=y+FCV_CARD_HEAD_H;
   for(int i=0;i<m_rowCount;++i)
     {
      int rh=RowHeight(i);
      DrawRow(i,ry,rh);
      ry+=rh;
     }

   m_fy=y+h+FCV_CARD_GAP;
   m_rowCount=0;
  }

//+------------------------------------------------------------------+
void DrawRow(const int i,const int ry,const int rh)
  {
   int lx=m_fx1+12, rx=m_fx2-12;

   if(m_rows[i].kind==FCV_ROW_NOTE)
     {
      uint noteClr=(m_rows[i].aux==FCV_SEM_NEUTRAL) ? m_t.faint : SemColor(m_rows[i].aux);
      WrapText(lx,ry+9,m_fx2-m_fx1-24,15,m_rows[i].hint,noteClr,FCV_FS_CAP,true);
      return;
     }

   bool en =m_rows[i].enabled;
   bool ok =m_rows[i].valid;
   //--- O rotulo carrega os dois estados: apagado quando bloqueado, vermelho
   //--- quando o valor ao lado esta invalido.
   uint labelClr = !en ? m_t.disabled : (ok ? m_t.fg : m_t.bad);
   uint hintClr  = !en ? m_t.disabled : m_t.faint;

   bool twoLine=((m_rows[i].kind==FCV_ROW_FIELD || m_rows[i].kind==FCV_ROW_TIME) &&
                 m_rows[i].hint!="") ||
                (m_rows[i].kind==FCV_ROW_COMBO && ComboHasHint(m_rows[i].aux));
   //--- Numa linha de duas alturas o rotulo fica em cima, a dica embaixo e o
   //--- controle no centro dos dois: a caixa da direita alinha com o conjunto
   //--- rotulo+dica, e nao so com o rotulo.
   int labelY=twoLine ? ry+14 : ry+rh/2;
   Txt(lx,labelY,m_rows[i].label,labelClr,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   if(twoLine)
      Txt(lx,ry+30,m_rows[i].hint,hintClr,FCV_FONT_UI,FCV_FS_CAP,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);

   switch(m_rows[i].kind)
     {
      case FCV_ROW_FIELD:
        {
         //--- O slot avanca mesmo quando o controle nao e registrado: o estado
         //--- pertence a posicao na tela e nao pode escorregar so porque uma
         //--- linha ficou bloqueada.
         int slot=NextSlot();
         int fid=m_rows[i].fid;
         PutEdit(rx-FCV_EDIT_W,ry+22-FCV_EDIT_H/2,FCV_EDIT_W,slot,fid,
                 EditValueFor(slot,fid,m_rows[i].value),en,ok);
         break;
        }

      case FCV_ROW_TIME:
        {
         //--- Duas caixas na coluna do campo comum: a hora abre a coluna, o
         //--- minuto encosta na direita, e o separador vive no vao entre elas.
         //--- Dois slots, um por caixa — compartilhar um faria a hora e o
         //--- minuto escreverem no mesmo estado.
         int slotH=NextSlot();
         int slotM=NextSlot();
         int cy=(twoLine ? ry+22 : ry+rh/2)-FCV_EDIT_H/2;
         int hx=rx-FCV_EDIT_W;
         int mx=rx-FCV_TIME_EDIT_W;
         PutEdit(hx,cy,FCV_TIME_EDIT_W,slotH,m_rows[i].fid,
                 EditValueFor(slotH,m_rows[i].fid,""),en,ok);
         Txt((hx+FCV_TIME_EDIT_W+mx)/2,cy+FCV_EDIT_H/2,":",
             !en ? m_t.disabled : m_t.faint,
             FCV_FONT_MONO,FCV_FS_VAL,FCV_FW_SEMI,TA_CENTER|TA_VCENTER);
         PutEdit(mx,cy,FCV_TIME_EDIT_W,slotM,m_rows[i].fid2,
                 EditValueFor(slotM,m_rows[i].fid2,""),en,ok);
         break;
        }

      case FCV_ROW_TOGGLE:
        {
         int slot=NextSlot();
         int fid=m_rows[i].fid;
         bool on=(fid!=FCV_FLD_NONE) ? FieldGetBool(fid) : m_stToggle[slot];
         int tx=rx-38, ty=ry+rh/2-10;
         RoundRect(tx,ty,tx+38,ty+21,10,ToggleTrack(on,en),m_t.surface);
         Disc(on?tx+28:tx+10,ty+10,8,!en ? m_t.fieldDim : m_t.ground);
         //--- Controle bloqueado nao publica caixa de clique. Nao basta parecer
         //--- desligado: ele nao pode responder.
         if(!en || m_toggleCount>=FCV_CTRL_MAX) break;
         m_toggleX[m_toggleCount]=tx;
         m_toggleY[m_toggleCount]=ty;
         m_toggleSlot[m_toggleCount]=slot;
         m_toggleFid[m_toggleCount]=fid;
         m_toggleCount++;
         break;
        }

      case FCV_ROW_COMBO:
        {
         int slot=NextSlot();
         int fid=m_rows[i].fid;
         int selIdx=(fid!=FCV_FLD_NONE) ? FieldGetIndex(fid) : m_stCombo[slot];
         //--- A explicacao acompanha a escolha atual, e por isso e resolvida
         //--- aqui, depois de saber o indice — nao na declaracao da tela.
         if(twoLine)
            Txt(lx,ry+30,ComboOptionHint(m_rows[i].aux,selIdx),hintClr,
                FCV_FONT_UI,FCV_FS_CAP,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
         //--- Mesma largura e mesma coluna do campo de digitacao. Alem do ritmo
         //--- visual, isso faz o popup cobrir exatamente a coluna onde os
         //--- OBJ_EDIT vivem — e sao eles que o popup precisa suprimir.
         int cyMid=twoLine ? ry+22 : ry+rh/2;
         PutCombo(rx-FCV_EDIT_W,cyMid-FCV_EDIT_H/2,FCV_EDIT_W,m_rows[i].aux,slot,en,fid);
         break;
        }

      case FCV_ROW_COLOR:
        PutSwatch(rx-FCV_SWATCH_W,ry+rh/2-FCV_EDIT_H/2,FCV_SWATCH_W,NextSlot(),en);
        break;

      case FCV_ROW_COLORSTYLE:
        {
         //--- Duas colunas a direita, na mesma linha do nome: a cor encosta no
         //--- estilo, e os dois pertencem visivelmente ao mesmo indicador.
         int slotColor=NextSlot();
         int slotStyle=NextSlot();
         int cy=ry+rh/2-FCV_EDIT_H/2;
         int styleX=rx-FCV_EDIT_W;
         PutSwatch(styleX-8-FCV_SWATCH_W_SLIM,cy,FCV_SWATCH_W_SLIM,slotColor,en);
         PutCombo (styleX,cy,FCV_EDIT_W,FCV_COMBO_LINESTYLE,slotStyle,en);
         break;
        }

      case FCV_ROW_STATIC:
        //--- numeros justificados a direita: alinhados a esquerda depois de um
        //--- nome, flutuam com o comprimento do nome e nao podem ser comparados
        Txt(rx,ry+rh/2,m_rows[i].value,SemColor(m_rows[i].aux),
            FCV_FONT_MONO,FCV_FS_VAL,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
        break;

      case FCV_ROW_BADGE:
        {
         int bw=TxtW(m_rows[i].value,FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD)+18;
         RoundRect(rx-bw,ry+rh/2-9,rx,ry+rh/2+9,FCV_RADIUS_PILL,SemDim(m_rows[i].aux),m_t.surface);
         Txt(rx-bw/2,ry+rh/2,m_rows[i].value,SemColor(m_rows[i].aux),
             FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
         break;
        }
     }
  }

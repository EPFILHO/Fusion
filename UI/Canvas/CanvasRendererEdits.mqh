//+------------------------------------------------------------------+
//| CanvasRendererEdits.mqh                                           |
//| Fragmento do corpo de CFusionCanvasRenderer — campos de digitacao |
//| nativos (OBJ_EDIT) sobre o canvas.                                |
//|                                                                   |
//| Regras permanentes do modelo hibrido:                             |
//|  - OBJ_EDIT criado DEPOIS do bitmap: ordem de desenho e ordem de  |
//|    criacao; OBJPROP_ZORDER so roteia mouse                        |
//|  - objeto nativo nao se recorta: campo que nao cabe INTEIRO na    |
//|    area visivel e destruido, nao reposicionado                    |
//|  - campo sob popup aberto nao e criado: pintaria por cima dele    |
//+------------------------------------------------------------------+

bool EditVisible(const int ly)
  { return (ly>=ContentTop() && ly+FCV_EDIT_H<=ContentBottom()); }

//--- Cores e travas de estado, aplicaveis tanto na criacao quanto na
//--- atualizacao de um campo que ja existe.
//--- Mesma tabela do FusionApplyEditStyle da 1.058: bloqueado vence invalido,
//--- porque um campo que nao aceita digitacao nao tem como ser corrigido e
//--- marca-lo de vermelho so confundiria.
void StyleEdit(const string n,const bool enabled,const bool valid)
  {
   uint bg     = !enabled ? m_t.fieldDim : (valid ? m_t.inset : m_t.fieldErr);
   uint border = !enabled ? m_t.disabled : (valid ? m_t.line  : m_t.bad);
   uint txt    = !enabled ? m_t.disabled : m_t.fg;
   ObjectSetInteger(m_chart,n,OBJPROP_BGCOLOR,ToChartColor(bg));
   ObjectSetInteger(m_chart,n,OBJPROP_BORDER_COLOR,ToChartColor(border));
   ObjectSetInteger(m_chart,n,OBJPROP_COLOR,ToChartColor(txt));
   ObjectSetInteger(m_chart,n,OBJPROP_READONLY,!enabled);
  }

//--- Esta e a terceira e ultima fronteira de escala: aqui as unidades logicas
//--- viram pixels de grafico. O resto do renderizador nunca ve a escala.
void MakeEdit(const string id,const int lx,const int ly,const int lw,const string v,
              const bool enabled,const bool valid)
  {
   string n=m_prefix+id;
   ObjectCreate(m_chart,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(m_chart,n,OBJPROP_XDISTANCE,m_px+S(lx));
   ObjectSetInteger(m_chart,n,OBJPROP_YDISTANCE,m_py+S(ly));
   ObjectSetInteger(m_chart,n,OBJPROP_XSIZE,S(lw));
   ObjectSetInteger(m_chart,n,OBJPROP_YSIZE,S(FCV_EDIT_H));
   ObjectSetInteger(m_chart,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   //--- Mesmo degrau tipografico dos numeros desenhados no canvas. O campo
   //--- nativo mede a fonte em pontos inteiros e o canvas em decimos, entao a
   //--- conversao arredonda — sem ela o valor dentro da caixa saia maior que
   //--- os valores da mesma coluna, que e o que fazia a coluna parecer torta.
   ObjectSetInteger(m_chart,n,OBJPROP_FONTSIZE,(S(FCV_FS_VAL)+5)/10);
   //--- Numero alinha a direita para as unidades ficarem numa coluna so. A
   //--- caixa estreita de hora/minuto e a excecao: dois digitos ocupam quase
   //--- toda a largura, nao ha coluna para alinhar, e centrado e como a 1.058
   //--- desenha (AddTimeEdit forca ALIGN_CENTER).
   ObjectSetInteger(m_chart,n,OBJPROP_ALIGN,(lw<FCV_EDIT_W) ? ALIGN_CENTER : ALIGN_RIGHT);
   ObjectSetInteger(m_chart,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(m_chart,n,OBJPROP_ZORDER,100);
   ObjectSetString (m_chart,n,OBJPROP_FONT,FCV_FONT_MONO);
   ObjectSetString (m_chart,n,OBJPROP_TEXT,v);
   StyleEdit(n,enabled,valid);
  }

void DestroyEdits(void)
  {
   ObjectsDeleteAll(m_chart,m_prefix+"edit_");
   m_liveEditCount=0;
  }

//--- Um campo deve existir agora?
bool EditWanted(const int i)
  {
   if(!EditVisible(m_editY[i])) return false;
   //--- campo sob popup aberto nao existe: o popup e desenhado no canvas e o
   //--- objeto nativo pintaria por cima dele
   if(m_popupOn &&
      m_editX[i] <= m_popupX2 && m_editX[i]+m_editW[i] >= m_popupX1 &&
      m_editY[i] <= m_popupY2 && m_editY[i]+FCV_EDIT_H >= m_popupY1) return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Sincroniza os campos nativos com a tela desenhada, por diferenca. |
//|                                                                   |
//| A versao anterior apagava todos e recriava a cada passada. Isso   |
//| quebrava de duas maneiras enquanto o usuario digitava: o campo em |
//| edicao era destruido sob o cursor — e o terminal deixava para tras|
//| o controle de edicao, que aparecia solto em posicao velha — e o   |
//| texto ainda nao confirmado era perdido no meio da digitacao.      |
//|                                                                   |
//| Agora o campo que continua existindo e apenas MOVIDO. So some o   |
//| que saiu da tela, so nasce o que entrou, e o texto so e reescrito |
//| quando o valor de origem muda de fato.                            |
//+------------------------------------------------------------------+
void BuildEdits(void)
  {
   if(m_minimized) { DestroyEdits(); return; }

   //--- 1) o que existe e nao e mais desejado, sai
   for(int k=m_liveEditCount-1;k>=0;--k)
     {
      bool keep=false;
      for(int i=0;i<m_editCount;++i)
         if(EditWanted(i) && m_liveEditSlot[k]==m_editSlot[i]) { keep=true; break; }
      if(keep) continue;
      ObjectDelete(m_chart,m_liveEditName[k]);
      for(int j=k;j<m_liveEditCount-1;++j)
        {
         m_liveEditName[j]=m_liveEditName[j+1];
         m_liveEditX[j]   =m_liveEditX[j+1];
         m_liveEditY[j]   =m_liveEditY[j+1];
         m_liveEditSlot[j]=m_liveEditSlot[j+1];
         m_liveEditFid[j] =m_liveEditFid[j+1];
         m_liveEditText[j]=m_liveEditText[j+1];
        }
      m_liveEditCount--;
     }

   //--- 2) o que e desejado: move o que ja existe, cria o que falta
   for(int i=0;i<m_editCount;++i)
     {
      if(!EditWanted(i)) continue;
      string id=StringFormat("edit_%d",m_editSlot[i]);
      string nm=m_prefix+id;

      int live=-1;
      for(int k=0;k<m_liveEditCount;++k)
         if(m_liveEditSlot[k]==m_editSlot[i]) { live=k; break; }

      if(live<0)
        {
         if(m_liveEditCount>=FCV_CTRL_MAX) continue;
         //--- NUNCA criar objeto nativo com o botao do mouse pressionado.
         //--- O popup do combo apaga os campos que ficam atras dele (o objeto
         //--- nativo pintaria por cima do desenho). Ao escolher um item, o
         //--- popup fecha e este BuildEdits recriava o campo exatamente sob o
         //--- cursor, com o botao ainda apertado — e o terminal entregava o
         //--- foco ao objeto recem-nascido. Era assim que clicar em "MN1"
         //--- acabava selecionando o campo "Desvio" que estava atras.
         //--- Adiado para a soltura do botao, que dispara um novo Render.
         if(m_mouseDown) { m_editsPending=true; continue; }
         MakeEdit(id,m_editX[i],m_editY[i],m_editW[i],m_editVal[i],m_editEnabled[i],m_editValid[i]);
         m_liveEditName[m_liveEditCount]=nm;
         m_liveEditX[m_liveEditCount]=m_editX[i];
         m_liveEditY[m_liveEditCount]=m_editY[i];
         m_liveEditSlot[m_liveEditCount]=m_editSlot[i];
         m_liveEditFid[m_liveEditCount]=m_editFid[i];
         m_liveEditText[m_liveEditCount]=m_editVal[i];
         m_liveEditCount++;
         continue;
        }
      m_liveEditFid[live]=m_editFid[i];

      if(m_liveEditX[live]!=m_editX[i] || m_liveEditY[live]!=m_editY[i])
        {
         ObjectSetInteger(m_chart,nm,OBJPROP_XDISTANCE,m_px+S(m_editX[i]));
         ObjectSetInteger(m_chart,nm,OBJPROP_YDISTANCE,m_py+S(m_editY[i]));
         m_liveEditX[live]=m_editX[i];
         m_liveEditY[live]=m_editY[i];
        }
      StyleEdit(nm,m_editEnabled[i],m_editValid[i]);
      //--- Texto so quando a origem muda. Reescrever a cada quadro apagaria o
      //--- que esta sendo digitado antes de o usuario confirmar.
      if(m_liveEditText[live]!=m_editVal[i])
        {
         ObjectSetString(m_chart,nm,OBJPROP_TEXT,m_editVal[i]);
         m_liveEditText[live]=m_editVal[i];
        }
     }
  }

//+------------------------------------------------------------------+
//| Foco de campo — deducao, porque o MQL5 nao informa.               |
//|                                                                   |
//| Com um OBJ_EDIT em edicao, o controle interno do terminal NAO     |
//| acompanha a mudanca de posicao do objeto: rolar o conteudo deixa  |
//| o controle parado, aparecendo solto sobre o painel. Nao existe    |
//| API para consultar nem para soltar o foco — as unicas solucoes    |
//| publicadas usam WinAPI via DLL, que nao cabe num EA distribuido.  |
//|                                                                   |
//| Tentamos soltar o foco por OBJPROP_TIMEFRAMES (o mesmo mecanismo  |
//| que a 1.058 usa para esconder controle nativo). Nao resolveu: o   |
//| controle sobrevive ao objeto sumir. Restou impedir a rolagem por  |
//| roda enquanto ha campo em edicao — barra, setas e arrasto seguem  |
//| funcionando, entao o bloqueio sempre tem saida.                   |
//|                                                                   |
//| O foco e anotado no clique e so e liberado quando o terminal      |
//| avisa que a edicao terminou (CHARTEVENT_OBJECT_ENDEDIT) ou quando |
//| o campo deixa de existir. Limpar no clique seguinte seria errado: |
//| clicar no canvas nem sempre encerra a edicao.                     |
//+------------------------------------------------------------------+
//--- Soltar o foco quando o clique foi para outro lugar. Esquecer o slot nao
//--- basta: o controle de edicao do terminal continua ativo e reapareceria
//--- solto sobre o painel ao rolar. Sem API para soltar o foco, a unica forma
//--- certa e destruir o objeto — o BuildEdits do mesmo quadro o recria na
//--- posicao correta, com o valor atual do rascunho.
void ReleaseEditFocus(void)
  {
   if(m_focusSlot<0) return;
   for(int k=0;k<m_liveEditCount;++k)
      if(m_liveEditSlot[k]==m_focusSlot)
        {
         //--- LER ANTES DE DESTRUIR. O objeto e a unica copia do que foi
         //--- digitado ate aqui: o terminal so avisa por ENDEDIT, e sair
         //--- clicando num botao nao gera esse aviso. Destruir sem ler jogava
         //--- fora o valor — digitar um periodo e clicar em SALVAR salvava o
         //--- valor antigo. Sair do campo confirma o que esta nele, que e o que
         //--- a 1.058 faz ao ler os controles na hora de salvar.
         if(ObjectFind(m_chart,m_liveEditName[k])>=0)
           {
            string txt=ObjectGetString(m_chart,m_liveEditName[k],OBJPROP_TEXT);
            if(m_liveEditFid[k]!=FCV_FLD_NONE)
               FieldSetText(m_liveEditFid[k],txt);   // pendencia vem da diferenca
            else if(m_focusSlot>=0 && m_focusSlot<FCV_STATE_MAX && txt!=m_liveEditText[k])
              {
               //--- Compara com o que NOS escrevemos no objeto, nao com o slot:
               //--- o slot nasce vazio enquanto o campo ja mostra o padrao
               //--- declarado da linha, e comparar com ele acusava alteracao so
               //--- por entrar e sair de um campo intocado.
               m_stEdit[m_focusSlot]=txt;
              }
           }
         ObjectDelete(m_chart,m_liveEditName[k]);
         //--- Sai tambem do registro de vivos: deixado la, o proximo quadro
         //--- tentaria mover um objeto que nao existe mais e o campo sumiria.
         for(int j=k;j<m_liveEditCount-1;++j)
           {
            m_liveEditName[j]=m_liveEditName[j+1];
            m_liveEditX[j]   =m_liveEditX[j+1];
            m_liveEditY[j]   =m_liveEditY[j+1];
            m_liveEditSlot[j]=m_liveEditSlot[j+1];
            m_liveEditFid[j] =m_liveEditFid[j+1];
            m_liveEditText[j]=m_liveEditText[j+1];
           }
         m_liveEditCount--;
         break;
        }
   m_focusSlot=-1;
  }

void NoteEditFocus(const int lx,const int ly)
  {
   for(int i=0;i<m_editCount;++i)
      if(m_editEnabled[i] &&
         lx>=m_editX[i] && lx<m_editX[i]+m_editW[i] &&
         ly>=m_editY[i] && ly<m_editY[i]+FCV_EDIT_H)
        { m_focusSlot=m_editSlot[i]; return; }
   //--- Clique fora de qualquer campo encerra a edicao. Sem isto o foco so
   //--- morria por ENDEDIT, que nao vem quando o usuario sai clicando num
   //--- botao — e a roda ficava bloqueada indefinidamente.
   ReleaseEditFocus();
  }

//--- Ha campo em edicao agora? Se o objeto ja nao existe (troca de aba,
//--- rolagem que o levou para fora), o foco morreu com ele.
bool EditHasFocus(void)
  {
   if(m_focusSlot<0) return false;
   if(ObjectFind(m_chart,m_prefix+StringFormat("edit_%d",m_focusSlot))<0)
     { m_focusSlot=-1; return false; }
   return true;
  }

//--- O slot pertence ao formulario de criar/duplicar perfil?
//---
//--- Importa porque o que se digita ali NAO e alteracao do perfil ativo: e o
//--- rascunho de um perfil que ainda nao existe — e por isso os dois campos sao
//--- LOCAIS, sem ligacao com SEASettings. Quem os le e o comando de criar, que
//--- os pega do slot na hora do clique.
bool SlotIsProfileForm(const int slot)
  { return (slot>=0 && (slot/FCV_SLOT_MAX)==FCV_SCREEN_PROFILE_EDIT); }

//--- Zera os campos do formulario de perfil (nome e magic).
void ClearProfileForm(void)
  {
   for(int i=0;i<FCV_SLOT_MAX;++i)
      m_stEdit[FCV_SCREEN_PROFILE_EDIT*FCV_SLOT_MAX+i]="";
  }

//--- O texto digitado volta para o slot da tela, nao para uma posicao na
//--- lista: a lista se refaz a cada passada, o slot nao.
void StoreEditText(const string objName)
  {
   string tail=StringSubstr(objName,StringLen(m_prefix+"edit_"));
   int slot=(int)StringToInteger(tail);
   if(slot<0 || slot>=FCV_STATE_MAX) return;
   //--- O objeto pode ja ter sido destruido (troca de tela, foco solto). Ler
   //--- dele devolveria "" e gravaria zero no campo — um valor apagado sem que
   //--- o usuario tenha digitado nada.
   if(ObjectFind(m_chart,objName)<0) return;
   string txt=ObjectGetString(m_chart,objName,OBJPROP_TEXT);
   //--- O identificador de campo vem do registro vivo, nao do nome do objeto:
   //--- o nome carrega so o slot, e o mesmo slot serve telas diferentes.
   int fid=FCV_FLD_NONE, live=-1;
   for(int k=0;k<m_liveEditCount;++k)
      if(m_liveEditName[k]==objName) { fid=m_liveEditFid[k]; live=k; break; }
   if(fid!=FCV_FLD_NONE)
     {
      FieldSetText(fid,txt);          // pendencia vem da diferenca
      //--- O rascunho normaliza o texto (" 14 " vira "14"). Guardar o que o
      //--- campo mostra evita que a sincronizacao por diferenca reescreva o
      //--- objeto no quadro seguinte e mova o cursor do usuario.
      if(live>=0) m_liveEditText[live]=txt;
      return;
     }
   //--- Compara com o que NOS escrevemos, nao com o slot: ele nasce vazio
   //--- enquanto o campo ja mostra o padrao declarado da linha.
   if(live>=0 && m_liveEditText[live]==txt) return;
   if(m_stEdit[slot]==txt) return;
   m_stEdit[slot]=txt;
   if(live>=0) m_liveEditText[live]=txt;
  }

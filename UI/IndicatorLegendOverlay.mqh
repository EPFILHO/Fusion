#ifndef __FUSION_INDICATOR_LEGEND_OVERLAY_MQH__
#define __FUSION_INDICATOR_LEGEND_OVERLAY_MQH__

#define FUSION_LEGEND_MIN_WIDTH  180
#define FUSION_LEGEND_MAX_WIDTH  300
#define FUSION_LEGEND_CHAR_WIDTH 6
#define FUSION_LEGEND_HEIGHT 136
#define FUSION_LEGEND_RIGHT  20
#define FUSION_LEGEND_TOP    40

//+------------------------------------------------------------------+
//| Legenda das medias — arrastavel pelo fundo.                       |
//|                                                                    |
//| ⚠ DOIS conceitos de posicao, e confundi-los quebra o              |
//| redimensionamento:                                                 |
//|                                                                    |
//|   DESEJADA (m_desiredLeft/Top) — onde o usuario POS a legenda. So  |
//|     muda quando ele conclui um arrasto. Nunca e sobrescrita por    |
//|     redimensionamento de grafico, troca de largura ou update de    |
//|     texto.                                                         |
//|   EFETIVA (m_left/m_top) — onde ela e realmente desenhada, ou      |
//|     seja, a desejada depois do clamp nas bordas.                   |
//|                                                                    |
//| E por isso que encolher o grafico e depois maximizar devolve a     |
//| legenda ao lugar escolhido: o clamp mexeu so na efetiva.           |
//|                                                                    |
//| A posicao e preferencia VISUAL por grafico: nao pertence ao        |
//| perfil, nao passa por SALVAR, nao cria pendencia e nao toca schema |
//| nem chart state. Vive em variavel global do terminal, como paleta, |
//| tema e escala do painel (ver CanvasRendererPrefs.mqh).             |
//+------------------------------------------------------------------+
class CIndicatorLegendOverlay
  {
private:
   long m_chartId;
   bool m_created;
   //--- Posicao EFETIVA (desenhada), ja com clamp.
   int  m_left;
   int  m_top;
   int  m_width;
   //--- Posicao DESEJADA pelo usuario. So o fim de um arrasto a altera.
   bool m_hasDesired;
   int  m_desiredLeft;
   int  m_desiredTop;
   //--- Arrasto manual. m_prevButtonDown existe para detectar a BORDA de
   //--- pressao: sem ela, arrastar o grafico e passar por cima da legenda
   //--- sequestraria o cursor no meio do movimento.
   bool m_dragging;
   bool m_prevButtonDown;
   int  m_grabDX;
   int  m_grabDY;
   bool m_savedScroll;
   //--- Zona proibida: o retangulo interativo do painel, publicado de fora.
   //--- A legenda nao conhece o painel, so a area que nao pode ocupar.
   bool m_hasExclusion;
   int  m_exLeft;
   int  m_exTop;
   int  m_exRight;
   int  m_exBottom;

   string ObjectName(const string role) const
     {
      return "Fusion_indicator_legend_" + role + "_" + StringFormat("%I64d", m_chartId);
     }

   //--- Chaves da preferencia. O ChartID entra no nome para que dois
   //--- graficos nunca compartilhem posicao.
   string PrefKeyX(void) const
     { return "Fusion2_Legenda_X_" + StringFormat("%I64d", m_chartId); }
   string PrefKeyY(void) const
     { return "Fusion2_Legenda_Y_" + StringFormat("%I64d", m_chartId); }

   //--- Uma coordenada so vale se for numero finito e estiver numa faixa
   //--- plausivel de pixel. Lixo vira default, nunca posicao negativa.
   bool ValidCoordinate(const double value) const
     {
      if(!MathIsValidNumber(value))
         return false;
      return (value >= 0.0 && value <= 100000.0);
     }

   //--- Os DOIS valores precisam existir. Meio par e par nenhum: aplicar so
   //--- o X deixaria a legenda num lugar que o usuario nunca escolheu.
   void LoadDesired(void)
     {
      m_hasDesired = false;
      string keyX = PrefKeyX();
      string keyY = PrefKeyY();
      if(!GlobalVariableCheck(keyX) || !GlobalVariableCheck(keyY))
         return;

      double x = GlobalVariableGet(keyX);
      double y = GlobalVariableGet(keyY);
      if(!ValidCoordinate(x) || !ValidCoordinate(y))
         return;

      m_desiredLeft = (int)x;
      m_desiredTop  = (int)y;
      m_hasDesired  = true;
     }

   //--- Gravada somente no fim de um arrasto valido. Nunca por tick, por
   //--- timer nem por redimensionamento.
   void SaveDesired(void)
     {
      GlobalVariableSet(PrefKeyX(), (double)m_desiredLeft);
      GlobalVariableSet(PrefKeyY(), (double)m_desiredTop);
     }

   //--- Unico lugar que decide o que cabe na tela. Criacao, arrasto, update
   //--- e redimensionamento passam por aqui — contas repetidas em quatro
   //--- lugares divergem no dia em que uma delas muda.
   void ClampToChart(int &left,int &top) const
     {
      int chartWidth  = (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      int chartHeight = (int)ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS, 0);

      int maxLeft = chartWidth  - m_width;
      int maxTop  = chartHeight - FUSION_LEGEND_HEIGHT;
      //--- Grafico menor que a propria legenda: encosta no zero em vez de
      //--- produzir coordenada negativa.
      if(maxLeft < 0) maxLeft = 0;
      if(maxTop  < 0) maxTop  = 0;

      if(left > maxLeft) left = maxLeft;
      if(top  > maxTop)  top  = maxTop;
      if(left < 0)       left = 0;
      if(top  < 0)       top  = 0;
     }

   bool CreateBackground(void)
     {
      string name = ObjectName("background");
      ObjectDelete(m_chartId, name);
      if(!ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;

      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top);
      ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, FUSION_LEGEND_HEIGHT);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
      //--- ⚠ SELECTABLE continua FALSE, e e proposital.
      //---
      //--- O arrasto nativo do MT5 (CHARTEVENT_OBJECT_DRAG) exige que o objeto
      //--- esteja SELECIONADO, e selecionar depende da preferencia "selecionar
      //--- objeto com um clique" do terminal: sem ela, o usuario precisa de
      //--- duplo clique e ainda ganha a moldura de selecao em volta da legenda.
      //--- Amarrar a usabilidade do produto a uma opcao global do MT5 nao e
      //--- aceitavel, entao o arrasto e feito a mao por CHARTEVENT_MOUSE_MOVE.
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
      //--- ZORDER 0 de proposito: acima disto a legenda passaria a capturar
      //--- cliques que pertencem ao painel.
      ObjectSetInteger(m_chartId, name, OBJPROP_ZORDER, 0);
      return true;
     }

   bool CreateLabel(const string role,const int top,const color textColor,const int fontSize)
     {
      string name = ObjectName(role);
      ObjectDelete(m_chartId, name);
      if(!ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0))
         return false;

      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left + 12);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top + top);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, name, OBJPROP_ZORDER, 0);
      ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial");
      return true;
     }

   void PositionLabel(const string role,const int top)
     {
      string name = ObjectName(role);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left + 12);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top + top);
     }

   void Layout(void)
     {
      string background = ObjectName("background");
      ObjectSetInteger(m_chartId, background, OBJPROP_XDISTANCE, m_left);
      ObjectSetInteger(m_chartId, background, OBJPROP_YDISTANCE, m_top);
      ObjectSetInteger(m_chartId, background, OBJPROP_XSIZE, m_width);
      PositionLabel("title", 8);
      PositionLabel("fast", 32);
      PositionLabel("slow", 56);
      PositionLabel("trend", 80);
      PositionLabel("trend2", 104);
     }

   //--- Posicao de fabrica: canto superior direito, com as mesmas margens de
   //--- sempre. Vale enquanto o usuario nao tiver movido a legenda.
   void AlignUpperRight(void)
     {
      int chartWidth = (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      m_left = MathMax(0, chartWidth - m_width - FUSION_LEGEND_RIGHT);
      m_top  = FUSION_LEGEND_TOP;
      ClampToChart(m_left, m_top);
     }

   bool InsideLegend(const int cx,const int cy) const
     {
      return (cx >= m_left && cx < m_left + m_width &&
              cy >= m_top  && cy < m_top  + FUSION_LEGEND_HEIGHT);
     }

   bool InsideExclusion(const int cx,const int cy) const
     {
      if(!m_hasExclusion)
         return false;
      return (cx >= m_exLeft && cx < m_exRight &&
              cy >= m_exTop  && cy < m_exBottom);
     }

   //--- A legenda proposta encosta na zona proibida?
   bool Overlaps(const int left,const int top) const
     {
      if(!m_hasExclusion)
         return false;
      return (left < m_exRight && left + m_width > m_exLeft &&
              top  < m_exBottom && top + FUSION_LEGEND_HEIGHT > m_exTop);
     }

   //--- Desvio da zona proibida.
   //---
   //--- Algoritmo: se a posicao proposta colide com o painel, geram-se as
   //--- quatro posicoes imediatamente adjacentes aos lados dele — esquerda,
   //--- direita, acima, abaixo — mantendo a outra coordenada como o usuario
   //--- pediu. Cada candidata passa pelo clamp do grafico, as que ainda colidem
   //--- ou nao cabem sao descartadas, e vence a mais proxima da proposta.
   //---
   //--- E isso que produz o deslizar pela borda em vez de salto: encostando por
   //--- cima, a candidata vencedora e a de cima, e o eixo livre segue o cursor.
   //--- Sem candidata valida (grafico pequeno demais), devolve a proposta ja
   //--- limitada — e quem protege o painel e a prioridade de clique.
   void AvoidExclusion(int &left,int &top) const
     {
      if(!Overlaps(left, top))
         return;

      int candLeft[4];
      int candTop[4];
      candLeft[0] = m_exLeft - m_width;  candTop[0] = top;                            // esquerda
      candLeft[1] = m_exRight;           candTop[1] = top;                            // direita
      candLeft[2] = left;                candTop[2] = m_exTop - FUSION_LEGEND_HEIGHT; // acima
      candLeft[3] = left;                candTop[3] = m_exBottom;                     // abaixo

      bool found = false;
      int  bestLeft = left;
      int  bestTop  = top;
      long bestCost = 0;

      for(int i = 0; i < 4; i++)
        {
         int cl = candLeft[i];
         int ct = candTop[i];
         ClampToChart(cl, ct);
         if(Overlaps(cl, ct))
            continue;

         long dx = (long)(cl - left);
         long dy = (long)(ct - top);
         long cost = dx * dx + dy * dy;
         if(!found || cost < bestCost)
           {
            found = true;
            bestCost = cost;
            bestLeft = cl;
            bestTop  = ct;
           }
        }

      if(found)
        {
         left = bestLeft;
         top  = bestTop;
        }
     }

   //--- Ordem obrigatoria: primeiro o que cabe na tela, depois o desvio do
   //--- painel. Invertida, o desvio poderia jogar a legenda para fora.
   void ResolvePosition(int &left,int &top) const
     {
      ClampToChart(left, top);
      AvoidExclusion(left, top);
     }

   //--- Enquanto arrasta, o grafico nao pode rolar junto. O valor anterior e
   //--- guardado e devolvido no fim — o painel usa o mesmo padrao, e sobrepor
   //--- um "false" fixo apagaria a preferencia de quem usa scroll.
   void BeginDrag(const int cx,const int cy)
     {
      m_dragging    = true;
      m_grabDX      = cx - m_left;
      m_grabDY      = cy - m_top;
      m_savedScroll = (bool)ChartGetInteger(m_chartId, CHART_MOUSE_SCROLL);
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, false);
     }

   void EndDrag(void)
     {
      if(!m_dragging)
         return;
      m_dragging = false;
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_savedScroll);

      //--- Onde parou vira a posicao desejada, e so aqui a preferencia e
      //--- gravada. Nunca por tick, timer ou redimensionamento.
      m_desiredLeft = m_left;
      m_desiredTop  = m_top;
      m_hasDesired  = true;
      SaveDesired();
      ChartRedraw(m_chartId);
     }

   //--- ⚠ TODO caminho que reposiciona a legenda passa por aqui. Antes,
   //--- criacao, mudanca de largura e CHART_CHANGE chamavam AlignUpperRight
   //--- direto, e qualquer um deles jogava a legenda de volta ao canto
   //--- depois de o usuario te-la movido.
   void ApplyPosition(void)
     {
      if(m_hasDesired)
        {
         m_left = m_desiredLeft;
         m_top  = m_desiredTop;
         ResolvePosition(m_left, m_top);
        }
      else
        {
         AlignUpperRight();
         //--- O canto superior direito tambem pode estar ocupado: painel
         //--- movido para la, ou grafico estreito.
         ResolvePosition(m_left, m_top);
        }

      Layout();
     }

   int RequiredWidth(const string fastText,const string slowText,const string trendText,const string trend2Text) const
     {
      int longest = MathMax(StringLen("Legenda Médias"), StringLen(fastText));
      longest = MathMax(longest, StringLen(slowText));
      longest = MathMax(longest, StringLen(trendText));
      longest = MathMax(longest, StringLen(trend2Text));
      int estimated = 24 + longest * FUSION_LEGEND_CHAR_WIDTH;
      return MathMax(FUSION_LEGEND_MIN_WIDTH, MathMin(FUSION_LEGEND_MAX_WIDTH, estimated));
     }

public:
          CIndicatorLegendOverlay(void)
     {
      m_chartId = 0;
      m_created = false;
      m_left = 0;
      m_top = 0;
      m_width = FUSION_LEGEND_MIN_WIDTH;
      m_hasDesired  = false;
      m_dragging       = false;
      m_prevButtonDown = false;
      m_grabDX         = 0;
      m_grabDY         = 0;
      m_savedScroll    = true;
      m_hasExclusion   = false;
      m_exLeft         = 0;
      m_exTop          = 0;
      m_exRight        = 0;
      m_exBottom       = 0;
      m_desiredLeft = 0;
      m_desiredTop  = 0;
     }

         ~CIndicatorLegendOverlay(void)
     {
      Destroy(REASON_REMOVE);
     }

   bool   IsCreated(void)
     {
      if(!m_created)
         return false;
      if(ObjectFind(m_chartId, ObjectName("background")) >= 0)
         return true;
      m_created = false;
      return false;
     }

   bool   CreateLegend(const long chartId,const int left,const int top)
     {
      m_chartId = chartId;
      m_left = left;
      m_top = top;
      m_width = FUSION_LEGEND_MIN_WIDTH;

      if(!CreateBackground() ||
         !CreateLabel("title", 8, clrWhite, 9) ||
         !CreateLabel("fast", 32, clrLime, 8) ||
         !CreateLabel("slow", 56, clrRed, 8) ||
         !CreateLabel("trend", 80, clrMagenta, 8) ||
         !CreateLabel("trend2", 104, clrOrange, 8))
        {
         Destroy(REASON_REMOVE);
         return false;
        }

      ObjectSetString(m_chartId, ObjectName("title"), OBJPROP_TEXT, "Legenda Médias");
      m_created = true;

      //--- ⚠ Sem isto o arrasto simplesmente nao acontece. Hoje quem liga o
      //--- evento de mouse e o painel canvas (CanvasRenderer), e a legenda
      //--- existe tambem quando o painel esta oculto — depender dele deixaria a
      //--- legenda presa nesses casos. Ligar duas vezes e inofensivo, e o
      //--- evento NUNCA e desligado no Destroy, porque o painel pode precisar
      //--- dele.
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);
      //--- A preferencia e relida a cada criacao: desligar e religar os
      //--- indicadores, ou reconstrui-los por mudanca de fingerprint, tem de
      //--- devolver a legenda onde o usuario a deixou.
      LoadDesired();
      ApplyPosition();
      return true;
     }

   bool   StartDialog(void)
     {
      ChartRedraw(m_chartId);
      return m_created;
     }

   void   Update(const string fastText,
                 const string slowText,
                 const string trendText,
                 const string trend2Text,
                 const color fastColor,
                 const color slowColor,
                 const color trendColor,
                 const color trend2Color)
     {
      if(!IsCreated())
         return;
      int requiredWidth = RequiredWidth(fastText, slowText, trendText, trend2Text);
      if(requiredWidth != m_width)
        {
         m_width = requiredWidth;
         if(m_dragging)
           {
            //--- ⚠ Durante o arrasto, NAO se parte da posicao desejada: ela
            //--- ainda e a anterior, e a legenda saltaria para o lugar antigo
            //--- no meio do movimento. Aqui a verdade e a posicao EFETIVA, que
            //--- esta debaixo do cursor — so o clamp precisa ser refeito com a
            //--- largura nova.
            ResolvePosition(m_left, m_top);
            Layout();
           }
         else
           {
            //--- A largura muda com o texto, entao o clamp precisa ser refeito —
            //--- mas a posicao DESEJADA nao se perde: ApplyPosition parte dela.
            ApplyPosition();
           }
        }
      ObjectSetString(m_chartId, ObjectName("fast"), OBJPROP_TEXT, fastText);
      ObjectSetString(m_chartId, ObjectName("slow"), OBJPROP_TEXT, slowText);
      ObjectSetString(m_chartId, ObjectName("trend"), OBJPROP_TEXT, trendText);
      ObjectSetString(m_chartId, ObjectName("trend2"), OBJPROP_TEXT, trend2Text);
      ObjectSetInteger(m_chartId, ObjectName("fast"), OBJPROP_COLOR, fastColor);
      ObjectSetInteger(m_chartId, ObjectName("slow"), OBJPROP_COLOR, slowColor);
      ObjectSetInteger(m_chartId, ObjectName("trend"), OBJPROP_COLOR, trendColor);
      ObjectSetInteger(m_chartId, ObjectName("trend2"), OBJPROP_COLOR, trend2Color);
     }

   //--- Publica a zona proibida. A legenda nao conhece o painel: recebe so um
   //--- retangulo de quem enxerga os dois. Sem retangulo valido, nao ha area
   //--- proibida.
   //---
   //--- Reposiciona na hora se a legenda ficou coberta — o painel pode ter sido
   //--- movido, restaurado ou aberto por cima dela. So a posicao EFETIVA muda:
   //--- a desejada continua guardada, para a legenda voltar quando o painel
   //--- sair da frente.
   void   SetPanelExclusion(const bool valid,const int left,const int top,const int right,const int bottom)
     {
      m_hasExclusion = valid;
      m_exLeft   = left;
      m_exTop    = top;
      m_exRight  = right;
      m_exBottom = bottom;

      if(!m_created || m_dragging)
         return;

      int newLeft = m_left;
      int newTop  = m_top;
      //--- Parte da DESEJADA quando existe: se o painel liberou a area, ela
      //--- volta sozinha para o lugar escolhido.
      if(m_hasDesired)
        {
         newLeft = m_desiredLeft;
         newTop  = m_desiredTop;
        }
      ResolvePosition(newLeft, newTop);

      if(newLeft != m_left || newTop != m_top)
        {
         m_left = newLeft;
         m_top  = newTop;
         Layout();
         ChartRedraw(m_chartId);
        }
     }

   //--- Devolve TRUE quando o gesto pertence a legenda — pressao que inicia o
   //--- arrasto, movimento durante ele e a soltura que o encerra.
   //---
   //--- ⚠ Quem chama NAO pode repassar esse evento adiante. O hit-test aqui e
   //--- manual, entao ZORDER nao protege nada: o mesmo CHARTEVENT_MOUSE_MOVE
   //--- chega a legenda e ao painel, e sem este aviso os dois reagiam ao mesmo
   //--- gesto — com a legenda parada sobre o painel, arrastava-se os dois de
   //--- uma vez. Tambem e o que evita os dois disputarem CHART_MOUSE_SCROLL.
   bool   ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_created)
         return false;

      //--- Arrasto proprio, sem selecao de objeto.
      //---
      //--- lparam e dparam sao a posicao do cursor; o bit 0 de sparam diz se o
      //--- botao esquerdo esta pressionado — a mesma leitura que o painel faz.
      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         int  cx   = (int)lparam;
         int  cy   = (int)dparam;
         bool down = (StringToInteger(sparam) & 1) != 0;
         bool pressedNow = (down && !m_prevButtonDown);
         m_prevButtonDown = down;

         if(m_dragging)
           {
            if(!down)
              {
               EndDrag();
               //--- ⚠ A soltura NAO e consumida, e isto e deliberado.
               //---
               //--- O painel so age na borda de DESCIDA do botao
               //--- (`down && !m_mouseDown && over`), entao soltar nunca vira
               //--- clique nele. O que ele faz com este evento e sincronizar
               //--- m_overPanel, m_mouseDown e CHART_MOUSE_SCROLL. Engolir a
               //--- soltura deixaria o scroll errado ate o mouse se mover de
               //--- novo — justamente ao terminar o arrasto sobre o painel.
               //---
               //--- A ordem ajuda: o EndDrag acima ja devolveu o scroll que a
               //--- legenda tomou emprestado, e o painel decide por ultimo.
               return false;
              }

            int left = cx - m_grabDX;
            int top  = cy - m_grabDY;
            ResolvePosition(left, top);
            //--- Redesenha so quando a posicao muda de fato. Movimento de mouse
            //--- gera muito evento, e repintar sem mudanca e desperdicio.
            if(left != m_left || top != m_top)
              {
               m_left = left;
               m_top  = top;
               Layout();
               ChartRedraw(m_chartId);
              }
            return true;
           }

         //--- ⚠ REDE DE SEGURANCA: dentro do retangulo da GUI, a legenda nao
         //--- pega o gesto, ponto. A exclusao geometrica ja deveria impedir que
         //--- ela estivesse ali, mas uma posicao antiga salva, um painel que se
         //--- moveu ou um grafico pequeno demais podem produzir sobreposicao —
         //--- e nesse caso combobox, aba ou botao nao podem ficar mudos por
         //--- causa de uma legenda que esta VISUALMENTE ATRAS.
         if(InsideExclusion(cx, cy))
            return false;

         //--- So comeca numa pressao NOVA dentro da legenda. Fora dela o evento
         //--- termina aqui sem tocar em nada: zoom, rolagem e arrasto do
         //--- grafico seguem normais.
         if(pressedNow && InsideLegend(cx, cy))
           {
            BeginDrag(cx, cy);
            return true;
           }
         return false;
        }

      //--- Redimensionamento: refaz o clamp e NADA MAIS. A posicao desejada e
      //--- a preferencia gravada ficam intactas, para a legenda poder voltar
      //--- ao lugar escolhido quando o grafico crescer de novo.
      //---
      //--- Ignorado durante o arrasto: reposicionar debaixo do cursor faria a
      //--- legenda pular da mao do usuario.
      if(id == CHARTEVENT_CHART_CHANGE && !m_dragging)
        {
         ApplyPosition();
         ChartRedraw(m_chartId);
        }
      //--- Redimensionamento nao e gesto: o painel precisa recebe-lo tambem.
      return false;
     }

   //--- ⚠ NAO apaga a preferencia de posicao. Destroy roda ao desligar os
   //--- indicadores, ao reconstrui-los e ao remover o EA; apagar a variavel
   //--- global aqui faria a legenda voltar ao canto em todos esses casos.
   //--- Objetos sao descartaveis, a preferencia do usuario nao e.
   void   Destroy(const int reason=REASON_REMOVE)
     {
      //--- Se os indicadores forem desligados no meio de um arrasto, o grafico
      //--- ficaria sem rolagem para sempre. Devolve o que foi emprestado.
      if(m_dragging)
        {
         m_dragging = false;
         ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_savedScroll);
        }
      m_prevButtonDown = false;

      ObjectDelete(m_chartId, ObjectName("title"));
      ObjectDelete(m_chartId, ObjectName("fast"));
      ObjectDelete(m_chartId, ObjectName("slow"));
      ObjectDelete(m_chartId, ObjectName("trend"));
      ObjectDelete(m_chartId, ObjectName("trend2"));
      ObjectDelete(m_chartId, ObjectName("background"));
      m_created = false;
     }
  };

#endif

//+------------------------------------------------------------------+
//| CanvasRendererPrimitives.mqh                                      |
//| Fragmento do corpo de CFusionCanvasRenderer — primitivas de       |
//| desenho e a fronteira de escala.                                  |
//|                                                                   |
//| REGRA CENTRAL: todo o resto do renderizador desenha em UNIDADES   |
//| LOGICAS (as medidas de projeto, com o painel a 590 px). A escala  |
//| e aplicada aqui dentro, em tres lugares e so tres:                |
//|   1. estas primitivas, ao falar com o CCanvas                     |
//|   2. a conversao das coordenadas de clique, em HandlePress        |
//|   3. a criacao dos campos nativos, em MakeEdit                    |
//| Assim mudar de 105% para 115% nao toca nenhuma tela.              |
//+------------------------------------------------------------------+

//--- logico -> dispositivo
int S(const int v) const { return (v*m_scale)/100; }
//--- dispositivo -> logico
int L(const int v) const { return (v*100)/m_scale; }

//--- FontSet e caro quando a face ainda nao foi carregada; o cache pula as
//--- repeticoes. Medido: frio, trocar de fonte custa 8x mais que nao trocar.
void SetFontCached(const string name,const int pt10,const int weight)
  {
   if(name==m_fontName && pt10==m_fontPt10 && weight==m_fontWeight) return;
   m_canvas.FontSet(name,-S(pt10),weight);
   m_fontName=name; m_fontPt10=pt10; m_fontWeight=weight;
  }

uint Blend(const uint fg,const uint bg,const double k)
  {
   double t=(k<0.0)?0.0:((k>1.0)?1.0:k);
   int fr=(int)((fg>>16)&0xFF), fgn=(int)((fg>>8)&0xFF), fb=(int)(fg&0xFF);
   int br=(int)((bg>>16)&0xFF), bgn=(int)((bg>>8)&0xFF), bb=(int)(bg&0xFF);
   return FCV_OPAQUE((int)(br+(fr-br)*t),(int)(bgn+(fgn-bgn)*t),(int)(bb+(fb-bb)*t));
  }

//+------------------------------------------------------------------+
//| Envelopes do CCanvas. Nenhum outro arquivo chama m_canvas direto: |
//| se chamasse, desenharia em pixel cru e sairia do lugar quando a   |
//| escala mudasse.                                                   |
//+------------------------------------------------------------------+
void Rect(const int x1,const int y1,const int x2,const int y2,const uint c)
  { m_canvas.FillRectangle(S(x1),S(y1),S(x2),S(y2),c); }

void Frame(const int x1,const int y1,const int x2,const int y2,const uint c)
  { m_canvas.Rectangle(S(x1),S(y1),S(x2),S(y2),c); }

void Disc(const int x,const int y,const int r,const uint c)
  { m_canvas.FillCircle(S(x),S(y),S(r),c); }

void Ring(const int x,const int y,const int r,const uint c)
  { m_canvas.Circle(S(x),S(y),S(r),c); }

void HLine(const int x1,const int x2,const int y,const uint c)
  { Rect(x1,y,x2,y,c); }

//--- CCanvas nao antialiasa; os cantos sao suavizados a mao, misturando com a
//--- cor de fundo conhecida. O laco roda em pixels de dispositivo — arredondar
//--- o raio antes de percorrer deixaria buracos na borda.
//--- Mascara de cantos: bit 0 superior-esquerdo, 1 superior-direito,
//--- 2 inferior-esquerdo, 3 inferior-direito. Uma aba de fichario arredonda
//--- so os de cima; os de baixo tem de encostar reto na linha.
#define FCV_CORNER_ALL 0x0F
#define FCV_CORNER_TOP 0x03

void RoundRect(const int x1,const int y1,const int x2,const int y2,
               const int r,const uint clr,const uint bg,
               const int corners=FCV_CORNER_ALL)
  {
   m_frameRects++;
   int dx1=S(x1), dy1=S(y1), dx2=S(x2), dy2=S(y2), dr=S(r);
   if(dr<=0) { m_canvas.FillRectangle(dx1,dy1,dx2,dy2,clr); return; }
   //--- os cantos nao arredondados sao preenchidos cheios antes do laco
   if((corners&0x01)==0) m_canvas.FillRectangle(dx1,dy1,dx1+dr,dy1+dr,clr);
   if((corners&0x02)==0) m_canvas.FillRectangle(dx2-dr,dy1,dx2,dy1+dr,clr);
   if((corners&0x04)==0) m_canvas.FillRectangle(dx1,dy2-dr,dx1+dr,dy2,clr);
   if((corners&0x08)==0) m_canvas.FillRectangle(dx2-dr,dy2-dr,dx2,dy2,clr);
   m_canvas.FillRectangle(dx1+dr,dy1,   dx2-dr,dy2,   clr);
   m_canvas.FillRectangle(dx1,   dy1+dr,dx1+dr,dy2-dr,clr);
   m_canvas.FillRectangle(dx2-dr,dy1+dr,dx2,   dy2-dr,clr);
   for(int c=0;c<4;++c)
     {
      //--- ordem dos bits: 0 SE, 1 SD, 2 IE, 3 ID
      int bit=(c==0)?0x01:((c==1)?0x02:((c==2)?0x04:0x08));
      if((corners&bit)==0) continue;
      int cx0=(c==0||c==2)?dx1+dr:dx2-dr, cy0=(c<2)?dy1+dr:dy2-dr;
      for(int px=-dr;px<=dr;++px)
         for(int py=-dr;py<=dr;++py)
           {
            if((c==0||c==2)&&px>0) continue;
            if((c==1||c==3)&&px<0) continue;
            if(c<2&&py>0) continue;
            if(c>=2&&py<0) continue;
            double d=MathSqrt((double)px*px+(double)py*py);
            double cov=(double)dr-d+0.5;
            if(cov<=0.0) continue;
            m_canvas.PixelSet(cx0+px,cy0+py,(cov>=1.0)?clr:Blend(clr,bg,cov));
           }
     }
  }

void RoundFrame(const int x1,const int y1,const int x2,const int y2,
                const int r,const uint border,const uint fill,const uint bg)
  {
   RoundRect(x1,y1,x2,y2,r,border,bg);
   RoundRect(x1+1,y1+1,x2-1,y2-1,r-1,fill,border);
  }

//--- Conta separadamente o texto que cai dentro do bitmap. Num conteudo
//--- rolavel a maior parte do que a tela emite fica fora da area util e o
//--- canvas recorta barato; so o visivel representa o custo real.
void Txt(const int x,const int y,const string s,const uint c,
         const string f,const int pt10,const int w,const uint al)
  {
   m_frameTexts++;
   int dy=S(y);
   if(dy>=0 && dy<m_curH) m_frameTextsVis++;
   SetFontCached(f,pt10,w);
   m_canvas.TextOut(S(x),dy,s,c,al);
  }

//--- Devolve a largura em unidades logicas: quem mede texto usa o resultado
//--- para calcular posicao logica, e misturar as duas escalas desalinharia
//--- tudo que e dimensionado pelo proprio conteudo.
int TxtW(const string s,const string f,const int pt10,const int w)
  {
   SetFontCached(f,pt10,w);
   return L((int)m_canvas.TextWidth(s));
  }

int WrapText(const int x,const int y,const int maxW,const int lineH,const string s,
             const uint c,const int pt10,const bool draw)
  {
   string words[];
   int n=StringSplit(s,' ',words);
   string line="";
   int ly=y, count=0;
   for(int i=0;i<n;++i)
     {
      string cand=(line=="")?words[i]:line+" "+words[i];
      if(TxtW(cand,FCV_FONT_UI,pt10,FCV_FW_NORMAL)<=maxW || line=="") line=cand;
      else
        {
         if(draw) Txt(x,ly,line,c,FCV_FONT_UI,pt10,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
         ly+=lineH; count++; line=words[i];
        }
     }
   if(line!="")
     {
      if(draw) Txt(x,ly,line,c,FCV_FONT_UI,pt10,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
      count++;
     }
   return count;
  }

//--- 'color' do MQL5 e BGR; o tema guarda ARGB. Converter explicitamente ao
//--- configurar objetos nativos, senao vermelho vira azul.
color ToChartColor(const uint argb)
  {
   int r=(int)((argb>>16)&0xFF), g=(int)((argb>>8)&0xFF), b=(int)(argb&0xFF);
   return (color)((b<<16)|(g<<8)|r);
  }

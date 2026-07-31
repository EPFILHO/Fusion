//+------------------------------------------------------------------+
//| CanvasRendererStress.mqh                                          |
//| Fragmento do corpo de CFusionCanvasRenderer — tela sintetica de   |
//| pior caso para medir o custo de desenho (tecla S para ver,        |
//| tecla M para medir).                                              |
//|                                                                   |
//| A densidade imita o painel real cheio: ~300 textos por quadro,    |
//| ~50 retangulos arredondados, numeros mono justificados a direita, |
//| badges e toggles — mais que a tela mais densa prevista.           |
//+------------------------------------------------------------------+

void DrawStressContent(void)
  {
   int paneX=m_fx1, x2=m_fx2;
   int y=m_fy;

   //--- Bloco de saturacao, primeiro de proposito: linhas de 20 px com rotulo
   //--- mais quatro colunas numericas, o suficiente para encher a area visivel
   //--- inteira. E o pior caso que importa — o que o canvas recorta por estar
   //--- fora da vista sai barato e nao representa um painel cheio.
   int rowH=20, satRows=26;
   int gh0=26+satRows*rowH+10;
   RoundRect(paneX,y,x2,y+gh0,8,m_t.surface,m_t.ground);
   Txt(paneX+12,y+17,"SATURACAO DA AREA VISIVEL",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int satCol=(x2-paneX-24)/5;
   for(int r=0;r<satRows;++r)
     {
      int ry=y+26+r*rowH;
      Txt(paneX+12,ry+rowH/2,StringFormat("Linha %02d",r+1),
          m_t.muted,FCV_FONT_UI,FCV_FS_SM,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
      for(int col=0;col<4;++col)
         Txt(paneX+12+(col+2)*satCol,ry+rowH/2,
             StringFormat("%.2f",(double)(r*4+col)*7.77),
             (col==3)?m_t.good:m_t.fg,FCV_FONT_MONO,FCV_FS_SM,FCV_FW_NORMAL,TA_RIGHT|TA_VCENTER);
     }
   y+=gh0+11;

   //--- 10 cartoes x (titulo + 6 linhas de rotulo + dica + valor mono)
   for(int c=0;c<10;++c)
     {
      int gh=26+6*42;
      RoundRect(paneX,y,x2,y+gh,8,m_t.surface,m_t.ground);
      Txt(paneX+12,y+17,StringFormat("GRUPO DE ESTRESSE %02d",c+1),
          m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
      for(int r=0;r<6;++r)
        {
         int ry=y+26+r*42;
         Txt(paneX+12,ry+13,StringFormat("Parametro %d.%d",c+1,r+1),
             m_t.fg,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
         Txt(paneX+12,ry+29,"Descricao curta do parametro",
             m_t.faint,FCV_FONT_UI,FCV_FS_CAP,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
         //--- numero mono contra o limite direito, como manda o plano
         Txt(x2-12,ry+21,StringFormat("%.5f",(double)(c*6+r)*1.61803),
             m_t.fg,FCV_FONT_MONO,FCV_FS_VAL,FCV_FW_SEMI,TA_RIGHT|TA_VCENTER);
         //--- a cada terceira linha, um badge de estado
         if(r%3==0)
           {
            int bw3=TxtW("OK",FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD)+16;
            RoundRect(x2-110-bw3,ry+13,x2-110,ry+29,8,m_t.gdim,m_t.surface);
            Txt(x2-110-bw3/2,ry+21,"OK",m_t.good,FCV_FONT_UI,FCV_FS_CAP,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
           }
        }
      y+=gh+11;
     }

   //--- tabela numerica 8x4, o padrao da aba Resultados
   int gh2=26+8*24+10;
   RoundRect(paneX,y,x2,y+gh2,8,m_t.surface,m_t.ground);
   Txt(paneX+12,y+17,"TABELA DE ESTRESSE",m_t.faint,FCV_FONT_UI,FCV_FS_SM,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int colW=(x2-paneX-24)/4;
   for(int r=0;r<8;++r)
     {
      int ry=y+26+r*24;
      for(int col=0;col<4;++col)
         Txt(paneX+12+(col+1)*colW,ry+12,StringFormat("%.2f",(double)(r*4+col)*12.34),
             (r%2==0)?m_t.fg:m_t.muted,FCV_FONT_MONO,FCV_FS_BODY,FCV_FW_NORMAL,TA_RIGHT|TA_VCENTER);
      HLine(paneX+12,x2-12,ry+23,m_t.soft);
     }
   m_fy=y+gh2;

   //--- Campos nativos no pior caso: sem eles o BuildEdits nao teria trabalho
   //--- nenhum durante a medicao, e o custo da parte hibrida — que e a mais
   //--- caracteristica desta arquitetura — ficaria de fora do numero.
   RowsReset();
   RowField("Campo 1","Linha com campo nativo","0.00");
   RowField("Campo 2","Linha com campo nativo","0.00");
   RowField("Campo 3","Linha com campo nativo","0.00");
   RowField("Campo 4","Linha com campo nativo","0.00");
   Card("CAMPOS NATIVOS");
  }

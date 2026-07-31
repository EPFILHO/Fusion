//+------------------------------------------------------------------+
//| CanvasRendererPerf.mqh                                            |
//| Fragmento do corpo de CFusionCanvasRenderer — medicao do custo de |
//| desenho, o unico risco estrutural que o prototipo nao estressou.  |
//|                                                                   |
//| Tres numeros separados, porque decidem coisas diferentes:         |
//|  1. TextOut unitario — o custo dominante segundo a comunidade;    |
//|     medido com fonte fixa e trocando fonte, para validar o cache  |
//|  2. Quadro cheio de pior caso — decide se redesenho total basta   |
//|     ou se vamos de regiao suja                                    |
//|  3. Update do bitmap — o custo fixo de subir o quadro a tela      |
//+------------------------------------------------------------------+

public:
void RunPerfSuite(void)
  {
   int  savTab=m_tab, savSub=m_sub[FCV_TAB_GESTAO], savRail=m_railSel[1], savScroll=m_scroll;
   bool savStress=m_stress, savMin=m_minimized;
   m_minimized=false; m_stress=true; m_tab=FCV_TAB_GESTAO;
   m_sub[FCV_TAB_GESTAO]=1; m_railSel[1]=4; m_scroll=0;
   //--- MESMO tamanho que o Render() usa. Sem a escala aqui, o benchmark
   //--- media um bitmap menor que o painel real e o desenho saia recortado na
   //--- direita e embaixo — resultado otimista, e o defeito so apareceu quando
   //--- a escala deixou de ser 100%.
   if(!EnsureSize(S(FCV_PANEL_W),S(m_ph))) return;

   //--- 1) TextOut unitario, 500 chamadas
   SetFontCached(FCV_FONT_MONO,90,FCV_FW_NORMAL);
   ulong t0=GetMicrosecondCount();
   for(int i=0;i<500;++i)
      m_canvas.TextOut(20+(i%400),40+(i%400),"0.12345",m_t.fg,TA_LEFT|TA_VCENTER);
   double usFix=(double)(GetMicrosecondCount()-t0)/500.0;

   t0=GetMicrosecondCount();
   for(int i=0;i<500;++i)
     {
      m_canvas.FontSet((i%2==0)?FCV_FONT_MONO:FCV_FONT_UI,-90,FCV_FW_NORMAL);
      m_canvas.TextOut(20+(i%400),40+(i%400),"0.12345",m_t.fg,TA_LEFT|TA_VCENTER);
     }
   double usSwap=(double)(GetMicrosecondCount()-t0)/500.0;
   m_fontName="";   // o FontSet direto invalidou o cache

   //--- 2) quadro cheio no pior caso sintetico
   DrawFrame();     // aquecimento
   int    frames=40;
   double sum=0.0, worst=0.0;
   double samples[40];
   for(int i=0;i<frames;++i)
     {
      t0=GetMicrosecondCount();
      DrawFrame();
      double ms=(double)(GetMicrosecondCount()-t0)/1000.0;
      samples[i]=ms;
      sum+=ms;
      if(ms>worst) worst=ms;
     }
   double avgFrame=sum/frames;
   //--- A mediana e o numero que descreve o desenho; a media e o pior sao
   //--- puxados por pausas do agendador, que num VPS compartilhado nao tem
   //--- nada a ver com o custo de pintar. Sem ela, um unico quadro roubado
   //--- pelo hipervisor faria parecer que o painel ficou lento.
   ArraySort(samples);
   double medFrame=(samples[frames/2-1]+samples[frames/2])/2.0;
   //--- Contadores do quadro de estresse, capturados AQUI: o Render() de
   //--- restauracao mais abaixo zera tudo e descreveria a outra tela.
   int stressTexts=m_frameTexts, stressVis=m_frameTextsVis, stressRects=m_frameRects;

   //--- 3) Update do bitmap (sem redesenho do grafico)
   sum=0.0;
   for(int i=0;i<frames;++i)
     {
      t0=GetMicrosecondCount();
      m_canvas.Update(false);
      sum+=(double)(GetMicrosecondCount()-t0)/1000.0;
     }
   double avgUpdate=sum/frames;

   //--- 4) Passo de arrasto: o caminho de maior frequencia do painel, porque
   //--- o mouse envia dezenas de eventos por segundo. Aqui nao ha pintura,
   //--- so reposicionamento — e a comparacao com o quadro cheio mostra o
   //--- quanto se ganhou em nao repintar o que nao mudou.
   int savPx=m_px, savPy=m_py;
   sum=0.0;
   for(int i=0;i<frames;++i)
     {
      ulong t1=GetMicrosecondCount();
      MoveTo(savPx+(i%2),savPy);
      sum+=(double)(GetMicrosecondCount()-t1)/1000.0;
     }
   double avgMove=sum/frames;
   MoveTo(savPx,savPy);

   //--- 5) Render() inteiro: desenho + Update + sincronizacao dos campos
   //--- nativos + ChartRedraw. E este o custo que o EA paga a cada
   //--- atualizacao; os anteriores sao as partes dele.
   sum=0.0;
   double worstFull=0.0;
   double fullSamples[40];
   for(int i=0;i<frames;++i)
     {
      ulong t2=GetMicrosecondCount();
      Render();
      double ms=(double)(GetMicrosecondCount()-t2)/1000.0;
      fullSamples[i]=ms;
      sum+=ms;
      if(ms>worstFull) worstFull=ms;
     }
   double avgFull=sum/frames;
   ArraySort(fullSamples);
   double medFull=(fullSamples[frames/2-1]+fullSamples[frames/2])/2.0;

   //--- A 5 Hz, sobre o Render() COMPLETO — nao so sobre o desenho. E esse o
   //--- ritmo com que o EA atualiza o painel com posicao aberta.
   double budget5Hz=5.0*medFull/1000.0*100.0;
   //--- arrasto a 100 eventos por segundo, o pior caso de frequencia
   double budgetDrag=100.0*avgMove/1000.0*100.0;

   m_tab=savTab; m_sub[FCV_TAB_GESTAO]=savSub; m_railSel[1]=savRail; m_scroll=savScroll;
   m_stress=savStress; m_minimized=savMin;
   Render();

   PrintFormat("=== Medicao de desenho — painel %dx%d ===",FCV_PANEL_W,m_ph);
   PrintFormat("Quadro de estresse: %d textos emitidos, %d deles dentro da area visivel · %d retangulos",
               stressTexts,stressVis,stressRects);
   PrintFormat("TextOut unitario: %.1f us com fonte fixa · %.1f us trocando fonte a cada chamada",
               usFix,usSwap);
   PrintFormat("Quadro cheio (pior caso sintetico): mediana %.2f ms · media %.2f ms · pior %.2f ms · %d quadros",
               medFrame,avgFrame,worst,frames);
   PrintFormat("Update do bitmap: media %.2f ms",avgUpdate);
   PrintFormat("Render() completo (desenho+Update+campos+ChartRedraw): mediana %.2f ms · media %.2f ms · pior %.2f ms",
               medFull,avgFull,worstFull);
   PrintFormat("Passo de arrasto (sem repintura): media %.3f ms",avgMove);
   PrintFormat("Quadro+Update continuos a 5 Hz: %.1f%% de um nucleo",budget5Hz);
   PrintFormat("Arrasto continuo a 100 eventos/s: %.1f%% de um nucleo",budgetDrag);
  }
private:

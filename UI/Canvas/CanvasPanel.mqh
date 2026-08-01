//+------------------------------------------------------------------+
//| CanvasPanel.mqh                                                   |
//| Fase 2 — CFusionCanvasPanel: mesma fronteira que CFusionPanel,    |
//| composta em cima do renderizador da Fase 1 em vez de herdar dela. |
//|                                                                   |
//| O EA nao sabe qual painel esta do outro lado dos 10 pontos de     |
//| contato (secao 5 do plano); so precisa que esta classe responda   |
//| aos 8 metodos com as mesmas assinaturas de CFusionPanel.          |
//|                                                                   |
//| ESQUELETO — cobre CreatePanel/StartDialog/Destroy/ChartEvent (o   |
//| ciclo de vida, que o renderizador da Fase 1 ja resolve) e deixa   |
//| Update/ConsumeCommand/LoadSettings/HasUnsavedDraftChanges          |
//| marcados como pendentes: exigem o mapeamento snapshot->tela e o   |
//| adaptador de validacao que ainda nao foi decidido.                |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_PANEL_MQH__
#define __FUSION_CANVAS_PANEL_MQH__

#include "../../Core/Types.mqh"
#include "CanvasRenderer.mqh"

class CFusionCanvasPanel
  {
private:
   CFusionCanvasRenderer m_renderer;
   SUIPanelSnapshot      m_snapshot;
   bool                  m_created;

public:
                     CFusionCanvasPanel(void) { m_created=false; }

   //--- Ciclo de vida. O renderizador da Fase 1 ja faz isto de verdade.
   bool              CreatePanel(const long chartId,const string name,const int subwin,
                                 const int x1,const int y1,const int x2,const int y2,
                                 const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      //--- Antes do Create: ele ja desenha o primeiro quadro, e desenhar com
      //--- dado neutro para so depois receber o real causaria um piscada.
      m_renderer.SetSnapshot(m_snapshot);
      //--- TODO Fase 3: paleta/tema/escala vem de input do EA, nao existe
      //--- ainda um caminho para eles chegarem aqui. Petroleo/Automatico por
      //--- ora, igual ao harness da Fase 1.
      m_created=m_renderer.Create(chartId,name,FUSION_CANVAS_THEME_AUTO,
                                  FUSION_PALETTE_PETROLEO,true,x1,y1);
      return m_created;
     }

   bool              StartDialog(void) { return m_created; }

   void              Destroy(const int reason=REASON_REMOVE)
     {
      if(m_created) m_renderer.Destroy();
      m_created=false;
     }

   void              ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(m_created) m_renderer.ChartEvent(id,lparam,dparam,sparam);
     }

   //--- Dados reais entrando. Etapa 2b: cabecalho e Status ja leem daqui;
   //--- Ligadas ao snapshot: Status, Resultados, Estrategias e Filtros (as duas
   //--- ultimas pelo rascunho de SEASettings, via identificador de campo por
   //--- controle). Ainda com os valores fixos da Fase 1: Gestao e Perfis.
   void              Update(const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      if(!m_created) return;
      m_renderer.SetSnapshot(m_snapshot);
      m_renderer.Render();
     }

   void              LoadSettings(const SUIPanelSnapshot &snapshot)
     {
      Update(snapshot);
     }

   void              LoadSettings(const SEASettings &settings,const string profileName,
                                  const SSymbolSpec &spec)
     {
      m_snapshot.settings=settings;
      m_snapshot.activeProfileName=profileName;
      m_snapshot.symbolSpec=spec;
      m_snapshot.symbol=spec.symbol;
      Update(m_snapshot);
     }

   //--- Comandos saindo. PENDENTE: nenhum controle do renderizador ainda
   //--- enfileira comando — os toggles da Fase 1 so mudam estado de tela
   //--- (m_stToggle), nao emitem SUICommand. Etapa 2c.
   bool              ConsumeCommand(SUICommand &command)
     {
      return false;
     }

   //--- PENDENTE: depende do par draft/committed que a Etapa 2d ainda vai
   //--- decidir como mapear para o modelo de slots do renderizador.
   bool              HasUnsavedDraftChanges(void) { return false; }
  };

#endif

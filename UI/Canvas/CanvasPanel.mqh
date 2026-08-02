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
//--- A lista de perfis vem do DISCO, nao de SEASettings, e por isso e o painel
//--- que a busca — mesmo desenho da 1.058, que tem um CSettingsStore dentro do
//--- proprio painel. O renderizador continua sem tocar em Persistence: ele
//--- recebe a lista pronta, pelo mesmo caminho por onde recebe o snapshot.
#include "../../Persistence/SettingsStore.mqh"
#include "CanvasRenderer.mqh"

class CFusionCanvasPanel
  {
private:
   CFusionCanvasRenderer m_renderer;
   SUIPanelSnapshot      m_snapshot;
   bool                  m_created;
   CSettingsStore        m_store;
   //--- Ultimo perfil ativo visto. Serve de gatilho de releitura: quando o EA
   //--- troca de perfil, a lista em disco quase sempre mudou junto (carga,
   //--- gravacao, exclusao). Reler a cada Update seria uma varredura de disco
   //--- ate 5x por segundo, com um parse de arquivo por perfil.
   string                m_lastActiveProfile;

   //--- Enumera os perfis e le o Magic de cada um. O Magic exige abrir o
   //--- arquivo: nao ha caminho barato para le-lo, e a propria 1.058 faz assim
   //--- em FusionFindProfileByMagicNumber. Por isso esta funcao roda em troca
   //--- de perfil, nunca por quadro.
   void              RefreshProfiles(void)
     {
      string names[];
      if(!m_store.ListProfiles(names)) return;

      int total=ArraySize(names);
      string keep[]; int magics[]; double lots[];
      ArrayResize(keep,total);
      ArrayResize(magics,total);
      ArrayResize(lots,total);
      int n=0;
      for(int i=0;i<total;++i)
        {
         SEASettings s;
         //--- Perfil ilegivel fica FORA da lista: exibi-lo sem Magic ofereceria
         //--- acoes sobre um arquivo que nem abriu.
         if(!m_store.LoadProfile(names[i],s)) continue;
         keep[n]  =names[i];
         magics[n]=s.magicNumber;
         lots[n]  =s.fixedLot;
         n++;
        }
      m_renderer.SetProfiles(keep,magics,lots,n,total);
     }

public:
                     CFusionCanvasPanel(void) { m_created=false; m_lastActiveProfile=""; }

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
      if(m_created)
        {
         RefreshProfiles();
         m_lastActiveProfile=m_snapshot.activeProfileName;
        }
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

   //--- Dados reais entrando. Ja leem daqui: cabecalho, Status, Resultados,
   //--- Estrategias, Filtros e Gestao — as tres ultimas pelo rascunho de
   //--- SEASettings, via identificador de campo por controle.
   //--- Ainda com os valores fixos da Fase 1: Perfis e Layout.
   void              Update(const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      if(!m_created) return;
      //--- Trocou o perfil ativo: relê o disco antes de desenhar, senao a lista
      //--- mostraria o estado anterior e o selo ATIVO ficaria na linha errada.
      if(m_snapshot.activeProfileName!=m_lastActiveProfile)
        {
         RefreshProfiles();
         m_lastActiveProfile=m_snapshot.activeProfileName;
        }
      //--- Botao ATUALIZAR: a lista e estado de disco e muda por fora, entao
      //--- precisa de um gatilho manual alem da troca de perfil ativo.
      else if(m_renderer.ConsumeProfileRefreshRequest())
         RefreshProfiles();
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

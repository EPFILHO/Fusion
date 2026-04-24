#ifndef __FUSION_UI_RESULTS_PAGE_MQH__
#define __FUSION_UI_RESULTS_PAGE_MQH__

#include <Controls\Label.mqh>
#include "../PanelUtils.mqh"

class CFusionPanel;

#define FUSION_RESULTS_ROW_COUNT 6

class CResultsPage
  {
private:
   CLabel            m_labels[FUSION_RESULTS_ROW_COUNT];
   CLabel            m_values[FUSION_RESULTS_ROW_COUNT];

   bool              AddLabel(CFusionPanel *parent,CLabel &label,const long chartId,const int subwin,
                              const string name,const int x1,const int y1,const int x2,const int y2,
                              const string text,const color clr,const int size=9)
     {
      if(!label.Create(chartId, name, subwin, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return parent.AddControl(label);
     }

   void              SetControlVisible(CLabel &control,const bool visible)
     {
      if(visible)
         control.Show();
      else
         control.Hide();
     }

public:
                     CResultsPage(void)
     {
     }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin)
     {
      string labels[FUSION_RESULTS_ROW_COUNT] = {"Lote", "Max Spread", "Magic", "Perfil", "Modo", "Execucao"};
      int y = 112;
      for(int i = 0; i < FUSION_RESULTS_ROW_COUNT; ++i)
        {
         if(!AddLabel(parent, m_labels[i], chartId, subwin, "Fusion_results_lbl_" + IntegerToString(i), 20, y, 170, y + 18, labels[i], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(parent, m_values[i], chartId, subwin, "Fusion_results_val_" + IntegerToString(i), 190, y, 510, y + 18, "--", FUSION_CLR_VALUE))
            return false;
         y += 34;
        }
      return true;
     }

   void              Update(const SUIPanelSnapshot &snapshot,const SEASettings &settings,const string committedProfileName)
     {
      m_values[0].Text(FusionFormatVolume(settings.fixedLot, snapshot.symbolSpec));
      m_values[1].Text(IntegerToString(settings.maxSpreadPoints));
      m_values[2].Text(IntegerToString(settings.magicNumber));
      m_values[3].Text(committedProfileName == "" ? snapshot.activeProfileName : committedProfileName);
      m_values[4].Text(snapshot.runtimeBlocked ? "SYMBOL LOCK" : (snapshot.started ? "HOT RELOAD READY" : "EDIT MODE"));
      m_values[5].Text(snapshot.runtimeBlocked ? snapshot.runtimeBlockReason : (snapshot.hasPosition ? "EA COM POSICAO" : "EA SEM POSICAO"));
      m_values[5].Color(snapshot.runtimeBlocked ? FUSION_CLR_BAD : FUSION_CLR_VALUE);
     }

   void              SetVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_RESULTS_ROW_COUNT; ++i)
        {
         SetControlVisible(m_labels[i], visible);
         SetControlVisible(m_values[i], visible);
        }
     }
  };

#undef FUSION_RESULTS_ROW_COUNT

#endif

#ifndef __FUSION_UI_STATUS_PAGE_MQH__
#define __FUSION_UI_STATUS_PAGE_MQH__

#include <Controls\Label.mqh>
#include "../PanelUtils.mqh"

class CFusionPanel;

#define FUSION_STATUS_ROW_COUNT 8

class CStatusPage
  {
private:
   CLabel            m_labels[FUSION_STATUS_ROW_COUNT];
   CLabel            m_values[FUSION_STATUS_ROW_COUNT];

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
                     CStatusPage(void)
     {
     }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin)
     {
      string labels[FUSION_STATUS_ROW_COUNT] = {"Estado", "Symbol", "Timeframe", "Strategies", "Filters", "Posicao", "Owner", "Resolver"};
      int y = 112;
      for(int i = 0; i < FUSION_STATUS_ROW_COUNT; ++i)
        {
         if(!AddLabel(parent, m_labels[i], chartId, subwin, "Fusion_status_lbl_" + IntegerToString(i), 20, y, 170, y + 18, labels[i], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(parent, m_values[i], chartId, subwin, "Fusion_status_val_" + IntegerToString(i), 190, y, 510, y + 18, "--", FUSION_CLR_VALUE))
            return false;
         y += 30;
        }
      return true;
     }

   void              Update(const SUIPanelSnapshot &snapshot)
     {
      m_values[0].Text(snapshot.runtimeBlocked ? "BLOCKED" : (snapshot.started ? "RUNNING" : "PAUSED"));
      m_values[0].Color(snapshot.runtimeBlocked ? FUSION_CLR_BAD : FUSION_CLR_VALUE);
      m_values[1].Text(snapshot.symbol);
      m_values[2].Text(snapshot.timeframe);
      m_values[3].Text(IntegerToString(snapshot.activeStrategies));
      m_values[4].Text(IntegerToString(snapshot.activeFilters));
      m_values[5].Text(snapshot.hasPosition ? "YES" : "NO");
      m_values[6].Text(snapshot.ownerStrategyName == "" ? "--" : snapshot.ownerStrategyName);
      m_values[7].Text(FusionConflictText(snapshot.conflictMode));
     }

   void              SetVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STATUS_ROW_COUNT; ++i)
        {
         SetControlVisible(m_labels[i], visible);
         SetControlVisible(m_values[i], visible);
        }
     }
  };

#undef FUSION_STATUS_ROW_COUNT

#endif

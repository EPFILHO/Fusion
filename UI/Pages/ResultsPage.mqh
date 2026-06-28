#ifndef __FUSION_UI_RESULTS_PAGE_MQH__
#define __FUSION_UI_RESULTS_PAGE_MQH__

#include <Controls\Label.mqh>
#include "../PanelUtils.mqh"

class CFusionPanel;

#define FUSION_RESULTS_ROW_COUNT 8

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

   color             ResultColor(const double value) const
     {
      if(value > 0.0000001)
         return FUSION_CLR_GOOD;
      if(value < -0.0000001)
         return FUSION_CLR_BAD;
      return FUSION_CLR_VALUE;
     }

public:
                     CResultsPage(void)
     {
     }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin)
     {
      string labels[FUSION_RESULTS_ROW_COUNT] = {"P/L Fechado", "P/L Flutuante", "P/L Projetado", "Trades do Dia", "Streak Loss/Win Atual", "Estado DD", "Pico / Piso DD", "Folga DD"};
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

   void              Update(const SUIPanelSnapshot &snapshot)
     {
      m_values[0].Text(DoubleToString(snapshot.dailyClosedProfit, 2));
      m_values[0].Color(ResultColor(snapshot.dailyClosedProfit));
      m_values[1].Text(DoubleToString(snapshot.dailyFloatingProfit, 2));
      m_values[1].Color(ResultColor(snapshot.dailyFloatingProfit));
      m_values[2].Text(DoubleToString(snapshot.dailyProjectedProfit, 2));
      m_values[2].Color(ResultColor(snapshot.dailyProjectedProfit));
      string dailyTradesText = IntegerToString(snapshot.dailyTradeCount);
      if(snapshot.dailyOutcomeCountsKnown)
        {
         dailyTradesText += StringFormat(" (%d Loss / %d Win", snapshot.dailyLossCount, snapshot.dailyWinCount);
         if(snapshot.dailyBreakevenCount > 0)
            dailyTradesText += StringFormat(" / %d BE", snapshot.dailyBreakevenCount);
         dailyTradesText += ")";
        }
      m_values[3].Text(dailyTradesText);
      m_values[3].Color(FUSION_CLR_VALUE);
      string lossStreakText = snapshot.settings.lossStreakEnabled ? IntegerToString(snapshot.lossStreak) : "OFF";
      string winStreakText = snapshot.settings.winStreakEnabled ? IntegerToString(snapshot.winStreak) : "OFF";
      m_values[4].Text("Loss " + lossStreakText + " | Win " + winStreakText);
      m_values[4].Color((snapshot.settings.lossStreakEnabled || snapshot.settings.winStreakEnabled) ?
                        FUSION_CLR_VALUE : FUSION_CLR_MUTED);

      string drawdownState = !snapshot.settings.enableDrawdown ? "OFF" :
                             (snapshot.drawdownLimitReached ? "ATINGIDO" :
                              (snapshot.drawdownProtectionActive ? "ATIVO" : "AGUARDANDO META"));
      m_values[5].Text(drawdownState);
      m_values[5].Color(snapshot.drawdownLimitReached ? FUSION_CLR_WARN :
                        (snapshot.settings.enableDrawdown ? FUSION_CLR_VALUE : FUSION_CLR_MUTED));

      bool hasDrawdownBase = (snapshot.drawdownProtectionActive ||
                              snapshot.drawdownLimitReached ||
                              snapshot.drawdownPeakProfit > 0.0);
      m_values[6].Text(hasDrawdownBase ?
                       StringFormat("%.2f / %.2f", snapshot.drawdownPeakProfit, snapshot.drawdownFloorProfit) : "--");
      m_values[6].Color(hasDrawdownBase ? FUSION_CLR_VALUE : FUSION_CLR_MUTED);
      m_values[7].Text(hasDrawdownBase ? DoubleToString(snapshot.drawdownBufferProfit, 2) : "--");
      m_values[7].Color(!hasDrawdownBase ? FUSION_CLR_MUTED :
                        (snapshot.drawdownBufferProfit <= 0.0 ? FUSION_CLR_WARN : FUSION_CLR_VALUE));
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

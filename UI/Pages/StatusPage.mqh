#ifndef __FUSION_UI_STATUS_PAGE_MQH__
#define __FUSION_UI_STATUS_PAGE_MQH__

#include <Controls\Label.mqh>
#include "../PanelUtils.mqh"

class CFusionPanel;

#define FUSION_STATUS_MAIN_ROW_COUNT 8
#define FUSION_STATUS_NOTICE_LINE_COUNT 3

class CStatusPage
  {
private:
   CLabel            m_labels[FUSION_STATUS_MAIN_ROW_COUNT];
   CLabel            m_values[FUSION_STATUS_MAIN_ROW_COUNT];
   CLabel            m_noticeLabel;
   CLabel            m_noticeTitle;
   CLabel            m_noticeLines[FUSION_STATUS_NOTICE_LINE_COUNT];

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

   void              WrapNotice(const string text,string &lines[]) const
     {
      ArrayResize(lines, FUSION_STATUS_NOTICE_LINE_COUNT);
      for(int i = 0; i < FUSION_STATUS_NOTICE_LINE_COUNT; ++i)
         lines[i] = "";

      string remaining = FusionTrimCopy(text);
      const int maxChars = 58;

      for(int lineIndex = 0; lineIndex < FUSION_STATUS_NOTICE_LINE_COUNT && remaining != ""; ++lineIndex)
        {
         if(StringLen(remaining) <= maxChars)
           {
            lines[lineIndex] = remaining;
            remaining = "";
            break;
           }

         int split = maxChars;
         while(split > 0 && StringGetCharacter(remaining, split) != ' ')
            split--;
         if(split <= 0)
            split = maxChars;

         lines[lineIndex] = FusionTrimCopy(StringSubstr(remaining, 0, split));
         remaining = FusionTrimCopy(StringSubstr(remaining, split + 1));
        }

      if(remaining != "")
        {
         string tail = lines[FUSION_STATUS_NOTICE_LINE_COUNT - 1];
         if(tail != "")
            tail += "...";
         else
            tail = "...";
         lines[FUSION_STATUS_NOTICE_LINE_COUNT - 1] = tail;
        }
     }

public:
                     CStatusPage(void)
     {
     }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin)
     {
      string labels[FUSION_STATUS_MAIN_ROW_COUNT] = {"Estado", "Symbol", "Timeframe", "Strategies", "Filters", "Posicao", "Owner", "Resolver"};
      int y = 112;
      for(int i = 0; i < FUSION_STATUS_MAIN_ROW_COUNT; ++i)
        {
         if(!AddLabel(parent, m_labels[i], chartId, subwin, "Fusion_status_lbl_" + IntegerToString(i), 20, y, 170, y + 18, labels[i], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(parent, m_values[i], chartId, subwin, "Fusion_status_val_" + IntegerToString(i), 190, y, 510, y + 18, "--", FUSION_CLR_VALUE))
            return false;
         y += 30;
        }

      if(!AddLabel(parent, m_noticeLabel, chartId, subwin, "Fusion_status_notice_lbl", 20, 352, 170, 370, "Aviso", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(parent, m_noticeTitle, chartId, subwin, "Fusion_status_notice_title", 190, 352, 520, 370, "Sem alertas.", FUSION_CLR_MUTED, 8))
         return false;

      int noticeY = 374;
      for(int line = 0; line < FUSION_STATUS_NOTICE_LINE_COUNT; ++line)
        {
         if(!AddLabel(parent, m_noticeLines[line], chartId, subwin, "Fusion_status_notice_line_" + IntegerToString(line), 190, noticeY, 520, noticeY + 16, "", FUSION_CLR_MUTED, 8))
            return false;
         noticeY += 18;
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

      string noticeTitle = "Sem alertas.";
      string noticeText = "Contexto do grafico estavel.";
      color noticeColor = FUSION_CLR_MUTED;

      if(snapshot.runtimeBlocked)
        {
         noticeTitle = "ATENCAO OPERACIONAL";
         noticeText = snapshot.runtimeBlockReason;
         noticeColor = FUSION_CLR_BAD;
        }
      else if(snapshot.startBlockedReason != "")
        {
         noticeTitle = "INICIO BLOQUEADO";
         noticeText = snapshot.startBlockedReason;
         noticeColor = FUSION_CLR_WARN;
        }
      else if(snapshot.activeProfileBlockedReason != "")
        {
         noticeTitle = "PERFIL BLOQUEADO";
         noticeText = snapshot.activeProfileBlockedReason;
         noticeColor = FUSION_CLR_WARN;
        }
      else if(snapshot.runtimeNotice != "")
        {
         noticeTitle = snapshot.started ? "AVISO OPERACIONAL" : "AVISO DE CONTEXTO";
         noticeText = snapshot.runtimeNotice;
         noticeColor = FUSION_CLR_WARN;
        }

      string lines[];
      WrapNotice(noticeText, lines);
      m_noticeTitle.Text(noticeTitle);
      m_noticeTitle.Color(noticeColor);
      for(int line = 0; line < FUSION_STATUS_NOTICE_LINE_COUNT; ++line)
        {
         m_noticeLines[line].Text(lines[line]);
         m_noticeLines[line].Color(noticeColor);
        }
     }

   void              SetVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STATUS_MAIN_ROW_COUNT; ++i)
        {
         SetControlVisible(m_labels[i], visible);
         SetControlVisible(m_values[i], visible);
        }

      SetControlVisible(m_noticeLabel, visible);
      SetControlVisible(m_noticeTitle, visible);
      for(int line = 0; line < FUSION_STATUS_NOTICE_LINE_COUNT; ++line)
         SetControlVisible(m_noticeLines[line], visible);
     }
  };

#undef FUSION_STATUS_MAIN_ROW_COUNT
#undef FUSION_STATUS_NOTICE_LINE_COUNT

#endif

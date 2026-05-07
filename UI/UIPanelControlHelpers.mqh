#ifndef __FUSION_UI_PANEL_CONTROL_HELPERS_MQH__
#define __FUSION_UI_PANEL_CONTROL_HELPERS_MQH__

   void                       ReleaseButton(CButton &button)
     {
      button.Pressed(false);
     }

   bool                       AddHitGroup(CFusionHitGroup &group,const string name)
     {
      if(!group.Create(m_chartId, name, m_subWindow, 0, 0, FUSION_PANEL_WIDTH, FUSION_PANEL_HEIGHT))
         return false;
      return AddControl(group);
     }

   CFusionHitGroup           *PushBuildTarget(CFusionHitGroup &group)
     {
      CFusionHitGroup *previous = m_buildTarget;
      m_buildTarget = GetPointer(group);
      return previous;
     }

   void                       PopBuildTarget(CFusionHitGroup *previous)
     {
      m_buildTarget = previous;
     }

   bool                       AddLabel(CLabel &label,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color clr,const int size=8)
     {
      if(!label.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return AddControl(label);
     }

   bool                       AddButton(CButton &button,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color bg)
     {
      if(!button.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      button.Text(text);
      button.FontSize(8);
      button.Color(clrWhite);
      button.ColorBackground(bg);
      return AddControl(button);
     }

   bool                       AddEdit(CEdit &edit,const string name,const int x1,const int y1,const int x2,const int y2,const string value)
     {
      if(!edit.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      edit.Text(value);
      edit.Color(clrBlack);
      edit.ColorBackground(clrWhite);
      return AddControl(edit);
     }

   bool                       AddPanel(CPanel &panel,const string name,const int x1,const int y1,const int x2,const int y2,const color bg,const color border,const ENUM_BORDER_TYPE borderType=BORDER_FLAT)
     {
      if(!panel.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      panel.ColorBackground(bg);
      panel.ColorBorder(border);
      panel.BorderType(borderType);
      return AddControl(panel);
     }

   string                     LiveEditText(CEdit &edit)
     {
      string name = edit.Name();
      if(name != "" && ObjectFind(m_chartId, name) >= 0)
         return ObjectGetString(m_chartId, name, OBJPROP_TEXT);
      return edit.Text();
     }

   void                       SetVisible(CWnd &control,const bool visible)
     {
      if(visible)
         control.Show();
      else
         control.Hide();
     }

#endif

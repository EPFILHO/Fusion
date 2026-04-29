#ifndef __FUSION_UI_HIT_TEST_GROUP_MQH__
#define __FUSION_UI_HIT_TEST_GROUP_MQH__

#include <Controls\WndContainer.mqh>

class CFusionHitGroup : public CWndContainer
  {
public:
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!IsVisible())
         return false;

      for(int i = ControlsTotal() - 1; i >= 0; --i)
        {
         CWnd *control = Control(i);
         if(control != NULL && control.OnEvent(id, lparam, dparam, sparam))
            return true;
        }

      return false;
     }

   virtual bool      OnMouseEvent(const int x,const int y,const int flags)
     {
      if(!IsVisible() || !Contains(x, y))
         return false;

      for(int i = ControlsTotal() - 1; i >= 0; --i)
        {
         CWnd *control = Control(i);
         if(control != NULL && control.OnMouseEvent(x, y, flags))
            return true;
        }

      return false;
     }

   virtual bool      Show(void)
     {
      StateFlagsSet(WND_STATE_FLAG_VISIBLE);
      return true;
     }

   virtual bool      Hide(void)
     {
      StateFlagsReset(WND_STATE_FLAG_VISIBLE);
      return true;
     }
  };

#endif

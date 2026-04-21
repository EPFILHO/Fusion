#ifndef __FUSION_STRATEGY_PANEL_BASE_MQH__
#define __FUSION_STRATEGY_PANEL_BASE_MQH__

#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include "PanelUtils.mqh"

class CFusionPanel;

class CStrategyPanelBase
  {
public:
   virtual ~CStrategyPanelBase(void) {}
   virtual string GetTitle(void) const = 0;
   virtual string GetButtonName(void) const = 0;
   virtual bool   Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2) = 0;
   virtual void   Show(void) = 0;
   virtual void   Hide(void) = 0;
   virtual void   Sync(const SEASettings &settings,const bool editable) = 0;
   virtual bool   HandleClick(const string objectName,SUICommand &command) = 0;
  };

#endif

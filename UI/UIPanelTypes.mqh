#ifndef __FUSION_UI_PANEL_TYPES_MQH__
#define __FUSION_UI_PANEL_TYPES_MQH__

#define FUSION_PANEL_WIDTH   580
#define FUSION_PANEL_HEIGHT  626
#define FUSION_PANEL_LEFT    10
#define FUSION_PANEL_TOP     20
#define FUSION_PANEL_MARGIN  10
#define FUSION_PROFILE_VISIBLE_ROWS 8

enum ENUM_FUSION_TAB
  {
   FUSION_TAB_STATUS = 0,
   FUSION_TAB_RESULTS,
   FUSION_TAB_STRATEGIES,
   FUSION_TAB_FILTERS,
   FUSION_TAB_PROFILES,
   FUSION_TAB_CONFIG,
   FUSION_TAB_COUNT
  };

enum ENUM_FUSION_STRATEGY_PAGE
  {
   FUSION_STRAT_OVERVIEW = 0,
   FUSION_STRAT_MACROSS,
   FUSION_STRAT_RSI,
   FUSION_STRAT_BB,
   FUSION_STRAT_COUNT
  };

enum ENUM_FUSION_FILTER_PAGE
  {
   FUSION_FILTER_OVERVIEW = 0,
   FUSION_FILTER_TREND,
   FUSION_FILTER_RSI,
   FUSION_FILTER_COUNT
  };

enum ENUM_FUSION_CONFIG_PAGE
  {
   FUSION_CFG_RISK = 0,
   FUSION_CFG_PROTECTION,
   FUSION_CFG_SYSTEM,
   FUSION_CFG_COUNT
  };

enum ENUM_FUSION_PROTECT_PAGE
  {
   FUSION_PROTECT_GENERAL = 0,
   FUSION_PROTECT_SPREAD,
   FUSION_PROTECT_SESSION,
   FUSION_PROTECT_NEWS,
   FUSION_PROTECT_DAY,
   FUSION_PROTECT_DRAWDOWN,
   FUSION_PROTECT_STREAK,
   FUSION_PROTECT_COUNT
  };

enum ENUM_FUSION_PROFILE_MODE
  {
   FUSION_PROFILE_BROWSE = 0,
   FUSION_PROFILE_NEW,
   FUSION_PROFILE_DUPLICATE
  };

struct SUIAccessState
  {
   bool hasLocalPositionLock;
   bool hasPeerProfileLock;
   bool profileEditMode;
   bool hasPendingChanges;
   bool configInputsValid;
   bool runtimeEditable;
   bool activeProfileEditable;
   bool profileLoadAllowed;
   bool profileAdminAllowed;
   bool canPause;
   bool canStart;
   bool canSave;
   bool canCancel;
  };

struct SUIProfileActionState
  {
   bool   selected;
   bool   selectedIsActive;
   bool   selectedIsDefault;
   bool   selectedRuntimeLocked;
   bool   selectedActiveProfileLocked;
   bool   canLoad;
   bool   canDuplicate;
   bool   canDelete;
   string blockedReason;
  };

struct SUIProfileEditDraftState
  {
   bool   editMode;
   bool   duplicateMode;
   bool   validName;
   bool   nameAvailable;
   bool   magicValid;
   bool   magicAvailable;
   bool   ready;
   int    draftMagic;
   string draftName;
   string magicConflictProfile;
   string error;
  };

#endif

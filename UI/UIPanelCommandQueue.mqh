#ifndef __FUSION_UI_PANEL_COMMAND_QUEUE_MQH__
#define __FUSION_UI_PANEL_COMMAND_QUEUE_MQH__

   void                       ResetCommand(SUICommand &command)
     {
      command.type        = UI_COMMAND_NONE;
      command.text        = "";
      command.hasSettings = false;
      command.reloadScope = RELOAD_HOT;
     }

   void                       ClearPendingCommand(void)
     {
      ResetCommand(m_pendingCommand);
      m_hasPendingCommand = false;
     }

   void                       QueueSimpleCommand(const ENUM_UI_COMMAND type)
     {
      ResetCommand(m_pendingCommand);
      m_pendingCommand.type = type;
      m_pendingCommand.text = DraftProfileName();
      m_hasPendingCommand   = true;
     }

   void                       QueueProfileCommand(const ENUM_UI_COMMAND type,const string profileName)
     {
      ResetCommand(m_pendingCommand);
      m_pendingCommand.type = type;
      m_pendingCommand.text = profileName;
      m_hasPendingCommand = true;
     }

   void                       QueueSaveProfileCommand(const string profileName,
                                                      const SEASettings &settings,
                                                      const ENUM_RELOAD_SCOPE reloadScope)
     {
      ResetCommand(m_pendingCommand);
      m_pendingCommand.type = UI_COMMAND_SAVE_PROFILE;
      m_pendingCommand.text = profileName;
      m_pendingCommand.hasSettings = true;
      m_pendingCommand.settings = settings;
      m_pendingCommand.reloadScope = reloadScope;
      m_hasPendingCommand = true;
     }

#endif

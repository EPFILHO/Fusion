#ifndef __FUSION_PLATFORM_FOLDER_LAUNCHER_MQH__
#define __FUSION_PLATFORM_FOLDER_LAUNCHER_MQH__

#import "shell32.dll"
int ShellExecuteW(int hwnd,string operation,string file,string parameters,string directory,int showCommand);
#import

bool FusionCanOpenFolder(void)
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return false;

   return (bool)MQLInfoInteger(MQL_DLLS_ALLOWED);
  }

bool FusionOpenFolder(const string folderPath)
  {
   if(folderPath == "" || !FusionCanOpenFolder())
      return false;

   int result = ShellExecuteW(0, "open", folderPath, "", "", 1);
   return (result > 32);
  }

#endif

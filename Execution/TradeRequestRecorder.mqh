#ifndef __FUSION_TRADE_REQUEST_RECORDER_MQH__
#define __FUSION_TRADE_REQUEST_RECORDER_MQH__

class CTradeRequestRecorder
  {
private:
   bool               m_enabled;
   string             m_fileName;
   int                m_lastError;

   string             SafeField(const string source) const
     {
      string value = source;
      StringReplace(value, ";", ",");
      StringReplace(value, "\r", " ");
      StringReplace(value, "\n", " ");
      return value;
     }

   string             SafeFilePart(const string source) const
     {
      string value = source;
      StringReplace(value, "\\", "_");
      StringReplace(value, "/", "_");
      StringReplace(value, ":", "_");
      StringReplace(value, "*", "_");
      StringReplace(value, "?", "_");
      StringReplace(value, "\"", "_");
      StringReplace(value, "<", "_");
      StringReplace(value, ">", "_");
      StringReplace(value, "|", "_");
      StringReplace(value, " ", "_");
      if(value == "")
         return "unknown";
      return value;
     }

   string             RetcodeName(const uint retcode) const
     {
      if(retcode == TRADE_RETCODE_DONE)
         return "DONE";
      if(retcode == TRADE_RETCODE_PLACED)
         return "PLACED";
      if(retcode == TRADE_RETCODE_DONE_PARTIAL)
         return "DONE_PARTIAL";
      if(retcode == 0)
         return "NO_RETCODE";
      return "OTHER";
     }

   string             FormatNumber(const double value) const
     {
      return DoubleToString(value, 8);
     }

   bool               WriteHeader(const int handle)
     {
      uint written = FileWrite(handle,
                               "server_time",
                               "event",
                               "account_login",
                               "account_server",
                               "symbol",
                               "magic",
                               "request_action",
                               "order_type",
                               "filling_mode",
                               "position_ticket",
                               "requested_volume",
                               "requested_price",
                               "requested_sl",
                               "requested_tp",
                               "deviation_points",
                               "order_send_ok",
                               "terminal_error",
                               "retcode",
                               "retcode_name",
                               "result_order",
                               "result_deal",
                               "executed_volume",
                               "executed_price",
                               "result_bid",
                               "result_ask",
                               "request_id",
                               "retcode_external",
                               "server_comment");
      return (written > 0);
     }

public:
                     CTradeRequestRecorder(void)
     {
      m_enabled = false;
      m_fileName = "";
      m_lastError = 0;
     }

   void               Init(const string symbol,const int magicNumber)
     {
      m_enabled = (MQLInfoInteger(MQL_TESTER) == 0);
      m_lastError = 0;

      string server = AccountInfoString(ACCOUNT_SERVER);
      string login = StringFormat("%I64d", AccountInfoInteger(ACCOUNT_LOGIN));
      m_fileName = "Fusion_trade_requests_" +
                   SafeFilePart(server) + "_" +
                   SafeFilePart(login) + "_" +
                   SafeFilePart(symbol) + "_" +
                   IntegerToString(magicNumber) + ".csv";
     }

   bool               Record(const string eventName,
                             const MqlTradeRequest &request,
                             const MqlTradeResult &result,
                             const bool orderSendOk,
                             const int terminalError)
     {
      if(!m_enabled)
         return true;
      if(m_fileName == "")
        {
         m_lastError = -1;
         return false;
        }

      ResetLastError();
      int handle = FileOpen(m_fileName,
                            FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI |
                            FILE_SHARE_READ | FILE_SHARE_WRITE,
                            ';',
                            CP_UTF8);
      if(handle == INVALID_HANDLE)
        {
         m_lastError = GetLastError();
         return false;
        }

      bool emptyFile = (FileSize(handle) == 0);
      if(!FileSeek(handle, 0, SEEK_END))
        {
         m_lastError = GetLastError();
         FileClose(handle);
         return false;
        }

      if(emptyFile && !WriteHeader(handle))
        {
         m_lastError = GetLastError();
         FileClose(handle);
         return false;
        }

      datetime now = TimeCurrent();
      if(now <= 0)
         now = TimeLocal();

      uint written = FileWrite(handle,
                               TimeToString(now, TIME_DATE | TIME_SECONDS),
                               eventName,
                               StringFormat("%I64d", AccountInfoInteger(ACCOUNT_LOGIN)),
                               SafeField(AccountInfoString(ACCOUNT_SERVER)),
                               SafeField(request.symbol),
                               StringFormat("%I64u", request.magic),
                               EnumToString(request.action),
                               EnumToString(request.type),
                               EnumToString(request.type_filling),
                               StringFormat("%I64u", request.position),
                               FormatNumber(request.volume),
                               FormatNumber(request.price),
                               FormatNumber(request.sl),
                               FormatNumber(request.tp),
                               StringFormat("%I64u", request.deviation),
                               orderSendOk ? "1" : "0",
                               IntegerToString(terminalError),
                               IntegerToString((int)result.retcode),
                               RetcodeName(result.retcode),
                               StringFormat("%I64u", result.order),
                               StringFormat("%I64u", result.deal),
                               FormatNumber(result.volume),
                               FormatNumber(result.price),
                               FormatNumber(result.bid),
                               FormatNumber(result.ask),
                               StringFormat("%u", result.request_id),
                               IntegerToString((int)result.retcode_external),
                               SafeField(result.comment));
      if(written == 0)
        {
         m_lastError = GetLastError();
         FileClose(handle);
         return false;
        }

      FileFlush(handle);
      FileClose(handle);
      m_lastError = 0;
      return true;
     }

   int                LastError(void) const
     {
      return m_lastError;
     }
  };

#endif

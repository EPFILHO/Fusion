//+------------------------------------------------------------------+
//| TextParse.mqh                                                     |
//| O que conta como numero digitado, e como um texto e aparado.      |
//|                                                                   |
//| Extraido de UI/PanelUtils.mqh na Etapa 2d, pelo mesmo motivo que  |
//| levou VolumeFormat.mqh para ca na 2b: a validacao da GUI 2.0      |
//| precisa recusar EXATAMENTE o que a 1.058 recusa, e PanelUtils     |
//| arrasta a biblioteca Controls inteira — que o renderizador em     |
//| canvas nao pode incluir.                                          |
//|                                                                   |
//| A alternativa era uma segunda copia das regras de parse. Ela      |
//| divergiria sem quebrar o build: "12a" seria recusado num painel e |
//| viraria 12 no outro, e os dois discordariam sobre o que e um      |
//| numero valido — justamente a classe de erro que nao aparece em    |
//| compilacao nenhuma.                                               |
//|                                                                   |
//| Nao depende de nada: so texto.                                    |
//+------------------------------------------------------------------+
#ifndef __FUSION_TEXT_PARSE_MQH__
#define __FUSION_TEXT_PARSE_MQH__

string FusionTrimCopy(const string text)
  {
   int start = 0;
   int end = StringLen(text) - 1;

   while(start <= end)
     {
      ushort ch = StringGetCharacter(text, start);
      if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
         break;
      start++;
     }

   while(end >= start)
     {
      ushort ch = StringGetCharacter(text, end);
      if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
         break;
      end--;
     }

   if(end < start)
      return "";
   return StringSubstr(text, start, end - start + 1);
  }

bool FusionIsBlank(const string text)
  {
   return FusionTrimCopy(text) == "";
  }

//--- Inteiro NAO negativo, so digitos. "12a" e recusado em vez de virar 12 pelo
//--- StringToInteger, que para no primeiro caractere invalido sem avisar.
bool FusionIsIntegerText(const string text,const bool allowZero=true)
  {
   string trimmed = FusionTrimCopy(text);
   if(trimmed == "")
      return false;

   int start = 0;
   if(StringGetCharacter(trimmed, 0) == '+')
      start = 1;
   else if(StringGetCharacter(trimmed, 0) == '-')
      return false;

   if(start >= StringLen(trimmed))
      return false;

   for(int i = start; i < StringLen(trimmed); ++i)
     {
      ushort ch = StringGetCharacter(trimmed, i);
      if(ch < '0' || ch > '9')
         return false;
     }

   if(!allowZero && StringToInteger(trimmed) == 0)
      return false;
   return true;
  }

//--- Virgula vira ponto: o teclado do usuario e o do idioma dele, e recusar
//--- "0,30" seria recusar a grafia que o proprio terminal exibe em boa parte
//--- das localizacoes.
string FusionNormalizeDecimalText(const string text)
  {
   string normalized = FusionTrimCopy(text);
   StringReplace(normalized, ",", ".");
   return normalized;
  }

bool FusionIsDecimalText(const string text,const bool allowZero=true)
  {
   string trimmed = FusionNormalizeDecimalText(text);
   if(trimmed == "")
      return false;

   bool hasSeparator = false;
   int start = 0;
   if(StringGetCharacter(trimmed, 0) == '+')
      start = 1;
   else if(StringGetCharacter(trimmed, 0) == '-')
      return false;

   if(start >= StringLen(trimmed))
      return false;

   for(int i = start; i < StringLen(trimmed); ++i)
     {
      ushort ch = StringGetCharacter(trimmed, i);
      if(ch == '.' || ch == ',')
        {
         if(hasSeparator)
            return false;
         hasSeparator = true;
         continue;
        }
      if(ch < '0' || ch > '9')
         return false;
     }

   double value = StringToDouble(trimmed);
   if(!allowZero && value <= 0.0)
      return false;
   return true;
  }

#endif

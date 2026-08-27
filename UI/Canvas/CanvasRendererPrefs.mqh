//+------------------------------------------------------------------+
//| CanvasRendererPrefs.mqh                                           |
//| Fragmento do corpo de CFusionCanvasRenderer — lembra a aparencia  |
//| escolhida entre sessoes.                                          |
//|                                                                   |
//| Paleta, tema e tamanho sao preferencia de quem opera, nao         |
//| configuracao do perfil: nao viajam no arquivo de perfil e nao     |
//| passam por SALVAR. Ficam em variaveis globais do terminal, que    |
//| sobrevivem a fechar e abrir o MT5.                                |
//|                                                                   |
//| Valem para o terminal inteiro, de proposito: quem gosta de um     |
//| tema gosta dele em todo grafico, e nao quer reescolher a cada     |
//| painel aberto.                                                    |
//+------------------------------------------------------------------+

#define FCV_PREF_PALETTE "Fusion2_Aparencia_Paleta"
#define FCV_PREF_THEME   "Fusion2_Aparencia_Tema"
#define FCV_PREF_SCALE   "Fusion2_Aparencia_Escala"

double PrefRead(const string name,const double fallback)
  {
   if(!GlobalVariableCheck(name)) return fallback;
   return GlobalVariableGet(name);
  }

void LoadAppearance(void)
  {
   if(!m_remember) return;

   int p=(int)PrefRead(FCV_PREF_PALETTE,(double)m_palette);
   if(p>=0 && p<FCV_PALETTE_COUNT) m_palette=(ENUM_FUSION_CANVAS_PALETTE)p;

   int t=(int)PrefRead(FCV_PREF_THEME,(double)m_themeMode);
   if(t>=0 && t<=2)
     {
      m_themeMode=(ENUM_FUSION_CANVAS_THEME)t;
      //--- tema fixado pelo usuario continua fixado; automatico volta a seguir
      //--- o grafico, senao um painel salvo como claro nunca mais se adaptaria
      m_userTheme=(m_themeMode!=FUSION_CANVAS_THEME_AUTO);
     }

   int s=(int)PrefRead(FCV_PREF_SCALE,(double)m_scale);
   if(s>=FCV_SCALE_MIN && s<=FCV_SCALE_MIN+(FCV_SCALE_COUNT-1)*FCV_SCALE_STEP)
      m_scale=s;
  }

void SaveAppearance(void)
  {
   if(!m_remember) return;
   GlobalVariableSet(FCV_PREF_PALETTE,(double)m_palette);
   GlobalVariableSet(FCV_PREF_THEME,  (double)m_themeMode);
   GlobalVariableSet(FCV_PREF_SCALE,  (double)m_scale);
  }

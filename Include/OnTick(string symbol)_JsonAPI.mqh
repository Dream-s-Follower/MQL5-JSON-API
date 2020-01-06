//+------------------------------------------------------------------+
//|                                        OnTick(string symbol).mqh |
//|                                            Copyright 2010, Lizar |
//|                            https://login.mql5.com/ru/users/Lizar |
//|                                              Revision 2011.01.30 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "https://login.mql5.com/ru/users/Lizar"

//+------------------------------------------------------------------+
//| The events enumeration is implemented as flags                   |
//| the events can be combined using the OR ("|") logical operation  |
//+------------------------------------------------------------------+

  
enum ENUM_CHART_EVENT_SYMBOL
  {
   CHARTEVENT_NO        =0,          // Events disabled
   CHARTEVENT_INIT      =0,          // "Initialization" event
   
   CHARTEVENT_NEWBAR_M1 =0x00000001, // "New bar" event on M1 chart
   CHARTEVENT_NEWBAR_M2 =0x00000002, // "New bar" event on M2 chart
   CHARTEVENT_NEWBAR_M3 =0x00000004, // "New bar" event on M3 chart
   CHARTEVENT_NEWBAR_M4 =0x00000008, // "New bar" event on M4 chart
   
   CHARTEVENT_NEWBAR_M5 =0x00000010, // "New bar" event on M5 chart
   CHARTEVENT_NEWBAR_M6 =0x00000020, // "New bar" event on M6 chart
   CHARTEVENT_NEWBAR_M10=0x00000040, // "New bar" event on M10 chart
   CHARTEVENT_NEWBAR_M12=0x00000080, // "New bar" event on M12 chart
   
   CHARTEVENT_NEWBAR_M15=0x00000100, // "New bar" event on M15 chart
   CHARTEVENT_NEWBAR_M20=0x00000200, // "New bar" event on M20 chart
   CHARTEVENT_NEWBAR_M30=0x00000400, // "New bar" event on M30 chart
   CHARTEVENT_NEWBAR_H1 =0x00000800, // "New bar" event on H1 chart
   
   CHARTEVENT_NEWBAR_H2 =0x00001000, // "New bar" event on H2 chart
   CHARTEVENT_NEWBAR_H3 =0x00002000, // "New bar" event on H3 chart
   CHARTEVENT_NEWBAR_H4 =0x00004000, // "New bar" event on H4 chart
   CHARTEVENT_NEWBAR_H6 =0x00008000, // "New bar" event on H6 chart
   
   CHARTEVENT_NEWBAR_H8 =0x00010000, // "New bar" event on H8 chart
   CHARTEVENT_NEWBAR_H12=0x00020000, // "New bar" event on H12 chart
   CHARTEVENT_NEWBAR_D1 =0x00040000, // "New bar" event on D1 chart
   CHARTEVENT_NEWBAR_W1 =0x00080000, // "New bar" event on W1 chart
     
   CHARTEVENT_NEWBAR_MN1=0x00100000, // "New bar" event on MN1 chart
   CHARTEVENT_TICK      =0x00200000, // "New tick" event
   
   CHARTEVENT_ALL       =0xFFFFFFFF, // All events enabled
  };

//--- 
#define  CHART_EVENT_SYMBOL CHARTEVENT_TICK // frequency of calling OnTick()

int    _handle_[];

int    _symbols_total_  = 0;     // total symbols
int    _symbols_market_ = 0;     // number of symbols in Market Watch
bool   _market_watch_   = false; // use symbols from Market Watch
bool   _testing_        = false; // In testing mode

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int LoadSymbol(string symbol)

// TODO only load when not already exists
  {
   //--- check if we work in Strategy Tester:
   _testing_=((bool)MQL5InfoInteger(MQL5_TESTING) ||
              (bool)MQL5InfoInteger(MQL5_OPTIMIZATION) ||
              (bool)MQL5InfoInteger(MQL5_VISUAL_MODE));
            
   //--- check settings
   if(_testing_ )
     {
      Print("Error: Strategy Tester is not working. ");
      return(1);
     }
     
   //--- Initialization of variables and arrays:
   _symbols_total_=SymbolsTotal(false);      // total symbols
   ArrayResize(_handle_,_symbols_total_);    // resize array for handles of "spys"
   ArrayInitialize(_handle_,INVALID_HANDLE); // initalizae array for handles of "spys"

    Print(_symbols_total_, symbol);
   _symbols_total_=ArraySize(tickSymbols);     
   for(int i=0;i<_symbols_total_;i++)
      if(!LoadAgent(i, symbol)) return(1);      
     Print(_symbols_total_, symbol);
   
   //--- Execute OnInit function of Expert Advisor
   //_OnInit();      
   return(0);   
  }

int UnloadAllSymbols()
  {
   //--- check if we work in Strategy Tester:
   _testing_=((bool)MQL5InfoInteger(MQL5_TESTING) ||
              (bool)MQL5InfoInteger(MQL5_OPTIMIZATION) ||
              (bool)MQL5InfoInteger(MQL5_VISUAL_MODE));
                      
   //--- check settings
   if(_testing_ )
     {
      Print("Error: Strategy Tester is not working. ");
      return(1);
     }

   _symbols_total_=ArraySize(tickSymbols);     
   for(int i=0;i<_symbols_total_;i++)
      if(!DeLoadAgent(i, tickSymbols[i])) return(1);      
     
   
   //--- Execute OnInit function of Expert Advisor
   //_OnInit();      
   return(0);   
  }

  

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//| Used only in Strategy Tester                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(_testing_)
     {
      for(int i=0;i<_symbols_total_;i++)
        {
         Print("a");
         string __symbol__=tickSymbols[i];
         if(MathAbs(GlobalVariableGet(__symbol__+"_flag")-2)<0.1) 
           {
            Print("b");
            GlobalVariableSet(__symbol__+"_flag",1);
            OnTick(__symbol__);
           }
        }   
     }   
  }

//+------------------------------------------------------------------+

//| ChartEvent function                                              |

//+------------------------------------------------------------------+

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)

  {
   //--- Call of OnTick(string symbol) or OnChartEvent event handler:
   if(id==CHARTEVENT_CUSTOM_LAST) 
     {
      OnTick(sparam);
      //--- synchronize "agents" with Market Watch if necessary: 
     }
   else _OnChartEvent(id,lparam,dparam,sparam);
  }

#define OnChartEvent _OnChartEvent // rendefine of OnChartEvent function

//+------------------------------------------------------------------+
//| Function for loading of "spys"                                   |
//| INPUT:  __id__     - id, corresponds to the symbol index in      |
//|                      the list of symbols                         |
//|         __symbol__ - symbol name                                 |
//| OUTPUT: true       - if successful                               |
//|         false      - if error                                    |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool LoadAgent(int __id__, string __symbol__)
  {
   _handle_[__id__]=iCustom(__symbol__,_Period,"Spy Control panel MCM",ChartID(),65534,CHART_EVENT_SYMBOL);
   if(_handle_[__id__]==INVALID_HANDLE) 
     {
      Print("Error in setting of agent for ",__symbol__);
      return(false);  
     }
   Print("The agent for ",__symbol__," is set.");
   return(true);  
  }  
  
//+------------------------------------------------------------------+
//| Function for release of the "spys"                               |
//| INPUT:  __id__     - id, corresponds to the symbol index in      |
//|                      the list of symbols                         |
//|         __symbol__ - symbol name                                 |
//| OUTPUT: true       - if successful                               |
//|         false      - if error                                    |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool DeLoadAgent(int __id__, string __symbol__)
  {
   if(_handle_[__id__]!=INVALID_HANDLE)
     {
      if(!IndicatorRelease(_handle_[__id__]))
        {
         Print("Error deletion of agent for ",__symbol__);
         return(false);  
        }
      Print("The agent for ",__symbol__," is deleted.");
      _handle_[__id__]=INVALID_HANDLE;
     }
   return(true);  
  }
  
//+------------------------------ end -------------------------------+
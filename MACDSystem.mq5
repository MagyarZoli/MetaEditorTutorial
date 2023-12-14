#include <Trade/Trade.mqh>

input double getLots = 0.01;

CTrade trade;

int handle;
int barsTotal;
ulong posTicket;

int OnInit() {
   handle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   barsTotal = iBars(_Symbol, PERIOD_CURRENT);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   
   if (bars > barsTotal) {
      barsTotal = bars;
      double macd[];
      double signal[];
      CopyBuffer(handle, MAIN_LINE, 1, 2, macd);
      CopyBuffer(handle, SIGNAL_LINE, 1, 2, signal);
      
      if (macd[1] > signal[1] && macd[0] < signal[0]) {
         if (posTicket > 0 && PositionSelectByTicket(posTicket)) {
            if (
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL &&
               trade.PositionClose(posTicket)
            ) posTicket = 0;  
         } else posTicket = 0;
      
         if (posTicket <= 0) {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double sl = NormalizeDouble(ask - 100 * _Point, _Digits);
            double tp = NormalizeDouble(ask + 100 * _Point, _Digits);
            if (trade.Buy(getLots, _Symbol, 0, sl, tp)) {
               posTicket = trade.ResultOrder();
            }
         }
      } else if (macd[1] < signal[1] && macd[0] > signal[0]) {
         if (posTicket > 0 && PositionSelectByTicket(posTicket)) {
            if (
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
               trade.PositionClose(posTicket)
            ) posTicket = 0;
         } else posTicket = 0;
         
         if (posTicket <= 0) {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double sl = NormalizeDouble(bid + 100 * _Point, _Digits);
            double tp = NormalizeDouble(bid - 100 * _Point, _Digits);
            if (trade.Sell(getLots, _Symbol, 0, sl, tp)) {
               posTicket = trade.ResultOrder();
            }
         }
      }
   }
}
#include <Trade/Trade.mqh>

CTrade trade;

int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   static datetime timestamp;
   datetime time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(timestamp != time) {
      timestamp = time;

      static int handleSlowMa = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE);
      double slowMaArray[];
      CopyBuffer(handleSlowMa, 0, 1, 2, slowMaArray);
      ArraySetAsSeries(slowMaArray, true);
   
      static int handleFastMa = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
      double fastMaArray[];
      CopyBuffer(handleFastMa, 0, 1, 2, fastMaArray);
      ArraySetAsSeries(fastMaArray, true);
   
      if(fastMaArray[0] > slowMaArray[0] && fastMaArray[1] < slowMaArray[1]) {
         Print("Fast Ma is now > than slow ma");
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl = ask - 100 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double tp = ask + 100 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         trade.Buy(0.01, _Symbol, ask, sl, tp, "This is a buy");
      }
      if(fastMaArray[0] < slowMaArray[0] && fastMaArray[1] > slowMaArray[1]) {
         Print("Fast Ma is now > than slow ma");
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl = bid - 100 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double tp = bid + 100 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         trade.Sell(0.01, _Symbol, bid, sl, tp, "This is a sell");
      }
   }
}

#include <Trade/Trade.mqh>

input double getLost = 0.01;

CTrade trade;

int lastBreakout = 0;

int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   double high = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1), _Digits);
   double low = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1), _Digits);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   lastBreakout = TradeLastBreakout(high, low, bid);
   TradePositionModify(high, low);
}

int TradeLastBreakout(double high, double low, double bid) {
   if (lastBreakout <= 0 && bid > high) {
      trade.Buy(getLost, _Symbol, 0, low);
      return 1;
   } else if (lastBreakout >= 0 && bid < low) {
      trade.Sell(getLost, _Symbol, 0, high);
      return -1;
   } 
   return lastBreakout;
}

void TradePositionModify(double high, double low) {
for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      CPositionInfo pos;
      if (pos.SelectByTicket(posTicket)) {
         if (pos.PositionType() == POSITION_TYPE_BUY && low > pos.StopLoss()) {
            trade.PositionModify(pos.Ticket(), low, pos.TakeProfit());
         } else if (pos.PositionType() == POSITION_TYPE_SELL && high < pos.StopLoss()) {
            trade.PositionModify(pos.Ticket(), high, pos.TakeProfit());
         }
      }
   }
}
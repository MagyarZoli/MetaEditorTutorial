#include <Trade/Trade.mqh>

input double getLots = 0.01;
input int tpPoints = 100;
input int slPoints = 100;
input int stochKPeriod = 5;
input int stochDPeriod = 3;
input int stochSlowing = 3;
input ENUM_MA_METHOD stochMethod = MODE_SMA;
input ENUM_STO_PRICE stochPriceField = STO_LOWHIGH;
input double stochUpperBound = 80;
input double stochLowerBound = 20;

CTrade trade;

int handle;
int totalBars;

int OnInit() {
   totalBars = iBars(_Symbol, PERIOD_CURRENT);
   handle = iStochastic(
      _Symbol, PERIOD_CURRENT,
      stochKPeriod, stochDPeriod, stochSlowing,
      stochMethod, stochPriceField
   );
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {

   TradePositionModify();

   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if (totalBars != bars) {
      totalBars = bars;
      double stoch[];
      double signal[];
      
      CopyBuffer(handle, 0, 1, 2, stoch);
      CopyBuffer(handle, 1, 1, 2, signal);
      
      if (
         stoch[1] > signal[1] && stoch[0] < signal[0] &&
         (stoch[1] <= stochLowerBound || signal[1] <= stochLowerBound)
      ) {
         double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         double sl = NormalizeDouble(ask - (slPoints * _Point), _Digits);
         double tp = NormalizeDouble(ask + (tpPoints * _Point), _Digits);
         trade.Buy(getLots, _Symbol, ask, sl, tp);
      } else if (
         stoch[1] < signal[1] && stoch[0] > signal[0] &&
         (stoch[1] >= stochUpperBound || signal[1] >= stochLowerBound)
      ) {
         double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         double sl = NormalizeDouble(bid + (slPoints * _Point), _Digits);
         double tp = NormalizeDouble(bid - (tpPoints * _Point), _Digits);
         trade.Sell(getLots, _Symbol, bid, sl, tp);
      }
   }
}

void TradePositionModify() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if (PositionSelectByTicket(posTicket)) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double posSl = PositionGetDouble(POSITION_SL);
         double posTp = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         if (posType == POSITION_TYPE_BUY) {
            double possibleWin = posTp - bid;
            double newSl = NormalizeDouble(bid - possibleWin, _Digits);
            if (newSl > posSl) trade.PositionModify(posTicket, newSl, posTp);
         } else if (posType == POSITION_TYPE_SELL) {
            double possibleWin = ask - posTp;
            double newSl = NormalizeDouble(ask + possibleWin, _Digits);
            if (newSl < posSl || posSl == 0) trade.PositionModify(posTicket, newSl, posTp);
         }
      }
   }
}
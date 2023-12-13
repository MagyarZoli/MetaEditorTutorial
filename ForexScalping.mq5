#include <Trade/Trade.mqh>

CTrade trade;
int magicNumber = 2;

int handleTrendMaFast;
int handleTrendMaSlow;
int handleMaFast;
int handleMaMiddle;
int handleMaSlow;

double setLots = 0.01;
double maTrendFast[], maTrendSlow[];
double maFast[], maMiddle[], maSlow[];

int OnInit() {
   trade.SetExpertMagicNumber(magicNumber);
   
   handleTrendMaFast = iMA(_Symbol, PERIOD_H1, 8, 0, MODE_EMA, PRICE_CLOSE);
   handleTrendMaSlow = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
   handleMaFast = iMA(_Symbol, PERIOD_M5, 8, 0, MODE_EMA, PRICE_CLOSE);
   handleMaMiddle = iMA(_Symbol, PERIOD_M5, 15, 0, MODE_EMA, PRICE_CLOSE);
   handleMaSlow = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   CopyBuffers();
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ScalpTrade(bid, TrendDirection(bid), Positions(bid), Orders());
}

void CopyBuffers() {
   CopyBuffer(handleTrendMaFast, 0, 0, 1, maTrendFast);
   CopyBuffer(handleTrendMaSlow, 0, 0, 1, maTrendSlow);
   CopyBuffer(handleMaFast, 0, 0, 1, maFast);
   CopyBuffer(handleMaMiddle, 0, 0, 1, maMiddle);
   CopyBuffer(handleMaSlow, 0, 0, 1, maSlow);
}

int TrendDirection(double bid) {
   if (maTrendFast[0] > maTrendSlow[0] && bid > maTrendFast[0]) return 1;
   else if (maTrendFast[0] < maTrendSlow[0] && bid < maTrendFast[0]) return -1;
   return 0;
}

int Positions(double bid) {
   int positions = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if (
         PositionSelectByTicket(posTicket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == magicNumber
      ) {
         positions++;
         TradePositionModify(bid, posTicket, (int)PositionGetInteger(POSITION_TYPE));
      }
   }
   return positions;
}

void TradePositionModify(double bid, ulong posTicket,int posType) {
   if (posType == POSITION_TYPE_BUY) TradePositionModifyBuy(bid, posTicket);
   else if (posType == POSITION_TYPE_SELL) TradePositionModifySell(bid, posTicket);
}

void TradePositionModifyBuy(double bid, ulong posTicket) {
   double posSl = PositionGetDouble(POSITION_SL);
   double posVolume = PositionGetDouble(POSITION_VOLUME);
   double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);          
   if (posVolume >= setLots) {
      double tp = posPriceOpen + (posPriceOpen - posSl);
      if (
         bid >= tp && 
         trade.PositionClosePartial(posTicket, NormalizeDouble(posVolume / 2,2))
      ) {
         double sl = NormalizeDouble(posPriceOpen, _Digits);
         trade.PositionModify(posTicket, sl, 0);
      }
   } else {
      int lowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 3, 1);
      double sl = NormalizeDouble(iLow(_Symbol, PERIOD_M5, lowest), _Digits);
      if (sl > posSl) trade.PositionModify(posTicket, sl, 0);
   }
}

void TradePositionModifySell(double bid, ulong posTicket) {
   double posSl = PositionGetDouble(POSITION_SL);
   double posVolume = PositionGetDouble(POSITION_VOLUME);
   double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);          
   if (posVolume >= setLots) {
   double tp = posPriceOpen - (posSl - posPriceOpen);
      if (
         bid >= tp && 
         trade.PositionClosePartial(posTicket, NormalizeDouble(posVolume / 2,2))
      ) {
         double sl = NormalizeDouble(posPriceOpen, _Digits);
         trade.PositionModify(posTicket, sl, 0);
      }
   } else {
      int highest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 3, 1);
      double sl = NormalizeDouble(iHigh(_Symbol, PERIOD_M5, highest), _Digits);
      if (sl > posSl) trade.PositionModify(posTicket, sl, 0);
   }
}

int Orders() {
   int orders = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong orderTicket = OrderGetTicket(i);
      if (
         OrderSelect(orderTicket) && 
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == magicNumber
      ) {
         if (OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() - 30 * PeriodSeconds(PERIOD_M1)) {
            trade.OrderDelete(orderTicket);
         }
         orders++;
      }
   }
   return orders;
}

void ScalpTrade(double bid, int trendDirection, int positions, int orders) {
   if (trendDirection == 1) {
      if (
         maFast[0] > maMiddle[0] && maMiddle[0] > maSlow[0] && 
         bid <= maFast[0] && positions + orders <= 0
      ) {
         int indexHighest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1);
         double highPrice = NormalizeDouble(iHigh(_Symbol, PERIOD_M5, indexHighest), _Digits);   
         double sl = NormalizeDouble(iLow(_Symbol, PERIOD_M5, 0) + 30 * _Point, _Digits);     
         trade.BuyStop(setLots, highPrice, _Symbol, sl);         
      }
   } else if (trendDirection == -1) {
      if (
         maFast[0] < maMiddle[0] && maMiddle[0] < maSlow[0] && 
         bid >= maFast[0] && positions + orders <= 0
      ) {
         int indexLowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1);
         double lowPrice = NormalizeDouble(iLow(_Symbol, PERIOD_M5, indexLowest), _Digits);     
         double sl = NormalizeDouble(iHigh(_Symbol, PERIOD_M5, 0) - 30 * _Point, _Digits);    
         trade.SellStop(setLots, lowPrice, _Symbol, sl);
      }
   }
}
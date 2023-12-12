#include <Trade/Trade.mqh>

CTrade trade;

int rsiHandle;
ulong posTicket;

int OnInit() {
   rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   double rsi[];
   CopyBuffer(rsiHandle, 0, 1, 1, rsi);
   
   if (rsi[0] > 70) {
      if (posTicket > 0 && PositionSelectByTicket(posTicket)) {
         TradePositionClose((int)PositionGetInteger(POSITION_TYPE), POSITION_TYPE_BUY);
      }
      if (posTicket >= 0) {
         trade.Sell(0.01, _Symbol);
         posTicket = trade.ResultOrder();
      }
   } else if (rsi[0] < 30) {
      if (posTicket > 0 && PositionSelectByTicket(posTicket)) {
         TradePositionClose((int)PositionGetInteger(POSITION_TYPE), POSITION_TYPE_SELL);
      }
      if (posTicket <= 0) {
         trade.Buy(0.01, _Symbol);
         posTicket = trade.ResultOrder();
      }
   }
   
   PosTicket(0.00300, 0.00500);
}

void PosTicket(double price1, double price2) {
   if (PositionSelectByTicket(posTicket)) {
      double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSL = PositionGetDouble(POSITION_SL);
      double posTP = PositionGetDouble(POSITION_TP);
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      
      if (posType == POSITION_TYPE_BUY && posSL == 0) {
         double sl = posPriceOpen - price1;
         double tp = posPriceOpen + price2;
         trade.PositionModify(posTicket, sl, posTP);
      } else if (posType == POSITION_TYPE_SELL && posSL == 0) {
         double sl = posPriceOpen - price2;
         double tp = posPriceOpen + price1;
         trade.PositionModify(posTicket, sl, posTP);
      }
   } else posTicket = 0;
}

void TradePositionClose(int posType, int enumPositionType) {
   if (posType == enumPositionType) {
      trade.PositionClose(posTicket);
      posTicket = 0;
   }
}
#include <Trade/Trade.mqh>

input double getLots = 0.01;
input double lotFactor = 2;
input int TpPoints = 100;
input int SlPoinst = 100;

CTrade trade;
int magicNumber = 111;
bool isTradeAllowed = true;

int OnInit() {
   trade.SetExpertMagicNumber(magicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   if (isTradeAllowed) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double tp = ask + (TpPoints * _Point);
      double sl = ask - (SlPoinst * _Point);
      ask = NormalizeDouble(ask, _Digits);
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      if (trade.Buy(getLots, _Symbol, ask, sl, tp)) isTradeAllowed = false;
   }
}

void OnTradeTransaction(
   const MqlTradeTransaction& trans,
   const MqlTradeRequest& request,
   const MqlTradeResult& result
) {
   if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      CDealInfo deal;
      deal.Ticket(trans.deal);
      HistorySelect(TimeCurrent() - PeriodSeconds(PERIOD_D1), TimeCurrent() + 10);
      if (
         deal.Magic() == magicNumber && deal.Symbol() == _Symbol && 
         deal.Entry() == DEAL_ENTRY_OUT
      ) {
         if (deal.Profit() > 0) {
            isTradeAllowed = true;
         } else {
            if (deal.DealType() == DEAL_TYPE_BUY) {
               double lotsVolume = NormalizeDouble(deal.Volume() * lotFactor, 2);
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double sl = NormalizeDouble(ask - (SlPoinst * _Point), _Digits);
               double tp = NormalizeDouble(ask + (TpPoints * _Point), _Digits);
               ask = NormalizeDouble(ask, _Digits);
               trade.Buy(lotsVolume, _Symbol, ask, sl, tp);
            } else if (deal.DealType() == DEAL_TYPE_SELL) {
               double lotsVolume = NormalizeDouble(deal.Volume() * lotFactor, 2);
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               double sl = NormalizeDouble(bid + (SlPoinst * _Point), _Digits);
               double tp = NormalizeDouble(bid - (TpPoints * _Point), _Digits);
               bid = NormalizeDouble(bid, _Digits);
               trade.Sell(lotsVolume, _Symbol, bid, sl, tp);
            }
         }  
      }
   }
}
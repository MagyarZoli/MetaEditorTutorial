#include "../Simulate.mqh"
#include "../SimulateRSI.mqh"

#include <Trade/Trade.mqh>

input group "==== Magic Number ====";
input int inpMagicNumber = 99915; //Magic number for the EA's trades.
input group "==== General =====";
input double inpLotSize = 1.0; //Lot size for trading.
input int inpStopLoss = 0; //Stop loss value.
input int inpTakeProfit = 0; //Take profit value.
input group "==== RSI ====";
input ENUM_APPLIED_PRICE inpAppliedPrice = PRICE_CLOSE;
input int inpRatio = 10; //ratio
input int inpNarrow = 0; //narrow
input int inpHour = 1; //Time period in hours.
input int inpShift = 1; //Shift value for RSI.
input group "==== MA ====";
input int inpPeriodMA = 3; //Period for the Moving Average.     

CTrade gTrade;
MqlTick gCurrentTick;
SimulateRSI gHandle[]; 
int gStart = 5;
int gEnd = 30;
int gBreakOut = 10;
datetime gLastOrderTime = 0; 
int gTimeInterval = (60 * 60 * inpHour); 
SimulateRSI gBestSell;
SimulateRSI gBestBuy;
int gSellCount = 0; 
int gBuyCount = 0;
ulong gTicketBuy[]; 
ulong gTicketSell[];
bool gStrategy[4]; 
bool gSellStrategy[2]; 
bool gBuyStrategy[2]; 
bool gHighLevel[2]; 
bool gLowLevel[2]; 

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  gTrade.SetExpertMagicNumber(inpMagicNumber);
  ArrayResize(gHandle, (gEnd - gStart) * 4);
  gBestSell = SimulateRSI();
  gBestBuy = SimulateRSI();
  int l = 0;
  for (int i = 0; i < gEnd - gStart; i++) {
    for (int j = gBreakOut; j <= gBreakOut * 4; j += gBreakOut) {
      gHandle[l++] = SimulateRSI(_Symbol, PERIOD_CURRENT, gStart + i, inpPeriodMA, inpAppliedPrice, 100 - j, j, inpShift, gTimeInterval);
    }
  }
  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {}

void OnTick() {
  for (int i = 0; i < ArraySize(gHandle); i++) {
    gHandle[i].Tick();
  }
  if (TimeCurrent() > gLastOrderTime + gTimeInterval) {
    gBestSell = BestSellSimulate();
    gBestBuy = BestBuySimulate();
  }
}

SimulateRSI BestSellSimulate() {
  double bestSellTotalProfit = 0.0;
  int bestSellIndex = -1;
  SimulateRSI bestSellSimulateRSI;
  for (int i = 0; i < ArraySize(gHandle); i++) {
    Simulate simulate = gHandle[i].GetSellSimulate();
    if (simulate.GetTotalProfit() > bestSellTotalProfit) {
      bestSellTotalProfit = simulate.GetTotalProfit();
      bestSellIndex = i;
      bestSellSimulateRSI = SimulateRSI(gHandle[bestSellIndex]);
    }
  }
  if (bestSellIndex == -1) {
    for (int i = 0; i < ArraySize(gHandle); i++) {
      if (gBestSell.Comparable(gHandle[i]) == 0) {
        bestSellIndex = i;
        bestSellSimulateRSI = gBestSell;
      }
    }
  }
  TradeSellStrategy(bestSellSimulateRSI);
  return bestSellSimulateRSI;
}

SimulateRSI BestBuySimulate() {
  double bestBuyTotalProfit = 0.0;
  int bestBuyIndex = -1;
  SimulateRSI bestBuySimulateRSI;
  for (int i = 0; i < ArraySize(gHandle); i++) {
    Simulate simulate = gHandle[i].GetBuySimulate();
    if (simulate.GetTotalProfit() > bestBuyTotalProfit) {
      bestBuyTotalProfit = simulate.GetTotalProfit();
      bestBuyIndex = i;
      bestBuySimulateRSI = SimulateRSI(gHandle[bestBuyIndex]);
    }
  }
  if (bestBuyIndex == -1) {
    for (int i = 0; i < ArraySize(gHandle); i++) {
      if (gBestBuy.Comparable(gHandle[i]) == 0) {
        bestBuyIndex = i;
        bestBuySimulateRSI = gBestBuy;
      }
    }
  }
  TradeBuyStrategy(bestBuySimulateRSI);
  return bestBuySimulateRSI;
}

void TradeSellStrategy(SimulateRSI &sellSimulateRSI) {
  ArrayResize(gTicketSell, (gSellCount + 1));
  gTicketSell[gSellCount] = 0;
  double buffer[];
  double bufferMA[];
  Simulate simulate = sellSimulateRSI.GetSellSimulate();
  simulate.GetBuffer(buffer);
  simulate.GetBufferMA(bufferMA);
  int max = simulate.GetMax();
  int min = simulate.GetMin();
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[1] < buffer[2] && gTicketSell[gSellCount] <= 0) { //FIXME
    if (gSellStrategy[0] && buffer[2] >= (max - inpRatio) && buffer[2] < max) {
      gSellStrategy[0] = false;
      TradeSell();
      CloseAllBuy();
    } else if (gSellStrategy[1] && buffer[2] >= max && buffer[2] < (max + inpRatio)) {
      gSellStrategy[1] = false;
      TradeSell();
      CloseAllBuy();
    } else if (!gStrategy[0] && buffer[2] >= (max + inpRatio)) {
      gStrategy[0] = true;
      TradeSell();
      CloseAllBuy();
    }
  } else if (!gStrategy[1] && (buffer[1] > max || buffer[2] > max) && buffer[1] < buffer[2]) {
    gStrategy[1] = true;
    TradeSell();
    CloseAllBuy();
  } else if (!gStrategy[2] && !gHighLevel[0] && gHighLevel[1]) {
    gStrategy[2] = true;
    TradeSell(); 
    CloseAllBuy();
  } else if (!gStrategy[3] && rsima >= max) {
    gStrategy[3] = true;
    TradeSell();
    CloseAllBuy();
  }
}

void TradeBuyStrategy(SimulateRSI &buySimulateRSI) {
  ArrayResize(gTicketBuy, (gBuyCount + 1));
  gTicketBuy[gBuyCount] = 0;
  double buffer[];
  double bufferMA[];
  Simulate simulate = Simulate(buySimulateRSI.GetBuySimulate());
  simulate.GetBuffer(buffer);
  simulate.GetBufferMA(bufferMA);
  int max = simulate.GetMax();
  int min = simulate.GetMin();
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[1] > buffer[2] && gTicketBuy[gBuyCount] <= 0) {
    if (gBuyStrategy[0] && buffer[2] <= (min + inpRatio) && buffer[2] > min) {
      gBuyStrategy[0] = false;
      TradeBuy();
      CloseAllSell();
    } else if (gBuyStrategy[1] && buffer[2] <= min && buffer[2] > (min - inpRatio)) {
      gBuyStrategy[1] = false;
      TradeBuy();
      CloseAllSell();
    } else if (gStrategy[0] && buffer[2] <= (min - inpRatio)) {
      gStrategy[0] = false;
      TradeBuy();
      CloseAllSell();
    } else if (gStrategy[1] && (buffer[1] < min || buffer[2] < min) && buffer[1] > buffer[2]) {
      gStrategy[1] = false;
      TradeBuy();
      CloseAllSell();
    } else if (gStrategy[2] && !gLowLevel[0] && gLowLevel[1]) {
      gStrategy[2] = false;
      TradeBuy();
      CloseAllSell();
    } else if (gStrategy[3] && rsima <= min) {
      gStrategy[3] = false;
      TradeBuy();
      CloseAllSell();
    }
  }
}

void TradeSell() {
  double sl = inpStopLoss == 0 ? 0 : gCurrentTick.ask + inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : gCurrentTick.ask - inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  gTrade.Sell(inpLotSize, _Symbol, gCurrentTick.bid, sl, tp, "TradeSell()");
  gTicketSell[gSellCount++] = gTrade.ResultOrder();
}

void TradeBuy() {
  double sl = inpStopLoss == 0 ? 0 : gCurrentTick.bid - inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : gCurrentTick.bid + inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  gTrade.Buy(inpLotSize, _Symbol, gCurrentTick.ask, sl, tp, "TradeBuy()");
  gTicketBuy[gBuyCount++] = gTrade.ResultOrder();
}

void CloseAllSell() {
  if (ArraySize(gTicketSell) > 0) {
    for (int j = 0; j < ArraySize(gTicketSell); j++) {
      gTrade.PositionClose(gTicketSell[j]);
    }
    ArrayResize(gTicketSell, 0);
    gSellCount = 0;
    for (int k = 0; k < ArraySize(gSellStrategy); k++) {
      gSellStrategy[k] = true;
    }
  }
}

void CloseAllBuy() {
  if (ArraySize(gTicketBuy) > 0) {
    for (int j = 0; j < ArraySize(gTicketBuy); j++) {
      gTrade.PositionClose(gTicketBuy[j]);
    }
    ArrayResize(gTicketBuy, 0);
    gBuyCount = 0;
    for (int k = 0; k < ArraySize(gBuyStrategy); k++) {
      gBuyStrategy[k] = true;
    }
  }
}

bool CheckInputs() {
  bool correct = true;
  if (inpMagicNumber <= 0) {
    Alert("MagicNumber <= 0");
    correct = false;
  }
  if (inpLotSize <= 0 || inpLotSize > 10) {
    Alert("Lot size <= 0 or > 10");
    correct = false;
  }
  if (inpStopLoss < 0) {
    Alert("Stop loss < 0");
    correct = false;
  }
  if (inpTakeProfit < 0) {
    Alert("Take profit < 0");
    correct = false;
  }
  if (inpRatio <= 0 || inpRatio >= 50) {
    Alert("RSI ratio <= 0 or >= 50");
    correct = false;
  }
  if (inpHour <= 0) {
    Alert("Hour <= 0");
    correct = false;
  }
  if (inpShift <= 0) {
    Alert("shift <= 0");
    correct = false;
  }
  if (inpPeriodMA <= 1) {
    Alert("MA period <= 1");
    correct = false;
  }
  return correct;
}

bool NormalizePrice(double &price) {
  double tickSize = 0;
  if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
    Print("Failed to get tick size");
    return false;
  }
  price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
  return true;
}

double RSIMovingAverage(double &bufferMA[]) {
  double rsima = 0;
  for (int i = 0; i < ArraySize(bufferMA); i++) {
    rsima += bufferMA[i];
  }
  return rsima / inpPeriodMA;
}
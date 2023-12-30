#include <Trade/Trade.mqh>

input int inpMagicNumber = 99915;
input double inpLotSize = 1.0;  
input int inpPeriod = 20;   
input int inpMax = 70;      
input int inpMin = 30;      
input int inpRatio = 10; 
input int inpNarrow = 0;
input int inpStopLoss = 0;
input int inpTakeProfit = 0;          
input int inpHour = 1;           

CTrade trade;
MqlTick currentTick;
int handle;
double buffer[];
ulong ticketBuy[];
ulong ticketSell[];
bool strategy[3];
bool sellStrategy[2];
bool buyStrategy[2];
bool highLevel[2];
bool lowLevel[2];
datetime lastOrderTime = 0;
int timeInterval = (60 * 60 * inpHour);
int sellCount = 0;
int buyCount = 0;
int max = inpMax;
int min = inpMin;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  trade.SetExpertMagicNumber(inpMagicNumber);
  sellStrategy[0] = true;
  sellStrategy[1] = true;
  buyStrategy[0] = true;
  buyStrategy[1] = true;
  handle = iRSI(_Symbol, PERIOD_CURRENT, inpPeriod, PRICE_CLOSE);
  if (handle == INVALID_HANDLE) {
    Alert("Failed to create indicator handle");
    return INIT_FAILED;
  }
  ArraySetAsSeries(buffer, true);
  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
  if (handle != INVALID_HANDLE) {
    IndicatorRelease(handle);
  }
}

void OnTick() {
  CopyBuffer(handle, 0, 2, 3, buffer);
  if (TimeCurrent() > lastOrderTime + timeInterval) {
    Level();
    TradeSellStrategy(sellCount);
    TradeBuyStrategy(buyCount);
    lastOrderTime = TimeCurrent();
  }
}

void TradeSellStrategy(int i) {
  ArrayResize(ticketSell, (i + 1));
  ticketSell[i] = 0;
  max = inpMax;
  for (int t = 0; t < (int) ticketSell.Size() - 1; t++) {
    min += inpNarrow;
  }
  if (
    buffer[0] < buffer[1] &&
    ticketSell[i] <= 0
  ) {
    if (
      buffer[1] >= (max - inpPeriod) && 
      buffer[1] < max && 
      sellStrategy[0]
    ) {
      sellStrategy[0] = false;
      TradeSell(i);
    } else if (
      buffer[1] >= max && 
      buffer[1] < (max + inpPeriod) && 
      sellStrategy[1]
    ) {
      sellStrategy[1] = false;
      TradeSell(i);
    } else if (
      strategy[0] &&
      buffer[1] >= (max + inpPeriod)
    ) {
      strategy[0] = false;
      TradeSell(i);
    }
    
    if (
      !strategy[1] &&
      (buffer[0] > max || buffer[1] > max) &&
      buffer[0] < buffer[1]
    ) {
      TradeSell(i);
      strategy[1] = true;
    }
   
    if (
      !strategy[2] &&
      !highLevel[0] && highLevel[1]
    ) {
      TradeSell(i);
      strategy[2] = true;
    }
  }
}

void TradeBuyStrategy(int i) {
  ArrayResize(ticketBuy, (i + 1));
  ticketBuy[i] = 0;
  min = inpMin;
  for (int t = 0; t < (int) ticketBuy.Size() - 1; t++) {
    max -= inpNarrow;
  }
  if (
    buffer[0] > buffer[1] && 
    ticketBuy[i] <= 0
  ) {
    if (
      buffer[1] <= (min + inpPeriod) && 
      buffer[1] > min &&
      buyStrategy[0]
    ) {
      buyStrategy[0] = false;
      TradeBuy(i);
    } else if (
      buffer[1] <= min && 
      buffer[1] > (min - inpPeriod) && 
      buyStrategy[1]
    ) {
      buyStrategy[1] = false;
      TradeBuy(i);
    } else if (
      !strategy[0] &&
      buffer[1] <= (min - inpPeriod)
    ) {
      strategy[0] = true;
      TradeBuy(i);
    }
    
    if (
      strategy[1] &&
      (buffer[0] < min || buffer[1] < min) &&
      buffer[0] > buffer[1]
    ) {
      TradeBuy(i);
      strategy[1] = false;
    }
    
    if (
      strategy[2] &&
      !lowLevel[0] && lowLevel[1]
    ) {
      TradeBuy(i);
      strategy[2] = false;
    }
  }
}

void TradeSell(int i) {
  double sl = inpStopLoss == 0 ? 0 : currentTick.ask + inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : currentTick.ask - inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  trade.Sell(inpLotSize, _Symbol, currentTick.bid, sl, tp, "");
  ticketSell[i] = trade.ResultOrder();
  sellCount++;
  if (ArraySize(ticketBuy) > 0) {
    for (int j = 0; j < ArraySize(ticketBuy); j++) {
      trade.PositionClose(ticketBuy[j]);
    }
    ArrayResize(ticketBuy, 0);
    buyCount = 0;
    for (int k = 0; k < (int) buyStrategy.Size(); k++) {
      buyStrategy[k] = true;
    }
  }
}

void TradeBuy(int i) {
  double sl = inpStopLoss == 0 ? 0 : currentTick.bid - inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : currentTick.bid + inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  trade.Buy(inpLotSize, _Symbol, currentTick.ask, sl, tp, "");
  ticketBuy[i] = trade.ResultOrder();
  buyCount++;
  if (ArraySize(ticketSell) > 0) {
    for (int j = 0; j < ArraySize(ticketSell); j++) {
      trade.PositionClose(ticketSell[j]);
    }
    ArrayResize(ticketSell, 0);
    sellCount = 0;
    for (int k = 0; k < (int) sellStrategy.Size(); k++) {
      sellStrategy[k] = true;
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
  if (inpPeriod <= 1) {
    Alert("RSI period <= 1");
    correct = false;
  }
  if (inpMax >= 100 || inpMax <= 50) {
    Alert("RSI max >= 100 or <= 50");
    correct = false;
  }
  if (inpMin <= 0 || inpMin >= 50) {
    Alert("RSI min >= 0 or >= 50");
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
  return correct;
}

void Level() {
  for (int i = 0; i <= 1; i++) {
    if (buffer[i] > inpMax) {
      highLevel[i] = true;
    } else if (buffer[i] < (inpMax - 10)) {
      highLevel[i] = false;
    }
    if (buffer[i] < inpMin) {
      lowLevel[i] = true;
    } else if (buffer[i] > (inpMin + 10)) {
      lowLevel[i] = false;
    }
  }
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
#include <Trade/Trade.mqh>

input group "==== Magic Number ====";
input int inpMagicNumber = 99915; //Magic number for the EA's trades.
input group "==== General =====";
input double inpLotSize = 1.0; //Lot size for trading.
input int inpStopLoss = 0; //Stop loss value.
input int inpTakeProfit = 0; //Take profit value.
input group "==== RSI ====";
input int inpRatio = 10; //ratio
input int inpNarrow = 0; //narrow
input int inpHour = 1; //Time period in hours.
input int inpShift = 1; //Shift value for RSI.
input group "==== MA ====";
input int inpPeriodMA = 3; //Period for the Moving Average.     

CTrade trade;
MqlTick currentTick; 
int start = 5;
int end = 30;
int handle[25];
double closePrice; 
ulong ticketBuy[]; 
ulong ticketSell[];
bool strategy[4]; 
bool sellStrategy[2]; 
bool buyStrategy[2]; 
bool highLevel[2]; 
bool lowLevel[2]; 
datetime lastOrderTime = 0; 
int timeInterval = (60 * 60 * inpHour); 
int sellCount = 0; 
int buyCount = 0; 
int simulateSellCount[25];
int simulateBuyCount[25];
ulong simulateTicketSell[25];
ulong simulateTicketBuy[25];
bool half = false; 

class Simulate {
private:
  double ctotalProfit;
  double cbuffer[];
  double cbufferMA[];
  int cmax;
  int cmin;
  int cperiod;
  
public:
  Simulate(double totalProfit, double &buffer[], double &bufferMA[], int max, int min, int period) {
    ctotalProfit = totalProfit;
    CopyArray(buffer, cbuffer);
    CopyArray(bufferMA, cbufferMA);
    cmax = max;
    cmin = min;
    cperiod = period;
  }
  
  Simulate(const Simulate &other) {
    ctotalProfit = other.ctotalProfit;
    CopyArray(other.cbuffer, cbuffer);
    CopyArray(other.cbufferMA, cbufferMA);
    cmax = other.cmax;
    cmin = other.cmin;
    cperiod = other.cperiod;
  }
  
  double GetTotalProfit() {
    return ctotalProfit;
  }
  
  void GetBuffer(double &buffer[]) {
    CopyArray(cbuffer, buffer);
  }
  
  void GetBufferMA(double &bufferMA[]) {
    CopyArray(cbufferMA, bufferMA);
  }
  
  int GetMax() {
    return cmax;
  }
  
  int GetMin() {
    return cmin;
  }
  
  int GetPeriod() {
    return cperiod;
  }

private:
  void CopyArray(const double &sourceArray[], double &destinationArray[]) {
    ArrayResize(destinationArray, ArraySize(sourceArray));
    for (int i = 0; i < ArraySize(sourceArray); i++) {
        destinationArray[i] = sourceArray[i];
    }
  }
};

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  trade.SetExpertMagicNumber(inpMagicNumber);
  sellStrategy[0] = true;
  sellStrategy[1] = true;
  buyStrategy[0] = true;
  buyStrategy[1] = true;
  for (int i = 0; i < ArraySize(handle); i++) {
    handle[i] = iRSI(_Symbol, PERIOD_CURRENT, i + start, PRICE_CLOSE); 
    if (handle[i] == INVALID_HANDLE) {
      Alert("Failed to create indicator handle");
      return INIT_FAILED;
    }
  }
  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
  for (int i = 0; i < ArraySize(handle); i++) {
    if (handle[i] != INVALID_HANDLE) {
      IndicatorRelease(handle[i]);
    }
  }
}

void OnTick() {
  closePrice = iClose(_Symbol, PERIOD_CURRENT, 0);
  Simulate simulateSellProfit[];
  Simulate simulateBuyProfit[];
  if (TimeCurrent() > lastOrderTime + timeInterval) {
    for (int i = 0; i < ArraySize(handle); i++) {
      double buffer[];
      double bufferMA[];
      ArraySetAsSeries(buffer, true);
      ArraySetAsSeries(bufferMA, true);
      CopyBuffer(handle[i], 0, inpShift, 3, buffer); 
      CopyBuffer(handle[i], 0, inpShift, inpPeriodMA, bufferMA);
      simulateSellCount[i] = 0;
      simulateBuyCount[i] = 0;
      for (int j = 10; j <= 40; j += 10) {
        lastOrderTime = TimeCurrent();
        Level(buffer, 100 - j, j);
        int indexSell = (j / 10) - 1;
        int indexBuy = (j / 10) - 1;
        //Print("Iteration: " + (string)j + " IndexSell: " + (string)indexSell + " IndexBuy: " + (string)indexBuy);
        Print("Array Sizes - Sell: " + (string)ArraySize(simulateSellProfit) + " Buy: " + (string)ArraySize(simulateBuyProfit));
        //if (indexSell >= 0 && indexSell < ArraySize(simulateSellProfit)) {
          //simulateSellProfit[indexSell] = SimulateSellStrategy(simulateSellCount[i], i, buffer, bufferMA, 100 - j, j, i + start);
          simulateSellCount[i]++;
        //} else {
        //  Print("--------------Invalid index for simulateSellProfit: " + (string)indexSell);
        //}
        //if (indexBuy >= 0 && indexBuy < ArraySize(simulateBuyProfit)) {
          //simulateBuyProfit[indexBuy] = SimulateBuyStrategy(simulateBuyCount[i], i, buffer, bufferMA, 100 - j, j, i + start);
          simulateBuyCount[i]++;
        //} else {
        //  Print("--------------Invalid index for simulateBuyProfit: " + (string)indexBuy);
        //}
      }
    }
    Print("Sell Profits: " + (string) ArraySize(simulateSellProfit)); //Sel Profits: 0
    Print("Buy Profits: " + (string) ArraySize(simulateBuyProfit)); //Buy Profits: 0
    //BestSimulate(simulateSellProfit, simulateBuyProfit);
  }
}

Simulate SimulateSellStrategy(int i, int index, double &buffer[], double &bufferMA[], int max, int min, int period) {
  double totalProfit = 0;
  simulateTicketSell[index] = 0;
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[0] < buffer[1] && simulateTicketSell[i] <= 0) {
    if (sellStrategy[0] && buffer[1] >= (max - period) && buffer[1] < max) {
      sellStrategy[0] = false;  
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    } else if (sellStrategy[1] && buffer[1] >= max && buffer[1] < (max + period)) {
      sellStrategy[1] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    } else if (!strategy[0] && buffer[1] >= (max + period)) {
      strategy[0] = true;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    } else if (!strategy[1] && (buffer[0] > max || buffer[1] > max) && buffer[0] < buffer[1]) {
      strategy[1] = true;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    } else if (!strategy[2] && !highLevel[0] && highLevel[1]) {
      strategy[2] = true;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    } else if (!strategy[3] && rsima >= max) {
      strategy[3] = true;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateBuyCount[index] = 0;
    }
  }
  return Simulate(totalProfit, buffer, bufferMA, max, min, period);
}

Simulate SimulateBuyStrategy(int i, int index, double &buffer[], double &bufferMA[], int max, int min, int period) {
  double totalProfit = 0;
  simulateTicketBuy[index] = 0;
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[0] > buffer[1] && simulateTicketBuy[i] <= 0) {
    if (buyStrategy[0] && buffer[1] <= (min + period) && buffer[1] > min) {
      buyStrategy[0] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    } else if (buyStrategy[1] && buffer[1] <= min && buffer[1] > (min - period)) {
      buyStrategy[1] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    } else if (strategy[0] && buffer[1] <= (min - period)) {
      strategy[0] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    } else if (strategy[1] && (buffer[0] < min || buffer[1] < min) && buffer[0] > buffer[1]) {
      strategy[1] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    } else if (strategy[2] && !lowLevel[0] && lowLevel[1]) {
      strategy[2] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    } else if (strategy[3] && rsima <= min) {
      strategy[3] = false;
      totalProfit += iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i);
      simulateSellCount[index] = 0;
    }
  }
  return Simulate(totalProfit, buffer, bufferMA, max, min, period);
}

void BestSimulate(Simulate &simulateSellProfit[], Simulate &simulateBuyProfit[]) {
  if (ArraySize(simulateSellProfit) != ArraySize(simulateBuyProfit)) {
    Print("Error: Sell and Buy arrays must have the same size.");
    return;
  }
  Print((string) ArraySize(simulateSellProfit) + " " + (string) ArraySize(simulateBuyProfit)); 
  double bestSellTotalProfit = 0.0;
  double bestBuyTotalProfit = 0.0;
  int bestSellIndex = 0;
  int bestBuyIndex = 0;
  for (int i = 0; i < ArraySize(simulateSellProfit); i++) {
    if (simulateSellProfit[i].GetTotalProfit() > bestSellTotalProfit) {
      bestSellTotalProfit = simulateSellProfit[i].GetTotalProfit();
      bestSellIndex = i;
    }
    if (simulateBuyProfit[i].GetTotalProfit() > bestBuyTotalProfit) {
      bestBuyTotalProfit = simulateBuyProfit[i].GetTotalProfit();
      bestBuyIndex = i;
    }
  }
  double sellBuffer[];
  double sellBufferMA[];
  double buyBuffer[];
  double buyBufferMA[];
  simulateSellProfit[bestSellIndex].GetBuffer(sellBuffer);
  simulateSellProfit[bestSellIndex].GetBufferMA(sellBufferMA);
  simulateBuyProfit[bestBuyIndex].GetBuffer(buyBuffer);
  simulateBuyProfit[bestBuyIndex].GetBufferMA(buyBufferMA);
  TradeSellStrategy(sellCount, sellBuffer, sellBufferMA, simulateSellProfit[bestSellIndex].GetMax(), simulateSellProfit[bestSellIndex].GetMin(), simulateSellProfit[bestSellIndex].GetPeriod());
  TradeBuyStrategy(buyCount, buyBuffer, buyBufferMA, simulateBuyProfit[bestBuyIndex].GetMax(), simulateBuyProfit[bestBuyIndex].GetMin(), simulateBuyProfit[bestBuyIndex].GetPeriod());
}

void TradeSellStrategy(int i, double &buffer[], double &bufferMA[], int max, int min, int period) {
  ArrayResize(ticketSell, (i + 1));
  ticketSell[i] = 0;
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[0] < buffer[1] && ticketSell[i] <= 0) {
    if (sellStrategy[0] && buffer[1] >= (max - period) && buffer[1] < max) {
      sellStrategy[0] = false;
      TradeSell(i);
      CloseAllBuy();
    } else if (sellStrategy[1] && buffer[1] >= max && buffer[1] < (max + period)) {
      sellStrategy[1] = false;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[0] && buffer[1] >= (max + period)) {
      strategy[0] = true;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[1] && (buffer[0] > max || buffer[1] > max) && buffer[0] < buffer[1]) {
      strategy[1] = true;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[2] && !highLevel[0] && highLevel[1]) {
      strategy[2] = true;
      TradeSell(i); 
      CloseAllBuy();
    } else if (!strategy[3] && rsima >= max) {
      strategy[3] = true;
      TradeSell(i);
      CloseAllBuy();
    }
  }
}

void TradeBuyStrategy(int i, double &buffer[],  double &bufferMA[], int max, int min, int period) {
  ArrayResize(ticketBuy, (i + 1));
  ticketBuy[i] = 0;
  double rsima = RSIMovingAverage(bufferMA);
  if (buffer[0] > buffer[1] && ticketBuy[i] <= 0) {
    if (buyStrategy[0] && buffer[1] <= (min + period) && buffer[1] > min) {
      buyStrategy[0] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (buyStrategy[1] && buffer[1] <= min && buffer[1] > (min - period)) {
      buyStrategy[1] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[0] && buffer[1] <= (min - period)) {
      strategy[0] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[1] && (buffer[0] < min || buffer[1] < min) && buffer[0] > buffer[1]) {
      strategy[1] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[2] && !lowLevel[0] && lowLevel[1]) {
      strategy[2] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[3] && rsima <= min) {
      strategy[3] = false;
      TradeBuy(i);
      CloseAllSell();
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
}

void CloseAllSell() {
  if (ArraySize(ticketSell) > 0) {
    for (int j = 0; j < ArraySize(ticketSell); j++) {
      trade.PositionClose(ticketSell[j]);
    }
    ArrayResize(ticketSell, 0);
    sellCount = 0;
    for (int k = 0; k < ArraySize(sellStrategy); k++) {
      sellStrategy[k] = true;
    }
  }
}

void CloseAllBuy() {
  if (ArraySize(ticketBuy) > 0) {
    for (int j = 0; j < ArraySize(ticketBuy); j++) {
      trade.PositionClose(ticketBuy[j]);
    }
    ArrayResize(ticketBuy, 0);
    buyCount = 0;
    for (int k = 0; k < ArraySize(buyStrategy); k++) {
      buyStrategy[k] = true;
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

void Level(double &buffer[], int max, int min) {
  for (int i = 0; i <= 1; i++) {
    if (buffer[i] > max) {
      highLevel[i] = true;
    } else if (buffer[i] < (max - 10)) {
      highLevel[i] = false;
    }
    if (buffer[i] < min) {
      lowLevel[i] = true;
    } else if (buffer[i] > (min + 10)) {
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

double RSIMovingAverage(double &bufferMA[]) {
  double rsima = 0;
  for (int i = 0; i < ArraySize(bufferMA); i++) {
    rsima += bufferMA[i];
  }
  return rsima / inpPeriodMA;
}
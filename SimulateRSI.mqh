#include "Simulate.mqh"

class SimulateRSI {
private:
  string cSymbol;
  ENUM_TIMEFRAMES cPeriod;
  int cPeriodRSI;
  int cPeriodMA;
  ENUM_APPLIED_PRICE cAppliedPrice;
  int cMax;
  int cMin;
  int cShift;
  int cTimeInterval;
  
  int gHandle;
  int gSellCount;
  int gBuyCount;
  int gSellSimulate[];
  int gBuySimulate[];
  double gBufferRSI[];
  double gBufferMA[];
  datetime gLastOrderTime;
  bool gHighLevel[2];
  bool gLowLevel[2];
  
  bool gStrategy[4];
  bool gSellStrategy[2];
  bool gBuyStrategy[2];
  
  double gSellApplied[];
  double gBuyApplied[];
  double gSellProfit;
  double gBuyProfit;
  
public:
  SimulateRSI() {
    cSymbol = _Symbol;
    cPeriod = PERIOD_CURRENT;
    cPeriodRSI = 5;
    cPeriodMA = 3;
    cAppliedPrice = PRICE_CLOSE;
    cMax = 90;
    cMin = 10;
    cShift = 1;
    cTimeInterval = 1;
    HandleInit();
  }
  
  SimulateRSI(
    string symbol, 
    ENUM_TIMEFRAMES period, 
    int periodRSI, 
    int periodMA, 
    ENUM_APPLIED_PRICE appliedPrice,
    int max,
    int min,
    int shift,
    int timeInterval
  ) {
    cSymbol = symbol;
    cPeriod = period;
    cPeriodRSI = periodRSI;
    cPeriodMA = periodMA;
    cAppliedPrice = appliedPrice;
    cMax = max;
    cMin = min;
    cShift = shift;
    cTimeInterval = timeInterval;
    HandleInit();
  }
  
  SimulateRSI(const SimulateRSI &other) {
    cSymbol = other.GetSymbol();
    cPeriod = other.GetPeriod();
    cPeriodRSI = other.GetPeriodRSI();
    cPeriodMA = other.GetPeriodMA();
    cAppliedPrice = other.GetAppliedPrice();
    cMax = other.GetMax();
    cMin = other.GetMin();
    cShift = other.GetShift();
    cTimeInterval = other.GetTimeInterval();
    HandleInit();
  }
  
  string GetSymbol() const {
    return cSymbol;
  }
  
  ENUM_TIMEFRAMES GetPeriod() const {
    return cPeriod;
  }
  
  int GetPeriodRSI() const {
    return cPeriodRSI;
  }
  
  int GetPeriodMA() const {
    return cPeriodMA;
  }
  
  ENUM_APPLIED_PRICE GetAppliedPrice() const {
    return cAppliedPrice;
  }
  
  int GetMax() const {
    return cMax;
  }
  
  int GetMin() const {
    return cMin;
  }
  
  int GetShift() const {
    return cShift;
  }
  
  int GetTimeInterval() const {
    return cTimeInterval;
  }
  
private:
  void HandleInit() {
    gHandle = iRSI(cSymbol, cPeriod, cPeriodRSI, cAppliedPrice);
    if (gHandle == INVALID_HANDLE) {
      Alert("Failed to create indicator handle");
      return;
    }
    gSellCount = 0;
    gBuyCount = 0;
    ArraySetAsSeries(gBufferRSI, true);
    ArraySetAsSeries(gBufferMA, true);
  }

  void Tick() {
    CopyBuffer(gHandle, 0, cShift, 3, gBufferRSI);
    CopyBuffer(gHandle, 0, cShift, cPeriodMA, gBufferMA);
    if (TimeCurrent() > gLastOrderTime + cTimeInterval) {
      Level(10);
      //
      //
      gLastOrderTime = TimeCurrent();
    }
  }
  
  void Level(int border) {
    for (int i = 0; i <= 1; i++) {
      if (gBufferRSI[i] > cMax) {
        gHighLevel[i] = true;
      } else if (gBufferRSI[i] < (cMax - border)) {
        gHighLevel[i] = false;
      }
      if (gBufferRSI[i] < cMin) {
        gLowLevel[i] = true;
      } else if (gBufferRSI[i] > (cMin + border)) {
        gLowLevel[i] = false;
      }
    }
  }
  
  double RSIMovingAverage() {
    double rsima = 0;
    for (int i = 0; i < ArraySize(gBufferMA); i++) {
      rsima += gBufferMA[i];
    }
    return rsima / cPeriodMA;
  }
  
  Simulate SimulateSellStrategy() {
    double totalProfit = 0.0;
    double rsima = RSIMovingAverage();
    if (gBufferRSI[0] < gBufferRSI[1]) {
      if (gSellStrategy[0] && gBufferRSI[1] >= (cMax - cPeriodRSI) && gBufferRSI[1] < cMax) {
        gSellStrategy[0] = false;
        totalProfit += SimulateCloseBuy(SimulateTradeSell(0));
      } else if (gSellStrategy[1] && gBufferRSI[1] >= cMax && gBufferRSI[1] < (cMax + cPeriodRSI)) {
        gSellStrategy[1] = false;
        totalProfit += SimulateCloseBuy(SimulateTradeSell(1));
      } else if (!gStrategy[0] && gBufferRSI[1] >= (cMax + cPeriodRSI)) {
        gStrategy[0] = true;
        totalProfit += SimulateCloseBuy(SimulateTradeSell(2));
      }
    } else if (!gStrategy[1] && (gBufferRSI[0] > cMax || gBufferRSI[1] > cMax) && gBufferRSI[0] < gBufferRSI[1]) {
      gStrategy[1] = true;
      totalProfit += SimulateCloseBuy(SimulateTradeSell(3));
    } else if (!gStrategy[2] && !gHighLevel[0] && gHighLevel[1]) {
      gStrategy[2] = true;
      totalProfit += SimulateCloseBuy(SimulateTradeSell(4));
    } else if (!gStrategy[3] && rsima >= cMax) {
      gStrategy[3] = true;
      totalProfit += SimulateCloseBuy(SimulateTradeSell(5));
    }
    return Simulate(totalProfit, gBufferRSI, gBufferMA, cMax, cMin, cPeriodRSI);
  }
  
  Simulate SimulateBuyStrategy() {
    double totalProfit = 0.0;
    double rsima = RSIMovingAverage();
    if (gBufferRSI[0] > gBufferRSI[1]) {
      if (gBuyStrategy[0] && gBufferRSI[1] <= (cMin + cPeriodRSI) && gBufferRSI[1] > cMin) {
        gBuyStrategy[0] = false;
        totalProfit += SimulateCloseSell(SimulateTradeBuy(0));
      } else if (gBuyStrategy[1] && gBufferRSI[1] <= cMin && gBufferRSI[1] > (cMin - cPeriodRSI)) {
        gBuyStrategy[1] = false;
        totalProfit += SimulateCloseSell(SimulateTradeBuy(1));
      } else if (gStrategy[0] && gBufferRSI[1] <= (cMin - cPeriodRSI)) {
        gStrategy[0] = false;
        totalProfit += SimulateCloseSell(SimulateTradeBuy(2));
      }
    } else if (gStrategy[1] && (gBufferRSI[0] < cMin || gBufferRSI[1] < cMin) && gBufferRSI[0] > gBufferRSI[1]) {
      gStrategy[1] = false;
      totalProfit += SimulateCloseSell(SimulateTradeBuy(3));
    } else if (gStrategy[2] && !gLowLevel[0] && gLowLevel[1]) {
      gStrategy[2] = false;
      totalProfit += SimulateCloseSell(SimulateTradeBuy(4));
    } else if (gStrategy[3] && rsima <= cMin) {
      gStrategy[3] = false;
      totalProfit += SimulateCloseSell(SimulateTradeBuy(5));
    }
    return Simulate(totalProfit, gBufferRSI, gBufferMA, cMax, cMin, cPeriodRSI);
  }
  
  double SimulateTradeSell(int index) {
    switch (cAppliedPrice) {
      case PRICE_CLOSE:
        gSellApplied[index] = iClose(cSymbol, cPeriod, 0);
        break;
      case PRICE_HIGH:
        gSellApplied[index] = iHigh(cSymbol, cPeriod, 0);
        break;
      case PRICE_LOW:
        gSellApplied[index] = iLow(cSymbol, cPeriod, 0);
        break;
      case PRICE_OPEN:
        gSellApplied[index] = iOpen(cSymbol, cPeriod, 0);
        break;
    }
    return gSellApplied[index];
  }
  
  double SimulateTradeBuy(int index) {
    switch (cAppliedPrice) {
      case PRICE_CLOSE:
        gBuyApplied[index] = iClose(cSymbol, cPeriod, 0);
        break;
      case PRICE_HIGH:
        gBuyApplied[index] = iHigh(cSymbol, cPeriod, 0);
        break;
      case PRICE_LOW:
        gBuyApplied[index] = iLow(cSymbol, cPeriod, 0);
        break;
      case PRICE_OPEN:
        gBuyApplied[index] = iOpen(cSymbol, cPeriod, 0);
        break;
    }
    return gBuyApplied[index];
  }
  
  double SimulateCloseSell(double close) {
    double result = 0.0;
    for (int i = 0; i < ArraySize(gSellApplied); i++) {
      if (gSellApplied[i] == 0) {
        continue;
      }
      result += gSellApplied[i] - close;
      gSellApplied[i] = 0;
    }
    return result;
  }
  
  double SimulateCloseBuy(double close) {
    double result = 0.0;
    for (int i = 0; i < ArraySize(gBuyApplied); i++) {
      if (gBuyApplied[i] == 0) {
        continue;
      }
      result += close - gBuyApplied[i];
      gBuyApplied[i] = 0;
    }
    return result;
  }
};
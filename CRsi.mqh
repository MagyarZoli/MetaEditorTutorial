#include <Trade/Trade.mqh>

class CRsi {
private:
  int cMagicNumber;
  double cLotSize;
  int cStopLoss;
  int cTakeProfit;
  int cPeriod;
  int cMax;
  int cMin;
  int cRatio;
  int cNarrow;
  int cHour;
  int cShift;
  int cPeriodMA;
  
  CTrade trade;
  MqlTick currentTick;
  int handle;
  double closePrice;
  ulong ticketBuy[];
  ulong ticketSell[];
  bool strategy[4];
  bool sellStrategy[2];
  bool buyStrategy[2];
  bool highLevel[2];
  bool lowLevel[2];
  datetime lastOrderTime;
  int timeInterval;
  int sellCount;
  int buyCount;
  int max;
  int min;

public:
  CRsi() {
    cMagicNumber = 111;
    cLotSize = 1;
    cStopLoss = 0;
    cTakeProfit = 0;
    cPeriod = 5;
    cMax = 90;
    cMin = 10;
    cRatio = 10;
    cNarrow = 0;
    cHour = 1;
    cShift = 1;
    cPeriodMA = 3;
    lastOrderTime = 0;
    timeInterval = (60 * 60 * 1);  
    sellCount = 0;
    buyCount = 0;
    max = cMax;
    min = cMin;
  }
  
  CRsi(
    int magicNumber,
    double lotSize, int stopLoss, int takeProfit,
    int rsiPeriod, int rsiRatio,
    int rsiNarrow, int rsiHour, int rsiShift,
    int maPeriod
  ) {
    if (!CheckArgs()) {
      cMagicNumber = magicNumber;
      cLotSize = lotSize;
      cStopLoss = stopLoss;
      cTakeProfit = takeProfit;
      cPeriod = rsiPeriod;
      cMax = 90;
      cMin = 10;
      cRatio = rsiRatio;
      cNarrow = rsiNarrow;
      cHour = rsiHour;
      cShift = rsiShift;
      cPeriodMA = maPeriod;
      lastOrderTime = 0;
      timeInterval = (60 * 60 * 1);  
      sellCount = 0;
      buyCount = 0;
      max = cMax;
      min = cMin;
    }
  }
  
  CRsi(
    int magicNumber,
    double lotSize, int stopLoss, int takeProfit,
    int rsiPeriod, int rsiMax, int rsiMin, int rsiRatio,
    int rsiNarrow, int rsiHour, int rsiShift,
    int maPeriod
  ) {
    if (!CheckArgs()) {
      cMagicNumber = magicNumber;
      cLotSize = lotSize;
      cStopLoss = stopLoss;
      cTakeProfit = takeProfit;
      cPeriod = rsiPeriod;
      cMax = rsiMax;
      cMin = rsiMin;
      cRatio = rsiRatio;
      cNarrow = rsiNarrow;
      cHour = rsiHour;
      cShift = rsiShift;
      cPeriodMA = maPeriod;
      lastOrderTime = 0;
      timeInterval = (60 * 60 * 1);  
      sellCount = 0;
      buyCount = 0;
      max = cMax;
      min = cMin;
    }
  }
  
  CRsi(int magicNumber, double lotSize, int &args[]) {
    if (ArraySize(args) == 10 && !CheckArgs()) {
      cMagicNumber = magicNumber;
      cLotSize = lotSize;
      cStopLoss = args[0];
      cTakeProfit = args[1];
      cPeriod = args[2];
      cMax = args[3];
      cMin = args[4];
      cRatio = args[5];
      cNarrow = args[6];
      cHour = args[7];
      cShift = args[8];
      cPeriodMA = args[9];
      lastOrderTime = 0;
      timeInterval = (60 * 60 * 1);  
      sellCount = 0;
      buyCount = 0;
      max = cMax;
      min = cMin;
    } else {
      CRsi();
    }
  }
  
  CRsi(const CRsi &other) {
    cMagicNumber = other.GetMagicNumber();
    cLotSize = other.GetLotSize();
    cStopLoss = other.GetStopLoss();
    cTakeProfit = other.GetTakeProfit();
    cPeriod = other.GetPeriod();
    cMax = other.GetMax();
    cMin = other.GetMin();
    cRatio = other.GetRatio();
    cNarrow = other.GetNarrow();
    cHour = other.GetHour();
    cShift = other.GetShift();
    cPeriodMA = other.GetPeriodMA();
    lastOrderTime = 0;
    timeInterval = (60 * 60 * 1);  
    sellCount = 0;
    buyCount = 0;
    max = cMax;
    min = cMin;
  }
  
  int GetMagicNumber() const {
    return cMagicNumber;
  }
  
  double GetLotSize() const {
    return cLotSize;
  }
  
  int GetStopLoss() const {
    return cStopLoss;
  }
  
  int GetTakeProfit() const {
    return cTakeProfit;
  }
  
  int GetPeriod() const {
    return cPeriod;
  }
  
  int GetMax() const {
    return cMax;
  }
  
  int GetMin() const {
    return cMin;
  }
    
  int GetRatio() const {
    return cRatio;
  }
    
  int GetNarrow() const {
    return cNarrow;
  }
  
  int GetHour() const {
    return cHour;
  }
    
  int GetShift() const {
    return cShift;
  }
    
  int GetPeriodMA() const {
    return cPeriodMA;
  }
  
  int GetSellCount() const {
    return sellCount;
  }
  
  int GetBuyCount() const {
    return buyCount;
  }
  
  void SetMagicNumber(int magicNumber) {
    if (magicNumber <= 0) {
      Alert("arg MagicNumber <= 0");
      return;
    }
    cMagicNumber = magicNumber;
  }
  
  void SetLotSize(double lotSize) {
    if (lotSize <= 0 || lotSize > 10) {
      Alert("arg Lot size <= 0 or > 10");
      return;
    }
    cLotSize = lotSize;
  }
  
  void SetStopLoss(int stopLoss) {
    if (stopLoss < 0) {
      Alert("arg Stop loss < 0");
      return;
    }
    cStopLoss = stopLoss;
  }
  
  void SetTakeProfit(int takeProfit) {
    if (takeProfit < 0) {
      Alert("arg Take profit < 0");
      return;
    }
    cTakeProfit = takeProfit;
  }
  
  void SetPeriod(int period) {
    if (period <= 1) {
      Alert("arg RSI period <= 1");
      return;
    }
    cPeriod = period;
  }
  
  void SetMax(int argMax) {
    if (argMax >= 100 || argMax <= 50) {
      Alert("arg RSI max >= 100 or <= 50");
      return;
    }
    cMax = argMax;
  }
  
  void SetMin(int argMin) {
    if (argMin <= 0 || argMin >= 50) {
      Alert("arg RSI min >= 0 or >= 50");
      return;
    }
    cMin = argMin;
  }
    
  void SetRatio(int ratio) {
    if (ratio <= 0 || ratio >= 50) {
      Alert("arg RSI ratio <= 0 or >= 50");
      return;
    }
    cRatio = ratio;
  }
    
  void SetNarrow(int narrow) {
    if (narrow <= 0) {
      Alert("arg Narrow <= 0");
      return;
    }
    cNarrow = narrow;
  }
  
  void SetHour(int hour) {
    if (hour <= 0) {
      Alert("arg Hour <= 0");
      return;
    }
    cHour = hour;
  }
    
  void SetShift(int shift) {
    if (shift <= 0) {
      Alert("arg shift <= 0");
      return;
    }
    cShift = shift;
  }
    
  void SetPeriodMA(int periodMA) {
    if (periodMA <= 1) {
      Alert("arg MA period <= 1");
      return;
    }
    cPeriodMA = periodMA;
  }
  
  void SetSellCount(int count) {
    if (count < 0) {
      Alert("arg sell count < 0");
      return;
    }
    sellCount = count;
  }
  
  void SetBuyCount(int count) {
    if (count < 0) {
      Alert("arg buy count < 0");
      return;
    }
    buyCount = count;
  }
  
  void TradeSellStrategy(int count, double &buffer[], double &bufferMA[], int argMax, int period) {
    ArrayResize(ticketSell, (count + 1));
    ticketSell[count] = 0;
    double rsima = RSIMovingAverage(bufferMA);
    if (buffer[1] < buffer[2] && ticketSell[count] <= 0) {
      if (sellStrategy[0] && buffer[2] >= (argMax - period) && buffer[2] < argMax) {
        sellStrategy[0] = false;
        TradeSell(count);
        CloseAllBuy();
      } else if (sellStrategy[1] && buffer[2] >= argMax && buffer[2] < (argMax + period)) {
        sellStrategy[1] = false;
        TradeSell(count);
        CloseAllBuy();
      } else if (!strategy[0] && buffer[2] >= (argMax + period)) {
        strategy[0] = true;
        TradeSell(count);
        CloseAllBuy();
      } else if (!strategy[1] && (buffer[1] > argMax || buffer[2] > argMax) && buffer[1] < buffer[2]) {
        strategy[1] = true;
        TradeSell(count);
        CloseAllBuy();
      } else if (!strategy[2] && !highLevel[0] && highLevel[1]) {
        strategy[2] = true;
        TradeSell(count); 
        CloseAllBuy();
      } else if (!strategy[3] && rsima >= argMax) {
        strategy[3] = true;
        TradeSell(count);
        CloseAllBuy();
      }
    }
  }
  
  void TradeBuyStrategy(int count, double &buffer[], double &bufferMA[], int argMin, int period) {
    ArrayResize(ticketBuy, (count + 1));
    ticketBuy[count] = 0;
    double rsima = RSIMovingAverage(bufferMA);
    if (buffer[1] > buffer[2] && ticketBuy[count] <= 0) {
    if (buyStrategy[0] && buffer[2] <= (argMin + period) && buffer[2] > argMin) {
      buyStrategy[0] = false;
      TradeBuy(count);
      CloseAllSell();
    } else if (buyStrategy[1] && buffer[2] <= argMin && buffer[2] > (argMin - period)) {
      buyStrategy[1] = false;
      TradeBuy(count);
      CloseAllSell();
    } else if (strategy[0] && buffer[2] <= (argMin - period)) {
      strategy[0] = false;
      TradeBuy(count);
      CloseAllSell();
    } else if (strategy[1] && (buffer[1] < argMin || buffer[2] < argMin) && buffer[1] > buffer[2]) {
      strategy[1] = false;
      TradeBuy(count);
      CloseAllSell();
    } else if (strategy[2] && !lowLevel[0] && lowLevel[1]) {
      strategy[2] = false;
      TradeBuy(count);
      CloseAllSell();
    } else if (strategy[3] && rsima <= argMin) {
      strategy[3] = false;
      TradeBuy(count);
      CloseAllSell();
    }
  }
  }
  
  void Level(double &buffer[], double &bufferMA[], int argMax, int argMin) {
    for (int i = 0; i <= 1; i++) {
      if (buffer[i] > argMax) {
        highLevel[i] = true;
      } else if (buffer[i] < (argMax - 10)) {
        highLevel[i] = false;
      }
      if (buffer[i] < argMin) {
        lowLevel[i] = true;
      } else if (buffer[i] > (argMin + 10)) {
        lowLevel[i] = false;
      }
    }
  }
  
  double RSIMovingAverage(double &bufferMA[]) {
    double rsima = 0;
    for (int i = 0; i < ArraySize(bufferMA); i++) {
      rsima += bufferMA[i];
    }
    return rsima / cPeriodMA;
  }
 
private: 
  void TradeSell(int count) {
    double sl = cStopLoss == 0 ? 0 : currentTick.ask + cStopLoss * _Point;
    double tp = cTakeProfit == 0 ? 0 : currentTick.ask - cTakeProfit * _Point;
    if (!NormalizePrice(sl)) {
      Print("Falided to normalize price stop loss");
      return;
    }
    if (!NormalizePrice(tp)) {
      Print("Falided to normalize price take profit");
      return;
    }
    trade.Sell(cLotSize, _Symbol, currentTick.bid, sl, tp, "");
    ticketSell[count] = trade.ResultOrder();
    sellCount++;
  }
  
  void TradeBuy(int count) {
    double sl = cStopLoss == 0 ? 0 : currentTick.bid - cStopLoss * _Point;
    double tp = cTakeProfit == 0 ? 0 : currentTick.bid + cTakeProfit * _Point;
    if (!NormalizePrice(sl)) {
      Print("Falided to normalize price stop loss");
      return;
    }
    if (!NormalizePrice(tp)) {
      Print("Falided to normalize price take profit");
      return;
    }
    trade.Buy(cLotSize, _Symbol, currentTick.ask, sl, tp, "");
    ticketBuy[count] = trade.ResultOrder();
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

  bool NormalizePrice(double &price) {
    double tickSize = 0;
    if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
      Print("Failed to get tick size");
      return false;
    }
    price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
    return true;
  }
  
  bool CheckArgs() {
    bool correct = true;
    if (cMagicNumber <= 0) {
      Alert("MagicNumber <= 0");
      correct = false;
    }
    if (cLotSize <= 0 || cLotSize > 10) {
      Alert("Lot size <= 0 or > 10");
      correct = false;
    }
    if (cStopLoss < 0) {
      Alert("Stop loss < 0");
      correct = false;
    }
    if (cTakeProfit < 0) {
      Alert("Take profit < 0");
      correct = false;
    }
    if (cPeriod <= 1) {
      Alert("RSI period <= 1");
      correct = false;
    }
    if (cMax >= 100 || cMax <= 50) {
      Alert("RSI max >= 100 or <= 50");
      correct = false;
    }
    if (cMin <= 0 || cMin >= 50) {
      Alert("RSI min >= 0 or >= 50");
      correct = false;
    }
    if (cRatio <= 0 || cRatio >= 50) {
      Alert("RSI ratio <= 0 or >= 50");
      correct = false;
    }
    if (cNarrow <= 0) {
      Alert("Narrow <= 0");
      correct = false;
    }
    if (cHour <= 0) {
      Alert("Hour <= 0");
      correct = false;
    }
    if (cShift <= 0) {
      Alert("shift <= 0");
      correct = false;
    }
    if (cPeriodMA <= 1) {
      Alert("MA period <= 1");
      correct = false;
    }
    return correct;
  }
};
#include "InterfaceStrategy.mqh"
#include <Trade/Trade.mqh>

class RSIStrategy : public InterfaceStrategy {
private:

  long _magicNumber;
  double _lotSize;
  int _period;
  int _level;
  int _stopLoss;
  int _takeProfit;
  bool _closeSignal;
  int handle;
  double buffer[];
  MqlTick currentTick;
  CTrade trade;
  datetime openTimeBuy;
  datetime openTimeSell;
  
public:

  RSIStrategy(
    long magicNumber,
    double lotSize,
    int period,
    int level, 
    int stopLoss, 
    int takeProfit, 
    bool closeSignal
  ) {
    _magicNumber = magicNumber;
    _lotSize = lotSize;
    _period = period;
    _level = level;
    _stopLoss = stopLoss;
    _takeProfit = takeProfit;
    _closeSignal = closeSignal;
  }
  
  ~RSIStrategy() {}
  
  int StrategyInit() const override {
    if (!CheckInputs()) {
      return INIT_PARAMETERS_INCORRECT;
    }
    trade.SetExpertMagicNumber(_magicNumber);
    handle = iRSI(_Symbol, PERIOD_CURRENT, _period, PRICE_CLOSE);
    if (handle == INVALID_HANDLE) {
      Alert("Failed to create indicator handle");
      return INIT_FAILED;
    }
    ArraySetAsSeries(buffer, true);
    return INIT_SUCCEEDED;
  }
  
  void StrategyDeinit() const override {
    if (handle != INVALID_HANDLE) {
      IndicatorRelease(handle);
    }
  }
  
  void StrategyTick() const override {
    if (!SymbolInfoTick(_Symbol, currentTick)) {
      Print("Failed to get current tick");
      return;
    }
    int values = CopyBuffer(handle, 0, 0, 2, buffer);
    if (values != 2) {
      Print("Faild to get indicator values");
      return;
    }
    Comment(
      "buffer[0]: ", buffer[0],
      "\nbuffer[1] ", buffer[1]
    );
    int cntBuy, cntSell;
    if (!CountOpenPos(cntBuy, cntSell)) {
      Print("Failed to count open positions");
      return;
    }
    OpenPosBuy(cntBuy);
    OpenPosSell(cntSell);
  }
  
  bool CheckInputs() const override {
    if (_magicNumber <= 0) {
      Alert("_magicNumber <= 0");
      return false;
    }
    if (_lotSize <= 0 || _lotSize > 10) {
      Alert("_lotSize <= 0 or > 10");
      return false;
    }
    if (_period <= 1) {
      Alert("_period <= 1");
      return false;
    }
    if (_level >= 100 || _level <= 50) {
      Alert("_level >= 100 or <= 50");
      return false;
    }
    if (_stopLoss < 0) {
      Alert("_stopLoss < 0");
      return false;
    }
    if (_takeProfit < 0) {
      Alert("_takeProfit < 0");
      return false;
    }
    return true;
  }
  
  bool NormalizePrice(double &price) const override {
    double tickSize = 0;
    if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
      Print("Failed to get tick size");
      return false;
    }
    price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
    return true;
  }
  
  bool CountOpenPos(int &cntBuy, int &cntSell) const override {
    cntBuy = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket <= 0) {
        Print("Failde to get position ticket");
        return false;
      }
      if (!PositionSelectByTicket(posTicket)) {
        Print("Falided to select position");
        return false;
      }
      long magic;
      if (!PositionGetInteger(POSITION_MAGIC, magic)) {
        Print("Falide to get position magic number");
        return false;
      }
      if (magic == _magicNumber) {
        long type;
        if (!PositionGetInteger(POSITION_TYPE, type)) {
          Print("Falide to get position type");
          return false;
        }
        if (type == POSITION_TYPE_BUY) {
          cntBuy++;
        }
        if (type == POSITION_TYPE_SELL) {
          cntSell++;
        }
      }
    }
    return true;
  }
  
  void OpenPosBuy(int cntBuy) const override {
    if (
      cntBuy == 0 &&
      buffer[1] >= (100 - _level) && buffer[0] < (100 - _level) &&
      openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0)
    ) {
      openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
      if (_closeSignal) {
        if (!ClosePos(2)) {
          Print("Failed to close sell position before opening a buy position");
          return;
        }
      }
      double sl = _stopLoss == 0 ? 0 : currentTick.bid - _stopLoss * _Point;
      double tp = _takeProfit == 0 ? 0 : currentTick.bid + _takeProfit * _Point;
      if (!NormalizePrice(sl)) {
        Print("Falided to normalize price stop loss");
        return;
      }
      if (!NormalizePrice(tp)) {
        Print("Falided to normalize price take profit");
        return;
      }
      trade.PositionOpen(
        _Symbol, ORDER_TYPE_BUY, _lotSize,
        currentTick.ask, sl, tp, "RSI EA"
      );
    }
  }
  
  void OpenPosSell(int cntSell) const override {
    if (
      cntSell == 0 &&
      buffer[1] <= _level && buffer[0] > _level &&
      openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0)
    ) {
      openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
      if (_closeSignal) {
        if (!ClosePos(1)) {
          Print("Failed to close buy position before opening a sell position");
          return;
        }
      }
      double sl = _stopLoss == 0 ? 0 : currentTick.ask + _stopLoss * _Point;
      double tp = _takeProfit == 0 ? 0 : currentTick.ask - _takeProfit * _Point;
      if (!NormalizePrice(sl)) {
        Print("Falided to normalize price stop loss");
        return;
      }
      if (!NormalizePrice(tp)) {
        Print("Falided to normalize price take profit");
        return;
      }
      trade.PositionOpen(
        _Symbol, ORDER_TYPE_SELL, _lotSize,
        currentTick.bid, sl, tp, "RSI EA"
      );
    }
  }
  
  bool ClosePos(int all_buy_sell) const override {
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket <= 0) {
        Print("Failed to get position ticket");
        return false;
      }
      if (!PositionSelectByTicket(posTicket)) {
        Print("Failed to select position");
        return false;
      }
      long magic;
      if (!PositionGetInteger(POSITION_MAGIC, magic)) {
        Print("Failed to get position magic number");
        return false;
      }
      if (magic == _magicNumber) {
        long type;
        if (!PositionGetInteger(POSITION_TYPE, type)) {
          Print("Failed to get position type");
          return false;
        }
        if (all_buy_sell == 1 && type == POSITION_TYPE_SELL) {
          Print("continue all_buy_sell == 1");
          continue;
        }
        if (all_buy_sell == 2 && type == POSITION_TYPE_BUY) {
          Print("continue all_buy_sell == 2");
          continue;
        }
        trade.PositionClose(posTicket);
        if (trade.ResultRetcode() != TRADE_RETCODE_DONE) {
          Print(
            "Failed to close position. ticket: ", (string)posTicket,
            " result: ", (string)trade.ResultRetcode(), 
            " : ", trade.CheckResultRetcodeDescription()
          );
        }
      }
    }
    return true;
  }
};
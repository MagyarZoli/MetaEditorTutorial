#include <Trade/Trade.mqh>

static input long inpMagincNumber = 54321; // magic number
static input double inpLotSize = 1; // lot size
static input int inpRSIPeriod = 14; // rsi period
static input int inpRSILevel = 70; // rsi level (upper)
static input int inpSl = 0; // stop loss in points (0 = off)
static input int inpTp = 0; // take profit in points (0 = off)
static input bool inpCloseSignal = true; // close trades by opposite signal
static input int inpMaxConsecutive = 3; // maximum number of consecutive

int handle;
double buffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  trade.SetExpertMagicNumber(inpMagincNumber);
  handle = iRSI(_Symbol, PERIOD_CURRENT, inpRSIPeriod, PRICE_CLOSE);
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
  if (!CheckTick()) {
    return;
  }
  int cntBuy, cntSell;
  if (!CountOpenPositions(cntBuy, cntSell)) {
    Print("Failed to count open positions");
    return;
  }
  
  if (
    cntBuy < inpMaxConsecutive &&
    buffer[1] >= (100 - inpRSILevel) &&
    buffer[0] < (100 - inpRSILevel) &&
    openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0)
  ) {
    openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (inpCloseSignal) {
      if (!ClosePositions(2)) {
        Print("Failed to close sell position before opening a buy position");
        return;
      }
    }
    double sl = inpSl == 0 ? 0 : currentTick.bid - inpSl * _Point;
    double tp = inpTp == 0 ? 0 : currentTick.bid + inpTp * _Point;
    if (!NormalizePrice(sl)) {
      Print("Falided to normalize price stop loss");
      return;
    }
    if (!NormalizePrice(tp)) {
      Print("Falided to normalize price take profit");
      return;
    }
    trade.PositionOpen(
      _Symbol, ORDER_TYPE_BUY, inpLotSize,
      currentTick.ask, sl, tp, "RSI EA"
    );
  }
  
  if (
    cntSell < inpMaxConsecutive &&
    buffer[1] <= inpRSILevel && 
    buffer[0] > inpRSILevel &&
    openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0)
  ) {
    openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (inpCloseSignal) {
      if (!ClosePositions(1)) {
        Print("Failed to close buy position before opening a sell position");
        return;
      }
    }
    double sl = inpSl == 0 ? 0 : currentTick.ask + inpSl * _Point;
    double tp = inpTp == 0 ? 0 : currentTick.ask - inpTp * _Point;
    if (!NormalizePrice(sl)) {
      Print("Falided to normalize price stop loss");
      return;
    }
    if (!NormalizePrice(tp)) {
      Print("Falided to normalize price take profit");
      return;
    }
    trade.PositionOpen(
      _Symbol, ORDER_TYPE_SELL, inpLotSize,
      currentTick.bid, sl, tp, "RSI EA"
    );
  }
}

bool CheckTick() {
  if (!SymbolInfoTick(_Symbol, currentTick)) {
    Print("Failed to get current tick");
    return false;
  }
  int values = CopyBuffer(handle, 0, 0, 2, buffer);
  if (values != 2) {
    Print("Faild to get indicator values");
    return false;
  }
  return true;
}

bool CheckInputs() {
  bool correct = true;
  if (inpMagincNumber <= 0) {
    Alert("MagicNumber <= 0");
    correct = false;
  }
  if (inpLotSize <= 0 || inpLotSize > 10) {
    Alert("Lot size <= 0 or > 10");
    correct = false;
  }
  if (inpRSIPeriod <= 1) {
    Alert("RSI period <= 1");
    correct = false;
  }
  if (inpRSILevel >= 100 || inpRSILevel <= 50) {
    Alert("RSI level >= 100 or <= 50");
    correct = false;
  }
  if (inpSl < 0) {
    Alert("Stop loss < 0");
    correct = false;
  }
  if (inpTp < 0) {
    Alert("Take profit < 0");
    correct = false;
  }
  return correct;
}

bool CountOpenPositions(int &cntBuy, int &cntSell) {
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
    if (magic == inpMagincNumber) {
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

bool NormalizePrice(double &price) {
  double tickSize = 0;
  if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
    Print("Failed to get tick size");
    return false;
  }
  price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
  return true;
}

bool ClosePositions(int all_buy_sell) {
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
    if (magic == inpMagincNumber) {
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
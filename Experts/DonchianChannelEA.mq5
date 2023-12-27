#include <Trade/Trade.mqh>

#define INDICATOR_NAME "DonchianChannel"

enum SL_TP_MODE_ENUM {
  SL_TP_MODE_PCT,
  SL_TP_MODE_POINTS
};

input group "==== General ====";
static input long inpMagincNumber = 54321; //magic number
static input double inpLotSize = 1; //lot size
input SL_TP_MODE_ENUM inpSLTPMode = SL_TP_MODE_PCT; //sl/tp mode
input int inpSl = 0; //stop loss %/points (0 = off)
input int inpTp = 0; //take profit %/points (0 = off)
input bool inpCloseSignal = true; //close trades by opposite signal
input int inpSizeFilter = 0; //size filter in points (0=off)
input group "==== Donchian Channel ====";
input int inpPeriod = 20; //period
input int inpOffset = 0; //offset in % of channel (0 -> 49%)
input color inpColor = clrBlue; //color

int handle;
double bufferUpper[];
double bufferLower[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  trade.SetExpertMagicNumber(inpMagincNumber);
  handle = iCustom(
    _Symbol, PERIOD_CURRENT, INDICATOR_NAME,
    inpPeriod, inpOffset, inpColor
  );
  if (handle == INVALID_HANDLE) {
    Alert("Failed to create indicator handle");
    return INIT_FAILED;
  }
  ArraySetAsSeries(bufferUpper, true);
  ArraySetAsSeries(bufferLower, true);
  ChartIndicatorDelete(NULL, 0, "Donhian(" + IntegerToString(inpPeriod) + ")");
  ChartIndicatorAdd(NULL, 0, handle);
  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
  if (handle != INVALID_HANDLE) {
    ChartIndicatorDelete(NULL, 0, "Donhian(" + IntegerToString(inpPeriod) + ")");
    IndicatorRelease(handle);
  }
}

void OnTick() {
  if (!IsNewBar()) {
    return;
  }
  
  if (!SymbolInfoTick(_Symbol, currentTick)) {
    Print("Failed to get current tick");
    return;
  }
  
  int values = (
    CopyBuffer(handle, 0, 0, 1, bufferUpper) + 
    CopyBuffer(handle, 1, 0, 1, bufferLower)
  );
  if (values != 2) {
    Print("Faild to get indicator values");
    return;
  }
  
  int cntBuy, cntSell;
  if (!CountOpenPositions(cntBuy, cntSell)) {
    Print("Failed to count open positions");
    return;
  }
  
  if (inpSizeFilter > 0 && bufferUpper[0] - bufferLower[0] < inpSizeFilter * _Point) {
    return;
  }
  
  if (
    cntBuy == 0 &&
    currentTick.ask <= bufferLower[0] &&
    openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0)
  ) {
    openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (inpCloseSignal) {
      if (!ClosePositions(2)) {
        Print("Failed to close sell position before opening a buy position");
        return;
      }
    }
    double sl = 0;
    double tp = 0;
    double range = bufferUpper[0] - bufferLower[0];
    if (inpSLTPMode == SL_TP_MODE_PCT) {
      sl = inpSl == 0 ? 0 : currentTick.bid - range * inpSl * 0.01;
      tp = inpTp == 0 ? 0 : currentTick.bid + range * inpTp * 0.01;
    } else {
      sl = inpSl == 0 ? 0 : currentTick.bid - inpSl * _Point;
      tp = inpTp == 0 ? 0 : currentTick.bid + inpTp * _Point;
    }
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
      currentTick.ask, sl, tp, "Donchian channel EA"
    );
  }
  
  if (
    cntSell == 0 &&
    currentTick.bid >= bufferUpper[0] &&
    openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0)
  ) {
    openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (inpCloseSignal) {
      if (!ClosePositions(1)) {
        Print("Failed to close buy position before opening a sell position");
        return;
      }
    }
    double sl = 0;
    double tp = 0;
    double range = bufferUpper[0] - bufferLower[0];
    if (inpSLTPMode == SL_TP_MODE_PCT) {
      sl = inpSl == 0 ? 0 : currentTick.ask + range * inpSl * 0.01;
      tp = inpTp == 0 ? 0 : currentTick.ask - range * inpTp * 0.01;
    } else {
      sl = inpSl == 0 ? 0 : currentTick.ask + inpSl * _Point;
      tp = inpTp == 0 ? 0 : currentTick.ask - inpTp * _Point;
    }
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
      currentTick.bid, sl, tp, "Donchian channel EA"
    );
  }
}

bool CheckInputs() {
  bool correct = true;
  if (inpMagincNumber <= 0) {
    Alert("Magicnumber <= 0");
    correct = false;
  }
  if (inpLotSize <= 0 || inpLotSize > 10) {
    Alert("Lot size <= 0 or > 10");
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
  if (inpTp == 0 && !inpCloseSignal) {
    Alert("No stop loss and no close signal");
    correct = false;
  }
  if (inpSizeFilter < 0) {
    Alert("Size filter < 0");
    correct = false;
  }
  if (inpPeriod <= 1) {
    Alert("Donchian channel period <= 1");
    correct = false;
  }
  if (inpOffset < 0 || inpOffset >= 50) {
    Alert("Donchian channel offset < 0 or >= 50");
    correct = false;
  }
  return correct;
}

bool IsNewBar() {
  static datetime previousTime = 0;
  datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
  if (previousTime != currentTime) {
    previousTime = currentTime;
    return true;
  }
  return false;
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
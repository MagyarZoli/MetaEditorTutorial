#include <Trade/Trade.mqh>

input group "==== General ====";
static input long inpMagicNumber = 778610; //magic number
static input double inpLotSize = 1; //lot size
input group "==== Trading ====";
input int inpSl = 200; //stop loss in points (0 = off)
input int inpTp = 0; //take profit in points (0 = off)
input bool inpCloseSignal = true; //close trades by opposite signal
input group "==== Stochastic ====";
input int inpKPeriod = 21; //K period
input int inpUpperLevel = 80; //upper level

int handle;
double bufferMain[];
MqlTick ct;
CTrade trade;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  
  trade.SetExpertMagicNumber(inpMagicNumber);
  
  handle = iStochastic(_Symbol, PERIOD_CURRENT, inpKPeriod, 1, 3, MODE_SMA, STO_LOWHIGH);
  if (handle == INVALID_HANDLE) {
    Alert("Failed to create indicator handle");
    return INIT_FAILED;
  }
  
  ArraySetAsSeries(bufferMain, true);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  if (handle != INVALID_HANDLE) {
    IndicatorRelease(handle);
  }
}

void OnTick() {
  if (!IsNewBar()) {
    return;
  }
  
  if (!SymbolInfoTick(_Symbol, cT)) {
    Print("Failed to get currnet symbol tick");
    return;
  }
  
  if (CopyBuffer(handle, 0, 1, 2, bufferMain) != 2) {
    Print("Failed to get indeicator values");
    return;
  }
  
  int cntBuy, cntSell;
  if (!CountOpenPositions(cntBuy, cntSell)) {
    Print("Failed to count open positions");
    return;
  }
  
  if (
    cntBuy == 0 && bufferMain[0] <= (100 - inpUpperLevel) &&
    bufferMain[1] > (100 - inpUpperLevel)
  ) {
    if (inpCloseSignal && !ClosePositions(2)) {
      return;
    }
    double sl = inpSl == 0 ? 0 : cT.bid - inpSl * _Point;
    double tp = inpTp == 0 ? 0 : cT.bid + inpTp * _Point;
    if (!NormalizePrice(sl)) {
      return;
    }
    if (!NormalizePrice(tp)) {
      return;
    }
    trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, inpLotSize, cT.ask, sl, tp, "Stochastic EA");
  }
  
  if (
    cntBuy == 0 && bufferMain[0] >= inpUpperLevel &&
    bufferMain[1] < inpUpperLevel
  ) {
    if (inpCloseSignal && !ClosePositions(1)) {
      return;
    }
    double sl = inpSl == 0 ? 0 : cT.ask + inpSl * _Point;
    double tp = inpTp == 0 ? 0 : cT.ask - inpTp * _Point;
    if (!NormalizePrice(sl)) {
      return;
    }
    if (!NormalizePrice(tp)) {
      return;
    }
    trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, inpLotSize, cT.bid, sl, tp, "Stochastic EA");
  }
   
}

bool CheckInputs() {
  if(inpMagicNumber <= 0) {
    Alert("Wrong input: MagicNumber <= 0");
    return false;
  }
  if (inpLotSize <= 0 || inpLotSize > 10) {
    Alert("Wrong input: Lot size <= 0 or > 10");
    return false;
  }
  if (inpSl< 0) {
    Alert("Wrong input: Stop loss < 0");
    return false;
  }
  if (inpTp < 0) {
    Alert("Wrong input: Take profit < 0");
    return false;
  }
  if (!inpCloseSignal &&inpSl == 0) {
    Alert("Wrong input: Close signal if false and no stop loss");
    return false;
  }
  if (inpKPeriod <= 0) {
    Alert("Wrong input: K period <= 0");
    return false;
  }
  if (inpUpperLevel <= 50 ||inpUpperLevel >= 100) {
    Alert("Wrong input: Upper level <= 50 or >= 100");
    return false;
  }
  
  return true;
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
    if (magic == inpMagicNumber) {
      long type;
      if (!PositionGetInteger(POSITION_TYPE, type)) {
        Print("Failed to get position type");
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
    if (magic == inpMagicNumber) {
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
#include <Trade/Trade.mqh>

static input long inpMagicNumber = 58473; //magicnumber
static input double inpLots = 1; //lot size
input int inpBars = 20; //bars fir high/low
input int inpSt = 200; //stop loss in points (0 = off)
input int inpTp = 0; //take profit in points (0 = off)

double high = 0;
double low = 0;
MqlTick currentTick, previousTick;
CTrade trade;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  
  trade.SetExpertMagicNumber(inpMagicNumber);
  
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
  if (!IsNewBar()) {
    return;
  }

  previousTick = currentTick;
  if (!SymbolInfoTick(_Symbol, currentTick)) {
    Print("Failed to get current tick");
    return;
  }
  
  int cntBuy, cntSell;
  if (!CountOpenPositions(cntBuy, cntSell)) {
    return;
  }
  
  if (
    cntBuy == 0 && high != 0 && 
    previousTick.ask < high && currentTick.ask >= high
  ) {
    double sl = inpSt == 0 ? 0 : currentTick.bid - inpSt * _Point;
    double tp = inpTp == 0 ? 0 : currentTick.bid + inpTp * _Point;
    if (!NormalizePrice(sl)) { 
      return;
    }
    if (!NormalizePrice(tp)) { 
      return;
    }
    trade.PositionOpen(
      _Symbol, ORDER_TYPE_BUY, inpLots, currentTick.ask, 
      sl, tp, "HighLowBreakout EA"
    );
  }
  if (
    cntSell == 0 && low != 0 && 
    previousTick.bid > low && currentTick.bid >= low
  ) {
    double sl = inpSt == 0 ? 0 : currentTick.ask + inpSt * _Point;
    double tp = inpTp == 0 ? 0 : currentTick.ask - inpTp * _Point;
    if (!NormalizePrice(sl)) { 
      return;
    }
    if (!NormalizePrice(tp)) { 
      return;
    }
    trade.PositionOpen(
      _Symbol, ORDER_TYPE_SELL, inpLots, currentTick.bid,
      sl, tp, "HighLowBreakout EA"
    );
  }
  
  high = iHigh(
    _Symbol, PERIOD_CURRENT, 
    iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, inpBars, 1)
  );
  low = iLow(
    _Symbol, PERIOD_CURRENT, 
    iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, inpBars, 1)
  );
  
  DrawObjects();
}

bool CheckInputs() {
  if (inpMagicNumber <= 0) {
    Alert("Wrong inputs: MagicNumber <= 0");
    return false;
  }
  if (inpLots <= 0) {
    Alert("Wrong inputs: Lot size <= 0");
    return false;
  }
  if (inpBars <= 0) {
    Alert("Wrong inputs: Bars <= 0");
    return false;
  }
  if (inpSt < 0) {
    Alert("Wrong inputs: Stop loss < 0");
    return false;
  }
  if (inpTp < 0) {
    Alert("Wrong inputs: Take profit < 0");
    return false;
  }
  return true;
}

void DrawObjects() {
  datetime time = iTime(_Symbol, PERIOD_CURRENT, inpBars);
  
  string highName = "high";
  ObjectDelete(NULL, highName);
  ObjectCreate(NULL, highName, OBJ_TREND, 0, time, high, TimeCurrent(), high);
  ObjectSetInteger(NULL, highName, OBJPROP_WIDTH, 2);
  ObjectSetInteger(NULL, highName, OBJPROP_COLOR, clrYellow);
  
  string lowName = "low";
  ObjectDelete(NULL, lowName);
  ObjectCreate(NULL, lowName, OBJ_TREND, 0, time, low, TimeCurrent(), low);
  ObjectSetInteger(NULL, lowName, OBJPROP_WIDTH, 2);
  ObjectSetInteger(NULL, lowName, OBJPROP_COLOR, clrYellow);
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
    if (magic == inpMagicNumber) {
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
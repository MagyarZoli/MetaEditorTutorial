#include <Trade/Trade.mqh>

static input long inpMagicNumber = 58473; //magicnumber
static input double inpLots = 1; //lot size
input int inpBars = 20; //bars fir high/low
input int inpIndexFilter = 0; //index filter in % (0 = off)
input int inpSizeFilter = 0; //channel size filter in points (0 = off)
input int inpSl = 200; //stop loss in points (0 = off)
input int inpTp = 0; //take profit in points (0 = off)
input bool inpTrailingSl = true; //trailing stop loss?

double high = 0;
double low = 0;
int highIdx = 0;
int lowIdx = 0;
MqlTick currentTick, previousTick;
CTrade trade;

int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  
  trade.SetExpertMagicNumber(inpMagicNumber);
  
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  ObjectDelete(NULL, "high");
  ObjectDelete(NULL, "low");
  ObjectDelete(NULL, "text");
  ObjectDelete(NULL, "indexFilter");
}

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
    previousTick.ask < high && currentTick.ask >= high &&
    CheckIndexFilter(highIdx) && CheckSizeFilter()
  ) {
    double sl = inpSl == 0 ? 0 : currentTick.bid - inpSl * _Point;
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
    previousTick.bid > low && currentTick.bid <= low &&
    CheckIndexFilter(lowIdx) && CheckSizeFilter()
  ) {
    double sl = inpSl == 0 ? 0 : currentTick.ask + inpSl * _Point;
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
  
  if (inpSl > 0 &&inpTrailingSl) {
    UpdateStopLoss(inpSl * _Point);
  }
  
  highIdx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, inpBars, 1);
  high = iHigh(_Symbol, PERIOD_CURRENT, highIdx);
  lowIdx = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, inpBars, 1);
  low = iLow(_Symbol, PERIOD_CURRENT, lowIdx);
  
  DrawObjects();
}

bool CheckInputs() {
  if (inpMagicNumber <= 0) {
    Alert("Wrong input: MagicNumber <= 0");
    return false;
  }
  if (inpLots <= 0) {
    Alert("Wrong input: Lot size <= 0");
    return false;
  }
  if (inpBars <= 0) {
    Alert("Wrong input: Bars <= 0");
    return false;
  }
  if (inpIndexFilter < 0 || inpIndexFilter >= 50) {
    Alert("Wrong input: index filter < 0 or >= 50");
    return false;
  }
  if (inpSizeFilter < 0) {
    Alert("Wrong input: Size filter < 0");
    return false;
  }
  if (inpSl <= 0) {
    Alert("Wrong input: Stop loss <= 0");
    return false;
  }
  if (inpTp < 0) {
    Alert("Wrong input: Take profit < 0");
    return false;
  }
  return true;
}

bool CheckIndexFilter(int index) {
  if (
    inpIndexFilter > 0 && 
    (index <= round(inpBars * inpIndexFilter * 0.01) || 
    index > inpBars - round(inpBars * inpIndexFilter * 0.01))
  ) {
    return false;
  }
  return true;
}

bool CheckSizeFilter() {
  if (
    inpSizeFilter > 0 && 
    high - low > inpSizeFilter * _Point
  ) {
    return false;
  }
  return true;
}

void DrawObjects() {
  datetime time = iTime(_Symbol, PERIOD_CURRENT, inpBars);
  datetime secoundTime = iTime(_Symbol, PERIOD_CURRENT, 1);
  
  string highName = "high";
  ObjectDelete(NULL, highName);
  ObjectCreate(NULL, highName, OBJ_TREND, 0, time, high, secoundTime, high);
  ObjectSetInteger(NULL, highName, OBJPROP_WIDTH, 3);
  ObjectSetInteger(
    NULL, highName, OBJPROP_COLOR,
    CheckIndexFilter(highIdx) && CheckSizeFilter() ? clrLime : clrGray
  );
  
  string lowName = "low";
  ObjectDelete(NULL, lowName);
  ObjectCreate(NULL, lowName, OBJ_TREND, 0, time, low, secoundTime, low);
  ObjectSetInteger(NULL, lowName, OBJPROP_WIDTH, 3);
  ObjectSetInteger(
    NULL, lowName, OBJPROP_COLOR, 
    CheckIndexFilter(lowIdx) && CheckSizeFilter() ? clrLime : clrGray
  );
  
  if (inpIndexFilter > 0) {
    datetime timeFilter = iTime(
      _Symbol, PERIOD_CURRENT, 
      (int) (inpBars - round(inpBars * inpIndexFilter * 0.01))
    );
    datetime secoundTimeFilter = iTime(
      _Symbol, PERIOD_CURRENT, 
      (int) round(inpBars * inpIndexFilter * 0.01)
    );
    string idxName = "indexFilter";
    ObjectCreate(NULL, idxName, OBJ_TREND, 0, timeFilter, low, secoundTimeFilter, low);
    ObjectSetInteger(NULL, idxName, OBJPROP_BACK, true);
    ObjectSetInteger(NULL, idxName, OBJPROP_FILL, true);
    ObjectSetInteger(NULL, idxName, OBJPROP_COLOR, clrMintCream);
  }
  
  string textName = "text";
  string text = (
    "Bars: " + (string) inpBars + 
    " index filter: " + DoubleToString(round(inpBars * inpIndexFilter * 0.01), 0) + 
    " high index: " + (string) highIdx + 
    " low index: " + (string) lowIdx +
    " size: " + DoubleToString((high - low) / _Point, 0)
  );
  ObjectDelete(NULL, textName);
  ObjectCreate(NULL, textName, OBJ_TEXT, 0, secoundTime, low);
  ObjectSetInteger(NULL, textName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
  ObjectSetInteger(NULL, textName, OBJPROP_COLOR, clrGray);
  ObjectSetString(NULL, textName, OBJPROP_TEXT, text);
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

void UpdateStopLoss(double slDistance) {
  if (inpSl == 0 || !inpTrailingSl) {
    return;
  }
  
  int posTotal = PositionsTotal();
  for (int i = posTotal - 1; i >= 0; i--) {
    ulong posTicket = PositionGetTicket(i);
    if (posTotal <= 0) {
      Print("Failde to get position ticket");
      return;
    }
    if (!PositionSelectByTicket(posTicket)) {
      Print("Failed to select position by ticket");
      return;
    }
    ulong magicNumber;
    if (!PositionGetInteger(POSITION_MAGIC, magicNumber)) {
      Print("Failed to get position magicnumber");
      return;
    }
    if (inpMagicNumber == magicNumber) {
      long posType = -1;
      if (!PositionGetInteger(POSITION_MAGIC, magicNumber)) {
        Print("Failed to get position type");
        return;
      }
      double currSl, currTp;
      if (!PositionGetDouble(POSITION_SL, currSl)) {
        Print("Failed to get position stop loss");
        return;
      }
      if (!PositionGetDouble(POSITION_TP, currTp)) {
        Print("Failed to get position take profit");
        return;
      }
      
      double currPrice = posType == POSITION_TYPE_BUY ? currentTick.bid : currentTick.ask;
      int n = posType == POSITION_TYPE_BUY ? 1 : -1;
      double newSl = currPrice - slDistance * n;
      if (!NormalizePrice(newSl)) {
        return;
      }
      
      if (
        (newSl * n < currSl * n) || 
        NormalizeDouble(MathAbs(newSl - currSl), _Digits) < _Point
      ) {
        continue;
      }
      
      long level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      if (level != 0 && MathAbs(currPrice - newSl) <= level * _Point) {
        Print("New stop loss inside stop level");
        continue;
      } 
      
      if (!trade.PositionModify(posTicket, newSl, currTp)) {
        Print(
          "Failed to modigy position, ticket: ", (string) posTicket,
          " currSl: ", (string) currSl,
          " newSl: ", (string) currTp
        );
        return;
      }
    }
  }
}
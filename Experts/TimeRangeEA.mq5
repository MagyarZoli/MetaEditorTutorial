#include <Trade/Trade.mqh>

struct RANGE_STRUCT {
   datetime start_time;
   datetime end_time;
   datetime close_time;
   double high;
   double low;
   bool f_entry;
   bool f_high_breakout;
   bool f_low_breakout;
   
   RANGE_STRUCT() : 
      start_time(0), 
      end_time(0), 
      close_time(0),
      high(0), 
      low(DBL_MAX), 
      f_entry(false), 
      f_high_breakout(false), 
      f_low_breakout(false) {};
};

enum BREAKOUT_MODE_ENUM {
   ONE_SIGNAL,
   TWO_SIGNALS
};

input group "==== General Inputs ====";
input long inpMagicNumber = 12345;
input double inpLots = 0.01;
input int inpSl = 150;
input int inpTp = 200;

input group "==== Range Inputs ====";
input int inpRangeStart = 600;
input int inpRangeDuration = 60 * 2;
input int inpRangeClose = 1200;

input group "==== Day of week filter ====";
input BREAKOUT_MODE_ENUM inpBreakoutMode = ONE_SIGNAL;
input bool inpMonday = true;
input bool inpTuesday = true;
input bool inpWednesday = true;
input bool inpThursday = true;
input bool inpFriday = true;

MqlTick prevTick, lastTick;
CTrade trade;
RANGE_STRUCT range;

int OnInit() {
   if (AlertHandle() == INIT_SUCCEEDED) {
      trade.SetExpertMagicNumber(inpMagicNumber);
      if (_UninitReason == REASON_PARAMETERS && CountOpenPositions() == 0) {
         CalculateRange();
      }
      DrawObjects();
   }
   return AlertHandle();
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(NULL, "range");
}

void OnTick() {
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);
   
   if (lastTick.time > range.start_time && lastTick.time < range.end_time) {
      range.f_entry = true;
      if (lastTick.ask > range.high) {
         range.high = lastTick.ask;
         DrawObjects();
      }
      if (lastTick.bid < range.low) {
         range.low = lastTick.bid;
         DrawObjects();
      }
   }
   
   if (inpRangeClose >= 0 && lastTick.time >= range.close_time) {
      if (!ClosePosition()) return;
   }
   
   if (
      ((inpRangeClose >= 0 && lastTick.time >= range.close_time) ||
      (range.f_high_breakout && range.f_low_breakout) ||
      (range.end_time == 0) ||
      (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry)) &&
      (CountOpenPositions() == 0)
   ) CalculateRange();
   
   CheckBreakouts();
}

int AlertHandle() {
   bool parametersIncorrect = false;
   if (inpMagicNumber <= 0) {
      parametersIncorrect = true;
      Alert("Magic number <= 0");
   }
   if (inpLots <= 0 || inpLots > 1) {
      parametersIncorrect = true;
      if (inpLots <= 0) Alert("Lots <= 0");
      else Alert("Lost > 1");
   }
   if (inpSl < 0 || inpSl > 1000) {
      parametersIncorrect = true;
      if (inpLots < 0) Alert("Stop loss < 0");
      else Alert("Stop loss > 1000");
   }
   if (inpTp < 0 || inpTp > 1000) {
      parametersIncorrect = true;
      if (inpTp < 0) Alert("Take profit < 0");
      else Alert("Take profit > 1000");
   }
   if (inpRangeClose < 0 && inpSl == 0) {
      parametersIncorrect = true;
      Alert("Close time and stop loss is off");
   }
   if (inpRangeStart <= 0 || inpRangeStart > 1440) {
      parametersIncorrect = true;
      if (inpRangeStart <= 0) Alert("Range start <= 0");
      else Alert("Range start > 1440");
   }
   if (inpRangeDuration <= 0 || inpRangeDuration > 1440) {
      parametersIncorrect = true;
      if (inpRangeDuration <= 0) Alert("Range duration <= 0");
      else Alert("Range duration > 1440");
   }
   if (
      inpRangeClose > 1440 || 
      (inpRangeStart + inpRangeDuration) % 1440 == inpRangeClose
   ) {
      parametersIncorrect = true;
      if (inpRangeClose > 1440) Alert("Range close time > 1440");
      else Alert ("End time = Close time");
   }
   if (inpMonday + inpTuesday + inpWednesday + inpThursday + inpFriday == 0) {
      parametersIncorrect = true;
      Alert("Range is prohibited on all days of the week");
   }
   if (parametersIncorrect) return INIT_PARAMETERS_INCORRECT;
   return INIT_SUCCEEDED;
}

void CalculateRange() {
   range.start_time = 0;
   range.end_time = 0;
   range.close_time = 0;
   range.high = 0.0;
   range.low = DBL_MAX;
   range.f_entry = false;
   range.f_high_breakout = false;
   range.f_low_breakout = false;
   int time_cycle = 60 * 60 * 24;
   
   CalculateRangeStart(time_cycle);
   CalculatRangeEnd(time_cycle);
   if (inpRangeClose >= 0) CalculatRangeClose(time_cycle);
   DrawObjects();
}

void CalculateRangeStart(int time_cycle) {
   range.start_time = (
      (lastTick.time - (lastTick.time % time_cycle)) +
      inpRangeStart * 60
   );
   for (int i = 0; i < 8; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if (
         lastTick.time >= range.start_time || 
         dow == 6 || dow == 0 ||
         (dow == 1 && !inpMonday) || 
         (dow == 2 && !inpTuesday) || 
         (dow == 3 && !inpWednesday) || 
         (dow == 4 && !inpThursday) || 
         (dow == 5 && !inpFriday) 
      ) {
         range.start_time += time_cycle;
      }
   }
}

void CalculatRangeEnd(int time_cycle) {
   range.end_time = range.start_time + inpRangeDuration * 60;
   for (int i = 0; i < 2; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if (dow == 6 || dow == 0) {
         range.end_time += time_cycle;
      }
   }
}

void CalculatRangeClose(int time_cycle) {
   range.close_time = (
      (range.end_time - (range.end_time % time_cycle)) +
      inpRangeClose * 60
   );
   for (int i = 0; i < 3; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if (
         range.close_time <= range.end_time ||
         dow == 6 || dow == 0
      ) {
         range.close_time += time_cycle;
      }
   }
}

void DrawObjects() {
   DrawVerticalLine("range start", range.start_time, clrBlue);
   DrawVerticalLine("range end", range.end_time, clrBlue);
   DrawVerticalLine("range close", range.close_time, clrRed);
   DrawHorizontalLine(
      "range high", range.high, clrBlue,
      0, range.start_time, range.end_time
   );
   DrawHorizontalLine(
      "range low", range.low, clrBlue,
      999999, range.start_time, range.end_time
   );
   DrawHorizontalLine(
      "range high_", range.high, clrDarkBlue,
      0, range.end_time, range.close_time
   );
   DrawHorizontalLine(
      "range low_", range.low, clrDarkBlue,
      999999, range.end_time, range.close_time
   );
   ChartRedraw();
}

void DrawVerticalLine(string objectName, datetime time, color lineColor) {
   ObjectDelete(NULL, objectName);
   if (time > 0) {
      string propValue = (
         objectName + "\n" + 
         TimeToString(time, TIME_DATE|TIME_MINUTES)
      );
      ObjectCreate(NULL, objectName, OBJ_VLINE, 0, time, 0);
      ObjectSetString(NULL, objectName, OBJPROP_TOOLTIP, propValue);
      ObjectSetInteger(NULL, objectName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(NULL, objectName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, objectName, OBJPROP_BACK, true);
   }
}

void DrawHorizontalLine(
   string objectName, double position, color lineColor, 
   int check, datetime fromTime, datetime toTime
) {
   ObjectDelete(NULL, objectName);
   if (position > check) {
      string propValue = (
         objectName + "\n" + 
         DoubleToString(position, _Digits)
      );
      ObjectCreate(
         NULL, objectName, OBJ_VLINE, 0, 
         fromTime, position, inpRangeClose >= 0 ? toTime : INT_MAX, position
      );
      ObjectSetString(NULL, objectName, OBJPROP_TOOLTIP, propValue);
      ObjectSetInteger(NULL, objectName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(NULL, objectName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, objectName, OBJPROP_BACK, true);
   }
}

void CheckBreakouts() {
   if (lastTick.time >= range.end_time && range.end_time > 0 && range.f_entry) {
      if (!range.f_high_breakout && lastTick.ask >= range.high) CheckBreakoutHigh();
      if (!range.f_low_breakout && lastTick.bid <= range.low) CheckBreakoutLow();
   }
}

void CheckBreakoutHigh() {
   range.f_high_breakout = true;
   if (inpBreakoutMode == ONE_SIGNAL) range.f_low_breakout = true;
   double sl = inpSl == 0 ? 0 : NormalizeDouble(
      lastTick.bid - ((range.high - range.low) * inpSl * 0.01),
      _Digits
   );
   double tp = inpTp == 0 ? 0 : NormalizeDouble(
      lastTick.bid + ((range.high - range.low) * inpTp * 0.01),
      _Digits
   );
   trade.PositionOpen(
      _Symbol, ORDER_TYPE_BUY, inpLots, lastTick.ask,
      sl, tp, "Time range EA"
   );
}

void CheckBreakoutLow() {
   range.f_low_breakout = true;
   if (inpBreakoutMode == ONE_SIGNAL) range.f_high_breakout = true;
   double sl = inpSl == 0 ? 0 : NormalizeDouble(
      lastTick.ask + ((range.high - range.low) * inpSl * 0.01),
      _Digits
   );
   double tp = inpTp == 0 ? 0 : NormalizeDouble(
      lastTick.ask - ((range.high - range.low) * inpTp * 0.01),
      _Digits
   );
   trade.PositionOpen(
      _Symbol, ORDER_TYPE_SELL, inpLots, lastTick.bid,
      sl, tp, "Time range EA"
   );
}

bool ClosePosition() {
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; i--) {
      if (total != PositionsTotal()) {
         total = PositionsTotal(); 
         i = total;
         continue;
      }
      ulong posTicket = PositionGetTicket(i);
      if (posTicket <= 0) {
         Print("Failed to get position ticket");
         return false;
      }
      if (!PositionSelectByTicket(posTicket)) {
         Print("Failed to select position by ticket");
         return false;
      }
      ulong magicnumber;
      if (!PositionGetInteger(POSITION_MAGIC, magicnumber)) {
         Print("Failed to get position magicnumber");
         return false;
      }
      if (magicnumber == inpMagicNumber) {
         trade.PositionClose(posTicket);
         if (trade.ResultRetcode() != TRADE_RETCODE_DONE) {
            Print(
               "Falide to close position. Result: " + 
               (string)trade.ResultRetcode() + ":" + trade.ResultRetcodeDescription()
            );
            return false;
         }
      }
   }
   return true;
}

int CountOpenPositions() {
   int counter = 0;
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket <= 0) {
         Print("Failed to get position ticket");
         return -1;
      }
      if (!PositionSelectByTicket(posTicket)) {
         Print("Failed to select position by ticket");
         return -1;
      }
      ulong magicnumber;
      if (!PositionGetInteger(POSITION_MAGIC, magicnumber)) {
         Print("Failed to get position magicnumber");
         return -1;
      }
      if (magicnumber == inpMagicNumber) counter++;
   }
   return counter;
}
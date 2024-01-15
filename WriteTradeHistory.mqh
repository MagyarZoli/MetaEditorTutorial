#include "TradeLog.mqh"

class WriteTradeHistory {
public:
  virtual void WriteToFile(string fileName, const TradeLog &tradeLogs[]) const = 0;
};
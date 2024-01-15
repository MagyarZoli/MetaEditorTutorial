#include "WriteTradeHistory.mqh"
#include "TradeLog.mqh"

class WriteJSON: public WriteTradeHistory {
public:
  virtual void WriteToFile(string fileName, const TradeLog &tradeLogs[]) const override {
    if (FileIsExist(fileName, 0)) {
      Alert("File is not exist.");
    }
    Print("File write");
    int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_CSV);
    if (fileHandle != INVALID_HANDLE) {
      FileWrite(fileHandle, "{ \"trades\": [");
      FileWrite(fileHandle, Data(fileHandle, tradeLogs));
      FileWrite(fileHandle, "]}");
    }
  }
  
private: 
  string Data(int fileHandle, const TradeLog &tradeLogs[]) const {
    string json = "";
    for (int i = 0; i < ArraySize(tradeLogs); i++) {
      TradeLog tradeLog = tradeLogs[i];
      json += StringFormat(
        "{" +
        "\"ticket\":%d," +
        "\"entryPrice\":%f," +
        "\"exitPrice\":%f," +
        "\"profit\":%f" +
        "}",
        tradeLog.GetTicket(),
        tradeLog.GetEntryPrice(),
        tradeLog.GetExitPrice(),
        tradeLog.GetProfit()
      );
      if (i < ArraySize(tradeLogs) - 1) {
        json += ",";
      }
    }
    return json;
  }
};
class TradeLog {
private:
  ulong cTicket;
  double cEntryPrice;
  double cExitPrice;
  double cProfit;
 
public:
  TradeLog() {
    cTicket = 0;
    cEntryPrice = 0.0;
    cExitPrice = 0.0;
    cProfit = 0.0;
  } 
  
  TradeLog(ulong ticket, double entryPrice, double exitPrice, double profit) {
    cTicket = ticket;
    cEntryPrice = entryPrice;
    cExitPrice = exitPrice;
    cProfit = profit;
  }
  
  TradeLog(const TradeLog &other) {
    cTicket = other.GetTicket();
    cEntryPrice = other.GetEntryPrice();
    cExitPrice = other.GetExitPrice();
    cProfit = other.GetProfit();
  }
  
  ulong GetTicket() const {
    return cTicket;
  }
  
  double GetEntryPrice() const {
    return cEntryPrice;
  }
  
  double GetExitPrice() const {
    return cExitPrice;
  }
  
  double GetProfit() const {
    return cProfit;
  }
};
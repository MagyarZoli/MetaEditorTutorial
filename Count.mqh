class Count {
private:
  int cSellCount;
  int cBuyCount;
  
public:
  Count() {
    cSellCount = 0;
    cBuyCount = 0;
  }
  
  int GetSellCount() {
    return cSellCount;
  }
  
  int GetBuyCount() {
    return cBuyCount;
  }
  
  void IncrementSellCount() {
    cSellCount++;
  }
  
  void IncrementBuyCount() {
    cBuyCount++;
  }
  
  void ClearSellCount() {
    cSellCount = 0;
  }
  
  void ClearBuyCount() {
    cBuyCount = 0;
  }
};
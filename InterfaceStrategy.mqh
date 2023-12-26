interface InterfaceStrategy {
public:
  virtual int StrategyInit() const;
  
  virtual void StrategyDeinit() const;
  
  virtual void StrategyTick() const;
  
  virtual bool CheckInputs() const;
  
  virtual bool NormalizePrice(double &price) const;
  
  virtual bool CountOpenPos(int &cntBuy, int &cntSell) const;
  
  virtual void OpenPosBuy(int cntBuy) const;
  
  virtual void OpenPosSell(int cntSell) const;
  
  virtual bool ClosePos(int all_buy_sell) const;
};
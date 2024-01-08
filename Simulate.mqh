class Simulate {
private:
  double ctotalProfit;
  int cmax;
  int cmin;
  int cperiod;

public:
  double cbuffer[];
  double cbufferMA[];
  
  Simulate() {
    ctotalProfit = 0.0;
    cmax = 90;
    cmin = 10;
    cperiod = 5;
  }
  
  Simulate(double totalProfit, double &buffer[], double &bufferMA[], int max, int min, int period) {
    ctotalProfit = totalProfit;
    cmax = max;
    cmin = min;
    cperiod = period;
    CopyArray(buffer, cbuffer);
    CopyArray(bufferMA, cbufferMA);
  }
  
  Simulate(const Simulate &other) {
    ctotalProfit = other.GetTotalProfit();
    cmax = other.GetMax();
    cmin = other.GetMin();
    cperiod = other.GetPeriod();
    CopyArray(other.cbuffer, cbuffer);
    CopyArray(other.cbufferMA, cbufferMA);
  }
  
  double GetTotalProfit() const{
    return ctotalProfit;
  }
  
  void GetBuffer(double &buffer[]) {
    CopyArray(cbuffer, buffer);
  }
  
  void GetBufferMA(double &bufferMA[]) {
    CopyArray(cbufferMA, bufferMA);
  }
  
  int GetMax() const {
    return cmax;
  }
  
  int GetMin() const {
    return cmin;
  }
  
  int GetPeriod() const {
    return cperiod;
  }

private:
  void CopyArray(const double &sourceArray[], double &destinationArray[]) {
    ArrayResize(destinationArray, ArraySize(sourceArray));
    for (int i = 0; i < ArraySize(sourceArray); i++) {
        destinationArray[i] = sourceArray[i];
    }
  }
};

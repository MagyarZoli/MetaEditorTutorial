class Simulate {
private:
  double cTotalProfit;
  int cMax;
  int cMin;
  int cPeriod;

public:
  double gBuffer[];
  double gBufferMA[];
  
  Simulate() {
    cTotalProfit = 0.0;
    cMax = 90;
    cMin = 10;
    cPeriod = 5;
    ArrayResize(gBuffer, 3);
    ArrayResize(gBufferMA, 3);
  }
  
  Simulate(double totalProfit, double &buffer[], double &bufferMA[], int max, int min, int period) {
    cTotalProfit = totalProfit;
    cMax = max;
    cMin = min;
    cPeriod = period;
    CopyArray(buffer, gBuffer);
    CopyArray(bufferMA, gBufferMA);
  }
  
  Simulate(const Simulate &other) {
    cTotalProfit = other.GetTotalProfit();
    cMax = other.GetMax();
    cMin = other.GetMin();
    cPeriod = other.GetPeriod();
    CopyArray(other.gBuffer, gBuffer);
    CopyArray(other.gBufferMA, gBufferMA);
  }
  
  double GetTotalProfit() const {
    return cTotalProfit;
  }
  
  int GetMax() const {
    return cMax;
  }
  
  int GetMin() const {
    return cMin;
  }
  
  int GetPeriod() const {
    return cPeriod;
  }
  
  void GetBuffer(double &buffer[]) {
    CopyArray(gBuffer, buffer);
  }
  
  void GetBufferMA(double &bufferMA[]) {
    CopyArray(gBufferMA, bufferMA);
  }

  int Comparable(const Simulate &other) {
    if (cTotalProfit > other.GetTotalProfit()) {
      return 1;
    } else if (cTotalProfit < other.GetTotalProfit()) {
      return -1;
    } 
    if (cPeriod > other.GetPeriod()) {
      return 1;
    } else if (cPeriod < other.GetPeriod()) {
      return -1;
    }
    if (cMax > other.GetMax()) {
      return 1;
    } else if (cMax < other.GetMax()) {
      return -1;
    }
    if (cMin > other.GetMin()) {
      return 1;
    } else if (cMin < other.GetMin()) {
      return 1;
    } 
    return 0;
  }

private:
  void CopyArray(const double &sourceArray[], double &destinationArray[]) {
    ArrayResize(destinationArray, ArraySize(sourceArray));
    for (int i = 0; i < ArraySize(sourceArray); i++) {
        destinationArray[i] = sourceArray[i];
    }
  }
};
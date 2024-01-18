class CMap {
private:
  int cKey;
  double cValue;
    
public:
  CMap () {
    cKey = 0;
    cValue = 0.0;
  }
  
  CMap (int key, double value) {
    cKey = key;
    cValue = value;
  }
  
  CMap (const CMap &other) {
    cKey = other.GetKey();
    cValue = other.GetValue();
  }
  
  int GetKey() const {
    return cKey;
  }
  
  double GetValue() const {
    return cValue;
  }
  
  void SetKey(int key) {
    cKey = key;
  }
  
  void SetValue(double value) {
    cValue = value;
  }
};
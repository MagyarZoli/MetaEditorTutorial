#include <Trade/DealInfo.mqh>
#include <Generic/HashMap.mqh>

//Options/ExpertAdvisors/Allow WebRequest for list URL: add new BASE_URL
#define BASE_URL "https://dxtrade.ftmo.com/dxsca-web/" 
#define ACCOUNT_FTMO "acc123"
#define PASSWORD_FTMO "password"

string gToken;
datetime gTimeout;
CHashMap<ulong, ulong> gPositions;

int OnInit() {
  Login();
  return INIT_SUCCEEDED;
}

void OnTick() {
  if (TimeCurrent() > gTimeout - 300) {
    Ping();
  }
}

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
  if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
    CDealInfo deal;
    if (HistoryDealSelect(trans.deal)) {
      deal.Ticket(trans.deal);
      string orderCode = IntegerToString(deal.Ticket());
      string instrument = deal.Symbol();
      double quantity = deal.Volume();
      if (SymbolInfoInteger(deal.Symbol(), SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_FOREX) {
        quantity *= 100000;
      }
      string side = deal.DealType() == DEAL_TYPE_BUY ? "BUY" : "SELL";
      ulong orderId;
      if (deal.Entry() == DEAL_ENTRY_IN) {
        PositionOpen(trans, orderCode, instrument, quantity, side, orderId);
      } else if (deal.Entry() == DEAL_ENTRY_OUT) {
        PositionClose(trans, orderCode, instrument, quantity, side, orderId);
      }
    }
  }
}

void PositionOpen(const MqlTradeTransaction& trans, string orderCode, string instrument, double quantity, string side, ulong& orderId) {
  for (int i = 0; i < 10; i++) {
    int res = placeOrder(orderCode, instrument, quantity, "OPEN", "", side, orderId);
    if (res == 200) {
      gPositions.Add(trans.position, orderId);
      Print(__FUNCTION__, " > Successfully sent pos #", trans.position, " to dxtrade as order #", orderId, "...");
      break;
    }
    Sleep(500);
  }   
}

void PositionClose(const MqlTradeTransaction& trans, string orderCode, string instrument, double quantity, string side, ulong& orderId) {
  ulong value;
  if (!gPositions.TryGetValue(trans.position, value)) {
    Print(__FUNCTION__, " > Unable to find dxtrade position for mt5 position #", trans.position, "...");
    return;
  }
  for (int i = 0; i < 10; i++) {
    int res = placeOrder(orderCode, instrument, quantity, "CLOSE", IntegerToString(value), side, orderId);
    if (res == 200) {
      gPositions.Remove(trans.position);
      Print(__FUNCTION__, " >Successfully closed pos #", trans.position, " at dxtrade with order #", orderId, "...");
      break;
    }
    Sleep(500);
  }
}

int Login() {
  string url = BASE_URL + "login";
  char post[], result[];
  string headers = "Content-Type: application/json\r\n" + 
    "Accept: application/json\r\n";
  string resultHeader;
  string domain = "default";
  string json = "{" +
    "\"username\": \"" + ACCOUNT_FTMO + "\"," +
    "\"domain\": \"" + domain + "\"," +
    "\"password\": \"" + PASSWORD_FTMO + "\"" +
  "}";
  StringToCharArray(json, post, 0, StringLen(json));
  return CheckWebRequestGenerateToken(__FUNCTION__, url, headers, 5000, post, result, resultHeader);
}

int Ping() {
  string url = BASE_URL + "ping";
  char post[], result[];
  string headers = "Content-Type: application/json\r\n" + 
    "Accept: application/json\r\n" + 
    "Authorization: DXAPI" + gToken + "\r\n";
  string resultHeader;
  string domain = "default";
  return CheckWebRequest(__FUNCTION__, url, headers, 5000, post, result, resultHeader);
}

int placeOrder(string orderCode, string instrument, double quantity, string posistionEffect, string posistionCode, string side, ulong& orderId) {
  string url = BASE_URL + "accounts/default:" + ACCOUNT_FTMO + "/orders";
  char post[], result[];
  string headers = "Content-Type: application/json\r\n" + 
    "Accept: application/json\r\n" + 
    "Authorization: DXAPI" + gToken + "\r\n";
  string resultHeader;
  string json = "{" +
    "\"account\": \"default:" + ACCOUNT_FTMO + "\"," +
    "\"orderCode\": \"" + orderCode + "\"," + 
    "\"type\" : \"MARKET\"," +
    "\"instrument\": \"" + instrument + "\"," +
    "\"quantity\": \"" + (string) quantity + "\"," +
    "\"positionEffect\": \"" + posistionEffect + "\"," +
    "\"positionCode\": \"" + posistionCode + "\"," +
    "\"side\": \"" + side + "\"," +
    "\"tif\": \"GTC\"" +
  "}";
  StringToCharArray(json, post, 0, StringLen(json));
  return CheckWebRequest(__FUNCTION__, url, headers, 5000, post, result, resultHeader);
}

string GetJsonStringValue(string json, string key) {
  int indexStart = StringFind(json, key) + StringLen(key) + 3;
  int indexEnd = StringFind(json, "\"", indexStart);
  return StringSubstr(json, indexStart, indexEnd - indexStart);
}

ulong GetJsonULongValue(string json, string key) {
  int indexStart = StringFind(json, key) + StringLen(key) + 3;
  int indexEnd = StringFind(json, ",", indexStart);
  return StringToInteger(StringSubstr(json, indexStart, indexEnd - indexStart));
}

int CheckWebRequestGenerateToken(string functionName, string url, string headers, int timeout, char &post[], char &result[], string resultHeader) {
  ResetLastError();
  int res = WebRequest("POST", url, headers, 5000, post, result, resultHeader);
  if (res == -1) {
    Print(functionName, " > web request failed... code: ", GetLastError());
  } else if (res != 200) {
    Print(functionName, " > server request failed... code: ", res);
  } else {
    string msg = CharArrayToString(result);
    Print(functionName, " > server request success.. ", msg);
    
    gToken = GetJsonStringValue(msg, "sessionToken");
    gTimeout = TimeCurrent() + PeriodSeconds(PERIOD_M30);
    Print(functionName, " > token: ", gToken, ", timout: ", gTimeout);
  }
  return res;
}

int CheckWebRequest(string functionName, string url, string headers, int timeout, char &post[], char &result[], string resultHeader) {
  ResetLastError();
  int res = WebRequest("POST", url, headers, 5000, post, result, resultHeader);
  if (res == -1) {
    Print(functionName, " > web request failed... code: ", GetLastError());
  } else if (res != 200) {
    Print(functionName, " > server request failed... code: ", res);
  } else {
    string msg = CharArrayToString(result);
    Print(functionName, " > server request success.. ", msg);
    
    gTimeout = TimeCurrent() + PeriodSeconds(PERIOD_M30);
    Print(functionName, " > token: ", gToken, ", timout: ", gTimeout);
  }
  return res;
}

int CheckWebRequestOrder(string functionName, string url, string headers, int timeout, char &post[], char &result[], string resultHeader, ulong& orderId) {
  ResetLastError();
  int res = WebRequest("POST", url, headers, 5000, post, result, resultHeader);
  if (res == -1) {
    Print(functionName, " > web request failed... code: ", GetLastError());
  } else if (res != 200) {
    Print(functionName, " > server request failed... code: ", res);
  } else {
    string msg = CharArrayToString(result);
    Print(functionName, " > server request success.. ", msg);
    
    orderId = GetJsonULongValue(msg, "orderId");
    gTimeout = TimeCurrent() + PeriodSeconds(PERIOD_M30);
    Print(functionName, " > token: ", gToken, ", timout: ", gTimeout);
  }
  return res;
}

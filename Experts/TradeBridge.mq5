//Options/ExpertAdvisors/Allow WebRequest for list URL: add new BASE_URL
#define BASE_URL "https://dxtrade.ftmo.com/dxsca-web/" 
#define ACCOUNT_FTMO "acc123"
#define PASSWORD_FTMO "password"

string gToken;
datetime gTimeout;

int OnInit() {
  Login();
  return INIT_SUCCEEDED;
}

void OnTick() {
  if (TimeCurrent() > gTimeout - 300) {
    Ping();
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

int SendOrderBuy(double lotSize, int orderCode) {
  string url = BASE_URL + "accounts/default:" + ACCOUNT_FTMO + "/orders";
  char post[], result[];
  string headers = "Content-Type: application/json\r\n" + 
    "Accept: application/json\r\n" + 
    "Authorization: DXAPI" + gToken + "\r\n";
  string resultHeader;
  string domain = "default";
  string json = "{" +
    "\"account\": \"default:" + ACCOUNT_FTMO + "\"," +
    "\"orderCode\": \"" + (string)orderCode + "\"," + 
    "\"type\" : \"MARKET\"," +
    "\"instrument\": \"" + _Symbol + "\"," +
    "\"quantity\": " + (string)(lotSize * 100000) + "," +
    "\"positionEffect\": \"OPEN\"," +
    "\"side\": \"BUY\"," +
    "\"tif\": \"GTC\"" +
  "}";
  StringToCharArray(json, post, 0, StringLen(json));
  return CheckWebRequest(__FUNCTION__, url, headers, 5000, post, result, resultHeader);
}

int SendOrderSell(double lotSize, int orderCode) {
  string url = BASE_URL + "accounts/default:" + ACCOUNT_FTMO + "/orders";
  char post[], result[];
  string headers = "Content-Type: application/json\r\n" + 
    "Accept: application/json\r\n" + 
    "Authorization: DXAPI" + gToken + "\r\n";
  string resultHeader;
  string domain = "default";
  string json = "{" +
    "\"account\": \"default:" + ACCOUNT_FTMO + "\"," +
    "\"orderCode\": \"" + (string)orderCode + "\"," + 
    "\"type\" : \"MARKET\"," +
    "\"instrument\": \"" + _Symbol + "\"," +
    "\"quantity\": " + (string)(lotSize * 100000) + "," +
    "\"positionEffect\": \"OPEN\"," +
    "\"side\": \"SELL\"," +
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

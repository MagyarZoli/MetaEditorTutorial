#property strict
#property indicator_chart_window

#include <Trade/Trade.mqh>

input group "==== Magic Number ====";
input int inpMagicNumber = 99915; //Magic number for the EA's trades.
input group "==== General =====";
input double inpLotSize = 1.0; //Lot size for trading.
input int inpStopLoss = 0; //Stop loss value.
input int inpTakeProfit = 0; //Take profit value.
input group "==== RSI ====";
input int inpPeriod = 10; //RSI period.
input int inpMax = 70; //Overbought level for RSI.
input int inpMin = 30; //Oversold level for RSI.
input int inpRatio = 10; //ratio
input int inpNarrow = 0; //narrow
input int inpHour = 1; //Time period in hours.
input int inpShift = 1; //Shift value for RSI.
input group "==== MA ====";
input int inpPeriodMA = 3; //Period for the Moving Average.     

CTrade trade; //Class is used for trading operations.
MqlTick currentTick; //Variables related to trading.
int handle; //Variables related to trading.
double closePrice; //Variables related to trading.
double buffer[]; //Arrays to store RSI values.
double bufferMA[]; //Arrays to store MA values.
ulong ticketBuy[]; //Arrays to store ticket information for buy and sell orders.
ulong ticketSell[]; //Arrays to store ticket information for buy and sell orders.
bool strategy[4]; //Boolean arrays for strategy conditions.
bool sellStrategy[2]; //Boolean arrays for strategy conditions.
bool buyStrategy[2]; //Boolean arrays for strategy conditions.
bool highLevel[2]; //Boolean arrays for high and low levels.
bool lowLevel[2]; //Boolean arrays for high and low levels.
datetime lastOrderTime = 0; //The time of the last order placed.
int timeInterval = (60 * 60 * inpHour); //Time interval for placing orders.
int sellCount = 0; //Counters for sell and buy orders.
int buyCount = 0; //Counters for sell and buy orders.
int max = inpMax; //Maximum values for RSI.
int min = inpMin; //Minimum values for RSI.
bool half = false; 

//+------------------------------------------------------------------+
//|The OnInit function is a special function in MQL4 that is executed| 
//|once when the expert advisor (EA) is attached to a chart. It is   |
//|typically used for initialization tasks.                          |
//| - Checks if the input parameters are correct using the           |
//|   CheckInputs function. If not, it returns                       |
//|   INIT_PARAMETERS_INCORRECT, indicating an issue with the input  |
//|   parameters.                                                    |
//| - Sets the expert magic number for the trading operations using  |
//|   the SetExpertMagicNumber method from the CTrade class.         |
//| - Creates an RSI (Relative Strength Index) indicator handle using| 
//|   the iRSI function. The handle is used to retrieve RSI values   |
//|   later in the script.                                           |
//| - Checks if the indicator handle creation was successful. If not,| 
//|   it raises an alert and returns INIT_FAILED.                    |
//| - Sets the buffer array as a series (reversed order) to simplify |
//|   accessing its elements.                                        |
//| - Sets the bufferMA array as a series.                           |
//| - return: INIT_SUCCEEDED If all the initialization steps are     |
//|   successful, the function returns INIT_SUCCEEDED, indicating    |
//|   that the EA is ready to operate.                               |  
//+------------------------------------------------------------------+
int OnInit() {
  if (!CheckInputs()) {
    return INIT_PARAMETERS_INCORRECT;
  }
  trade.SetExpertMagicNumber(inpMagicNumber);
  sellStrategy[0] = true;
  sellStrategy[1] = true;
  buyStrategy[0] = true;
  buyStrategy[1] = true;
  handle = iRSI(_Symbol, PERIOD_CURRENT, inpPeriod, PRICE_CLOSE);
  if (handle == INVALID_HANDLE) {
    Alert("Failed to create indicator handle");
    return INIT_FAILED;
  }
  ArraySetAsSeries(buffer, true);
  ArraySetAsSeries(bufferMA, true);
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|The OnDeinit function is a special function in MQL4 that is called|
//|when the expert advisor (EA) is removed from the chart.           |
//| - Checks if the RSI indicator handle (handle) is not equal to    |
//|   INVALID_HANDLE, indicating that it is a valid handle.          |
//| - If the handle is valid, it releases the indicator handle using |
//|   the IndicatorRelease function. This is important for freeing up|
//|   resources associated with the indicator handle when the EA is  |
//|   removed from the chart.                                        |        
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  if (handle != INVALID_HANDLE) {
    IndicatorRelease(handle);
  }
}

//+------------------------------------------------------------------+
//|The OnTick function is a special function in MQL4 that is called  |
//|every time a new tick is received. It is a crucial part of the    |
//|expert advisor (EA) logic where the main trading decisions        |
//|are made.                                                         |
//| - Copies the RSI values to the buffer array using the CopyBuffer |
//|   function. It retrieves the last 3 RSI values starting from the |
//|   inpShift index.                                                |
//| - Copies the RSI values to the bufferMA array. It retrieves RSI  |
//|   values over a period of inpPeriodMA starting from the inpShift |
//|   index.                                                         |
//| - Gets the current close price of the symbol.                    |
//| - Checks if enough time has passed since the last order based on |
//|   the specified time interval (timeInterval).                    |
//| - Level: Updates the highLevel and lowLevel flags based on RSI   |
//|   values. This related to threshold levels for trading decisions.|
//| - TradeSellStrategy(sellCount): Executes the sell strategy based |
//|   on the current market conditions. The sellCount variable       |
//|   indicates the number of open sell positions.                   |
//| - TradeBuyStrategy(buyCount): Executes the buy strategy based on | 
//|   the current market conditions. The buyCount variable indicates |
//|   the number of open buy positions.                              |
//| - Updates the lastOrderTime to the current time, indicating the  |
//|   time of the most recent order.                                 |
//| - It checks RSI values, determines if enough time has passed     |
//|   since the last order, updates relevant flags, and executes the |
//|   sell and buy strategies accordingly.                           |
//+------------------------------------------------------------------+
void OnTick() {
  CopyBuffer(handle, 0, inpShift, 3, buffer); 
  CopyBuffer(handle, 0, inpShift, inpPeriodMA, bufferMA);
  closePrice = iClose(_Symbol, PERIOD_CURRENT, 0);
  if (TimeCurrent() > lastOrderTime + timeInterval) {
    Level();
    TradeSellStrategy(sellCount);
    TradeBuyStrategy(buyCount);
    lastOrderTime = TimeCurrent();
  }
}

//+------------------------------------------------------------------+
//|TradeSellStrategy function implement a set of conditions for      |
//|initiating a sell trade based on a combination of RSI             |
//|(Relative Strength Index) and moving average criteria.            | 
//| - Resizes the ticketSell array to accommodate the new sell trade |
//|   at index (i + 1).                                              |
//| - Initializes the element at index i in the ticketSell           |
//|   array to 0.                                                    |
//| - Calculates the simple moving average of RSI using the          |
//|   RSIMovingAverage function.                                     |
//| - The function checks various conditions to determine whether to |
//|   initiate a sell trade.                                         |
//| - Conditions are evaluated for different strategies              |
//|   (sellStrategy and strategy) based on RSI values, moving        |
//|   averages, and other criteria. If a condition is met, the       |
//|   corresponding strategy flag is set to false, and the           |
//|   TradeSell(i) function is called to execute the sell trade.     |
//| - CloseAllBuy() is called to close any existing buy positions.   |
//|   This function, together with the other components of the       |
//|   script, plays a role in the overall trading strategy,          |
//|   generating sell signals based on a combination of conditions   |
//|   related to RSI, moving averages, and other variables.          |                         
//+------------------------------------------------------------------+
void TradeSellStrategy(int i) {
  ArrayResize(ticketSell, (i + 1));
  ticketSell[i] = 0;
  double rsima = RSIMovingAverage();
  if (buffer[0] < buffer[1] && ticketSell[i] <= 0) {
    if (sellStrategy[0] && buffer[1] >= (max - inpPeriod) && buffer[1] < max) {
      sellStrategy[0] = false;
      TradeSell(i);
      CloseAllBuy();
    } else if (sellStrategy[1] && buffer[1] >= max && buffer[1] < (max + inpPeriod)) {
      sellStrategy[1] = false;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[0] && buffer[1] >= (max + inpPeriod)) {
      strategy[0] = true;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[1] && (buffer[0] > max || buffer[1] > max) && buffer[0] < buffer[1]) {
      strategy[1] = true;
      TradeSell(i);
      CloseAllBuy();
    } else if (!strategy[2] && !highLevel[0] && highLevel[1]) {
      strategy[2] = true;
      TradeSell(i); 
      CloseAllBuy();
    } else if (!strategy[3] && rsima >= max) {
      strategy[3] = true;
      TradeSell(i);
      CloseAllBuy();
    }
  }
}

//+------------------------------------------------------------------+
//|TradeBuyStrategy function implement a set of conditions for       |
//|initiating a buy trade based on a combination of RSI              |
//|(Relative Strength Index) and moving average criteria.            |
//| - Resizes the ticketBuy array to accommodate the new buy trade at|
//|   index (i + 1).                                                 |
//| - Initializes the element at index i in the ticketBuy array to 0.|
//| - Calculates the simple moving average of RSI using the          |
//|   RSIMovingAverage function.                                     |
//| - The function checks various conditions to determine whether to |
//|   initiate a buy trade.                                          |
//| - Conditions are evaluated for different strategies              |
//|   (buyStrategy and strategy) based on RSI values, moving         |
//|   averages, and other criteria. If a condition is met, the       |
//|   corresponding strategy flag is set to false, and the           |
//|   TradeBuy(i) function is called to execute the buy trade.       | 
//| - CloseAllSell() is called to close any existing sell positions. |
//|   This function a key part of the trading strategy, combining    |
//|   multiple conditions to generate buy signals based on RSI and   |
//|   moving average criteria. The specific conditions are based on  |
//|   the values of the buffer, buyStrategy, strategy, and other     |
//|   variables.                                                     |
//+------------------------------------------------------------------+
void TradeBuyStrategy(int i) {
  ArrayResize(ticketBuy, (i + 1));
  ticketBuy[i] = 0;
  double rsima = RSIMovingAverage();
  if (buffer[0] > buffer[1] && ticketBuy[i] <= 0) {
    if (buyStrategy[0] && buffer[1] <= (min + inpPeriod) && buffer[1] > min) {
      buyStrategy[0] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (buyStrategy[1] && buffer[1] <= min && buffer[1] > (min - inpPeriod)) {
      buyStrategy[1] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[0] && buffer[1] <= (min - inpPeriod)) {
      strategy[0] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[1] && (buffer[0] < min || buffer[1] < min) && buffer[0] > buffer[1]) {
      strategy[1] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[2] && !lowLevel[0] && lowLevel[1]) {
      strategy[2] = false;
      TradeBuy(i);
      CloseAllSell();
    } else if (strategy[3] && rsima <= min) {
      strategy[3] = false;
      TradeBuy(i);
      CloseAllSell();
    }
  }
}

//+------------------------------------------------------------------+
//|TradeSell function responsible for executing a sell trade based on|
//|specified parameters.                                             |
//| - Calculates the stop loss (sl) based on the ask price, taking   |
//|   into account the specified stop loss distance (inpStopLoss).   |
//|   If inpStopLoss is set to 0, the stop loss is set to 0.         |
//| - Calculates the take profit (tp) based on the ask price, taking |
//|   into account the specified take profit distance                |
//|   (inpTakeProfit). If inpTakeProfit is set to 0, the take profit |
//|   is set to 0.                                                   |
//| - Normalizes the stop loss price. If normalization fails, it     |
//|   prints an error message and returns from the function.         |
//| - Normalizes the take profit price. If normalization fails, it   |
//|   prints an error message and returns from the function.         |
//| - Executes the sell trade using the Sell method from the CTrade  |
//|   class. It specifies the lot size (inpLotSize), trading symbol  |
//|   (_Symbol), current bid price (currentTick.bid), stop loss (sl),|
//|   take profit (tp), and an empty string as the comment.          |
//| - Stores the result of the order in the ticketSell array at      |
//|   index i.                                                       |
//| - Increments the sellCount variable, possibly used for tracking  |
//|   the number of open sell positions.                             |
//+------------------------------------------------------------------+
void TradeSell(int i) {
  double sl = inpStopLoss == 0 ? 0 : currentTick.ask + inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : currentTick.ask - inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  trade.Sell(inpLotSize, _Symbol, currentTick.bid, sl, tp, "");
  ticketSell[i] = trade.ResultOrder();
  sellCount++;
}

//+------------------------------------------------------------------+
//|TradeBuy function responsible for executing a buy trade based on  |
//|specified parameters.                                             |
//| - Calculates the stop loss (sl) based on the bid price, taking   |
//|   into account the specified stop loss distance (inpStopLoss).   |
//|   If inpStopLoss is set to 0, the stop loss is set to 0.         |
//| - Calculates the take profit (tp) based on the bid price, taking |
//|   into account the specified take profit distance                |
//|   (inpTakeProfit). If inpTakeProfit is set to 0, the take profit |
//|   is set to 0.                                                   |
//| - Normalizes the stop loss price. If normalization fails, it     |
//|   prints an error message and returns from the function.         |
//| - Normalizes the take profit price. If normalization fails, it   |
//|   prints an error message and returns from the function.         |
//| - Executes the buy trade using the Buy method from the CTrade    |
//|   class. It specifies the lot size (inpLotSize), trading symbol  |
//|   (_Symbol), current ask price (currentTick.ask), stop loss (sl),|
//|   take profit (tp), and an empty string as the comment.          |
//| - Stores the result of the order in the ticketBuy array at       |
//|   index i.                                                       |
//| - Increments the buyCount variable, possibly used for tracking   |
//|   the number of open buy positions.                              |
//+------------------------------------------------------------------+
void TradeBuy(int i) {
  double sl = inpStopLoss == 0 ? 0 : currentTick.bid - inpStopLoss * _Point;
  double tp = inpTakeProfit == 0 ? 0 : currentTick.bid + inpTakeProfit * _Point;
  if (!NormalizePrice(sl)) {
    Print("Falided to normalize price stop loss");
    return;
  }
  if (!NormalizePrice(tp)) {
    Print("Falided to normalize price take profit");
    return;
  }
  trade.Buy(inpLotSize, _Symbol, currentTick.ask, sl, tp, "");
  ticketBuy[i] = trade.ResultOrder();
  buyCount++;
}

//+------------------------------------------------------------------+
//|CloseAllSell function a part of a trading script. This function is|
//|designed to close all existing sell positions.                    |
//| - Checks if there are open sell positions by examining the size  | 
//|   of the ticketSell array.                                       |
//| - Closes the sell position identified by the ticket number       |
//|   ticketSell[j] using the PositionClose method from the CTrade   |
//|   class. ArrayResize(ticketSell, 0): Resizes the ticketSell array|
//|   to 0, effectively clearing it.                                 |
//| - Resets the sellCount variable to 0.                            |
//| - Iterates through the sellStrategy array and sets all elements  |
//|   to true. This step reset some flags related to the sell        |
//|   strategy.                                                      |                                     
//+------------------------------------------------------------------+
void CloseAllSell() {
  if (ArraySize(ticketSell) > 0) {
    for (int j = 0; j < ArraySize(ticketSell); j++) {
      trade.PositionClose(ticketSell[j]);
    }
    ArrayResize(ticketSell, 0);
    sellCount = 0;
    for (int k = 0; k < ArraySize(sellStrategy); k++) {
      sellStrategy[k] = true;
    }
  }
}

//+------------------------------------------------------------------+
//|CloseAllBuy function a part of a trading script. This function is |
//|designed to close all existing buy positions.                     |
//| - Checks if there are open buy positions by examining the size of|
//|   the ticketBuy array.                                           |
//| - Closes the buy position identified by the ticket number        |
//|   ticketBuy[j] using the PositionClose method from the CTrade    |
//|   class. ArrayResize(ticketBuy, 0): Resizes the ticketBuy array  |
//|   to 0, effectively clearing it.                                 |
//| - Resets the buyCount variable to 0.                             |
//| - Iterates through the buyStrategy array and sets all elements to|
//|   true. This step reset some flags related to the buy strategy.  |                                         
//+------------------------------------------------------------------+
void CloseAllBuy() {
  if (ArraySize(ticketBuy) > 0) {
    for (int j = 0; j < ArraySize(ticketBuy); j++) {
      trade.PositionClose(ticketBuy[j]);
    }
    ArrayResize(ticketBuy, 0);
    buyCount = 0;
    for (int k = 0; k < ArraySize(buyStrategy); k++) {
      buyStrategy[k] = true;
    }
  }
}

//+------------------------------------------------------------------+
//|CheckInputs function appears to validate the input parameters used|
//|in the trading script. It checks various conditions for the input |
//|values and raises an alert if any of the conditions are not met.  |
//| - Each if statement checks a specific condition related to an    |
//|   input parameter. If the condition is not met, an alert is      |
//|   triggered, and correct is set to false.                        |
//| - The function returns correct, indicating whether all input     |
//|   parameters pass the validation.                                |                           
//+------------------------------------------------------------------+
bool CheckInputs() {
  bool correct = true;
  if (inpMagicNumber <= 0) {
    Alert("MagicNumber <= 0");
    correct = false;
  }
  if (inpLotSize <= 0 || inpLotSize > 10) {
    Alert("Lot size <= 0 or > 10");
    correct = false;
  }
  if (inpStopLoss < 0) {
    Alert("Stop loss < 0");
    correct = false;
  }
  if (inpTakeProfit < 0) {
    Alert("Take profit < 0");
    correct = false;
  }
  if (inpPeriod <= 1) {
    Alert("RSI period <= 1");
    correct = false;
  }
  if (inpMax >= 100 || inpMax <= 50) {
    Alert("RSI max >= 100 or <= 50");
    correct = false;
  }
  if (inpMin <= 0 || inpMin >= 50) {
    Alert("RSI min >= 0 or >= 50");
    correct = false;
  }
  if (inpRatio <= 0 || inpRatio >= 50) {
    Alert("RSI ratio <= 0 or >= 50");
    correct = false;
  }
  if (inpHour <= 0) {
    Alert("Hour <= 0");
    correct = false;
  }
  if (inpShift <= 0) {
    Alert("shift <= 0");
    correct = false;
  }
  if (inpPeriodMA <= 1) {
    Alert("MA period <= 1");
    correct = false;
  }
  return correct;
}

//+------------------------------------------------------------------+
//|Level function appears a part of a trading strategy where it      |
//|assesses whether the RSI (Relative Strength Index) values in the  |
//|buffer array are within certain levels.                           |
//| - this function update boolean flags (highLevel and lowLevel)    |
//|   based on whether the RSI values are above certain thresholds   |
//|   (inpMax and inpMin). The additional conditions involving 10    |
//|   units are used to provide a buffer or tolerance around these   |
//|   thresholds.                                                    |
//| - The resulting flags (highLevel and lowLevel) might be used in  |
//|   the trading logic to make decisions based on the RSI levels in |
//|   relation to the specified thresholds.                          |                                       
//+------------------------------------------------------------------+
void Level() {
  for (int i = 0; i <= 1; i++) {
    if (buffer[i] > inpMax) {
      highLevel[i] = true;
    } else if (buffer[i] < (inpMax - 10)) {
      highLevel[i] = false;
    }
    if (buffer[i] < inpMin) {
      lowLevel[i] = true;
    } else if (buffer[i] > (inpMin + 10)) {
      lowLevel[i] = false;
    }
  }
}

//+------------------------------------------------------------------+
//|NormalizePrice function is used to normalize a price value        |
//|based on the tick size of the trading symbol. Normalizing the     |
//|price is important in trading to ensure that the price adheres to |
//|the minimum price movement defined by the tick size.              |
//| - Retrieves the tick size of the trading symbol using            |
//| - SymbolInfoDouble. If the retrieval fails, it prints an error   |
//|   message and returns false.                                     |
//| - Normalizes the price by dividing it by the tick size, rounding | 
//|   to the nearest tick using MathRound, and then multiplying it   |
//|   back by the tick size. The result is assigned to the price     |
//|   variable. _Digits is used to specify the number of decimal     |
//|   places in the price.                                           |
//| - return: If the normalization is successful, the function       |
//|   returns true.                                                  |                                           
//+------------------------------------------------------------------+
bool NormalizePrice(double &price) {
  double tickSize = 0;
  if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
    Print("Failed to get tick size");
    return false;
  }
  price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
  return true;
}

//+------------------------------------------------------------------+
//|RSIMovingAverage appears to calculate the simple moving average   |
//|(SMA) of the values stored in the bufferMA array.                 |
//| - rsima: This variable is used to accumulate the sum of the      |
//|   values in the bufferMA array.                                  |
//| - The for loop iterates through each element in the bufferMA     |
//|   array. rsima += bufferMA[i];: Adds each value in the array to  |
//|   the rsima variable.                                            |
//| - After the loop, the function calculates the average by dividing|
//|   the sum (rsima) by the period (inpPeriodMA).                   |
//| - return: The calculated average.                                |
//+------------------------------------------------------------------+
double RSIMovingAverage() {
  double rsima = 0;
  for (int i = 0; i < ArraySize(bufferMA); i++) {
    rsima += bufferMA[i];
  }
  return rsima / inpPeriodMA;
}
//+------------------------------------------------------------------+
//|                                                TradeExecutor.mq4 |
//|                                      Copyright 2020, Lenny Kioko |
//|                                    https://lennykioko.github.io/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lenny Kioko"
#property link      "https://lennykioko.github.io/"
#property version   "1.00"
#property strict
#property show_inputs

#include <json.mqh>


extern string url = "https://mobile-exeutor/api/mql4/";

extern double accountSize = 1000;
extern double percentageRisk = 1.0;

double riskPerTradeDollars = (accountSize * (percentageRisk / 100));

int accountNumber = AccountNumber();

double magicNB = 5744;
string bodyString;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnTick()
{
  if(DayOfWeek() != 0 && DayOfWeek() != 6)
  {
    listener();
    void  Sleep(1000);
  }
}

int makeRequest(string url, string reqType)
{
  string cookie = NULL, headers;
  char post[], body[];

  int timeout = 7000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection

  ResetLastError();
  int statusCode = WebRequest(reqType, url, cookie, NULL, timeout, post, 0, body, headers);
  bodyString = CharArrayToString(body);
  return statusCode
}

void listener() {
  int reqStatusCode = makeRequest("GET", url);

  if (reqStatusCode == 200) {
    JSONParser * parser = new JSONParser();
    JSONValue * jv = parser.parse(bodyString);

    if (jv == NULL) {
      Alert("error: " + (string)parser.getErrorCode() + parser.getErrorMessage());
    } else {
      if (jv.isObject()) {
        JSONObject * jo = jv;
        string symbol = jo.getString("symbol");
        string orderType = jo.getString("orderType");
        // double account = jo.getDouble("account");
        double slPrice = jo.getDouble("slPrice");
        double tpPrice = jo.getDouble("tpPrice");
        double pendingOrderPrice = jo.getDouble("pendingOrderPrice");
        // double riskDollars = jo.getDouble("riskDollars");

        int trade = executeTrade(ordertype, symbol, accountSize, percentageRisk, pendingOrderPrice, slPrice, tpPrice);
        int submit = makeRequest("GET", url + IntegerToString(trade, 0))
        bodyString = "";
      }
    delete jv;
    }
    delete parser;
  }
}


void executeTrade(string orderType, string symbol, double accountSize, double percentageRisk, double pendingOrderPrice, double stopLossPrice, double takeProfitPrice)
{
  if(IsTradingAllowed())
  {
    // buy
    if(orderType == "sell" && pendingOrderPrice == 0.0)
    {
        double entryPrice = MarketInfo(symbol, MODE_ASK);
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUY, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // sell
    if(orderType == "buy" && pendingOrderPrice == 0.0)
    {
        double entryPrice = MarketInfo(symbol, MODE_BID);
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELL, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // buystop
    if(orderType == "buystop")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUYSTOP, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // sellstop
    if(orderType == "sellstop")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELLSTOP, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // buylimit
    if(orderType == "buylimit")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUYLIMIT, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
        return openOrderID;
    }

    // selllimit
    if(orderType == "selllimit")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELLLIMIT, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }
  }
}

//+------------------------------------------------------------------+

// custom re-usable functions

// works for fx pairs, may not work for indices
double GetPipValue(string symbol)
{
  int vdigits = (int)MarketInfo(symbol, MODE_DIGITS);

  if(vdigits >= 4)
  {
    return 0.0001;
  }
  else
  {
    return 0.01;
  }
}

double CalculateLotSize(string symbol, double riskDollars, double entryPrice, double slPrice)
{
  double pipValue = MarketInfo(symbol, MODE_TICKVALUE) * 10;
  double pips = MathAbs(entryPrice - slPrice) / GetPipValue();
  double div = pips * pipValue;
  double lot = NormalizeDouble(riskDollars / div, 2);

  return lot;
}

bool IsTradingAllowed()
{
  if(!IsTradeAllowed())
  {
    Alert("Expert Advisor is NOT Allowed to Trade. Check AutoTrading.");
    return false;
  }

  if(!IsTradeAllowed(Symbol(), TimeCurrent()))
  {
    Alert("Trading NOT Allowed for specific Symbol and Time");
    return false;
  }
  return true;
}

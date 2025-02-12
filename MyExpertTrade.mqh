//+------------------------------------------------------------------+
//|                                                MyExpertTrade.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert\ExpertTrade.mqh>

//+------------------------------------------------------------------+
//| Наследник от ExpertTrade. Переопределяет и добавляет функции     |
//+------------------------------------------------------------------+
class CMyExpertTrade: public CExpertTrade
  {
public:
   bool              Buy(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "");
   bool              Sell(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "");

  };
//+------------------------------------------------------------------+
//| Easy LONG. При цене выше Ask - покупка по-рынку. Ниже - BuyLimit |
//+------------------------------------------------------------------+
bool              CMyExpertTrade::Buy(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "")
  {
   double ask, stops_level;
//--- checking
   if(m_symbol == NULL)
      return(false);
   string symbol = m_symbol.Name();
   if(symbol == "")
      return(false);
//---
   ask = m_symbol.Ask();
   stops_level = m_symbol.StopsLevel() * m_symbol.Point();
   if(price != 0.0)
     {
      if(price > ask + stops_level)
        {
         if(stopOrder == "stopOrder")
            //--- send "BUY_STOP" order
            return(OrderOpen(symbol, ORDER_TYPE_BUY_STOP, volume, 0.0, price, sl, tp,
                             m_order_type_time, m_order_expiration, comment));
         //--- Ордер по рынку
         return(PositionOpen(symbol, ORDER_TYPE_BUY, volume, ask, sl, tp, comment));
        }
      if(price < ask - stops_level)
        {
         //--- send "BUY_LIMIT" order
         return(OrderOpen(symbol, ORDER_TYPE_BUY_LIMIT, volume, 0.0, price, sl, tp,
                          m_order_type_time, m_order_expiration, comment));
        }
     }
//---
   return(PositionOpen(symbol, ORDER_TYPE_BUY, volume, ask, sl, tp, comment));
  }
//+-----------------------------------------------------------------------+
//| Easy SHORT. При цене ниже Bid - продажа по-рынку. Выше - SellLimit    |
//+-----------------------------------------------------------------------+
bool              CMyExpertTrade::Sell(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "")
  {
   double bid, stops_level;
//--- checking
   if(m_symbol == NULL)
      return(false);
   string symbol = m_symbol.Name();
   if(symbol == "")
      return(false);
//---
   bid = m_symbol.Bid();
   stops_level = m_symbol.StopsLevel() * m_symbol.Point();
   if(price != 0.0)
     {
      if(price > bid + stops_level)
        {
         //--- send "SELL_LIMIT" order
         return(OrderOpen(symbol, ORDER_TYPE_SELL_LIMIT, volume, 0.0, price, sl, tp,
                          m_order_type_time, m_order_expiration, comment));
        }
      if(price < bid - stops_level)
        {
         if(stopOrder == "stopOrder")
            //--- send "SELL_STOP" order
            return(OrderOpen(symbol, ORDER_TYPE_SELL_STOP, volume, 0.0, price, sl, tp,
                             m_order_type_time, m_order_expiration, comment));
         //--- Ордер по рынку
         return(PositionOpen(symbol, ORDER_TYPE_SELL, volume, bid, sl, tp, comment));
        }
     }
//---
   return(PositionOpen(symbol, ORDER_TYPE_SELL, volume, bid, sl, tp, comment));
  }     
//+------------------------------------------------------------------+

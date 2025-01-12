//+------------------------------------------------------------------+
//|                                                    gridRobot.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalMA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//--- подключаем класс Сетки
#include "Grid.mqh"
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
string             Expert_Title         = "gridRobot";        // Document name
ulong                    Expert_MagicNumber   = 20272;      //
bool                     Expert_EveryTick     = true;      //
//--- inputs for main signal
int                Signal_ThresholdOpen = 10;         // Signal threshold value to open [0...100]
int                Signal_ThresholdClose = 10;        // Signal threshold value to close [0...100]
double             Signal_PriceLevel    = 0.0;        // Price level to execute a deal
double             Signal_StopLevel     = 50.0;       // Stop Loss level (in points)
double             Signal_TakeLevel     = 50.0;       // Take Profit level (in points)
int                Signal_Expiration    = 4;          // Expiration of pending orders (in bars)
input int                Signal_MA_PeriodMA   = 45;         // Moving Average(12,0,...) Period of averaging
int                Signal_MA_Shift      = 0;          // Moving Average(12,0,...) Time shift
ENUM_MA_METHOD     Signal_MA_Method     = MODE_SMA;   // Moving Average(12,0,...) Method of averaging
ENUM_APPLIED_PRICE Signal_MA_Applied    = PRICE_CLOSE; // Moving Average(12,0,...) Prices series
double             Signal_MA_Weight     = 1.0;        // Moving Average(12,0,...) Weight [0...1.0]


enum enumStrengthSignal {strong, medium, poor};
enum enumModeTrade {_Buy, _Sell, _Signal};
struct levelStruct
  {
   double            levelPrice;
   ulong             orderTicket;
  };
levelStruct levelsGrid[];


input int _grids = 10;
input double Step = 0.25;
input enumStrengthSignal StrengthSignal = medium; //Сила сингала
input enumModeTrade modeTrade = _Sell; //Направление
input int trailingStop = 1;
input int trailingProfit = 2;

int Position_Lots;
double orderLots = 1;
int lastPositionVolumeStop;
int lastPositionVolumeProfit;
int grids = _grids + 1;




//input double lvlUP = 84;
//input double lvlDoun = 66;
//input double k_grids = 0.3;
//double Step = NormalizeDouble((lvlUP - lvlDoun)/grids, 2);
//double Step = (lvlUP - lvlDoun) / (_grids);
//int gridsTP = (int)((grids - 1) / (1 + k_grids));
//int gridsSL = (int)(gridsTP * k_grids > 1 ? gridsTP * k_grids : 1);
//double             Position_Lots    = gridsTP * orderLots;        // Fixed volume
//double             Position_Lots    = orderLots;
//double PriceArray[];








//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
class CMyExpertTrade: public CExpertTrade
  {
public:
   //+------------------------------------------------------------------+
   //| Easy LONG trade operation                                        |
   //+------------------------------------------------------------------+
   bool              Buy(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "")
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
   //+------------------------------------------------------------------+
   //| Easy SHORT trade operation                                       |
   //+------------------------------------------------------------------+
   bool              Sell(double volume, double price, double sl, double tp, const string stopOrder = "", const string comment = "")
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


  };



//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
class CMyExpert: public CExpert
  {

public:
   CGrid             m_grid;
   //+-------------Глобальные переменные класса Эксперта-----------------------------------+
   int               OrdersCount;
   bool              PositionIsBay;
   double            lotsSL;
   int               positionVolume;
   int               k_position;
   double            currentPrice;

   //+-----------Проверка, что цена между уровнями----------------------------------+

   bool              PriceInLvl()
     {
      return !((!PositionIsBay && (currentPrice > levelsGrid[0].levelPrice || currentPrice < levelsGrid[grids - 1].levelPrice))
               || (PositionIsBay && (currentPrice < levelsGrid[0].levelPrice || currentPrice > levelsGrid[grids - 1].levelPrice)));
     }

   //+-----------Инициализация Сетки-------------------------------------------+
   bool              Init_Grid()
     {
      m_grid.GridInit(5, 3, Step, 100, SELL)();
      m_grid.PrintGrid();
      double PositionPrice = m_position.PriceOpen();
      int gridsSL = _grids - Position_Lots;
      lotsSL = grids - 2;
      k_position = PositionIsBay ? 1 : -1;
      lastPositionVolumeStop = (int)Position_Lots;
      lastPositionVolumeProfit = (int)Position_Lots;
      ArrayResize(levelsGrid, grids);
      //levelsGrid[0].levelPrice = NormalizeDouble(PositionIsBay ? lvlDoun : lvlUP, m_symbol.Digits());
      for(int i = 0; i <= grids - 1; i++)
        {
         levelsGrid[i].levelPrice = NormalizeDouble(PositionPrice + k_position * (-Step * gridsSL + Step * i), m_symbol.Digits());
        }
      return true;
     }
   //+-----------Обновление Сетки-------------------------------------------+

   bool              Refresh_Grid()
     {
      lotsSL = grids - 2;
      if(!PriceInLvl())
        {
         m_trade.PositionClose(m_symbol.Name());
         DeleteOrders();
         return false;
        }
      Refresh_Tickets_Orders();
      int indexCurrentPrice = grids - 1 - positionVolume;
      for(int i = 0; i < grids; i++)
        {
         if(levelsGrid[i].orderTicket == 0)
           {
            if(i == 0)
              {
               if(PositionIsBay)
                 {
                  OpenShort(levelsGrid[i].levelPrice, 0, 0, lotsSL, "stopOrder");
                  continue;
                 }
               else
                 {
                  OpenLong(levelsGrid[i].levelPrice, 0, 0, lotsSL, "stopOrder");
                  continue;
                 }
              }
            else
               if(i != indexCurrentPrice)
                 {
                  if(levelsGrid[i].levelPrice < levelsGrid[indexCurrentPrice].levelPrice)
                    {
                     OpenLong(levelsGrid[i].levelPrice, 0, 0, orderLots);
                    }
                  else
                     if(levelsGrid[i].levelPrice > levelsGrid[indexCurrentPrice].levelPrice)
                       {
                        OpenShort(levelsGrid[i].levelPrice, 0, 0, orderLots);
                       }
                 }
           }
         else
           {
            if(i == indexCurrentPrice)
               if(levelsGrid[i].orderTicket != 0)
                  m_trade.OrderDelete(levelsGrid[i].orderTicket);
           }
        }
      return true;
     }

   //+-----------Обновление Тикетов Ордеров-------------------------------------------+
   void              Refresh_Tickets_Orders()
     {
      OrdersCount = OrdersTotal();
      double OrdersPrice[];
      ulong  OrdersTicket[];
      ArrayResize(OrdersPrice, OrdersCount);
      ArrayResize(OrdersTicket, OrdersCount);
      for(int i = 0; i < OrdersCount; i++)
        {
         m_order.SelectByIndex(i);
         OrdersPrice[i] = m_order.PriceOpen();
         OrdersTicket[i] = m_order.Ticket();
        }
      for(int i = 0; i < grids; i++)
        {
         int orderIndex = ArraySearch(OrdersPrice, levelsGrid[i].levelPrice);
         if(orderIndex != -1)
           {
            levelsGrid[i].orderTicket = OrdersTicket[orderIndex];
            ArrayRemove(OrdersTicket, orderIndex, 1);
            ArrayRemove(OrdersPrice, orderIndex, 1);
           }
         else
           {
            levelsGrid[i].orderTicket = 0;
           }
        }
      for(int i = ArraySize(OrdersTicket) - 1; i >= 0; i--)
        {
         m_trade.OrderDelete(OrdersTicket[i]);
        }
     }

   //+------------------------------------------------------------------+
   bool              Processing(void)
     {
      //--- calculate signal direction once
      m_signal.SetDirection();
      bool PositionExist = SelectPosition();
      PositionIsBay = m_position.PositionType() == POSITION_TYPE_BUY;
      OrdersCount = OrdersTotal();
      currentPrice = m_symbol.Last();
      if(!PositionExist)
        {
         if(OrdersCount != 0)
           {
            DeleteOrders();
            return true;
           }
         switch(modeTrade)
           {
            case _Sell:
               m_trade.Sell(Position_Lots, 0, 0, 0);
               break;
            case _Buy:
               m_trade.Buy(Position_Lots, 0, 0, 0);
               break;
            case _Signal:
               CheckOpen();
               break;
           }
         // m_trade.Buy(Position_Lots,0,0,0);
         // if(CheckOpen())
         //    return(true);
         // return false;
        }
      if(PositionExist)
        {
         positionVolume = (int)m_position.Volume();
         if(OrdersCount == 0)
           {
            Init_Grid();
           }
         else
           {
            if(lastPositionVolumeStop - positionVolume >= trailingStop && trailingStop > 0)
              {
               ArrayRemove(levelsGrid, 0, 1);
               m_trade.OrderDelete(levelsGrid[0].orderTicket);
               grids--;
               lastPositionVolumeStop = positionVolume;
              }
            if(lastPositionVolumeProfit - positionVolume >= trailingProfit && trailingProfit > 0)
              {
               ArrayRemove(levelsGrid, 0, 1);
               m_trade.OrderDelete(levelsGrid[0].orderTicket);
               ArrayResize(levelsGrid, grids);
               levelsGrid[grids - 1].levelPrice = levelsGrid[grids - 2].levelPrice + k_position * Step;
               levelsGrid[grids - 1].orderTicket = 0;
               lastPositionVolumeProfit = positionVolume;
              }
           }
         Refresh_Grid();
        }
      return true;
     }
   //+------------------------------------------------------------------+
   //| Long position open or limit/stop order set                       |
   //+------------------------------------------------------------------+
   bool              OpenLong(double price, double sl, double tp, double lot, const string stopOrder = "")
     {
      if(price == EMPTY_VALUE)
         return(false);
      //--- check lot for open
      lot = LotCheck(lot, price, ORDER_TYPE_BUY);
      if(lot == 0.0)
         return(false);
      //---
      return(((CMyExpertTrade*)m_trade).Buy(lot, price, sl, tp, stopOrder));
     }
   //+------------------------------------------------------------------+
   //| Short position open or limit/stop order set                      |
   //+------------------------------------------------------------------+
   bool              OpenShort(double price, double sl, double tp, double lot, const string stopOrder = "")
     {
      if(price == EMPTY_VALUE)
         return(false);
      //--- check lot for open
      lot = LotCheck(lot, price, ORDER_TYPE_SELL);
      if(lot == 0.0)
         return(false);
      //---
      return(((CMyExpertTrade*)m_trade).Sell(lot, price, sl, tp, stopOrder));
     }


  };


CMyExpert ExtExpert;


//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   switch(StrengthSignal)
     {
      case strong:
         Position_Lots = (int)(_grids * 0.9);
         break;
      case medium:
         Position_Lots = (int)(_grids * 0.75);
         break;
      case poor:
         Position_Lots = (int)(_grids * 0.6);
         break;
     }
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(), Period(), Expert_EveryTick, Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__ + ": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal = new CExpertSignal;
   if(signal == NULL)
     {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
//signal.StopLevel(Signal_StopLevel);
//signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSignalMA
   CSignalMA *filter0 = new CSignalMA;
   if(filter0 == NULL)
     {
      //--- failed
      printf(__FUNCTION__ + ": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.PeriodMA(Signal_MA_PeriodMA);
   filter0.Shift(Signal_MA_Shift);
   filter0.Method(Signal_MA_Method);
   filter0.Applied(Signal_MA_Applied);
   filter0.Weight(Signal_MA_Weight);
   filter0.PatternsUsage(1);
//--- Creation of trailing object
   CTrailingNone *trailing = new CTrailingNone;
   if(trailing == NULL)
     {
      //--- failed
      printf(__FUNCTION__ + ": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__ + ": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money = new CMoneyFixedLot;
   if(money == NULL)
     {
      //--- failed
      printf(__FUNCTION__ + ": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__ + ": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Lots(Position_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__ + ": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set ExpertTrade (Торговый Объект Эксперта)
   CExpertTrade    *trade = new CMyExpertTrade;
   if(!ExtExpert.InitTrade(Expert_MagicNumber, trade))
     {
      //--- failed
      printf(__FUNCTION__ + ": error initializing Торгового Объекта");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }

//+------------------------------------------------------------------+
int ArraySearch(double &array[], double num)
  {
   int arrSize = ArraySize(array);
   for(int i = 0; i < arrSize; i++)
     {
      if(num == array[i])
         return i;
     }
   return -1;
  }
//+------------------------------------------------------------------+

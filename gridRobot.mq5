//+------------------------------------------------------------------+
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
//--- подключаем Функции для работы с Массивами
#include "MyArray.mqh"
//Главный класс Эксперта
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalMA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//--- подключаем класс Сетки
#include "Grid.mqh"
//--- подключаем класс Массива Открытых Ордеров
#include "OrdersArray.mqh"
//--- подключаем Измененный Торговый Объект
#include "MyExpertTrade.mqh"

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
input int trailingProfit = 1;

int Position_Lots;
double orderLots = 1;
int grids = _grids + 1;

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
class CMyExpert: public CExpert
{
protected:
   CMyExpertTrade    trade;
   CGrid             m_grid;
   COrdersArray      m_orderS;
public:

                     CMyExpert(void):m_orderS(GetPointer(m_order), GetPointer(trade), &m_grid, GetPointer(ExtExpert)),
                     m_grid(&m_position)
   {
      this.m_trade = GetPointer(trade);
   };
   //+-------------Глобальные переменные класса Эксперта-----------------------------------+
   int               OrdersCount;
   bool              PositionIsBay;
   double            lotsSL;
   int               positionVolume;
   int               k_position;
   double            currentPrice;
   int               currentPosition;
   int               lastPositionVolumeStop;
   int               lastPositionVolumeProfit;

   //+------------------------------------------------------------------+
   bool              Processing(void)
   {
      //--- calculate signal direction once
      m_signal.SetDirection();
      bool PositionExist = SelectPosition();
      positionVolume = (int)m_position.Volume();
      PositionIsBay = m_position.PositionType() == POSITION_TYPE_BUY;
      OrdersCount = OrdersTotal();
      currentPrice = m_symbol.Last();
      if(!PositionExist)
      {
         if(OrdersCount != 0)
         {
            DeleteOrders();
            m_grid.Deinit();
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
         if(OrdersCount == 0)
         {
            m_grid.Init(_grids, Step);
            lastPositionVolumeStop = (int)Position_Lots;
            lastPositionVolumeProfit = (int)Position_Lots;
         }
         else
         {
            if(lastPositionVolumeStop - positionVolume >= trailingStop && trailingStop > 0)
            {
               //m_grid.ShiftStopLoss(1);
               lastPositionVolumeStop = positionVolume;
            }
            if(lastPositionVolumeProfit - positionVolume >= trailingProfit && trailingProfit > 0)
            {
               m_grid.ShiftGrid(1);
               lastPositionVolumeProfit = positionVolume;
            }
         }
         m_grid.UpdateGridByPosition();
         m_grid.PrintGrid();
         m_orderS.SynhronizingOrdersWithGrid();
         //m_orderS.OrdersPrint();
      }
      if(currentPosition != positionVolume)
      {
         currentPosition = positionVolume;
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

   //+------------------------------------------------------------------+
//| Initialization trade object                                      |
//+------------------------------------------------------------------+
   bool              InitTrade(ulong magic,CExpertTrade *obj=NULL)
   {
//--- tune trade object
      m_trade.SetSymbol(GetPointer(m_symbol));
      m_trade.SetExpertMagicNumber(magic);
      m_trade.SetMarginMode();
//--- set default deviation for trading in adjusted points
      m_trade.SetDeviationInPoints((ulong)(3*m_adjusted_point/m_symbol.Point()));
//--- ok
      return(true);
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
////--- Set ExpertTrade (Торговый Объект Эксперта)
//   CExpertTrade    *trade = new CMyExpertTrade;
//   if(!ExtExpert.InitTrade(Expert_MagicNumber, trade))
//   {
//      //--- failed
//      printf(__FUNCTION__ + ": error initializing Торгового Объекта");
//      ExtExpert.Deinit();
//      return(INIT_FAILED);
//   }
//   ExtExpert.m_orderS.Set_m_trade(trade);
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                         Grid.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_DIRECTION
  {
   BUY,
   SELL
  };
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Grid grid(5, 3, 0.5, SymbolInfoDouble(Symbol(), SYMBOL_ASK), SELL);
   grid.PrintGrid();
   Print("ShiftGrid - 2");
   grid.ShiftGrid(2);
   grid.PrintGrid();
   Print("ShiftGrid - 10");
   grid.ShiftGrid(10);
   grid.PrintGrid();
   Print("ShiftStopLoss - 1");
   grid.ShiftStopLoss(1);
   grid.PrintGrid();
  }

//+------------------------------------------------------------------+
//|    Основной класс Сетки                                                              |
//+------------------------------------------------------------------+
class Grid
  {
protected:
   //---Основные параметры сетки
   int               GridSize;
   int               Position;
   double            Step;
   double            PriceCenter;
   ENUM_DIRECTION            Direction;
   //---Расчетные параметры сетки
   int               StopLossSize;
   int               IndexCenter;
   double            Levels[];
   double            UpLevels[];
   double            DownLevels[];
   int               k_direction;
public:
                     Grid(int size, int position, double step, double priceCenter, ENUM_DIRECTION direction);
                    ~Grid(void) {}
   void              SetLevels(double priceCenter);
   void              PrintGrid(void);
   bool              SetPosition(int position);
   bool              ShiftGrid(int shift = 1);
   bool              ShiftStopLoss(int shift = 1);
  };
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
Grid::Grid(int size, int position, double step, double priceCenter, ENUM_DIRECTION direction)
  {
//---Инициализация основых параметров сетки
   GridSize = size;
   Position = position;
   Step = direction == BUY ? step : -1 * step;
   PriceCenter = priceCenter;
   Direction = direction;
//---Инициализация расчетных параметров сетки
   IndexCenter = GridSize - Position;
   StopLossSize = GridSize - 1;
   ArrayResize(Levels, GridSize + 1);
   SetLevels(PriceCenter);
  }
//+------------------------------------------------------------------+
//|   Установка уровней Сетки                                        |
//+------------------------------------------------------------------+
void              Grid::SetLevels(double priceCenter)
  {
   for(int i = 0; i <= GridSize; i++)
     {
      Levels[i] = priceCenter - IndexCenter * Step + i * Step;
     }
  }
//+------------------------------------------------------------------+
//|  Печать сетки                                                    |
//+------------------------------------------------------------------+
void              Grid::PrintGrid(void)
  {
   Print("-------------------------------------------------------------");
   Print("Direction: " + (Direction == BUY ? "Покупка" : "Продажа"));
   Print("Price_Center: " + (string)PriceCenter);
   Print("Index_Center: " + (string)IndexCenter);
   Print("StopLoss_Size: " + (string)StopLossSize);
   Print("Grid_Size: " + (string)GridSize);
   Print("Position: " + (string)Position);
   Print("--------------Levels--------------");
   ArrayPrint(Levels, 2, " -- ");
   Print("-------------------------------------------------------------");
  }

//+------------------------------------------------------------------+
//|   Синхронизация Сетки в зависимости от отрытой позиции           |
//+------------------------------------------------------------------+
bool Grid::SetPosition(int position)
  {
   if(position > StopLossSize || position < 1)
      return false;
   Position = position;
   IndexCenter = GridSize - Position;
   PriceCenter = Levels[IndexCenter];
   return true;
  }

//+------------------------------------------------------------------+
//|    Смещение Сетки по тренду, что бы она не закрылась             |
//+------------------------------------------------------------------+
bool Grid::ShiftGrid(int shift = 1)
  {
   if(shift < 1)
      return false;
   PriceCenter += Step * shift;
   SetLevels(PriceCenter);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool             Grid:: ShiftStopLoss(int shift = 1)
  {
   if(shift < 1 || shift >= IndexCenter)
      return false;
   ArrayRemove(Levels, 0,  shift);
   GridSize -= shift;
   StopLossSize -= shift;
   IndexCenter -= shift;
   return true;
  }
//+------------------------------------------------------------------+

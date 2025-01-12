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
//|    Основной класс Сетки                                                              |
//+------------------------------------------------------------------+
class CGrid
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
                     CGrid(void) {}
                     ~CGrid(void) {}
  bool               GridInit(int size, int position, double step, double priceCenter, ENUM_DIRECTION direction);
                    
   void              SetLevels(double priceCenter);
   void              PrintGrid(void);
   bool              SetPosition(int position);
   bool              ShiftGrid(int shift = 1);
   bool              ShiftStopLoss(int shift = 1);
  };
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
bool CGrid::GridInit(int size, int position, double step, double priceCenter, ENUM_DIRECTION direction)
  {
  if(position >= size || position < 1 || step <= 0 || priceCenter <= 0)
  {
      Print("Ошибочные параметры Сетки");
      return false;
  }
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
   return true;
  }
//+------------------------------------------------------------------+
//|   Установка уровней Сетки                                        |
//+------------------------------------------------------------------+
void              CGrid::SetLevels(double priceCenter)
  {
   for(int i = 0; i <= GridSize; i++)
     {
      Levels[i] = priceCenter - IndexCenter * Step + i * Step;
     }
  }
//+------------------------------------------------------------------+
//|  Печать сетки                                                    |
//+------------------------------------------------------------------+
void              CGrid::PrintGrid(void)
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
bool CGrid::SetPosition(int position)
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
bool CGrid::ShiftGrid(int shift = 1)
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
bool             CGrid:: ShiftStopLoss(int shift = 1)
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
// Тестовый комментарий

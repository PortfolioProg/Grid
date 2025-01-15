//+------------------------------------------------------------------+
//|                                                         Grid.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Структура Сетки                                                 |
//+------------------------------------------------------------------+
struct Grid
  {
   //---Основные параметры сетки
   int               GridSize;
   int               PositionSize;
   double            Step;
   double            PriceCenter;
   ENUM_POSITION_TYPE           Direction;
   //---Расчетные параметры сетки
   int               StopLossSize;
   int               IndexCenter;
   double            Levels[];
   double            UpLevels[];
   double            DownLevels[];
  };
//+------------------------------------------------------------------+
//|    Основной класс Сетки                                          |
//+------------------------------------------------------------------+
class CGrid
  {
protected:
   Grid              grid;
   CPositionInfo     *m_position;
public:
                     CGrid(CPositionInfo *m_positionRef);
                    ~CGrid(void){};
   bool               GridInit(int gridSize, int positionSize, double step, double priceCenter, ENUM_POSITION_TYPE direction);
   bool              GridInit(int gridSize, double step);
   void              SetLevels(double priceCenter);
   void              PrintGrid(void);
   bool              SetPosition(int positionSize);
   bool              SetPosition();
   bool              ShiftGrid(int shift = 1);
   bool              ShiftStopLoss(int shift = 1);
   void              GetGrid(Grid &gridRef);
  };
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
CGrid::CGrid(CPositionInfo *m_positionRef)
  {
   this.m_position = m_positionRef;
  }

//+------------------------------------------------------------------+
//| Инициализатор сетки 1                                                 |
//+------------------------------------------------------------------+
bool CGrid::GridInit(int gridSize, int positionSize, double step, double priceCenter, ENUM_POSITION_TYPE direction)
  {
   if(positionSize >= gridSize || positionSize < 1 || step <= 0 || priceCenter <= 0)
     {
      Print("Ошибочные параметры Сетки");
      return false;
     }
//---Инициализация основых параметров сетки
   grid.GridSize = gridSize;
   grid.PositionSize = positionSize;
   grid.Step = (direction == POSITION_TYPE_BUY) ? step : -1 * step;
   grid.PriceCenter = priceCenter;
   grid.Direction = direction;
//---Инициализация расчетных параметров сетки
   grid.IndexCenter = gridSize - positionSize;
   grid.StopLossSize = gridSize - 1;
   ArrayResize(grid.Levels, gridSize + 1);
   SetLevels(priceCenter);
   return true;
  }
//+------------------------------------------------------------------+
//| Инициализатор сетки 2                                                  |
//+------------------------------------------------------------------+
bool CGrid::GridInit(int gridSize, double step)
  {
   int positionSize = (int)m_position.Volume();
   if(positionSize >= gridSize)
     {
      Print("Ошибочные параметры Сетки");
      return false;
     }
//---Инициализация основых параметров сетки
   grid.GridSize = gridSize;
   grid.PositionSize = positionSize;
   grid.Direction = m_position.PositionType();
   grid.Step = (grid.Direction == POSITION_TYPE_BUY) ? step : -1 * step;
   grid.PriceCenter = m_position.PriceOpen();

//---Инициализация расчетных параметров сетки
   grid.IndexCenter = gridSize - positionSize;
   grid.StopLossSize = gridSize - 1;
   ArrayResize(grid.Levels, gridSize + 1);
   SetLevels(grid.PriceCenter);
   return true;
  }
//+------------------------------------------------------------------+
//|   Установка уровней Сетки                                        |
//+------------------------------------------------------------------+
void              CGrid::SetLevels(double priceCenter)
  {
   for(int i = 0; i <= grid.GridSize; i++)
     {
      grid.Levels[i] = priceCenter - grid.IndexCenter * grid.Step + i * grid.Step;
     }
  }
//+------------------------------------------------------------------+
//|  Печать сетки                                                    |
//+------------------------------------------------------------------+
void              CGrid::PrintGrid(void)
  {
   Print("-------------------------------------------------------------");
   Print("Direction: " + (grid.Direction == POSITION_TYPE_BUY ? "Покупка" : "Продажа"));
   Print("Price_Center: " + (string)grid.PriceCenter);
   Print("Index_Center: " + (string)grid.IndexCenter);
   Print("StopLoss_Size: " + (string)grid.StopLossSize);
   Print("Grid_Size: " + (string)grid.GridSize);
   Print("PositionSize: " + (string)grid.PositionSize);
   Print("--------------Levels--------------");
   ArrayPrint(grid.Levels, 2, " -- ");
   Print("-------------------------------------------------------------");
  }

//+------------------------------------------------------------------+
//|   Синхронизация Сетки в зависимости от отрытой позиции           |
//+------------------------------------------------------------------+
bool CGrid::SetPosition(int positionSize)
  {
   if(positionSize > grid.StopLossSize || positionSize < 1)
      return false;
   grid.PositionSize = positionSize;
   grid.IndexCenter = grid.GridSize - grid.PositionSize;
   grid.PriceCenter = grid.Levels[grid.IndexCenter];
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CGrid::SetPosition()
  {
   int positionSize = (int)m_position.Volume();
   if(positionSize > grid.StopLossSize || positionSize < 1)
      return false;
   grid.PositionSize = positionSize;
   grid.IndexCenter = grid.GridSize - grid.PositionSize;
   grid.PriceCenter = grid.Levels[grid.IndexCenter];
   return true;
  }
//+------------------------------------------------------------------+
//|    Смещение Сетки по тренду, что бы она не закрылась             |
//+------------------------------------------------------------------+
bool CGrid::ShiftGrid(int shift = 1)
  {
   if(shift < 1)
      return false;
   grid.PriceCenter += grid.Step * shift;
   this.SetLevels(grid.PriceCenter);
   return true;
  }

//+------------------------------------------------------------------+
//|   Подтягивание СтопЛоса                                          |
//+------------------------------------------------------------------+
bool             CGrid:: ShiftStopLoss(int shift = 1)
  {
   if(shift < 1 || shift >= grid.IndexCenter)
      return false;
   ArrayRemove(grid.Levels, 0,  shift);
   grid.GridSize -= shift;
   grid.StopLossSize -= shift;
   grid.IndexCenter -= shift;
   return true;
  }

//+------------------------------------------------------------------+
//|   Получение сетки                                                |
//+------------------------------------------------------------------+
void            CGrid:: GetGrid(Grid &gridRef)
  {
   this.SetPosition();
   gridRef = this.grid;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

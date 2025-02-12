//+------------------------------------------------------------------+
//|                                                         Grid.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>

struct LevelsGrid
  {
   double            price;
   ENUM_ORDER_TYPE   type;
  };

//+------------------------------------------------------------------+
//| Структура Сетки                                                  |
//+------------------------------------------------------------------+
struct Grid
  {
   //---Основные параметры сетки
   double            PriceCenter;
   int               PositionSize;
   int               GridSize;
   int               DownCountEmptyLevel;
   int               UpCountEmptyLevel;
   //---Расчетные параметры сетки
   int               IndexCenter;
   int               StopLossSize;
   LevelsGrid        Levels[];
   //---Параметры при инициализации сетки
   ENUM_POSITION_TYPE           Direction;
   double            Step;
  };
//+------------------------------------------------------------------+
//|    Основной класс Сетки                                          |
//+------------------------------------------------------------------+
class CGrid
  {
protected:
   Grid              grid;
   bool              gridExist;
   CPositionInfo     *m_position;
   void              SetLevels();
   void              CalculationStopLossSize(void);
   void              CalculationGrid(void);
public:
                     CGrid(CPositionInfo *m_positionRef);
                    ~CGrid(void) {};
   bool              Init(int gridSize, double step);
   void              Deinit();
   bool              GetStatusGrid();
   void              PrintGrid(void);
   bool              UpdateGridByPosition();
   bool              ShiftGrid(int shift = 1);
   bool              AddUpLevelsGrid(int upLevels = 1);
   bool              ShiftStopLoss(int shift = 1);
   void              GetGrid(Grid &gridRef);
   void              GetLevels(LevelsGrid &levelsRef[]);
  };
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
CGrid::CGrid(CPositionInfo *m_positionRef)
  {
   this.m_position = m_positionRef;
  }
//+------------------------------------------------------------------+
//| Расчет сетки                                                 |
//+------------------------------------------------------------------+
void CGrid::CalculationGrid(void)
  {
   if(grid.DownCountEmptyLevel != 0)
     {
      double lastPrice = SymbolInfoDouble(Symbol(), SYMBOL_LAST);
      double countStep = (lastPrice - grid.PriceCenter) / grid.Step;
      if(countStep > 0)
        {
         grid.DownCountEmptyLevel = 0;
        }
      else
        {
         int newCount = (int)MathAbs(countStep) + 1;
         if(newCount < grid.DownCountEmptyLevel)
            grid.DownCountEmptyLevel = newCount;
        }
     }
   grid.IndexCenter = grid.GridSize - grid.PositionSize + grid.DownCountEmptyLevel - grid.UpCountEmptyLevel;
   grid.StopLossSize = grid.PositionSize + grid.IndexCenter - 1 - grid.DownCountEmptyLevel;
   ArrayResize(grid.Levels, grid.GridSize + 1);
   SetLevels();
  }

//+------------------------------------------------------------------+
//| Инициализатор сетки                                                 |
//+------------------------------------------------------------------+
bool CGrid::Init(int gridSize, double step)
  {
   int positionSize = (int)m_position.Volume();
   if(positionSize >= gridSize)
     {
      Print("Ошибочные параметры Сетки");
      this.Deinit();
      return false;
     }
//---Инициализация основых параметров сетки
   grid.PriceCenter = m_position.PriceOpen();
   grid.PositionSize = positionSize;
   grid.GridSize = gridSize;
   grid.DownCountEmptyLevel = 0;
   grid.UpCountEmptyLevel = 0;
   grid.Direction = m_position.PositionType();
   grid.Step = (grid.Direction == POSITION_TYPE_BUY) ? step : -1 * step;
//---Инициализация расчетных параметров сетки
   CalculationGrid();
   //grid.IndexCenter = gridSize - positionSize;
   //grid.StopLossSize = gridSize - 1;
   //ArrayResize(grid.Levels, gridSize + 1);
   //SetLevels();
   gridExist = true;
   return true;
  }
//+------------------------------------------------------------------+
//|   Деинициализация сетки                                          |
//+------------------------------------------------------------------+
void     CGrid::Deinit()
  {
   gridExist = false;
  }
//+------------------------------------------------------------------+
//|    Синхронизация Сетки в зависимости от отрытой позиции       |
//+------------------------------------------------------------------+
bool CGrid::UpdateGridByPosition()
  {
   int positionSize = (int)m_position.Volume();
   if(positionSize > grid.StopLossSize || positionSize < 1)
      return false;
   grid.PositionSize = positionSize;
   grid.IndexCenter = grid.GridSize - grid.PositionSize;
   grid.PriceCenter = grid.Levels[grid.IndexCenter].price;
   if(grid.DownCountEmptyLevel != 0)
     {
      double lastPrice = SymbolInfoDouble(Symbol(), SYMBOL_LAST);
      double countStep = (lastPrice - grid.PriceCenter) / grid.Step;
      if(countStep > 0)
        {
         grid.DownCountEmptyLevel = 0;
        }
      else
        {
         int newCount = (int)MathAbs(countStep) + 1;
         if(newCount < grid.DownCountEmptyLevel)
            grid.DownCountEmptyLevel = newCount;
        }
     }
   CalculationStopLossSize();
   this.SetLevels();
   return true;
  }
//+------------------------------------------------------------------+
//|    Смещение Сетки по тренду, что бы она не закрылась             |
//+------------------------------------------------------------------+
bool CGrid::ShiftGrid(int shift = 1)
  {
   if(shift < 1 || shift > grid.StopLossSize - grid.PositionSize)
      return false;
   grid.PriceCenter = grid.Levels[grid.IndexCenter + shift].price;
   grid.DownCountEmptyLevel = shift;
   CalculationStopLossSize();
   this.SetLevels();
   return true;
  }
//+------------------------------------------------------------------+
//|   Как Смещение, только СтопЛосс остается на месте                |
//+------------------------------------------------------------------+
bool              CGrid::AddUpLevelsGrid(int upLevels = 1)
  {
   grid.UpCountEmptyLevel = upLevels;
   return true;
  }
//+------------------------------------------------------------------+
//|   Подтягивание СтопЛоса                                          |
//+------------------------------------------------------------------+
bool             CGrid::ShiftStopLoss(int shift = 1)
  {
   if(shift < 1 || shift >= grid.IndexCenter)
      return false;
   ArrayRemove(grid.Levels, 0,  shift);
   grid.GridSize -= shift;
   grid.StopLossSize -= shift;
   grid.IndexCenter -= shift;
   this.SetLevels();
   return true;
  }

//+------------------------------------------------------------------+
//|   Установка уровней Сетки                                        |
//+------------------------------------------------------------------+
void              CGrid::SetLevels()
  {
   for(int i = 0; i <= grid.GridSize; i++)
     {
      grid.Levels[i].price = grid.PriceCenter - grid.IndexCenter * grid.Step + i * grid.Step;
      if(i == 0)
        {
         grid.Levels[i].type = (ENUM_ORDER_TYPE)((grid.Direction == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_BUY_STOP);
        }
      else
         if(0 < i && i < grid.IndexCenter - grid.DownCountEmptyLevel)
           {
            grid.Levels[i].type = (ENUM_ORDER_TYPE)((grid.Direction == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT);
           }
         else
            if(grid.IndexCenter - grid.DownCountEmptyLevel <= i && i <= grid.IndexCenter)
              {
               grid.Levels[i].type = ORDER_TYPE_CLOSE_BY;
              }
            else
               if(i > grid.IndexCenter)
                 {
                  grid.Levels[i].type = (ENUM_ORDER_TYPE)((grid.Direction == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL_LIMIT : ORDER_TYPE_BUY_LIMIT);
                 }
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
   ArrayPrint(grid.Levels);
   Print("-------------------------------------------------------------");
  }

//+------------------------------------------------------------------+
//|   Получение сетки                                                |
//+------------------------------------------------------------------+
void            CGrid::GetGrid(Grid &gridRef)
  {
   this.UpdateGridByPosition();
   gridRef = this.grid;
  }
//+------------------------------------------------------------------+
//|   Получение уровней сетки                                        |
//+------------------------------------------------------------------+
void              CGrid::GetLevels(LevelsGrid &levelsRef[])
  {
   this.UpdateGridByPosition();
   ArrayCopy(levelsRef, grid.Levels);
  }
//+------------------------------------------------------------------+
//|   Расчет Размера СтопЛосса                                             |
//+------------------------------------------------------------------+
void            CGrid::CalculationStopLossSize(void)
  {
   grid.StopLossSize = grid.PositionSize + grid.IndexCenter - grid.DownCountEmptyLevel - 1;
  }
//+------------------------------------------------------------------+
//|  Получение статуса. Сетка работает или нет                       |
//+------------------------------------------------------------------+
bool CGrid::GetStatusGrid(void)
  {
   return gridExist;
  }
//+------------------------------------------------------------------+

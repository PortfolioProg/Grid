//+------------------------------------------------------------------+
//|                                                  OrdersArray.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\OrderInfo.mqh>
#include "MyExpertTrade.mqh"
#include "Grid.mqh"
//--- подключаем Функции для работы с Массивами
#include "MyArray.mqh"
//+------------------------------------------------------------------+
//| Структура Массива Ордеров                                        |
//+------------------------------------------------------------------+
struct Orders
{
   ulong             ticket;
   double            price;
   ENUM_ORDER_TYPE   type;
};
//+------------------------------------------------------------------+
//|    Основной класс Массива Выставленных (Открытых) Ордеров        |
//+------------------------------------------------------------------+
class            COrdersArray
{
   Orders            orders[];
   int               ordersCount;
   COrderInfo        *m_order;
   CMyExpertTrade    *m_trade;
   CGrid             *m_grid;

public:
                     COrdersArray(COrderInfo *m_orderRef, CMyExpertTrade  *m_tradeRef, CGrid *m_gridRef);
   void              UpdateOrders();
   void              GetOrders(Orders &ordersRef[]);
   void              OrdersPrint();
   void              SynhronizingTickersWithGrid();
};

//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
COrdersArray::COrdersArray(COrderInfo *m_orderRef, CMyExpertTrade  *m_tradeRef, CGrid *m_gridRef)
{
   this.m_order = m_orderRef;
   this.m_trade = m_tradeRef;
   this.m_grid = m_gridRef;
}

//+------------------------------------------------------------------+
//|   Получение Тикетов Открытых Ордеров                             |
//+------------------------------------------------------------------+
void           COrdersArray::UpdateOrders()
{
   ordersCount = OrdersTotal();
   ArrayResize(orders, ordersCount);
   for(int i = 0; i < ordersCount; i++)
   {
      m_order.SelectByIndex(i);
      orders[i].ticket = m_order.Ticket();
      orders[i].price = m_order.PriceOpen();
      orders[i].type = m_order.OrderType();
   }
}
//+------------------------------------------------------------------+
//|    Передача Тикетов Открытых Ордеров в полученный массив         |
//+------------------------------------------------------------------+
void           COrdersArray::GetOrders(Orders &ordersRef[])
{
   ArrayCopy(ordersRef,orders);
}
//+------------------------------------------------------------------+
//|    Печать массива Тикетов Открытых Ордеров                       |
//+------------------------------------------------------------------+
void           COrdersArray::OrdersPrint()
{
   UpdateOrders();
   Print("-----------------------------------------");
   for(int i = 0; i < ordersCount; i++)
   {
      Print("Тикет: "+ (string)orders[i].ticket +" Цена: "+ (string)orders[i].price +" Тип: " + EnumToString(orders[i].type));
   }
}
//+------------------------------------------------------------------+
//|    Синхронизация Ордеров по Сетке                                |
//+------------------------------------------------------------------+
void COrdersArray::SynhronizingTickersWithGrid()
{
   Grid grid;
   m_grid.GetGrid(grid);
   this.UpdateOrders();
   Print("---------------------------");
   for(int i = 0; i <= grid.GridSize; i++)
   {
      for(int j =0; j < ordersCount; j++)
      {
         if(grid.Levels[i] == orders[j].price)
         {
            if(grid.Direction == POSITION_TYPE_BUY)
            {
               if(i == 0)
               {
                  if(orders[j].type != ORDER_TYPE_SELL_STOP)
                  {
                     Print("Отправили ORDER_TYPE_SELL_STOP по цене - " + grid.Levels[i]);
                     //OpenShort(grid.Levels[i], 0, 0, grid.StopLossSize, "stopOrder");
                     break;
                  }
               }
               else if(0 < i && i < grid.IndexCenter)
               {
                  if(orders[j].type != ORDER_TYPE_BUY_LIMIT)
                  {
                     Print("Отправили ORDER_TYPE_BUY_LIMIT по цене - " + grid.Levels[i]);
                     //OpenLong(grid.Levels[i], 0, 0, 1);
                     break;
                  }
               }
               else if(i == grid.IndexCenter)
                  break;
               else if(i > grid.IndexCenter)
               {
                  if(orders[j].type != ORDER_TYPE_SELL_LIMIT)
                  {
                     Print("Отправили ORDER_TYPE_SELL_LIMIT по цене - " + grid.Levels[i]);
                     //OpenShort(grid.Levels[i], 0, 0, 1);
                     break;
                  }
               }
            }
            if(grid.Direction == POSITION_TYPE_SELL)
            {
               if(i == 0)
               {
                  if(orders[j].type != ORDER_TYPE_BUY_STOP)
                  {
                     Print("Отправили ORDER_TYPE_BUY_STOP по цене - " + grid.Levels[i]);
                     //OpenShort(grid.Levels[i], 0, 0, grid.StopLossSize, "stopOrder");
                     break;
                  }
               }
               else if(0 < i && i < grid.IndexCenter)
               {
                  if(orders[j].type != ORDER_TYPE_SELL_LIMIT)
                  {
                     Print("Отправили ORDER_TYPE_SELL_LIMIT по цене - " + grid.Levels[i]);
                     //OpenLong(grid.Levels[i], 0, 0, 1);
                     break;
                  }
               }
               else if(i == grid.IndexCenter)
                  break;
               else if(i > grid.IndexCenter)
               {
                  if(orders[j].type != ORDER_TYPE_BUY_LIMIT)
                  {
                     Print("Отправили ORDER_TYPE_BUY_LIMIT по цене - " + grid.Levels[i]);
                     //OpenShort(grid.Levels[i], 0, 0, 1);
                     break;
                  }
               }
            }
            ArrayRemove(orders, j, 1);
            ordersCount--;
            break;
         }
      }
   }
   for(int i = 0; i < ordersCount; i++)
   {
      //m_trade.OrderDelete(orders[i].ticket);
      Print("Удалили ордер с Тикетом - " + orders[i].ticket + " С ценой - " + orders[i].price);
   }
//Print("grid.Levels: " + (string)grid.Levels[i] + " || ordersPrice[j]: " + (string)ordersPrice[j]);
//Print("ordersType " + j + ": "+ EnumToString(ordersType[j]));
}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  OrdersArray.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//Главный класс Эксперта
#include <Expert\Expert.mqh>
#include <Trade\OrderInfo.mqh>
//#include <Expert\ExpertTrade.mqh>
#include "MyExpertTrade.mqh"
#include "Grid.mqh"
//--- подключаем Функции для работы с Массивами
#include "MyArray.mqh"
//Опережающее объявление, что бы была возмжность использовать функции объекта CMyExpert. На ошибки не обращать внимание. Компилятор "гонит".
class CMyExpert;
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
   CMyExpert			*m_expert;
   void              UpdateOrders();
   void              SendOrder(double price, ENUM_ORDER_TYPE type, int StopLossSize);
public:
                     COrdersArray(COrderInfo *m_orderRef, CMyExpertTrade  *m_tradeRef, CGrid *m_gridRef, CMyExpert *m_expertRef);
   void              GetOrders(Orders &ordersRef[]);
   void              OrdersPrint();
   bool              SynhronizingOrdersWithGrid();
   void Set_m_trade(CExpertTrade  *m_tradeRef){
      this.m_trade = m_tradeRef;
   }
};

//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
COrdersArray::COrdersArray(COrderInfo *m_orderRef, CMyExpertTrade  *m_tradeRef, CGrid *m_gridRef, CMyExpert *m_expertRef)
{
   this.m_order = m_orderRef;
   this.m_trade = m_tradeRef;
   this.m_grid = m_gridRef;
   this.m_expert = m_expertRef;
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
//|    Отправка ордеров Ордеров                                      |
//+------------------------------------------------------------------+
void COrdersArray::SendOrder(double price, ENUM_ORDER_TYPE type, int StopLossSize)
{
   switch(type)
   {
   case ORDER_TYPE_SELL_STOP:
      m_expert.OpenShort(price, 0, 0, StopLossSize, "stopOrder");
      Print("Отправили ORDER_TYPE_SELL_STOP по цене - " + (string)price);
      break;
   case ORDER_TYPE_BUY_STOP:
      m_expert.OpenLong(price, 0, 0, StopLossSize, "stopOrder");
      Print("Отправили ORDER_TYPE_BUY_STOP по цене - " + (string)price);
      break;
   case ORDER_TYPE_SELL_LIMIT:
      m_expert.OpenShort(price, 0, 0, 1);
      Print("Отправили ORDER_TYPE_SELL_LIMIT по цене - " + (string)price);
      break;
   case ORDER_TYPE_BUY_LIMIT:
      m_expert.OpenLong(price, 0, 0, 1);
      Print("Отправили ORDER_TYPE_BUY_LIMIT по цене - " + (string)price);
      break;
   }
}
//+------------------------------------------------------------------+
//|    Синхронизация Ордеров по Сетке                                |
//+------------------------------------------------------------------+
bool COrdersArray::SynhronizingOrdersWithGrid()
{
   Grid grid;
   if(!m_grid.GetStatusGrid())
      return false;
   m_grid.GetGrid(grid);
   this.UpdateOrders();
   Print("---------------------------");
   for(int i = 0; i <= grid.GridSize; i++)
   {
      bool gridPriceExist = false;
      for(int j =0; j < ordersCount; j++)
      {
         if(grid.Levels[i].price == orders[j].price)
         {
            gridPriceExist = true;
            if(grid.Levels[i].type != orders[j].type)
            {
               this.SendOrder(grid.Levels[i].price, grid.Levels[i].type, grid.StopLossSize);
               break;
            }
            ArrayRemove(orders, j, 1);
            ordersCount--;
            break;
         }
      }
      if(!gridPriceExist)
         this.SendOrder(grid.Levels[i].price, grid.Levels[i].type, grid.StopLossSize);
   }
   for(int i = 0; i < ordersCount; i++)
   {
      m_trade.OrderDelete(orders[i].ticket);
      Print("Удалили ордер с Тикетом - " + (string)orders[i].ticket + " С ценой - " + (string)orders[i].price);
   }
//Print("grid.Levels: " + (string)grid.Levels[i] + " || ordersPrice[j]: " + (string)ordersPrice[j]);
//Print("ordersType " + j + ": "+ EnumToString(ordersType[j]));
   return true;
}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                 OrdersArray.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\OrderInfo.mqh>
#include "MyExpertTrade.mqh"
#include "Grid.mqh"

//+------------------------------------------------------------------+
//|    Основной класс Массива Выставленных (Открытых) Ордеров                                                              |
//+------------------------------------------------------------------+
class            COrdersArray
  {
   ulong             ordersTicket[];
   double            ordersPrice[];
   ENUM_ORDER_TYPE   ordersType[];
   int               ordersCount;
   COrderInfo        *m_order;
   CMyExpertTrade    *m_trade;
   CGrid             *m_grid;

public:
                     COrdersArray(COrderInfo *m_orderRef, CMyExpertTrade  *m_tradeRef, CGrid *m_gridRef);
   void              UpdateOrders();
   void              GetTickets(ulong &ticketsRef[]);
   void              TicketsPrint();
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
//|   Получение Тикетов Открытых Ордеров                                                               |
//+------------------------------------------------------------------+
void           COrdersArray::UpdateOrders()
  {
   ordersCount = OrdersTotal();
   ArrayResize(ordersTicket, ordersCount);
   ArrayResize(ordersPrice, ordersCount);
   ArrayResize(ordersType, ordersCount);
   for(int i = 0; i < ordersCount; i++)
     {
      m_order.SelectByIndex(i);
      ordersTicket[i] = m_order.Ticket();
      ordersPrice[i] = m_order.PriceOpen();
      ordersType[i] = m_order.OrderType();
     }
  }
//+------------------------------------------------------------------+
//|    Передача Тикетов Открытых Ордеров в полученный массив                                                              |
//+------------------------------------------------------------------+
void           COrdersArray::GetTickets(ulong &ticketsRef[])
  {
   ArrayCopy(ticketsRef,ordersTicket);
  }
//+------------------------------------------------------------------+
//|    Печать массива Тикетов Открытых Ордеров                                                            |
//+------------------------------------------------------------------+
void           COrdersArray::TicketsPrint()
  {
   UpdateOrders();
   ArrayPrint(ordersTicket);
  }
//+------------------------------------------------------------------+
//|    Синхронизая Ордеров по Сетке                                                           |
//+------------------------------------------------------------------+
this.UpdateOrders();
Grid grid;
m_grid.GetGrid(grid);
for(int i = 0; i <= grid.GridSize; i++)
{
  for(int j =0; j < ordersCount; j++)
  {
    if(grid.Levels[i] == ordersPrice[j])
    {
      
    }
  }
}


//+------------------------------------------------------------------+

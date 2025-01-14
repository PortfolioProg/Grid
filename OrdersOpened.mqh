//+------------------------------------------------------------------+
//|                                                 OrdersOpened.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//|    Основной класс Массива Выставленных (Открытых) Ордеров                                                              |
//+------------------------------------------------------------------+
class            COrdersOpened
  {
   ulong             tickets[];
   COrderInfo        *m_order;

public:
                     COrdersOpened(COrderInfo *m_orderRef);
   void              UpdateTickets();
   void              GetTickets(ulong &ticketsRef[]);
   void              TicketsPrint();
  };

//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
COrdersOpened::COrdersOpened(COrderInfo *m_orderRef)
  {
   this.m_order = m_orderRef;
  }

//+------------------------------------------------------------------+
//|   Получение Тикетов Открытых Ордеров                                                               |
//+------------------------------------------------------------------+
void           COrdersOpened::UpdateTickets()
  {
   int ordersCount = OrdersTotal();
   ArrayResize(tickets, ordersCount);
   for(int i = 0; i < ordersCount; i++)
     {
      m_order.SelectByIndex(i);
      tickets[i] = m_order.Ticket();
     }
  }
//+------------------------------------------------------------------+
//|    Передача Тикетов Открытых Ордеров в полученный массив                                                              |
//+------------------------------------------------------------------+
void           COrdersOpened::GetTickets(ulong &ticketsRef[])
  {
   ArrayCopy(ticketsRef,tickets);
  }
//+------------------------------------------------------------------+
//|    Печать массива Тикетов Открытых Ордеров                                                            |
//+------------------------------------------------------------------+
void           COrdersOpened::TicketsPrint()
  {
   UpdateTickets();
   ArrayPrint(tickets);
  }
//+------------------------------------------------------------------+

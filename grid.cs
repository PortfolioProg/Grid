using System;
using System.Linq;
using System.Collections.Generic;



namespace SpaceGrid;

public static class Program
{
        public static void Main()
        {
                Grid grid = new Grid("Buy", 100, 3, 5, 1);
                grid.PrintGrid();

                grid.SetPosition(2);
                Console.WriteLine("grid.SetPosition(2)");
                grid.PrintGrid();

                grid.ShiftSL();
                Console.WriteLine("grid.ShiftSL()");
                grid.PrintGrid();

                grid.ShiftGrid(2);
                Console.WriteLine("grid.ShiftGrid(2)");
                grid.PrintGrid();


                List<Order> orders = new List<Order>(1) { new Order(101, "Buy") };
                Order.OrdersPrint(orders);

                orders = grid.SynchOrders(orders);
                Order.OrdersPrint(orders);
        }

        public class Grid
        {

                public string Direction { get; private set; }
                public double Price { get; private set; }
                public int Position { get; private set; }
                public int Size { get; private set; }
                public double Step { get; private set; }
                public int SL { get; private set; }
                public int IndexCenter { get; private set; }
                private List<double> Levels { get; set; }
                private List<double> UpLevels { get; set; }
                private List<double> DownLevels { get; set; }
                private int k_direction;

                public Grid(string direction, double initPrice, int position, int size, double step)
                {
                        Direction = direction;
                        Price = initPrice;
                        Position = position;
                        Size = size;
                        Step = step;

                        IndexCenter = Size - Position;
                        SL = Size - 1;
                        k_direction = direction == "Buy" ? 1 : -1;
                        Levels = new List<double>(size + 1);
                        for (int i = 0; i <= size; i++)
                        {
                                Levels.Add(initPrice - k_direction * (IndexCenter * step) + k_direction * i * step);
                        }

                }


                public void PrintGrid()
                {
                        Console.WriteLine(new string('-', 7));
                        foreach (var lvl in Levels)
                        {
                                Console.WriteLine(lvl);
                        }
                        Console.WriteLine(new string('-', 7));
                        Console.WriteLine($"Size: {Size}");
                        Console.WriteLine($"SL: {SL}");
                        Console.WriteLine($"Position: {Position}");
                        Console.WriteLine($"Price: {Price}");
                        Console.WriteLine($"IndexCenter: {IndexCenter}");
                        Console.WriteLine("DownLevels: " + string.Join(", ", GetDownLevels()));
                        Console.WriteLine("UpLevels: " + string.Join(", ", GetUpLevels()));
                        Console.WriteLine("StopLevel: " + GetStopLevel());
                        Console.WriteLine("CenterLevel: " + GetCenterLevel());

                        Console.WriteLine(new string('-', 25));
                }

                public bool SetPosition(int position)
                {
                        if (position > SL || position < 1)
                                return false;
                        Position = position;
                        IndexCenter = Size - Position;
                        Price = Levels[IndexCenter];
                        return true;
                }

                public bool ShiftSL(int shift = 1)
                {
                        if (shift < 1 || shift >= IndexCenter)
                                return false;
                        Levels.RemoveRange(0, shift);
                        Size -= shift;
                        SL -= shift;
                        IndexCenter -= shift;
                        return true;
                }

                public bool ShiftGrid(int shift = 1)
                {
                        if (shift < 1)
                                return false;
                        for (int i = 0; i < shift; i++)
                        {
                                Levels.Add(Levels[Size + i] + k_direction * Step);
                        }
                        Levels.RemoveRange(0, shift);
                        Price += k_direction * Step * shift;
                        return true;
                }

                public List<double> GetLevels()
                {
                        return Levels;
                }


                public List<double> GetDownLevels()
                {
                        var downLevels = new List<double>();
                        for (int i = 1; i < IndexCenter; i++)
                        {
                                downLevels.Add(Levels[i]);
                        }
                        return downLevels;
                }

                public List<double> GetUpLevels()
                {
                        var UpLevels = new List<double>();
                        for (int i = IndexCenter + 1; i <= Size; i++)
                        {
                                UpLevels.Add(Levels[i]);
                        }
                        return UpLevels;
                }

                public double GetStopLevel()
                {
                        return Levels[0];
                }
                public double GetCenterLevel()
                {
                        return Levels[IndexCenter];
                }

                public List<Order> SynchOrders(List<Order> orders, bool onlyDown = false)
                {
                        var newOrders = new List<Order>(Size);
                        if (orders.Any())
                        {
                                for (int i = orders.Count - 1; i >= 0; i--)
                                {
                                        if (orders[i].Price == Levels[0] && orders[i].Type == (k_direction == 1 ? "SellStop" : "BuyStop"))
                                        {
                                                orders.RemoveAt(i);
                                                break;
                                        }
                                }
                        }
                        newOrders.Add(new Order(Levels[0], k_direction == 1 ? "SellStop" : "BuyStop"));
                        Order.OrderSend(Levels[0], k_direction == 1 ? "SellStop" : "BuyStop");

                        if (orders.Any())
                        {
                                foreach (var order in orders)
                                {
                                        order.OrderDelete();
                                }
                        }

                        return newOrders;
                }
        }

        public class Order
        {
                public double Price { get; set; }
                public string Type { get; set; }

                public Order(double price = 0, string type = "")
                {
                        Price = price;
                        Type = type;
                }

                public static bool OrdersPrint(List<Order> orders)
                {
                        if (!orders.Any()) return false;
                        foreach (var order in orders)
                        {
                                Console.WriteLine($"Order. Price: {order.Price}, Type: {order.Type}");
                        }
                        Console.WriteLine(new string('-', 25));
                        return true;
                }

                public static void OrderSend(double price, string type)
                {
                        Console.WriteLine($"OrderSend. Price: {price}, Type: {type}");
                }

                public void OrderDelete()
                {
                        Console.WriteLine($"OrderDelete. Price: {Price}, Type: {Type}");
                }
        }
}


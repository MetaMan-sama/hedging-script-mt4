//+------------------------------------------------------------------+
//|                        HedgingScript.mq4                         |
//|     Places counter-orders to hedge existing positions            |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input string HedgeSymbol = "EURUSD";      // Symbol to hedge
input double LotSize = 0.1;               // Lot size for the hedge order
input bool CloseHedgeOnProfit = true;     // Automatically close hedge when in profit
input double HedgeProfitThreshold = 10.0; // Profit threshold for closing the hedge (in currency)

//+------------------------------------------------------------------+
//| Main Function                                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Hedging Script Started.");

   if (!CheckSymbol(HedgeSymbol)) {
      Print("Symbol not available: ", HedgeSymbol);
      return;
   }

   // Check for existing open positions
   int existingTicket = FindOpenPosition(HedgeSymbol);
   if (existingTicket < 0) {
      Print("No existing positions found for ", HedgeSymbol, ". Exiting script.");
      return;
   }

   // Place a counter-order (hedge)
   int hedgeTicket = PlaceHedgeOrder(HedgeSymbol, LotSize);
   if (hedgeTicket < 0) {
      Print("Failed to place hedge order.");
      return;
   }

   Print("Hedge placed. Monitoring hedge position...");

   // Monitor the hedge position
   if (CloseHedgeOnProfit) {
      MonitorHedgeProfit(hedgeTicket);
   }

   Print("Hedging Script Completed.");
}

//+------------------------------------------------------------------+
//| Check if the symbol is available                                |
//+------------------------------------------------------------------+
bool CheckSymbol(string symbol)
{
   if (MarketInfo(symbol, MODE_BID) <= 0) {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Find an open position for the specified symbol                  |
//+------------------------------------------------------------------+
int FindOpenPosition(string symbol)
{
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == symbol) {
            return OrderTicket();
         }
      }
   }
   return -1; // No open position found
}

//+------------------------------------------------------------------+
//| Place a hedge order                                             |
//+------------------------------------------------------------------+
int PlaceHedgeOrder(string symbol, double lotSize)
{
   double price = MarketInfo(symbol, MODE_ASK);
   double slippage = 3;

   int ticket = OrderSend(
      symbol,                // Symbol
      OP_SELL,               // Hedge with sell order (counter-order to a buy position)
      lotSize,               // Lot size
      NormalizeDouble(price, MarketInfo(symbol, MODE_DIGITS)), // Price
      (int)slippage,         // Slippage
      0,                     // Stop Loss
      0,                     // Take Profit
      "Hedge Order",         // Comment
      0,                     // Magic number
      0,                     // Expiration
      clrRed                 // Color
   );

   if (ticket < 0) {
      Print("Failed to place hedge order. Error: ", GetLastError());
      return -1;
   }

   Print("Hedge order placed. Ticket: ", ticket, " | Lot Size: ", lotSize);
   return ticket;
}

//+------------------------------------------------------------------+
//| Monitor the hedge position for profit                          |
//+------------------------------------------------------------------+
void MonitorHedgeProfit(int ticket)
{
   while (true) {
      if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
         Print("Hedge position not found. Exiting monitoring.");
         return;
      }

      // Check if the hedge position is closed
      if (OrderCloseTime() > 0) {
         Print("Hedge position already closed.");
         return;
      }

      // Check profit of the hedge position
      double profit = OrderProfit();
      if (profit >= HedgeProfitThreshold) {
         Print("Hedge profit threshold reached: ", profit, ". Closing hedge...");
         if (CloseHedgePosition(ticket)) {
            Print("Hedge closed successfully.");
            return;
         }
      }

      Sleep(1000); // Check every second
   }
}

//+------------------------------------------------------------------+
//| Close the hedge position                                        |
//+------------------------------------------------------------------+
bool CloseHedgePosition(int ticket)
{
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
      Print("Failed to select hedge position. Error: ", GetLastError());
      return false;
   }

   double closePrice = MarketInfo(OrderSymbol(), MODE_BID);
   bool result = OrderClose(ticket, OrderLots(), closePrice, 3, clrGreen);

   if (!result) {
      Print("Failed to close hedge position. Error: ", GetLastError());
      return false;
   }

   return true;
}

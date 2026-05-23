# Hedging Script — MQL4 Script

A MetaTrader 4 script that automates **counter-order hedging** of an existing open position on a configurable symbol — locating the open position via `FindOpenPosition()`, placing an opposing `OP_SELL` order at the current Ask price via `PlaceHedgeOrder()`, and optionally monitoring the hedge position in a `MonitorHedgeProfit()` loop that automatically closes the hedge via `OrderClose()` when the running profit reaches the configurable `HedgeProfitThreshold`.

---

## Overview

Hedging — placing a counter-position to an existing trade — is a risk management technique used to lock in current exposure, limit further loss, or protect an unrealized profit while keeping the original position open. Rather than closing a losing trade and realizing the loss, a hedge freezes the net exposure by opening an equal and opposite position, effectively capping the loss at the current level until market conditions clarify. This script provides a complete one-click hedging workflow: it validates the hedge symbol availability, finds the first open position on the symbol, places a hedge order of the same lot size in the opposite direction, then enters a second monitoring loop that checks `OrderProfit()` on the hedge ticket every second and closes it when it crosses `HedgeProfitThreshold` — automating the harvest of the hedge profit when the market reverses.

---

## Features

- **`CheckSymbol()` availability validation** — calls `MarketInfo(HedgeSymbol, MODE_BID) <= 0` before any order activity; aborts with a log message if the symbol is unavailable
- **`FindOpenPosition()` ticket resolver** — iterates `OrdersTotal()` via `OrderSelect(i, SELECT_BY_POS, MODE_TRADES)`, returning the first ticket matching `OrderSymbol() == HedgeSymbol`; returns `-1` if no open position is found
- **Opposing-direction `PlaceHedgeOrder()`** — fetches `MarketInfo(symbol, MODE_ASK)` for the hedge price, dispatches `OrderSend()` with `OP_SELL` (counter to assumed long exposure), `LotSize`, normalized price, and 3-point slippage; returns the ticket or `-1` on failure
- **`CloseHedgeOnProfit` conditional monitor** — when `true`, enters `MonitorHedgeProfit()` which loops `Sleep(1000)` per iteration, calls `OrderSelect(ticket, SELECT_BY_TICKET)`, checks `OrderCloseTime() > 0` for already-closed guard, evaluates `OrderProfit() >= HedgeProfitThreshold`, and calls `OrderClose()` with current Bid price on threshold breach
- **`CloseHedgePosition()`** — standalone close function using `OrderClose(ticket, OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3, clrGreen)` with full error logging on failure
- All events — hedge placement, profit monitoring values, closure success/failure — logged to the MT4 **Experts** tab

---

## How It Works

1. `CheckSymbol(HedgeSymbol)` validates availability; aborts on failure
2. `FindOpenPosition(HedgeSymbol)` locates the existing position ticket; aborts if `-1`
3. `PlaceHedgeOrder(HedgeSymbol, LotSize)` dispatches `OP_SELL` hedge order; aborts on `-1` return
4. If `CloseHedgeOnProfit = true`: `MonitorHedgeProfit(hedgeTicket)` enters 1-second loop checking `OrderProfit() >= HedgeProfitThreshold` → calls `CloseHedgePosition(hedgeTicket)` on breach

---

## Input Parameters

| Parameter              | Type   | Default  | Description                                                            |
|------------------------|--------|----------|------------------------------------------------------------------------|
| `HedgeSymbol`          | string | `EURUSD` | Symbol on which to find the existing position and place the hedge      |
| `LotSize`              | double | `0.1`    | Lot size for the counter-order hedge position                          |
| `CloseHedgeOnProfit`   | bool   | `true`   | Automatically close the hedge when profit threshold is reached         |
| `HedgeProfitThreshold` | double | `1.0`    | Profit in account currency at which to automatically close the hedge   |

---

## Installation

1. Copy `Hedging_Script_001.mq4` to `MQL4/Scripts/` in your MT4 data folder
2. Compile in MetaEditor (F7)
3. Drag onto any chart from Navigator → Scripts
4. Configure inputs and click **OK**

> **Warning:** This script places a real counter-order and optionally manages it in a live monitoring loop. Always test on a **demo account** first.

> **Note:** The script assumes an existing open position in the `OP_BUY` direction when placing an `OP_SELL` hedge. Verify the directionality matches your exposure before running on a live account.

---

## Requirements

- MetaTrader 4 (`#property strict` compatible build)
- MQL4 compiler (MetaEditor)
- An existing open position on `HedgeSymbol`

---

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

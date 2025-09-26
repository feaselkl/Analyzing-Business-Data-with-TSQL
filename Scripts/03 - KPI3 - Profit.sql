USE [WideWorldImporters];
GO

/* ============================================================
   KPI 3: Profit
   Profit = Revenue - Cost of Goods Sold
   ============================================================
   Steps:
   1. Calculate revenue and quantity per StockItemID
   2. Join with StockItemHoldings to get cost
   3. Derive profit at both item-level and total-level
   ============================================================
*/

/* Step 1: Base CTE - revenue and quantity per stock item */
WITH OrderMetrics AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
        SUM(ol.Quantity) AS Quantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)

/* Step 2: Total Revenue, Cost, and Profit */
SELECT
    CAST(SUM(o.Revenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(o.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalCost,
    CAST(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalProfit
FROM OrderMetrics o
INNER JOIN Warehouse.StockItems si
    ON o.StockItemID = si.StockItemID
INNER JOIN Warehouse.StockItemHoldings sih
    ON si.StockItemID = sih.StockItemID;


/* Step 3: Most Profitable Products (all-time) */
WITH OrderMetrics AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
        SUM(ol.Quantity) AS Quantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)
SELECT
    si.StockItemName,
    CAST(SUM(o.Revenue) AS DECIMAL(18,2)) AS Revenue,
    CAST(SUM(o.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS Cost,
    CAST(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS Profit
FROM OrderMetrics o
INNER JOIN Warehouse.StockItems si
    ON o.StockItemID = si.StockItemID
INNER JOIN Warehouse.StockItemHoldings sih
    ON si.StockItemID = sih.StockItemID
GROUP BY si.StockItemName
ORDER BY Profit DESC;


/* Step 4: Per-item revenue, cost, profit with totals */
WITH OrderMetrics AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
        SUM(ol.Quantity) AS Quantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
),
Metrics AS
(
    SELECT
        si.StockItemName,
        SUM(o.Revenue) AS Revenue,
        SUM(o.Quantity * sih.LastCostPrice) AS Cost,
        SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit
    FROM OrderMetrics o
    INNER JOIN Warehouse.StockItems si
        ON o.StockItemID = si.StockItemID
    INNER JOIN Warehouse.StockItemHoldings sih
        ON si.StockItemID = sih.StockItemID
    GROUP BY si.StockItemName
)
SELECT
    m.StockItemName,
    CAST(m.Revenue AS DECIMAL(18,2)) AS Revenue,
    CAST(m.Cost AS DECIMAL(18,2)) AS Cost,
    CAST(m.Profit AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(m.Revenue) OVER () AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(m.Cost) OVER () AS DECIMAL(18,2)) AS TotalCost,
    CAST(SUM(m.Profit) OVER () AS DECIMAL(18,2)) AS TotalProfit
FROM Metrics m
ORDER BY Profit DESC;

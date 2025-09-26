USE [WideWorldImporters];
GO

/* ============================================================
   KPI 2: Cost of Goods Sold (COGS)
   ============================================================
   Steps:
   1. Aggregate quantity sold per StockItemID
   2. Join to StockItems and StockItemHoldings
   3. Calculate cost per item and total cost
   ============================================================
*/

/* Step 1: Inspect raw quantities per stock item */
SELECT 
    ol.StockItemID,
    SUM(ol.Quantity) AS TotalQuantity
FROM Sales.OrderLines ol
GROUP BY ol.StockItemID
ORDER BY ol.StockItemID;

/* Step 2: Create a CTE for total quantity sold per stock item */
WITH OrderQuantities AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.Quantity) AS TotalQuantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)
SELECT * 
FROM OrderQuantities
ORDER BY StockItemID;

/* Step 3: Join CTE with StockItems and StockItemHoldings 
   to calculate per-item cost */
WITH OrderQuantities AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.Quantity) AS TotalQuantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)
SELECT
    si.StockItemID,
    si.StockItemName,
    sih.LastCostPrice,
    o.TotalQuantity,
    CAST(o.TotalQuantity * sih.LastCostPrice AS DECIMAL(18,2)) AS ItemCost
FROM OrderQuantities o
INNER JOIN Warehouse.StockItems si
    ON o.StockItemID = si.StockItemID
INNER JOIN Warehouse.StockItemHoldings sih
    ON si.StockItemID = sih.StockItemID
ORDER BY ItemCost DESC;

/* Step 4: Calculate total COGS across all items */
WITH OrderQuantities AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.Quantity) AS TotalQuantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)
SELECT
    CAST(SUM(o.TotalQuantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalCOGS
FROM OrderQuantities o
INNER JOIN Warehouse.StockItems si
    ON o.StockItemID = si.StockItemID
INNER JOIN Warehouse.StockItemHoldings sih
    ON si.StockItemID = sih.StockItemID;

/* Step 5: Bonus – format result for reporting */
WITH OrderQuantities AS
(
    SELECT
        ol.StockItemID,
        SUM(ol.Quantity) AS TotalQuantity
    FROM Sales.OrderLines ol
    GROUP BY ol.StockItemID
)
SELECT
    FORMAT(SUM(o.TotalQuantity * sih.LastCostPrice), 'C', 'en-US') AS TotalCOGS
FROM OrderQuantities o
INNER JOIN Warehouse.StockItems si
    ON o.StockItemID = si.StockItemID
INNER JOIN Warehouse.StockItemHoldings sih
    ON si.StockItemID = sih.StockItemID;

USE [WideWorldImporters]
GO
/* KPI 2:  Cost */

-- Estimate cost of goods sold
-- This is a lot harder to do in Wide World Importers than we'd hope!

-- We can use a Common Table Expression (CTE) to act as a subquery
-- CTEs take the following shape:  WITH cteName AS ()
-- We can reference the results of a CTE as though it were a table
-- Note that CTEs are not materialized (unlike Oracle/Postgres)

-- We want the quantity per stock item ID and to multiply it by
-- latest cost price.  Step 1:  get quantity sold per stock item:
SELECT
	ol.StockItemID,
	SUM(ol.Quantity) AS Quantity
FROM Sales.OrderLines ol
GROUP BY
	ol.StockItemID;

-- To use this, we'll wrap it in a CTE
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	*
FROM orders o;

-- Now we can join the results to other tables
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	si.StockItemID,
	si.StockItemName,
	sih.LastCostPrice,
	o.Quantity,
	o.Quantity * sih.LastCostPrice AS Cost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- How much has WWI spent on COGS?
-- Note that we're aggregating on two separate levels.
-- Having an intermediary CTE makes it easier for us to do this.
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	SUM(o.Quantity * sih.LastCostPrice) AS TotalCost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- Bonus: formatting
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$0,###.##') AS TotalCost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;
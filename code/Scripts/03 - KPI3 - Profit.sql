USE [WideWorldImporters]
GO
/* KPI 3:  Profit */

-- Business question: "What is our profit per product, and what's the overall total?"

-- We will define profit:  Profit = Revenue - Cost of Goods Sold
-- There's a lot more to accounting profit than this, naturally,
-- but this isn't an accounting course!

-- We can calculate revenue, cost, and therefore profit
-- using the same combination of aggregation and a CTE that we used for cost.
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	FORMAT(SUM(o.Revenue), N'$#,###.00') AS TotalRevenue,
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS TotalCost,
	FORMAT(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Profit
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- Which are the most profitable products,
-- in terms of total profit over all time?
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	si.StockItemName,
	FORMAT(SUM(o.Revenue), N'$#,###.00') AS Revenue,
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Cost,
	FORMAT(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Profit
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID
GROUP BY
	si.StockItemName
ORDER BY
	-- Downside to FORMAT: the formatted output is text, so we
	-- have to repeat the full calculation in the ORDER BY clause.
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) DESC;

-- Can we get per-item rev/cost/profit as well as total rev/cost/profit?
-- We can calculate a total using an aggregate window function.
-- The OVER() clause makes it a window function — it calculates across all rows
-- without collapsing them into groups the way GROUP BY does.
--
-- PROBLEM: Without GROUP BY, the joins produce duplicate rows (one per stock item match).
-- DISTINCT removes those duplicates so we see each stock item only once.
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT DISTINCT
	si.StockItemName,
	FORMAT(SUM(o.Revenue) OVER (), N'$#,###.00') AS TotalRevenue,
	FORMAT(SUM(o.Quantity * sih.LastCostPrice) OVER (), N'$#,###.00') AS TotalCost,
	FORMAT(SUM(o.Revenue) OVER () - SUM(o.Quantity * sih.LastCostPrice) OVER (), N'$#,###.00') AS TotalProfit
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- This query demonstrates a common mistake — you CANNOT mix regular aggregation
-- (GROUP BY) with window functions in the same SELECT.
-- !! THIS QUERY WILL FAIL !!
-- SQL Server doesn't know whether to group first or compute the window first.
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	si.StockItemName,
	SUM(o.Revenue) AS Revenue,
	SUM(o.Quantity * sih.LastCostPrice) AS Cost,
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit,
	SUM(o.Revenue) OVER () AS TotalRevenue,
	SUM(o.Quantity * sih.LastCostPrice) OVER () AS TotalCost,
	SUM(o.Revenue) OVER () - SUM(o.Quantity * sih.LastCostPrice) OVER () AS TotalProfit
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID
GROUP BY
	si.StockItemName
ORDER BY
	Profit DESC;

-- The solution: use a second CTE to pre-aggregate, then apply window functions
-- to the pre-aggregated results.
-- Fortunately, revenue, cost, and profit are additive!
-- This means that we can summarize the results in any order,
-- including taking aggregations of aggregations.
-- Note the comma between CTEs: WITH orders AS (...), metrics AS (...)
-- You only write WITH once, then separate additional CTEs with commas.
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
),
metrics AS
(
	SELECT
		si.StockItemName,
		SUM(o.Revenue) AS Revenue,
		SUM(o.Quantity * sih.LastCostPrice) AS Cost,
		SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit
	FROM Warehouse.StockItems si
		INNER JOIN Warehouse.StockItemHoldings sih
			ON si.StockItemID = sih.StockItemID
		INNER JOIN orders o
			ON si.StockItemID = o.StockItemID
	GROUP BY
		si.StockItemName
)
SELECT
	m.StockItemName,
	FORMAT(m.Revenue, N'$#,###.00') AS Revenue,
	FORMAT(m.Cost, N'$#,###.00') AS Cost,
	FORMAT(m.Profit, N'$#,###.00') AS Profit,
	FORMAT(SUM(m.Revenue) OVER (), N'$#,###.00') AS TotalRevenue,
	FORMAT(SUM(m.Cost) OVER (), N'$#,###.00') AS TotalCost,
	FORMAT(SUM(m.Profit) OVER (), N'$#,###.00') AS TotalProfit
FROM metrics m
ORDER BY
	m.Profit DESC;
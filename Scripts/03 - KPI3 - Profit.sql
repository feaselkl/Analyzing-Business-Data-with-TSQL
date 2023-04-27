/* KPI 3:  Profit */

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
	SUM(o.Revenue) AS TotalRevenue,
	SUM(o.Quantity * sih.LastCostPrice) AS TotalCost,
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit
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
ORDER BY
	Profit DESC;

-- Can we get per-item rev/cost/profit as well as total rev/cost/profit?
-- We can calculate a total using an aggregate window function.
-- We know it's a window function because of the OVER clause.
-- This particular window function just gives us totals.
-- Note the DISTINCT clause--that's here because the window function
-- *result* is an aggregate but does not require that the result set be aggregated!
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
	SUM(o.Revenue) OVER () AS TotalRevenue,
	SUM(o.Quantity * sih.LastCostPrice) OVER () AS TotalCost,
	SUM(o.Revenue) OVER () - SUM(o.Quantity * sih.LastCostPrice) OVER () AS TotalProfit
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- If we try to mix an aggregate window function with normal aggregations,
-- we get a runtime error.  This query won't work as-is.
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

-- Fortunately, revenue, cost, and profit are additive!
-- This means that we can summarize the results in any order,
-- including taking aggregations of aggregations.
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
	m.Revenue,
	m.Cost,
	m.Profit,
	SUM(m.Revenue) OVER () AS TotalRevenue,
	SUM(m.Cost) OVER () AS TotalCost,
	SUM(m.Profit) OVER () AS TotalProfit
FROM metrics m
ORDER BY
	Profit DESC;
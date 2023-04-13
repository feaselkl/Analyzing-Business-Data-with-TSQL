/* KPI 3:  Profit */

-- Calculating total revenue, total cost of goods sold
-- Simple assumption:  Profit = Revenue - Cost
-- Yes, there are complications we are ignoring...
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
-- Gives a runtime error based on aggregation
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
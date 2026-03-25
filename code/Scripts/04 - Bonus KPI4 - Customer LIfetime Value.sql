USE [WideWorldImporters]
GO
/* KPI 4:  Customer Lifetime Value */
-- Business Question: What is the lifetime value of each customer?
-- This is a bonus KPI — available in the repo for reference.
-- CLV (Customer Lifetime Value) measures how much total revenue or profit
-- a single customer has generated over their entire relationship with us.

-- Start with revenue per customer
-- This is a simple definition of CLV
SELECT
	o.CustomerID,
	c.CustomerName,
	FORMAT(SUM(ol.UnitPrice * ol.Quantity), N'$#,###.00') AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
GROUP BY
	o.CustomerID,
	c.CustomerName
ORDER BY
	SUM(ol.UnitPrice * ol.Quantity) DESC;

-- A more meaningful CLV uses profit instead of revenue
-- We might be more interested in *profit* per customer
WITH orders AS
(
	SELECT
		o.CustomerID,
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
		INNER JOIN Sales.Orders o
			ON ol.OrderID = o.OrderID
	GROUP BY
		o.CustomerID,
		ol.StockItemID
)
SELECT
	o.CustomerID,
	c.CustomerName,
	FORMAT(SUM(o.Revenue), N'$#,###.00') AS Revenue,
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Cost,
	FORMAT(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Profit
FROM orders o
	INNER JOIN Warehouse.StockItems si
		ON si.StockItemID = o.StockItemID
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
GROUP BY
	o.CustomerID,
	c.CustomerName
ORDER BY
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) DESC;

-- We can slice CLV by dimensions like customer category to find patterns
-- We typically want to slice measures like CLV across
-- multiple dimensions, such as customer category and size.
-- This is a transactional system, so we have to fight a little bit.
WITH orders AS
(
	SELECT
		o.CustomerID,
		ol.StockItemID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
		INNER JOIN Sales.Orders o
			ON ol.OrderID = o.OrderID
	GROUP BY
		o.CustomerID,
		ol.StockItemID
)
SELECT
	o.CustomerID,
	c.CustomerCategoryID,
	c.CustomerName,
	FORMAT(SUM(o.Revenue), N'$#,###.00') AS Revenue,
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Cost,
	FORMAT(SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS Profit
FROM orders o
	INNER JOIN Warehouse.StockItems si
		ON si.StockItemID = o.StockItemID
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
WHERE
	c.CustomerCategoryID <> 3 /* Novelty shops — check Sales.CustomerCategories for all mappings */
GROUP BY
	o.CustomerID,
	c.CustomerCategoryID,
	c.CustomerName
-- Filter to high-profit customers (threshold chosen to limit the result set for demo purposes)
HAVING
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) > 170000
ORDER BY
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) DESC;
GO
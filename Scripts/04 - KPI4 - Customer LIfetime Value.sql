/* KPI 4:  Customer Lifetime Value */

-- Start with revenue per customer
-- This is a simple definition of CLV
SELECT
	o.CustomerID,
	c.CustomerName,
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
GROUP BY
	o.CustomerID,
	c.CustomerName
ORDER BY
	Revenue DESC;

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
	SUM(o.Revenue) AS Revenue,
	SUM(o.Quantity * sih.LastCostPrice) AS Cost,
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit
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
	Profit DESC;

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
	SUM(o.Revenue) AS Revenue,
	SUM(o.Quantity * sih.LastCostPrice) AS Cost,
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) AS Profit
FROM orders o
	INNER JOIN Warehouse.StockItems si
		ON si.StockItemID = o.StockItemID
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
WHERE
	c.CustomerCategoryID <> 3 /* Novelty shops */
GROUP BY
	o.CustomerID,
	c.CustomerCategoryID,
	c.CustomerName
HAVING
	SUM(o.Revenue) - SUM(o.Quantity * sih.LastCostPrice) > 170000
ORDER BY
	Profit DESC;
GO
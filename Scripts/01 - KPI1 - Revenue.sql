/* KPI 1:  Revenue */

-- Calculate revenue per order line
SELECT
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol;

-- Calculate total revenue per customer
SELECT
	o.CustomerID,
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
GROUP BY
	o.CustomerID
ORDER BY
	Revenue DESC;

-- Find customers whose total revenue is under $150,000
SELECT
	o.CustomerID,
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
GROUP BY
	o.CustomerID
HAVING
	SUM(ol.UnitPrice * ol.Quantity) < 150000
ORDER BY
	o.CustomerID ASC;
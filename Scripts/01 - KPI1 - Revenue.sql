USE [WideWorldImporters]
GO
/* KPI 1:  Revenue */

-- This script serves as a baseline of what I expect you to know:
-- SELECT, FROM, INNER JOIN, WHERE, GROUP BY, HAVING, ORDER BY
-- Aggregation and how it impacts non-aggregated columns

-- Check out order lines table
SELECT TOP(100) * FROM Sales.OrderLines;

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
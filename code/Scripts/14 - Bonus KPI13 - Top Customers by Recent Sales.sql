USE [WideWorldImporters]
GO
/* KPI 13:  Top Customers by Recent Sales */
-- Business Question: Based on their most recent orders, who are our
-- highest-value customers right now?
-- This is a bonus KPI — available in the repo for reference.
-- T-SQL Concepts: CROSS APPLY with TOP for "top N per group", chained APPLY

-- CROSS APPLY with TOP(5) gets the 5 most recent orders for each customer.
-- This is a classic "top N per group" pattern that's hard to do with JOINs alone.
-- 5 latest orders for each customer
SELECT
	sc.CustomerID,
	sc.CustomerName,
	o.OrderID,
	o.OrderDate,
	FORMAT(ol.TotalRevenue, N'$#,###.00') AS TotalRevenue
FROM Sales.Customers sc
	CROSS APPLY
	(
		SELECT TOP(5)
			o.OrderID,
			o.OrderDate
		FROM Sales.Orders o
		WHERE
			o.CustomerID = sc.CustomerID
		ORDER BY
			o.OrderDate DESC
	) o
	CROSS APPLY
	(
		SELECT
			SUM(ol.Quantity * ol.UnitPrice) AS TotalRevenue
		FROM Sales.OrderLines ol
		WHERE
			ol.OrderID = o.OrderID
	) ol
ORDER BY
	sc.CustomerID,
	o.OrderID;

-- Use average order value (AOV) from the 5 most recent orders (not lifetime) to find
-- customers who are high-value *right now*.
-- Top 20 customers based on most recent AOV
SELECT TOP(20) WITH TIES
	sc.CustomerID,
	sc.CustomerName,
	FORMAT(AVG(ol.TotalRevenue), N'$#,###.00') AS AverageOrderValue
FROM Sales.Customers sc
	CROSS APPLY
	(
		SELECT TOP(5)
			o.OrderID,
			o.OrderDate
		FROM Sales.Orders o
		WHERE
			o.CustomerID = sc.CustomerID
		ORDER BY
			o.OrderDate DESC
	) o
	CROSS APPLY
	(
		SELECT
			SUM(ol.Quantity * ol.UnitPrice) AS TotalRevenue
		FROM Sales.OrderLines ol
		WHERE
			ol.OrderID = o.OrderID
	) ol
GROUP BY
	sc.CustomerID,
	sc.CustomerName
ORDER BY
	AVG(ol.TotalRevenue) DESC;
USE [WideWorldImporters]
GO
/* KPI 13:  Top Customers by Recent Sales */

-- 5 latest orders for each customer
SELECT
	sc.CustomerID,
	sc.CustomerName,
	o.OrderID,
	o.OrderDate,
	ol.TotalRevenue
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

-- Top 20 customers based on most recent AOV
SELECT TOP(20)
	sc.CustomerID,
	sc.CustomerName,
	AVG(ol.TotalRevenue) AS AverageOrderValue
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
	AverageOrderValue DESC;
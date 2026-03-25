USE [WideWorldImporters]
GO
/* KPI 10:  Average Order Value */
-- Business Question: What is the average order value (AOV), and how does it trend over time?
-- This is a bonus KPI — available in the repo for reference.
-- T-SQL Concepts: Correct aggregation levels, running totals, moving averages, WINDOW clause

-- Calculating order value
SELECT TOP(100)
	ol.OrderID,
	ol.OrderLineID,
	ol.Quantity,
	FORMAT(ol.UnitPrice, N'$#,###.00') AS UnitPrice,
	FORMAT(ol.Quantity * ol.UnitPrice, N'$#,###.00') AS OrderValue
FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID;

-- CAUTION: This next query is WRONG! It averages across order *lines*, not *orders*.
-- A single order with 3 lines would be counted 3 times.
-- Average Order Value?
SELECT
	FORMAT(AVG(ol.Quantity * ol.UnitPrice), N'$#,###.00') AS AverageOrderValue
FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID;

-- The correct approach: first aggregate to one row per order using a CTE,
-- then take the average of order totals.
-- Actual AOV
WITH Orders AS
(
	SELECT
		o.OrderID,
		SUM(ol.Quantity * ol.UnitPrice) AS OrderLineRevenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
	GROUP BY
		o.OrderID
)
SELECT
	FORMAT(AVG(o.OrderLineRevenue), N'$#,###.00') AS AverageOrderValue
FROM Orders o;

-- AOV by sales territory
WITH Orders AS
(
	SELECT
		sp.SalesTerritory,
		o.OrderID,
		SUM(ol.Quantity * ol.UnitPrice) AS OrderLineRevenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
		INNER JOIN Sales.Customers c
			ON o.CustomerID = c.CustomerID
		INNER JOIN Application.Cities ci
			ON c.PostalCityID = ci.CityID
		INNER JOIN Application.StateProvinces sp
			ON ci.StateProvinceID = sp.StateProvinceID
	GROUP BY
		sp.SalesTerritory,
		o.OrderID
)
SELECT
	o.SalesTerritory,
	FORMAT(AVG(o.OrderLineRevenue), N'$#,###.00') AS AverageOrderValue
FROM Orders o
GROUP BY
	o.SalesTerritory
ORDER BY
	AVG(o.OrderLineRevenue) DESC;

-- Filter to a single customer (ID 13) so we can see the per-order detail.
-- (Customer 13 is "Wingtip Toys" in WideWorldImporters.)
-- Revenue per order
WITH Orders AS
(
	SELECT
		o.OrderDate,
		o.OrderID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
	WHERE
		o.CustomerID = 13
	GROUP BY
		o.OrderDate,
		o.OrderID
)
SELECT
	o.OrderDate,
	o.OrderID,
	FORMAT(o.Revenue, N'$#,###.00') AS Revenue
FROM Orders o
ORDER BY
	o.OrderDate ASC,
	o.OrderID ASC;

-- Running totals and moving averages show how AOV trends over time.
-- ROWS BETWEEN 9 PRECEDING AND CURRENT ROW creates a "sliding window"
-- that includes the current row plus the 9 rows before it (10 rows total).
-- This gives us a moving average over the last 10 orders.
-- Now add running total and moving average
WITH Orders AS
(
	SELECT
		o.OrderDate,
		o.OrderID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
	WHERE
		o.CustomerID = 13
	GROUP BY
		o.OrderDate,
		o.OrderID
)
SELECT
	o.OrderDate,
	o.OrderID,
	FORMAT(o.Revenue, N'$#,###.00') AS Revenue,
	FORMAT(SUM(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID), N'$#,###.00') AS RunningTotal,
	-- Overall moving average "stabilizes" and becomes tough to move
	FORMAT(AVG(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID), N'$#,###.00') AS MovingAverage,
	FORMAT(SUM(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW), N'$#,###.00') AS Last10RunningTotal,
	-- Last 10 moving average remains fairly easy to move over time
	FORMAT(AVG(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW), N'$#,###.00') AS Last10MovingAverage
FROM Orders o
ORDER BY
	o.OrderDate ASC,
	o.OrderID ASC;

-- SQL Server 2022 introduced the WINDOW clause, which lets us define
-- a named window once and reuse it. This avoids repeating the same
-- ORDER BY in multiple window functions.
-- A bonus for SQL Server 2022: the WINDOW clause
WITH Orders AS
(
	SELECT
		o.OrderDate,
		o.OrderID,
		SUM(ol.UnitPrice * ol.Quantity) AS Revenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
	WHERE
		o.CustomerID = 13
	GROUP BY
		o.OrderDate,
		o.OrderID
)
SELECT
	o.OrderDate,
	o.OrderID,
	FORMAT(o.Revenue, N'$#,###.00') AS Revenue,
	FORMAT(SUM(o.Revenue) OVER ord, N'$#,###.00') AS RunningTotal,
	-- Overall moving average "stabilizes" and becomes tough to move
	FORMAT(AVG(o.Revenue) OVER ord, N'$#,###.00') AS MovingAverage,
	FORMAT(SUM(o.Revenue) OVER ord10, N'$#,###.00') AS Last10RunningTotal,
	-- Last 10 moving average remains fairly easy to move over time
	FORMAT(AVG(o.Revenue) OVER ord10, N'$#,###.00') AS Last10MovingAverage
FROM Orders o
WINDOW
	ord AS (ORDER BY o.OrderDate, o.OrderID),
	ord10 AS (ord ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
ORDER BY
	o.OrderDate ASC,
	o.OrderID ASC;

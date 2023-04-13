/* KPI 10:  Average Order Value */

-- Calculating order value
SELECT TOP(100)
	ol.OrderID,
	ol.OrderLineID,
	ol.Quantity,
	ol.UnitPrice,
	ol.Quantity * ol.UnitPrice AS OrderValue
FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID;

-- Average Order Value?
SELECT
	AVG(ol.Quantity * ol.UnitPrice) AS AverageOrderValue
FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID;

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
	AVG(o.OrderLineRevenue) AS AverageOrderValue
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
	AVG(o.OrderLineRevenue) AS AverageOrderValue
FROM Orders o
GROUP BY
	o.SalesTerritory
ORDER BY
	AverageOrderValue DESC;

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
	o.Revenue
FROM Orders o
ORDER BY
	o.OrderDate ASC,
	o.OrderID ASC;

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
	o.Revenue,
	SUM(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID) AS RunningTotal,
	-- Overall moving average "stabilizes" and becomes tough to move
	AVG(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID) AS MovingAverage,
	SUM(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN 10 PRECEDING AND CURRENT ROW) AS Last10RunningTotal,
	-- Last 10 moving average remains fairly easy to move over time
	AVG(o.Revenue) OVER (ORDER BY o.OrderDate, o.OrderID
        ROWS BETWEEN 10 PRECEDING AND CURRENT ROW) AS Last10MovingAverage
FROM Orders o
ORDER BY
	o.OrderDate ASC,
	o.OrderID ASC;
USE [WideWorldImporters]
GO
/* KPI 6:  Customers by Geography */

-- Overall customers by sales territory
SELECT
	sp.SalesTerritory,
	COUNT(*) AS NumberOfCustomers
FROM Sales.Customers sc
	INNER JOIN Application.Cities c
		ON sc.PostalCityID = c.CityID
	INNER JOIN Application.StateProvinces sp
		ON c.StateProvinceID = sp.StateProvinceID
GROUP BY
	sp.SalesTerritory;

-- Which did each customer place its first order and in which
-- state/province and sales territory does the customer reside?
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
)
SELECT
	sc.CustomerID,
	fco.FirstOrderMonth,
	sp.StateProvinceCode,
	sp.SalesTerritory
FROM Sales.Customers sc
	INNER JOIN FirstCustomerOrder fco
		ON sc.CustomerID = fco.CustomerID
	INNER JOIN Application.Cities c
		ON sc.PostalCityID = c.CityID
	INNER JOIN Application.StateProvinces sp
		ON c.StateProvinceID = sp.StateProvinceID
ORDER BY
	fco.FirstOrderMonth DESC;

-- New customers by region by month
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
)
SELECT
	sp.SalesTerritory,
	fco.FirstOrderMonth AS CalendarMonth,
	COUNT(*) AS NewCustomers
FROM Sales.Customers sc
	INNER JOIN FirstCustomerOrder fco
		ON sc.CustomerID = fco.CustomerID
	INNER JOIN Application.Cities c
		ON sc.PostalCityID = c.CityID
	INNER JOIN Application.StateProvinces sp
		ON c.StateProvinceID = sp.StateProvinceID
GROUP BY
	sp.SalesTerritory,
	fco.FirstOrderMonth
ORDER BY
	sp.SalesTerritory,
	fco.FirstOrderMonth DESC;

-- Use LAG() and LEAD() to look at other months
-- LAG() allows us to look at the prior row
-- LEAD() allows us to look at the next row
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
),
NewCustomersBySalesTerritory AS
(
	SELECT
		sp.SalesTerritory,
		fco.FirstOrderMonth AS CalendarMonth,
		COUNT(*) AS NewCustomers
	FROM Sales.Customers sc
		INNER JOIN FirstCustomerOrder fco
			ON sc.CustomerID = fco.CustomerID
		INNER JOIN Application.Cities c
			ON sc.PostalCityID = c.CityID
		INNER JOIN Application.StateProvinces sp
			ON c.StateProvinceID = sp.StateProvinceID
	GROUP BY
		sp.SalesTerritory,
		fco.FirstOrderMonth
)
SELECT
	n.SalesTerritory,
	n.CalendarMonth,
	LAG(n.NewCustomers, 2) OVER (PARTITION BY n.SalesTerritory ORDER BY n.CalendarMonth) AS TwoMonthsAgoNewCustomers,
	LAG(n.NewCustomers) OVER (PARTITION BY n.SalesTerritory ORDER BY n.CalendarMonth) AS PriorMonthNewCustomers,
	n.NewCustomers,
	LEAD(n.NewCustomers) OVER (PARTITION BY n.SalesTerritory ORDER BY n.CalendarMonth) AS NextMonthNewCustomers,
	LEAD(n.NewCustomers, 2) OVER (PARTITION BY n.SalesTerritory ORDER BY n.CalendarMonth) AS TwoMonthsAheadNewCustomers
FROM NewCustomersBySalesTerritory n
ORDER BY
	n.SalesTerritory,
	n.CalendarMonth;

-- The problem:  LAG() and LEAD() look at prior *records*, not prior *months*!
-- The solution:  use a calendar table and create a matrix!
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
),
NewCustomersBySalesTerritory AS
(
	SELECT
		sp.SalesTerritory,
		fco.FirstOrderMonth AS CalendarMonth,
		COUNT(*) AS NewCustomers
	FROM Sales.Customers sc
		INNER JOIN FirstCustomerOrder fco
			ON sc.CustomerID = fco.CustomerID
		INNER JOIN Application.Cities c
			ON sc.PostalCityID = c.CityID
		INNER JOIN Application.StateProvinces sp
			ON c.StateProvinceID = sp.StateProvinceID
	GROUP BY
		sp.SalesTerritory,
		fco.FirstOrderMonth
),
TotalMonths AS
(
	SELECT DISTINCT
		c.FirstDayOfMonth AS CalendarMonth
	FROM dbo.Calendar c
	WHERE
		c.Date >= (SELECT MIN(FirstOrderMonth) FROM FirstCustomerOrder)
		AND c.Date <= (SELECT MAX(FirstOrderMonth) FROM FirstCustomerOrder)
		
),
SalesTerritories AS
(
	SELECT DISTINCT
		sp.SalesTerritory
	FROM Application.StateProvinces sp
)
SELECT
	sp.SalesTerritory,
	tm.CalendarMonth,
	ISNULL(LAG(n.NewCustomers, 2) OVER (PARTITION BY sp.SalesTerritory ORDER BY tm.CalendarMonth), 0) AS TwoMonthsAgoNewCustomers,
	ISNULL(LAG(n.NewCustomers) OVER (PARTITION BY sp.SalesTerritory ORDER BY tm.CalendarMonth), 0) AS PriorMonthNewCustomers,
	ISNULL(n.NewCustomers, 0) AS NewCustomers,
	ISNULL(LEAD(n.NewCustomers) OVER (PARTITION BY sp.SalesTerritory ORDER BY tm.CalendarMonth), 0) AS NextMonthNewCustomers,
	ISNULL(LEAD(n.NewCustomers, 2) OVER (PARTITION BY sp.SalesTerritory ORDER BY tm.CalendarMonth), 0) AS TwoMonthsAheadNewCustomers
FROM TotalMonths tm
	CROSS JOIN SalesTerritories sp
	LEFT OUTER JOIN NewCustomersBySalesTerritory n
		ON tm.CalendarMonth = n.CalendarMonth
		AND sp.SalesTerritory = n.SalesTerritory
ORDER BY
	sp.SalesTerritory,
	tm.CalendarMonth;
GO

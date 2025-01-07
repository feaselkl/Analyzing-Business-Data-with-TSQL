USE [WideWorldImporters]
GO
/* KPI 11:  Customer Percentile by Sales */

-- Prior to 2022, we use PERCENTILE_CONT(), which is a window function
-- APPROX_PERCENTILE_CONT() is a grouping function which is *much* faster
-- and guaranteed to be within ~1.33% or so of the real value
WITH CustomerSales AS
(
	SELECT
		o.CustomerID,
		SUM(ol.Quantity * ol.UnitPrice) AS TotalRevenue
	FROM Sales.Orders o
		INNER JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
	GROUP BY
		o.CustomerID
),
Percentiles AS
(
	SELECT
		APPROX_PERCENTILE_CONT(0.00) WITHIN GROUP (ORDER BY TotalRevenue) AS P00,
		APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TotalRevenue) AS P25,
		APPROX_PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY TotalRevenue) AS P50,
		APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalRevenue) AS P75,
		APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY TotalRevenue) AS P95,
		APPROX_PERCENTILE_CONT(1.00) WITHIN GROUP (ORDER BY TotalRevenue) AS P100
	FROM CustomerSales cs
)
SELECT
	FORMAT(p.P00, N'$0,###.##') AS Minimum,
	FORMAT(p.P25, N'$0,###.##') AS P25,
	FORMAT(p.P50, N'$0,###.##') AS Median,
	FORMAT(p.P75, N'$0,###.##') AS P75,
	FORMAT(p.P95, N'$0,###.##') AS P95,
	FORMAT(p.P100, N'$0,###.##') AS Maximum,
	FORMAT(p.P75 - p.P25, N'$0,###.##') AS IQR
FROM Percentiles p;

-- Now by sales territory
WITH CustomerSales AS
(
	SELECT
		sp.SalesTerritory,
		o.CustomerID,
		SUM(ol.Quantity * ol.UnitPrice) AS TotalRevenue
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
		o.CustomerID
),
Percentiles AS
(
	SELECT
		cs.SalesTerritory,
		COUNT(*) AS NumberOfCustomers,
		APPROX_PERCENTILE_CONT(0.00) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P00,
		APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P25,
		APPROX_PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P50,
		APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P75,
		APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P95,
		APPROX_PERCENTILE_CONT(1.00) WITHIN GROUP (ORDER BY cs.TotalRevenue) AS P100
	FROM CustomerSales cs
	GROUP BY
		cs.SalesTerritory
)
SELECT
	p.SalesTerritory,
	p.NumberOfCustomers,
	FORMAT(p.P00, N'$0,###.##') AS Minimum,
	FORMAT(p.P25, N'$0,###.##') AS P25,
	FORMAT(p.P50, N'$0,###.##') AS Median,
	FORMAT(p.P75, N'$0,###.##') AS P75,
	FORMAT(p.P95, N'$0,###.##') AS P95,
	FORMAT(p.P100, N'$0,###.##') AS Maximum,
	FORMAT(p.P75 - p.P25, N'$0,###.##') AS IQR
FROM Percentiles p
ORDER BY
	SalesTerritory;
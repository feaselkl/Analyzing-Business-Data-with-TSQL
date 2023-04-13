/* KPI 8:  Average Time to First Conversion */

-- Compare account opening date to first order date for each customer
SELECT
	c.CustomerID,
	c.AccountOpenedDate,
	fco.FirstOrderDate
FROM Sales.Customers c
	OUTER APPLY
	(
		SELECT TOP(1)
			o.OrderDate AS FirstOrderDate
		FROM Sales.Orders o
		WHERE
			o.CustomerID = c.CustomerID
		ORDER BY
			o.OrderDate ASC
	) fco;

-- Average days to first conversion
-- Note the 1.0 * nd.NumberOfDays so we don't do integer math
SELECT
	CAST(AVG(1.0 * nd.NumberOfDays) AS DECIMAL(6,2)) AS AverageDaysToFirstConversion
FROM Sales.Customers c
	OUTER APPLY
	(
		SELECT TOP(1)
			o.OrderDate AS FirstOrderDate
		FROM Sales.Orders o
		WHERE
			o.CustomerID = c.CustomerID
		ORDER BY
			o.OrderDate ASC
	) fco
	CROSS APPLY
	(
		SELECT
			DATEDIFF(DAY, c.AccountOpenedDate, ISNULL(fco.FirstOrderDate, GETUTCDATE())) AS NumberOfDays
	) nd;

-- Average days to first conversion over time
-- Are we seeing first conversion time increase or decrease?
SELECT
	cal.CalendarYear,
	cal.CalendarQuarterName,
	CAST(AVG(1.0 * nd.NumberOfDays) AS DECIMAL(6,2)) AS AverageDaysToFirstConversion
FROM Sales.Customers c
	CROSS APPLY
	(
		SELECT TOP(1)
			o.OrderDate AS FirstOrderDate
		FROM Sales.Orders o
		WHERE
			o.CustomerID = c.CustomerID
		ORDER BY
			o.OrderDate ASC
	) fco
	INNER JOIN dbo.Calendar cal
		ON fco.FirstOrderDate = cal.Date
	CROSS APPLY
	(
		SELECT
			DATEDIFF(DAY, c.AccountOpenedDate, ISNULL(fco.FirstOrderDate, GETUTCDATE())) AS NumberOfDays
	) nd
GROUP BY
	cal.CalendarYear,
	cal.CalendarQuarterName
ORDER BY
	cal.CalendarYear,
	cal.CalendarQuarterName;
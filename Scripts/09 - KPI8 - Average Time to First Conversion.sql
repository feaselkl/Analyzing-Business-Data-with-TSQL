/* KPI 8:  Average Time to First Conversion */

-- The APPLY operator allows us to perform a function for each row on the left-hand side.
-- APPLY has been around since SQL Server 2005 and has two flavors:  CROSS APPLY and OUTER APPLY.
-- CROSS APPLY is semantically similar to (but not the same as) INNER JOIN.
-- OUTER APPLY is semantically similar to (but not the same as) LEFT OUTER JOIN.

-- Compare account opening date to first order date for each customer
-- Use APPLY to get the first order.  Note that there is a correlation here
-- where we can't run APPLY without the outer table Sales.Customers.
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
-- Also, we can chain together APPLY operations.
-- If we have an APPLY with just a SELECT clause, it shows up in the execution plan
-- as a Compute Scalar and has zero performance impact.
-- The benefit is that we take a somewhat-nasty calculation and
-- don't need to show it in our final SELECT clause,
-- letting humans understand the math more easily.
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
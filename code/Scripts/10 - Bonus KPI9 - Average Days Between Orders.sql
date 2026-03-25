USE [WideWorldImporters]
GO
/* KPI 9:  Average Days between Orders */
-- Business Question: On average, how many days pass between a customer's orders?
-- This is a bonus KPI — available in the repo for reference.
-- T-SQL Concepts: LEAD window function, DATEDIFF for date arithmetic

-- LEAD() looks at the next row within each customer's orders (ordered by date).
-- This gives us each order paired with the customer's next order date.
WITH Orders AS
(
	SELECT
		o.CustomerID,
		o.OrderDate,
		LEAD(o.OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS NextOrderDate
	FROM Sales.Orders o
)
SELECT
	CAST(AVG(1.0 * DATEDIFF(DAY, o.OrderDate, o.NextOrderDate)) AS DECIMAL(6,2)) AS AverageDaysBetweenOrders
FROM Orders o
WHERE
	o.NextOrderDate IS NOT NULL;

-- Break it down by quarter to see if ordering frequency is changing over time.
WITH Orders AS
(
	SELECT
		o.CustomerID,
		o.OrderDate,
		LEAD(o.OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS NextOrderDate
	FROM Sales.Orders o
)
SELECT
	cal.CalendarYear,
	cal.CalendarQuarterName,
	CAST(AVG(calc.DaysBetweenOrders) AS DECIMAL(6,2)) AS AverageDaysBetweenOrders
FROM Orders o
	INNER JOIN dbo.Calendar cal
		ON o.OrderDate = cal.Date
	CROSS APPLY
	(
		SELECT
			1.0 * DATEDIFF(DAY, o.OrderDate, o.NextOrderDate) AS DaysBetweenOrders
	) calc
GROUP BY
	cal.CalendarYear,
	cal.CalendarQuarterName
ORDER BY
	cal.CalendarYear,
	cal.CalendarQuarterName;
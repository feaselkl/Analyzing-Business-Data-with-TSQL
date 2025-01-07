USE [WideWorldImporters]
GO
/* KPI 9:  Average Days between Orders */
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

-- Average days between orders over time
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
	CAST(AVG(dbo.DaysBetweenOrders) AS DECIMAL(6,2)) AS AverageDaysBetweenOrders
FROM Orders o
	INNER JOIN dbo.Calendar cal
		ON o.OrderDate = cal.Date
	CROSS APPLY
	(
		SELECT
			1.0 * DATEDIFF(DAY, o.OrderDate, o.NextOrderDate) AS DaysBetweenOrders
	) dbo
GROUP BY
	cal.CalendarYear,
	cal.CalendarQuarterName
ORDER BY
	cal.CalendarYear,
	cal.CalendarQuarterName;
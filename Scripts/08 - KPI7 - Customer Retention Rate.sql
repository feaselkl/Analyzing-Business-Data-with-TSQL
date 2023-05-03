USE [WideWorldImporters]
GO
/* KPI 7:  Customer Retention Rate */
-- Quick reminder on customer status:
-- New customer:  first order was in a given month
-- Retained customer:  ordered in a given month and in the prior month
-- Inactive customer:  did not order in a given month but did order in the prior month
-- Resurrected customer:  did not order in the prior month but did order in the given month
-- Churned customer:  did not order in a given month or in the prior month

-- Knowing about LAG() and building a calendar-customer matrix, we can perform a customer
-- analysis over any time period, not just a single one.
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
),
Months AS
(
	SELECT DISTINCT
		cal.FirstDayOfMonth AS CalendarMonth,
		cal.LastDayOfMonth
	FROM dbo.Calendar cal
	WHERE
		cal.Date >= (SELECT MIN(o.OrderDate) FROM Sales.Orders o)
		AND cal.Date <= (SELECT MAX(o.OrderDate) FROM Sales.Orders o)
),
Orders AS
(
	SELECT
		c.CustomerID,
		m.CalendarMonth,
		CASE
			WHEN m.CalendarMonth = fco.FirstOrderMonth THEN 1
			ELSE 0
		END AS IsFirstMonth,
		CASE
			WHEN COUNT(o.OrderID) > 0 THEN 1
			ELSE 0
		END AS HasOrder
	FROM Sales.Customers c
		CROSS JOIN Months m
		INNER JOIN FirstCustomerOrder fco
			ON c.CustomerID = fco.CustomerID
		LEFT OUTER JOIN Sales.orders o
			ON c.CustomerID = o.CustomerID
			AND o.OrderDate >= m.CalendarMonth
			AND o.OrderDate <= m.LastDayOfMonth
	WHERE
		m.CalendarMonth >= fco.FirstOrderMonth
	GROUP BY
		c.CustomerID,
		m.CalendarMonth,
		fco.FirstOrderMonth
),
LaggedOrders AS
(
	SELECT
		o.CustomerID,
		o.CalendarMonth,
		o.IsFirstMonth,
		o.HasOrder,
		ISNULL(LAG(o.HasOrder) OVER (PARTITION BY o.CustomerID ORDER BY o.CalendarMonth), 0) AS PriorMonthHasOrder
	FROM Orders o
),
MonthlyCustomerStatus AS
(
	SELECT
		o.CalendarMonth,
		SUM(o.IsFirstMonth) AS NewCustomers,
		SUM(CASE WHEN o.HasOrder = 1 AND o.PriorMonthHasOrder = 1 THEN 1 ELSE 0 END) AS RetainedCustomers,
		SUM(CASE WHEN o.HasOrder = 0 AND o.PriorMonthHasOrder = 1 THEN 1 ELSE 0 END) AS InactiveCustomers,
		SUM(CASE WHEN o.HasOrder = 1 AND o.PriorMonthHasOrder = 0 AND o.IsFirstMonth = 0 THEN 1 ELSE 0 END) AS ResurrectedCustomers,
		SUM(CASE WHEN o.HasOrder = 0 AND o.PriorMonthHasOrder = 0 THEN 1 ELSE 0 END) AS ChurnedCustomers
	FROM LaggedOrders o
	GROUP BY
		o.CalendarMonth
)
SELECT
	mo.CalendarMonth,
	mo.NewCustomers,
	mo.RetainedCustomers,
	mo.InactiveCustomers,
	mo.ResurrectedCustomers,
	mo.ChurnedCustomers,
	CAST(1.0 * (mo.NewCustomers + mo.RetainedCustomers) /
        LAG(mo.NewCustomers + mo.RetainedCustomers)
            OVER (ORDER BY mo.CalendarMonth) AS DECIMAL(4,3)) AS RetentionRate
FROM MonthlyCustomerStatus mo
ORDER BY
	mo.CalendarMonth;
/* KPI 5: Number of Customers */
-- New customer:  first order was in a given month
-- Retained customer:  ordered in a given month and in the prior month
-- Inactive customer:  did not order in a given month but did order in the prior month
-- Resurrected customer:  did not order in the prior month but did order in the given month
-- Churned customer:  did not order in a given month or in the prior month

DECLARE
	@MonthOfInterest DATE = '2015-07-16';

-- Make sure that @MonthOfInterest is the beginning of a month
SELECT
	DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthOfInterest), 0),
	-- Only works in SQL Server 2022 or later!
	DATETRUNC(MONTH, @MonthOfInterest);
GO

-- To resolve this, we are going to need a few result sets.
-- There are 3 result sets in total we'll quickly review.
DECLARE
	@MonthOfInterest DATE = '2015-07-16';

SELECT
	@MonthOfInterest = DATETRUNC(MONTH, @MonthOfInterest);

-- Did we have an order in the prior month?
SELECT
	c.CustomerID,
	COUNT(o.OrderID) AS NumberOfOrders
FROM Sales.Customers c
	LEFT OUTER JOIN Sales.orders o
		ON c.CustomerID = o.CustomerID
		AND o.OrderDate >= DATEADD(MONTH, -1, @MonthOfInterest)
		AND o.OrderDate < @MonthOfInterest
GROUP BY
	c.CustomerID;

-- Order in month before?
SELECT
	c.CustomerID,
	COUNT(o.OrderID) AS NumberOfOrders
FROM Sales.Customers c
	LEFT OUTER JOIN Sales.orders o
		ON c.CustomerID = o.CustomerID
		AND o.OrderDate >= DATEADD(MONTH, -2, @MonthOfInterest)
		AND o.OrderDate < DATEADD(MONTH, -1, @MonthOfInterest)
GROUP BY
	c.CustomerID;

-- First month a customer ordered
SELECT
	o.CustomerID,
	MIN(DATETRUNC(MONTH, o.OrderDate)) AS OrderDate
FROM Sales.Orders o
GROUP BY
	o.CustomerID;
GO



-- Now let's put it all together
DECLARE
	@MonthOfInterest DATE = '2015-07-16';

SELECT
	@MonthOfInterest = DATETRUNC(MONTH, @MonthOfInterest);

-- As a quick reminder:
-- New customer:  first order was in a given month
-- Retained customer:  ordered in a given month and in the prior month
-- Inactive customer:  did not order in a given month but did order in the prior month
-- Resurrected customer:  did not order in the prior month but did order in the given month
-- Churned customer:  did not order in a given month or in the prior month
WITH FirstCustomerOrder AS
(
	SELECT
		o.CustomerID,
		MIN(DATETRUNC(MONTH, o.OrderDate)) AS FirstOrderMonth
	FROM Sales.Orders o
	GROUP BY
		o.CustomerID
),
MonthlyOrders AS
(
	SELECT
		c.CustomerID,
		1 AS MonthsAgo,
		CASE
			WHEN COUNT(o.OrderID) > 0 THEN 1
			ELSE 0
		END AS HasOrder
	FROM Sales.Customers c
		LEFT OUTER JOIN Sales.orders o
			ON c.CustomerID = o.CustomerID
			AND o.OrderDate >= DATEADD(MONTH, -1, @MonthOfInterest)
			AND o.OrderDate < @MonthOfInterest
	GROUP BY
		c.CustomerID

	UNION ALL

	SELECT
		c.CustomerID,
		2 AS MonthsAgo,
		CASE
			WHEN COUNT(o.OrderID) > 0 THEN 1
			ELSE 0
		END AS HasOrder
	FROM Sales.Customers c
		LEFT OUTER JOIN Sales.orders o
			ON c.CustomerID = o.CustomerID
			AND o.OrderDate >= DATEADD(MONTH, -2, @MonthOfInterest)
			AND o.OrderDate < DATEADD(MONTH, -1, @MonthOfInterest)
	GROUP BY
		c.CustomerID
),
OrderDetails AS
(
	SELECT
		mo.CustomerID,
		MAX(CASE WHEN mo.MonthsAgo = 1 THEN HasOrder END) AS LastMonthOrder,
		MAX(CASE WHEN mo.MonthsAgo = 2 THEN HasOrder END) AS PriorMonthOrder,
		fco.FirstOrderMonth
	FROM MonthlyOrders mo
		LEFT OUTER JOIN FirstCustomerOrder fco
			ON mo.CustomerID = fco.CustomerID
	GROUP BY
		mo.CustomerID,
		fco.FirstOrderMonth
)
SELECT
	COUNT(*) AS NumberOfCustomers,
	SUM(CASE WHEN od.FirstOrderMonth = @MonthOfInterest THEN 1 ELSE 0 END) AS NewCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 1 AND od.PriorMonthOrder = 1 THEN 1 ELSE 0 END) AS RetainedCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 0 AND od.PriorMonthOrder = 1 THEN 1 ELSE 0 END) AS InactiveCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 1 AND od.PriorMonthOrder = 0 THEN 1 ELSE 0 END) AS ResurrectedCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 0 AND od.PriorMonthOrder = 0 THEN 1 ELSE 0 END) AS ChurnedCustomers
FROM OrderDetails od;
USE [WideWorldImporters]
GO
/* KPI 5: Number of Customers */
-- Business Question: How many customers do we have in each status category
-- (new, retained, inactive, resurrected, churned) for a given month?
-- T-SQL Concepts: DATETRUNC, DATEADD, DATEDIFF, CTEs, CASE expressions, UNION ALL

-- Let's say we want to know the beginning of the month based on the current date.
-- Let's also say that the current date is 2015-07-16, because that's about as far as WWI data goes.
DECLARE
	@MonthOfInterest DATE = '2015-07-16';
GO

-- Prior to SQL Server 2022, there was one easy(ish) way to get this answer:
-- Figure out how many months there were from the beginning of time.
-- DATEDIFF(Interval, Start Date, End Date)
-- Note that SQL Server can actually handle numeric inputs for DATETIME.
SELECT DATEDIFF(MONTH, 0, '2015-07-16');

-- By the way, when was the beginning of time?
-- Find out with DATEADD().
-- DATEADD(Interval, Number of periods to add, Start Date)
SELECT DATEADD(MONTH, 0, 0);

-- Now we can add the number of months from 1900-01-01 to 1900-01-01 and get our result.
DECLARE
	@MonthOfInterest DATE = '2015-07-16';

SELECT
	DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthOfInterest), 0);
GO

-- SQL Server 2022 offers a cleaner way of getting this.
DECLARE
	@MonthOfInterest DATE = '2015-07-16';

SELECT
	DATETRUNC(MONTH, @MonthOfInterest);
GO

-- In retail, we typically have customers fit into a few buckets.
-- For simplicity, let's use these definitions:
-- New customer				First order was in a given month
-- Retained customer		Ordered in a given month and in the prior month
-- Inactive customer		Did not order in a given month but did order in the prior month
-- Resurrected customer		Did not order in the prior month but did order in the given month
-- Churned customer			Did not order in a given month or in the prior month

-- To calculate this in our dataset, we are going to build up a solution from parts.
-- There are 3 result sets in total we'll quickly review.
DECLARE
	@MonthOfInterest DATE = DATETRUNC(MONTH, '2015-07-16');

-- Did we have an order in the prior month?
-- We can use DATEADD() to find that out.
-- IMPORTANT: The date conditions are in the ON clause (not WHERE) on purpose.
-- With a LEFT JOIN, putting conditions in WHERE would filter out customers
-- with no orders, turning it into an INNER JOIN. Keeping them in ON
-- preserves all customers and just controls which orders match.
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
-- Use DATEADD() to go from 2 months go, up to (but not including)
-- 1 month ago
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
-- DATETRUNC() operates on more than just literals and variables.
-- It also works on data in tables.
SELECT
	o.CustomerID,
	MIN(DATETRUNC(MONTH, o.OrderDate)) AS OrderDate
FROM Sales.Orders o
GROUP BY
	o.CustomerID;
GO



-- Now we combine the building blocks above into one query.
-- We use three CTEs: one for each customer's first order month,
-- one for whether each customer ordered in recent months,
-- and one that pivots the monthly order data into columns.

-- Now let's put it all together
DECLARE
	@MonthOfInterest DATE = DATETRUNC(MONTH, '2015-07-16');

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

	-- UNION ALL stacks the results of two queries into one result set.
	-- (UNION without ALL would remove duplicates, which we don't want here.)
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
		-- Pivot rows into columns: for each customer, pull LastMonthOrder
		-- and PriorMonthOrder into separate columns.
		-- MAX(CASE WHEN ...) is a common pivot pattern in T-SQL.
		-- It picks the value from the matching row and ignores NULLs from non-matching rows.
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
-- Finally, we use CASE expressions to classify each customer
-- based on their order history in the last two months.
SELECT
	COUNT(*) AS NumberOfCustomers,
	SUM(CASE WHEN od.FirstOrderMonth = @MonthOfInterest THEN 1 ELSE 0 END) AS NewCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 1 AND od.PriorMonthOrder = 1 THEN 1 ELSE 0 END) AS RetainedCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 0 AND od.PriorMonthOrder = 1 THEN 1 ELSE 0 END) AS InactiveCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 1 AND od.PriorMonthOrder = 0 THEN 1 ELSE 0 END) AS ResurrectedCustomers,
	SUM(CASE WHEN od.LastMonthOrder = 0 AND od.PriorMonthOrder = 0 THEN 1 ELSE 0 END) AS ChurnedCustomers
FROM OrderDetails od;
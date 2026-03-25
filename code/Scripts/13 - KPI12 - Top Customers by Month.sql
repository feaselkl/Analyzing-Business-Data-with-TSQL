USE [WideWorldImporters]
GO
/* KPI 12:  Top Customers by Month */
-- Business Question: Who are our top customers for a given month,
-- and how do we handle ties correctly?
-- T-SQL Concepts: TOP, TOP WITH TIES, ROW_NUMBER, RANK, DENSE_RANK, PARTITION BY

-- Who are the top 10 customers for the month of August, 2015
-- in terms of number of orders?
WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
)
SELECT TOP(10)
	cr.CustomerID,
	sc.CustomerName,
	cr.NumberOfOrders
FROM CustomerResults cr
	INNER JOIN Sales.Customers sc
		ON cr.CustomerID = sc.CustomerID
ORDER BY
	cr.NumberOfOrders DESC;

-- Problem: TOP(10) arbitrarily cuts off ties. Were there other customers
-- with the same order count who got left out?
-- Were these the only ones with 7 orders?
WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
	HAVING COUNT(*) >= 7
)
SELECT
	cr.CustomerID,
	sc.CustomerName,
	cr.NumberOfOrders
FROM CustomerResults cr
	INNER JOIN Sales.Customers sc
		ON cr.CustomerID = sc.CustomerID
ORDER BY
	cr.NumberOfOrders DESC;

-- TOP WITH TIES includes all rows that tie with the last row.
-- This ensures we don't arbitrarily exclude customers with the same count.
-- We *could* use WITH TIES here
WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
)
SELECT TOP(10) WITH TIES
	cr.CustomerID,
	sc.CustomerName,
	cr.NumberOfOrders
FROM CustomerResults cr
	INNER JOIN Sales.Customers sc
		ON cr.CustomerID = sc.CustomerID
ORDER BY
	cr.NumberOfOrders DESC;

-- Ranking window functions give us more control over how we handle ties.
-- Another way to perform these calculations:  ranking window functions.
-- Three ranking window functions exist:  ROW_NUMBER(), RANK(), DENSE_RANK()
-- (A fourth ranking function, NTILE(), also exists, but we'll ignore it today)

-- ROW_NUMBER() assigns sequential numbers (1, 2, 3, ...) to each row in the result.
-- We must include an ORDER BY clause for ROW_NUMBER()
SELECT TOP(50)
	c.Date,
	ROW_NUMBER() OVER (ORDER BY c.Date ASC) AS rownum
FROM dbo.Calendar c
ORDER BY
	c.Date ASC;

-- The ranking function's ORDER BY does not have to be the same as
-- the ORDER BY clause in the window function!
SELECT TOP(50)
	c.Date,
	ROW_NUMBER() OVER (ORDER BY c.Date ASC) AS rownum
FROM dbo.Calendar c
ORDER BY
	c.DayOfWeek ASC,
	FiscalWeekOfYear ASC;

-- We can also break data out into window partitions using the PARTITION BY clause.
SELECT
	c.Date,
	c.DayName,
	ROW_NUMBER() OVER (PARTITION BY c.DayName ORDER BY c.Date ASC) AS rownum
FROM dbo.Calendar c
WHERE
	c.FirstDayOfMonth = '1901-01-01'
ORDER BY
	c.DayName,
	c.Date;

-- Now let's apply it to our customer results
-- and look at data in August, 2015.
-- ROW_NUMBER() arbitrarily assigns unique numbers in the event of a tie.
WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
)
SELECT
	cr.CustomerID,
	sc.CustomerName,
	cr.NumberOfOrders,
	ROW_NUMBER() OVER (ORDER BY cr.NumberOfOrders DESC) AS RowNum
FROM CustomerResults cr
	INNER JOIN Sales.Customers sc
		ON cr.CustomerID = sc.CustomerID
ORDER BY
	cr.NumberOfOrders DESC;

-- Side-by-side comparison of the three ranking functions:
-- ROW_NUMBER: 1, 2, 3, 4, 5 (ties broken arbitrarily)
-- RANK:       1, 1, 3, 4, 5 (ties share rank, next rank skips)
-- DENSE_RANK: 1, 1, 2, 3, 4 (ties share rank, next rank doesn't skip)
-- If we want to handle ties, there are two additional ranking functions:
-- RANK() and DENSE_RANK()
-- RANK() shows ties like a race:  T-1, T-1, 3, 4, 5.
-- DENSE_RANK() shows ties like levels:  T-1, T-1, 2, 3, 4.
WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
)
SELECT
	cr.CustomerID,
	sc.CustomerName,
	cr.NumberOfOrders,
	ROW_NUMBER() OVER (ORDER BY cr.NumberOfOrders DESC) AS RowNum,
	RANK() OVER (ORDER BY cr.NumberOfOrders DESC) AS Ranking,
	DENSE_RANK() OVER (ORDER BY cr.NumberOfOrders DESC) AS DenseRanking
FROM CustomerResults cr
	INNER JOIN Sales.Customers sc
		ON cr.CustomerID = sc.CustomerID
ORDER BY
	RowNum ASC;

WITH CustomerResults AS
(
	SELECT
		o.CustomerID,
		COUNT(*) AS NumberOfOrders
	FROM Sales.Orders o
		INNER JOIN dbo.Calendar c
			ON o.OrderDate = c.Date
	WHERE
		c.FirstDayOfMonth = '2015-08-01'
	GROUP BY
		o.CustomerID
),
rankings AS
(
	SELECT
		cr.CustomerID,
		sc.CustomerName,
		cr.NumberOfOrders,
		ROW_NUMBER() OVER (ORDER BY cr.NumberOfOrders DESC) AS RowNum,
		RANK() OVER (ORDER BY cr.NumberOfOrders DESC) AS Ranking,
		DENSE_RANK() OVER (ORDER BY cr.NumberOfOrders DESC) AS DenseRanking
	FROM CustomerResults cr
		INNER JOIN Sales.Customers sc
			ON cr.CustomerID = sc.CustomerID
)
SELECT
	r.CustomerID,
	r.CustomerName,
	r.NumberOfOrders,
	r.RowNum,
	r.Ranking,
	r.DenseRanking
FROM rankings r
WHERE
	r.Ranking <= 10
ORDER BY
	RowNum ASC;
/* KPI 12:  Top Customers by Month */
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

-- Another way to perform these calculations:  ranking window functions.
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

-- Two ways to handle ties:  RANK() and DENSE_RANK()
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
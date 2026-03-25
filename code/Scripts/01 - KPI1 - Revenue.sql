USE [WideWorldImporters]
GO
/* Preface: make sure Wide World Importers database is set to
	compatibility level 160 (SQL Server 2022). This is
	necessary for certain scripts to run correctly. */
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 160;

/* KPI 1:  Revenue */

-- Business question: "How much revenue are we generating, and which customers
-- drive the most (or least)?"

-- This script serves as a baseline of what I expect you to know:
-- SELECT, FROM, INNER JOIN, WHERE, GROUP BY, HAVING, ORDER BY
-- Aggregation and how it impacts non-aggregated columns

-- Preview the raw data we'll be working with
-- Returns: up to 100 rows showing all columns in the OrderLines table
SELECT TOP(100)
	*
FROM Sales.OrderLines;

-- Note: "ol" is a table alias (short name) for Sales.OrderLines.
-- Aliases make queries shorter and easier to read.
-- "AS" after a calculation (like SUM(...) AS Revenue) gives the result column a name.

-- Calculate total revenue across all order lines
-- Returns: one number — total revenue across all orders
SELECT
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol;

-- Break down revenue by customer using GROUP BY, sorted highest first
-- Returns: one row per customer with their CustomerID and total Revenue
SELECT
	o.CustomerID,
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
GROUP BY
	o.CustomerID
ORDER BY
	Revenue DESC;

-- HAVING filters *after* aggregation (unlike WHERE, which filters before).
-- Note: In T-SQL, HAVING cannot reference column aliases like "Revenue".
-- We must repeat the full expression: SUM(ol.UnitPrice * ol.Quantity).

-- Filter to only low-revenue customers using HAVING (filters on aggregated values)
-- HAVING is like WHERE, but it runs after GROUP BY so it can reference aggregates
-- Returns: one row per customer whose total revenue is under $150,000
SELECT
	o.CustomerID,
	SUM(ol.UnitPrice * ol.Quantity) AS Revenue
FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o
		ON ol.OrderID = o.OrderID
GROUP BY
	o.CustomerID
HAVING
	SUM(ol.UnitPrice * ol.Quantity) < 150000
ORDER BY
	o.CustomerID ASC;
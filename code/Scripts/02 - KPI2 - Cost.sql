USE [WideWorldImporters]
GO
/* KPI 2:  Cost */

-- Business question: "What is our estimated cost of goods sold (COGS)?"

-- Estimate cost of goods sold
-- This is a lot harder to do in Wide World Importers than we'd hope!

-- We can use a Common Table Expression (CTE) to act as a subquery.
-- CTEs are defined with WITH...AS and can be referenced like tables in subsequent queries.
-- CTEs take the following shape:  WITH cteName AS ()
-- We can reference the results of a CTE as though it were a table
-- Note: SQL Server re-runs the CTE query each time you reference it.

-- We want the quantity per stock item ID and to multiply it by
-- latest cost price.  Step 1:  get quantity sold per stock item:
-- Returns: one row per stock item with its StockItemID and total Quantity sold
SELECT
	ol.StockItemID,
	SUM(ol.Quantity) AS Quantity
FROM Sales.OrderLines ol
GROUP BY
	ol.StockItemID;

-- To use this, we'll wrap it in a CTE
-- Returns: same result as above, but now inside a reusable CTE named "orders"
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	*
FROM orders o;

-- Now we can join the CTE results to other tables to bring in cost data
-- Returns: one row per stock item with name, last cost price, quantity, and calculated cost
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	si.StockItemID,
	si.StockItemName,
	sih.LastCostPrice,
	o.Quantity,
	o.Quantity * sih.LastCostPrice AS Cost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- How much has WWI spent on COGS?
-- Note that we're aggregating on two separate levels:
--   1) Inside the CTE: SUM quantity per stock item
--   2) Outside: SUM cost across all stock items
-- Having an intermediary CTE makes it easier for us to do this.
-- Returns: one number — total estimated COGS
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	SUM(o.Quantity * sih.LastCostPrice) AS TotalCost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;

-- FORMAT() displays numbers in a readable style.
-- The N before the string means it's a Unicode (NVARCHAR) literal — a T-SQL convention.

-- Bonus: FORMAT() displays the result as a currency string for readability
-- Returns: one value — total COGS formatted as "$X,XXX.XX"
WITH orders AS
(
	SELECT
		ol.StockItemID,
		SUM(ol.Quantity) AS Quantity
	FROM Sales.OrderLines ol
	GROUP BY
		ol.StockItemID
)
SELECT
	FORMAT(SUM(o.Quantity * sih.LastCostPrice), N'$#,###.00') AS TotalCost
FROM Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih
		ON si.StockItemID = sih.StockItemID
	INNER JOIN orders o
		ON si.StockItemID = o.StockItemID;
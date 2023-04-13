/* KPI 2:  Cost */

-- This looks like cost, but is total purchases
-- One definition of cost but we typically want cost of goods sold!
SELECT
	SUM(pol.ReceivedOuters * pol.ExpectedUnitPricePerOuter) AS Cost
FROM Purchasing.PurchaseOrderLines pol;

-- Estimate cost of goods sold
-- This is a lot harder to do in Wide World Importers than we'd hope!
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
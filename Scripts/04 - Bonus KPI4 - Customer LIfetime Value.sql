USE [WideWorldImporters];
GO

/* KPI 4: Customer Lifetime Value (CLV) */

-- Revenue per customer
SELECT
    o.CustomerID,
    c.CustomerName,
    CAST(SUM(ol.UnitPrice * ol.Quantity) AS DECIMAL(18,2)) AS TotalRevenue
FROM Sales.OrderLines AS ol
INNER JOIN Sales.Orders AS o
    ON ol.OrderID = o.OrderID
INNER JOIN Sales.Customers AS c
    ON o.CustomerID = c.CustomerID
GROUP BY
    o.CustomerID,
    c.CustomerName
ORDER BY
    TotalRevenue DESC;



-- Profit per customer using cost from StockItemHoldings
WITH CustomerOrders AS
(
    SELECT
        o.CustomerID,
        ol.StockItemID,
        CAST(SUM(ol.UnitPrice * ol.Quantity) AS DECIMAL(18,2)) AS Revenue,
        SUM(ol.Quantity) AS Quantity
    FROM Sales.OrderLines AS ol
    INNER JOIN Sales.Orders AS o
        ON ol.OrderID = o.OrderID
    GROUP BY
        o.CustomerID,
        ol.StockItemID
)
SELECT
    co.CustomerID,
    c.CustomerName,
    CAST(SUM(co.Revenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(co.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalCost,
    CAST(SUM(co.Revenue) - SUM(co.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalProfit
FROM CustomerOrders AS co
INNER JOIN Warehouse.StockItems AS si
    ON si.StockItemID = co.StockItemID
INNER JOIN Warehouse.StockItemHoldings AS sih
    ON si.StockItemID = sih.StockItemID
INNER JOIN Sales.Customers AS c
    ON co.CustomerID = c.CustomerID
GROUP BY
    co.CustomerID,
    c.CustomerName
ORDER BY
    TotalProfit DESC;



-- Profit per customer with CustomerCategory, excluding novelty shops
WITH CustomerOrders AS
(
    SELECT
        o.CustomerID,
        ol.StockItemID,
        CAST(SUM(ol.UnitPrice * ol.Quantity) AS DECIMAL(18,2)) AS Revenue,
        SUM(ol.Quantity) AS Quantity
    FROM Sales.OrderLines AS ol
    INNER JOIN Sales.Orders AS o
        ON ol.OrderID = o.OrderID
    GROUP BY
        o.CustomerID,
        ol.StockItemID
)
SELECT
    co.CustomerID,
    c.CustomerCategoryID,
    c.CustomerName,
    CAST(SUM(co.Revenue) AS DECIMAL(18,2)) AS TotalRevenue,
    CAST(SUM(co.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalCost,
    CAST(SUM(co.Revenue) - SUM(co.Quantity * sih.LastCostPrice) AS DECIMAL(18,2)) AS TotalProfit
FROM CustomerOrders AS co
INNER JOIN Warehouse.StockItems AS si
    ON si.StockItemID = co.StockItemID
INNER JOIN Warehouse.StockItemHoldings AS sih
    ON si.StockItemID = sih.StockItemID
INNER JOIN Sales.Customers AS c
    ON co.CustomerID = c.CustomerID
WHERE c.CustomerCategoryID NOT IN (3) -- Exclude novelty shops
GROUP BY
    co.CustomerID,
    c.CustomerCategoryID,
    c.CustomerName
HAVING
    SUM(co.Revenue) - SUM(co.Quantity * sih.LastCostPrice) > 170000
ORDER BY
    TotalProfit DESC;
GO

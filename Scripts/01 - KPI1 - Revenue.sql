USE [WideWorldImporters];
GO

/* ============================================================
   KPI 1: Revenue Analysis
   ============================================================
   - Revenue per order line
   - Total revenue per customer
   - Customers with revenue under $150,000
   ============================================================
*/

/* Step 1: Inspect OrderLines */
SELECT TOP (100) *
FROM Sales.OrderLines
ORDER BY OrderLineID;

/* Step 2: Revenue per order line */
SELECT
    ol.OrderLineID,
    ol.OrderID,
    ol.UnitPrice,
    ol.Quantity,
    CAST(ol.UnitPrice * ol.Quantity AS DECIMAL(18,2)) AS Revenue
FROM Sales.OrderLines ol
ORDER BY ol.OrderLineID;

/* Step 3: Total revenue per customer */
SELECT
    o.CustomerID,
    SUM(ol.UnitPrice * ol.Quantity) AS TotalRevenue
FROM Sales.OrderLines ol
INNER JOIN Sales.Orders o
    ON ol.OrderID = o.OrderID
GROUP BY o.CustomerID
ORDER BY TotalRevenue DESC;

/* Step 4: Customers with revenue under $150,000 */
SELECT
    o.CustomerID,
    SUM(ol.UnitPrice * ol.Quantity) AS TotalRevenue
FROM Sales.OrderLines ol
INNER JOIN Sales.Orders o
    ON ol.OrderID = o.OrderID
GROUP BY o.CustomerID
HAVING SUM(ol.UnitPrice * ol.Quantity) < 150000
ORDER BY o.CustomerID ASC;

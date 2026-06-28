Create Database Adventure_Works;
use Adventure_Works;

SELECT COUNT(*)
FROM FactInternetSales;

SELECT COUNT(*)
FROM Fact_Internet_Sales_new;

SELECT COUNT(*)
FROM dimcustomer;

-- check count of dimproduct
SELECT COUNT(*)
FROM dimproduct;

SELECT COUNT(*)
FROM dimsalesterritory;
-- change table name here 
ALTER TABLE DimProduct
RENAME COLUMN `ï»¿ProductKey` TO ProductKey;

-- change table name here 
ALTER TABLE dimsalesterritory
RENAME COLUMN ï»¿SalesTerritoryKey TO Salesterritorykey; 

-- change table name here 
ALTER TABLE dimsalesterritory
RENAME COLUMN ï»¿SalesTerritoryKey TO Salesterritorykey; 

# 0. Union of Fact Internet sales and Fact internet sales new
SELECT * FROM FactInternetSales
UNION ALL
SELECT * FROM Fact_Internet_Sales_New;


# 1.Lookup the productname from the Product sheet to Sales sheet.
CREATE VIEW Sales_Product_Lookup AS
SELECT S.*,
P.EnglishProductName AS ProductName
FROM Sales_Union_Final S
LEFT JOIN DimProduct P ON S.ProductKey = P.ProductKey;
-- to check view and excution of query
select * from Sales_Product_Lookup;

-- 2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.
CREATE VIEW Sales_Customer_Product_Lookup AS
SELECT S.*,
CONCAT(C.FirstName, ' ', C.LastName) AS CustomerFullName,
P.`Unit Price` AS ProductUnitPrice
FROM Sales_Union_Final AS S
LEFT JOIN DimCustomer AS C ON S.CustomerKey = C.CustomerKey
LEFT JOIN DimProduct AS P ON S.ProductKey = P.ProductKey;    
DESCRIBE DimProduct;
-- to check the output
SELECT *FROM Sales_Customer_Product_Lookup;
DESCRIBE DimProduct;

-- 3.calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey)
SELECT OrderDateKey, STR_TO_DATE(OrderDateKey, '%Y%m%d') AS OrderDate
FROM Sales_Union_Final;

# YEAR
SELECT YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Year
FROM Sales_Union_Final;

# MONTH  NUMBER
SELECT MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo
FROM Sales_Union_Final;

# MONTH FULL NAME
SELECT MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthFullName
FROM Sales_Union_Final;

# QUARTER 1,2,3,4
SELECT CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d'))) AS Quarter
FROM Sales_Union_Final;

#YEAR MONTH (YYYY-MM)
SELECT DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'),'%Y-%b'
    ) AS YearMonth
FROM Sales_Union_Final;

# WEEKDAY NUMBER
SELECT WEEKDAY(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 1 AS WeekdayNo
FROM Sales_Union_Final;

# WEEKDAY NAME
SELECT DAYNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS WeekdayName
FROM Sales_Union_Final;

# FINANCIAL MONTH
SELECT
CASE
WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) >= 4
THEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) - 3
ELSE MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 9
END AS FinancialMonth
FROM Sales_Union_Final;

#FINANCIAL QUARTER
SELECT
CASE
WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 4 AND 6 THEN 'Q1'
WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 7 AND 9 THEN 'Q2'
WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 10 AND 12 THEN 'Q3'
ELSE 'Q4'
END AS FinancialQuarter
FROM Sales_Union_Final;


-- 4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
# FORMULA: Sales Amount = Unit Price × Order Quantity × (1 - Unit Discount)
SELECT UnitPrice,OrderQuantity,UnitPriceDiscountPct,
(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS SalesAmount
FROM Sales_Union_Final;

-- 5.Calculate the Productioncost uning the columns(unit cost ,order quantity)
# FORMULA:Production Cost = Unit Cost × Order Quantity
SELECT
ProductStandardCost,OrderQuantity,
(ProductStandardCost * OrderQuantity) AS ProductionCost
FROM Sales_Union_Final;

-- 6.CALCULATE THE PROFIT
# FORMULA: Profit = Sales Amount - Production Cost
SELECT (UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS SalesAmount,
(ProductStandardCost * OrderQuantity) AS ProductionCost,
((UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct))
- (ProductStandardCost * OrderQuantity)) AS Profit FROM Sales_Union_Final;

-- total Profit
SELECT SUM((UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct))- (ProductStandardCost * OrderQuantity)) AS TotalProfit
FROM Sales_Union_Final;

-- 11.Create a combinational chart (bar and Line) to show Salesamount and Productioncost together
SELECT MONTHNAME(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS Month,
SUM(SalesAmount) AS TotalSales,
SUM(ProductStandardCost * OrderQuantity) AS ProductionCost
FROM Sales_Customer_Product_Lookup
GROUP BY MONTH(STR_TO_DATE(OrderDateKey,'%Y%m%d')),MONTHNAME(STR_TO_DATE(OrderDateKey,'%Y%m%d'))
ORDER BY MONTH(STR_TO_DATE(OrderDateKey,'%Y%m%d'));


-- 12.Build addtional KPI /Charts for Performance by Products, Customers, Region
# Top 10 Products by Sales
SELECT P.EnglishProductName, SUM(S.SalesAmount) AS TotalSales
FROM Sales_Union_Final S
LEFT JOIN DimProduct P ON S.ProductKey = P.ProductKey
GROUP BY P.EnglishProductName
ORDER BY TotalSales DESC
LIMIT 10;

# Top 10 Customers by Sales
SELECT CustomerFullName, SUM(SalesAmount) AS TotalSales
FROM Sales_Customer_Product_Lookup
GROUP BY CustomerFullName
ORDER BY TotalSales DESC
LIMIT 10;

# Region Performance
SELECT * FROM DimSalesTerritory;
SELECT ST.SalesTerritoryRegion,SUM(S.SalesAmount) AS TotalSales
FROM Sales_Union_Final S
LEFT JOIN DimSalesTerritory ST ON S.SalesTerritoryKey = ST.SalesTerritoryKey
GROUP BY ST.SalesTerritoryRegion
ORDER BY TotalSales DESC;

SELECT * FROM DimSalesTerritory;

-- KPI 1: Total Sales
SELECT SUM(SalesAmount) AS TotalSales
FROM Sales_Union_Final;


-- KPI 2: Total Production Cost
SELECT SUM(ProductStandardCost * OrderQuantity) AS TotalProductionCost
FROM Sales_Union_Final;

-- KPI 3: Total Profit
SELECT SUM(SalesAmount) AS TotalSales,SUM(TotalProductCost) AS TotalProductCost,SUM(Freight) AS TotalFreight,SUM(TaxAmt) AS TotalTax,
SUM(SalesAmount) - SUM(TotalProductCost + Freight + TaxAmt) AS TotalProfit
FROM Sales_Union_Final;

-- KPI 4: Profit Margin (%)
SELECT ROUND(((SUM(SalesAmount)- SUM(TotalProductCost)- SUM(Freight)- SUM(TaxAmt))/ NULLIF(SUM(SalesAmount), 0)) * 100,2) AS ProfitMargin
FROM Sales_Union_Final;

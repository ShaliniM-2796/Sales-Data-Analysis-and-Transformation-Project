--Sales Data Analysis and Transformation Project

-- 1. Database Creation and Table Selection
CREATE DATABASE calculations;
USE calculations;

SELECT * FROM factinternetsales;
SELECT COUNT(*) FROM factinternetsales;

-- 2. Column Renaming for Data Cleaning
ALTER TABLE factinternetsales
RENAME COLUMN ProductKey TO Productkey;

SELECT * FROM factinternetsalesnew;
SELECT COUNT(*) FROM factinternetsalesnew;

SELECT * FROM dimcustomer;
SELECT COUNT(*) FROM dimcustomer;

ALTER TABLE dimcustomer
RENAME COLUMN CustomerKey TO Customerkey;

SELECT * FROM dimdate;
SELECT COUNT(*) FROM dimdate;

ALTER TABLE dimdate
RENAME COLUMN DateKey TO Datekey;

SELECT * FROM dimproduct;
SELECT COUNT(*) FROM dimproduct;

ALTER TABLE dimproduct
RENAME COLUMN ProductKey TO Productkey;

SELECT * FROM dimproductcategory;
SELECT COUNT(*) FROM dimproductcategory;

ALTER TABLE dimproductcategory
RENAME COLUMN ProductCategoryKey TO ProductCategorykey;

SELECT * FROM dimproductsubcategory;
SELECT COUNT(*) FROM dimproductsubcategory;

ALTER TABLE dimproductsubcategory
RENAME COLUMN ProductSubcategoryKey TO ProductSubcategorykey;

SELECT * FROM dimsalesterritory;
SELECT COUNT(*) FROM dimsalesterritory;

ALTER TABLE dimsalesterritory
RENAME COLUMN SalesTerritoryKey TO SalesTerritoryKey;

-- 3. Data Union
CREATE VIEW salesunion AS 
SELECT * FROM calculations.factinternetsales
UNION
SELECT * FROM calculations.factinternetsalesnew;

-- 4. Data Lookup and Join
SELECT s.*, dp.EnglishProductName
FROM salesunion s
JOIN dimproduct dp ON s.ProductKey = dp.ProductKey;

-- 5. Customer and Unit Price Lookup
SELECT s.*, 
CONCAT(dc.FirstName, ' ', dc.MiddleName, ' ', dc.LastName) AS CustomerFullName, 
s.UnitPrice
FROM salesunion s
JOIN dimcustomer dc ON s.CustomerKey = dc.CustomerKey
JOIN dimproduct dp ON s.ProductKey = dp.ProductKey;

-- 6. Date Field Transformations
SELECT STR_TO_DATE(OrderDateKey, '%Y%m%d') AS 'OrderDate' FROM salesunion;
SELECT YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS 'Year' FROM salesunion;
SELECT MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS 'MonthNo' FROM salesunion;
SELECT MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS 'MonthName' FROM salesunion;
SELECT CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d'))) AS 'Quarter' FROM salesunion;
SELECT DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'), '%Y %b') AS 'YearMonth' FROM salesunion;
SELECT WEEKDAY(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS 'WeekdayNo' FROM salesunion;
SELECT DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'), '%W') AS 'WeekdayName' FROM salesunion;

-- 7. Financial Calculations
SELECT CASE 
       WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) <= 3 THEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 9
       ELSE MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) - 3
       END AS FinancialMonth 
FROM salesunion;

SELECT CASE 
       WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) <= 3 THEN 'Q4'
       WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) <= 6 THEN 'Q1'
       WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) <= 9 THEN 'Q2'
       ELSE 'Q3'
       END AS FinancialQuarter 
FROM salesunion;

-- 8. Sales Amount Calculation
SELECT ROUND(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct), 2) AS SalesAmount
FROM salesunion;

-- 9. Production Cost Calculation
SELECT ROUND(ProductStandardCost * OrderQuantity, 2) AS ProductionCost
FROM salesunion;

-- 10. Profit Calculation
SELECT ROUND((UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) - (ProductStandardCost * OrderQuantity), 2) AS Profit
FROM salesunion;

-- 11. Year-wise Sales Analysis
SELECT YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Year, 
ROUND(SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)), 2) AS SalesAmount
FROM salesunion 
GROUP BY YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) 
ORDER BY SalesAmount DESC;

-- 12. Month-wise Sales for Line Chart
SELECT MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Month, 
ROUND(SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)), 2) AS SalesAmount
FROM salesunion 
GROUP BY Month;

-- 13. Quarter-wise Sales
SELECT 
    CASE 
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 7 AND 9 THEN 'Q3'
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 10 AND 12 THEN 'Q4'
    END AS Quarter,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM salesunion 
GROUP BY Quarter;

-- 14. Combination Chart for Sales and Production Cost
SELECT MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Month, 
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales, 
SUM(ProductStandardCost * OrderQuantity) AS TotalCost
FROM salesunion 
GROUP BY Month;

-- 15. Top 10 Products by Sales
SELECT p.EnglishProductName AS Top_10_Products, 
ROUND(SUM(s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)), 2) AS SalesAmount
FROM dimproduct p 
JOIN salesunion s ON p.ProductKey = s.ProductKey
GROUP BY p.EnglishProductName
LIMIT 10;

-- 16. Top 10 Customers by Sales
SELECT CONCAT(c.FirstName, ' ', COALESCE(c.MiddleName, ''), ' ', COALESCE(c.LastName, '')) AS Top_10_Customers, 
ROUND(SUM(s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)), 2) AS SalesAmount
FROM dimcustomer c 
JOIN salesunion s ON c.CustomerKey = s.CustomerKey
GROUP BY Top_10_Customers
ORDER BY SalesAmount DESC
LIMIT 10;

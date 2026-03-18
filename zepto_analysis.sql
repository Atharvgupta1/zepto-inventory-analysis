-- =========================================
-- RETAIL INVENTORY & PRICING ANALYSIS
-- =========================================


-- 1. SETTING UP THE TABLE
-- Creating a structured table to store product-level retail data

DROP TABLE IF EXISTS zepto;

CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150),
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INTEGER,
    outOfStock BOOLEAN,
    quantity INTEGER );


-- =========================================
-- 2. UNDERSTANDING THE DATA
-- Exploring the dataset to get a basic sense of structure and quality
-- =========================================

-- Total number of products in the dataset
SELECT COUNT(*) AS total_products 
FROM zepto;

-- Checking for missing or incomplete records
SELECT * 
FROM zepto
WHERE name IS NULL 
   OR category IS NULL 
   OR mrp IS NULL;

-- Understanding how products are distributed across categories
SELECT 
    category, 
    COUNT(*) AS product_count
FROM zepto
GROUP BY category
ORDER BY product_count DESC;

-- Checking how many products are in stock vs out of stock
SELECT 
    outOfStock, 
    COUNT(*) AS total_products
FROM zepto
GROUP BY outOfStock;

-- Identifying duplicate product names (if any)
SELECT 
    name, 
    COUNT(*) AS duplicate_count
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1;


-- =========================================
-- 3. CLEANING THE DATA
-- Fixing inconsistencies to ensure accurate analysis
-- =========================================

-- Identifying products with invalid pricing
SELECT * 
FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

-- Removing unrealistic entries where MRP is zero
DELETE FROM zepto 
WHERE mrp = 0;

-- Converting prices from paise to rupees for better readability
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- Verifying whether discount percentages are accurate
SELECT 
    name, 
    mrp, 
    discountedSellingPrice,
    discountPercent,
    ROUND(((mrp - discountedSellingPrice)/mrp)*100,2) AS actual_discount
FROM zepto;


-- =========================================
-- 4. FEATURE CREATION
-- Creating additional metrics to improve analysis
-- =========================================

-- Calculating price per gram to evaluate product value
SELECT 
    name, 
    weightInGms, 
    discountedSellingPrice,
    ROUND(discountedSellingPrice / weightInGms,2) AS price_per_gram
FROM zepto;

-- Categorizing products based on weight
SELECT 
    name,
    CASE 
        WHEN weightInGms < 1000 THEN 'Low'
        WHEN weightInGms < 5000 THEN 'Medium'
        ELSE 'Bulk'
    END AS weight_category
FROM zepto;

-- Estimating profit (assuming cost = 70% of MRP)
SELECT 
    name, 
    mrp, 
    discountedSellingPrice,
    ROUND(mrp * 0.7,2) AS estimated_cost,
    ROUND(discountedSellingPrice - (mrp * 0.7),2) AS estimated_profit
FROM zepto;


-- =========================================
-- 5. BUSINESS ANALYSIS
-- Answering practical retail questions using SQL
-- =========================================

-- Identifying products that offer high discounts (potential best deals)
SELECT 
    name, 
    mrp, 
    discountPercent
FROM zepto
ORDER BY discountPercent DESC, discountedSellingPrice ASC
LIMIT 10;

-- Finding expensive products that are currently out of stock (high demand signal)
SELECT 
    name, 
    mrp
FROM zepto
WHERE outOfStock = TRUE 
  AND mrp > 300;

-- Estimating total inventory value by category (not actual revenue)
SELECT 
    category,
    SUM(discountedSellingPrice * availableQuantity) AS inventory_value
FROM zepto
GROUP BY category;

-- Identifying overpriced products (high MRP with low discount)
SELECT 
    name, 
    mrp, 
    discountPercent
FROM zepto
WHERE mrp > 500 
  AND discountPercent < 10;

-- Understanding pricing and discount trends across categories
SELECT 
    category,
    AVG(discountedSellingPrice) AS avg_price,
    AVG(discountPercent) AS avg_discount
FROM zepto
GROUP BY category;

-- Detecting potential dead inventory (high stock but low discount)
SELECT 
    name, 
    availableQuantity
FROM zepto
WHERE availableQuantity > 100 
  AND discountPercent < 10;

-- Identifying products at risk of stockout (very low stock)
SELECT 
    name, 
    availableQuantity
FROM zepto
WHERE availableQuantity < 10 
  AND outOfStock = FALSE;
	
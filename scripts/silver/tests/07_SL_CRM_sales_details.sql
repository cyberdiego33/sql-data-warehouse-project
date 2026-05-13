SELECT TOP (1000) [sls_ord_num]
      ,[sls_prd_key]
      ,[sls_cust_id]
      ,[sls_order_dt]
      ,[sls_ship_dt]
      ,[sls_due_dt]
      ,[sls_sales]
      ,[sls_quantity]
      ,[sls_price]
  FROM [DataWarehouse].[bronze].[crm_sales_details]

-- 01 Checking for unwanted spaces
SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num); -- good

-- 02 Checking the dates quality
/* The dates (sls_order_dt, sls_ship_dt, sls_due_dt) are bad dates and need tranformation  */

SELECT 
sls_order_dt
FROM bronze.crm_sales_details
WHERE 
    sls_order_dt <= 0 -- Is a negative num
    OR LEN(sls_order_dt) != 8; -- Is not complete 
    -- 0 Exist and also some dates are not complete

-- Fix
SELECT 
    -- sls_ord_num, sls_prd_key, sls_cust_id,
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
         ELSE CAST (CAST(sls_order_dt AS VARCHAR) AS DATE) -- Changing the type from INT to DATE
    END AS sls_ord_dt                                      -- INT can't be converted directly so we first change to a VARCHAR
FROM bronze.crm_sales_details
WHERE 
    sls_order_dt <= 0 -- Is a negative num
    OR LEN(sls_order_dt) != 8;

-- 03 Checking for invalid date orders where the order date is older than the shipping date
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt; 
-- Good

-- 05 Time to check the sales, quantity and price
/*
01 Sales should be = Quantity * Price
02 Negative, zeros, NULLs are Not Allowed!
*/
SELECT sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_quantity > 1

SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;
-- Alot of bad data

--Fix
SELECT 
    sls_sales AS old_sales_value,
    sls_quantity,
    sls_price AS old_sales_price,

    CASE WHEN sls_sales IS NULL 
        OR sls_sales <= 0 
        OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    CASE WHEN sls_price IS NULL
        OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
    OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Inserting the Cleaned Data into Silver table crm_sales_details
INSERT INTO silver.crm_sales_details (
    sls_ord_num, sls_prd_key, sls_cust_id,
    sls_order_dt, sls_ship_dt, sls_due_dt,
    sls_sales, sls_quantity, sls_price
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE 
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
    END AS sls_order_dt,

    CASE  -- Applying same rule for sls_ship_dt 
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE) 
    END AS sls_ship_dt,

    CASE  -- Applying same rule for sls_due_dt 
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE) 
    END AS sls_due_dt,

    CASE WHEN sls_sales IS NULL 
        OR sls_sales <= 0 
        OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    
    sls_quantity,
    CASE WHEN sls_price IS NULL
        OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;

-- Go back and check the health of the silver table
SELECT * FROM silver.crm_sales_details;
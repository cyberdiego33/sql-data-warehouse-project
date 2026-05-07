SELECT [prd_id]
      ,[prd_key]
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
      ,[prd_nm]
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,CASE UPPER(TRIM(prd_line))
           WHEN 'M' THEN 'Mountain'
           WHEN 'R' THEN 'Road'
           WHEN 'S' THEN 'Other Sales'
           WHEN 'T' THEN 'Touring'
           ELSE 'n/a'
       END AS prd_line
      ,prd_start_dt
      ,DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
  FROM [DataWarehouse].[bronze].[crm_prd_info]

-- 01 Check for duplicate prd_id or NULL prd_id
SELECT prd_id, COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL; -- No Duplicates found

-- 02 Checking for Unwwanted spaces on the prd_nm
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- 03 Checking the cost column for negative or Null values
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL; -- Found 2 Null Values

-- 04 Checking Data Credibility, Standardization & Consistency
SELECT DISTINCT prd_line 
FROM bronze.crm_prd_info;
-- Changed M,R,S,T TO Mountain, Road, Other Sales, Touring

-- 05 Checking for invalid Order Dates
SELECT prd_start_dt, prd_end_dt
FROM bronze.crm_prd_info
-- So the dates are bad, the end dates are even earlier than the start dates
-- The fix
SELECT 
    prd_id, prd_key, prd_nm,
    prd_start_dt, prd_end_dt,
    DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509'); 
-- This method uses the next start-date of the same product minus a day to decide the end date 

-- Loading the data into the silver Layer
INSERT INTO silver.crm_prd_info (
    prd_id, cat_id, prd_key,
    prd_nm, prd_cost, prd_line,
    prd_start_dt, prd_end_dt
) SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
      ,prd_nm
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,CASE UPPER(TRIM(prd_line))
           WHEN 'M' THEN 'Mountain'
           WHEN 'R' THEN 'Road'
           WHEN 'S' THEN 'Other Sales'
           WHEN 'T' THEN 'Touring'
           ELSE 'n/a'
       END AS prd_line
      ,prd_start_dt
      ,DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
  FROM bronze.crm_prd_info;

 -- Checking the quality of the silver table
 SELECT * FROM silver.crm_prd_info;
SELECT 
	cid, bdate, gen
FROM bronze.erp_cust_az12;

-- Checking if the cid in this Table will match the cst_key in crm_cust_info
SELECT * FROM silver.crm_cust_info; -- Looks like there's extra char (NAS) in some cid rows
--Example
SELECT cid, bdate, gen 
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011000'; -- Brought a result but has extra NAS

-- clean up
SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	bdate, gen
FROM bronze.erp_cust_az12
-- TESTING at once
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info); 


-- Checking for Dates that are out-of-range (> 100yrs ago / in FUTURE)
SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1926-01-01' OR bdate > GETDATE(); -- Found some

-- Replacing on the FUTURE dates to Null
SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate,
	gen
FROM bronze.erp_cust_az12;

-- Data Standardization & Consistency for COLUMN (gen)
SELECT DISTINCT gen
FROM bronze.erp_cust_az12; -- Bad
-- Fix
SELECT DISTINCT gen,
	CASE 
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12

-- Inserting Cleaned Data
INSERT INTO silver.erp_cust_az12 (
	cid, bdate, gen
) SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate,
	CASE 
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12;

-- Always go back to check Data Quality
SELECT * FROM silver.erp_cust_az12;
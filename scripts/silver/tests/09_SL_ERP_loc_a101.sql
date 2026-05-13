SELECT cid, cntry
FROM bronze.erp_loc_a101;

-- Test if cid matches cst_key in crm_cust_info
SELECT cst_key FROM silver.crm_cust_info;
-- There is a - BTW the AW and the 00011000 (AW-0011000) in erp_loc_a101

-- Fix
SELECT 
	REPLACE(cid, '-', '') AS cid,
	cntry
FROM bronze.erp_loc_a101;

-- Data Standardization & Consistency for cntry (Country)
SELECT DISTINCT cntry FROM bronze.erp_loc_a101
ORDER BY cntry; -- Bad
-- Fix
SELECT
	 DISTINCT cntry AS old_cntry,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END AS cntry -- Normalized and Handled missing, abbreviated, Null or blank country values
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- Inserting Cleaned Data into Silver Table
INSERT INTO silver.erp_loc_a101 (
	cid, cntry
) SELECT
	REPLACE(cid, '-', '') AS cid,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101;

-- Always remember to check Data quality
SELECT * FROM silver.erp_loc_a101;
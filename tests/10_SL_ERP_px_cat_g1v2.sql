SELECT 
	id, cat, subcat, maintenance
FROM bronze.erp_px_cat_g1v2;

-- Check for unwanted spaces
SELECT cat
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
	OR subcat != TRIM(subcat)
	OR maintenance != TRIM(maintenance) -- Good

-- Data Standardization & Consistency
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;

-- This Table has GOOD Data Quality
INSERT INTO silver.erp_px_cat_g1v2 (
	id, cat, subcat, maintenance
) SELECT 
	id, cat, subcat, maintenance
FROM bronze.erp_px_cat_g1v2;

-- Final Check
SELECT * FROM silver.erp_px_cat_g1v2;

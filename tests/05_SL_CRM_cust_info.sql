-- 01 Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT 
	cst_id, count(*) AS noOfDuplicates
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;
-- Result: Duplicate Primary Keys & Nullish Primary Key

-- Cleaning duplicate primary key 
-- Creating TEMP TABLE based on the result
DROP TABLE IF EXISTS #NoDuplicatesID;
SELECT *
INTO #NoDuplicatesID
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t
WHERE flag_last = 1;

SELECT * FROM #NoDuplicatesID WHERE flag_last > 1; -- Cleaned

-- 02  Check for unwanted spaces
SELECT *
FROM #NoDuplicatesID
WHERE cst_firstname != TRIM(cst_firstname) OR cst_lastname != TRIM(cst_lastname);
-- Unwanted Spaces Exists

-- Cleaning
DROP TABLE IF EXISTS #NoUWTspaces;

SELECT 
	cst_id, cst_key,
	TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname,
	cst_marital_status, cst_gndr, cst_create_date
INTO #NoUWTspaces
FROM #NoDuplicatesID;

SELECT *
FROM #NoUWTspaces
WHERE cst_firstname != TRIM(cst_firstname) OR cst_lastname != TRIM(cst_lastname);
-- Cleaned

-- 03 Data Standardization & Consistency
-- Changing Abbrevated values to full Meaningful values
SELECT 
	cst_id, cst_key,
	cst_firstname, cst_lastname, 
	CASE WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
		 WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
		 ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
		 WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date
INTO #Clean_crm_cust_info
FROM #NoUWTspaces
ORDER BY cst_id;

SELECT * FROM #Clean_crm_cust_info; -- Cleaned

-- 04 Loading crm_cust_info into Silver Layer
INSERT INTO silver.crm_cust_info (
	cst_id, cst_key, 
	cst_firstname, cst_lastname,
	cst_marital_status, cst_gndr,
	cst_create_date
) SELECT 
	cst_id, cst_key, 
	cst_firstname, cst_lastname,
	cst_marital_status, cst_gndr,
	cst_create_date
FROM #Clean_crm_cust_info;


-- FINAL CHECK on silver.crm_cust_info
-- 01 Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT 
	cst_id, count(*) AS noOfDuplicates
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL; -- Good

-- 02  Check for unwanted spaces
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) OR cst_lastname != TRIM(cst_lastname); -- Good

-- 03 Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info; -- Good 

-- Check out the whole table 
SELECT * FROM silver.crm_cust_info WHERE cst_id = 11006;


-- Everything in 1 single Query
TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info(
	cst_id, cst_key, 
	cst_firstname, cst_lastname,
	cst_marital_status, cst_gndr,
	cst_create_date
)
SELECT 
	cst_id, cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
		 WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
		 ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
		 WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM (
SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t
WHERE flag_last = 1;

SELECT * FROM silver.crm_cust_info;

/* CREATE CLUSTERED INDEX IX_silver_crm_cust_info_cst_id 
ON silver.crm_cust_info (cst_id); */

/* Joining the 3 tables on customer info */
SELECT 
	ci.cst_id, ci.cst_key,
	ci.cst_firstname, ci.cst_lastname,
	ci.cst_marital_status, ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate, ca.gen,
	la.cntry
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
-- It happens that we have 2 columns for the same info ci.cst_gndr & ca.gen

-- Data integration: Combining 2 cols in one 
-- We Decided CRM is the Master for gender info 
SELECT DISTINCT
	ci.cst_gndr, ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr 
		 ELSE COALESCE(ca.gen, 'n/a') 
	END AS new_gen
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
ORDER BY 1,2

-- We are creating a view instead of a table
CREATE VIEW gold.dim_customers AS -- If line shows error: ignore 😒
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key, -- Surrogate Key
	ci.cst_id AS customer_id, 
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name, 
	ci.cst_lastname AS last_name, 
	la.cntry AS country,
	ci.cst_marital_status AS marital_status, 
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr 
		 ELSE COALESCE(ca.gen, 'n/a') 
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid

/* Checking the Quality of the Gold View */
SELECT * FROM gold.dim_customers;
SELECT DISTINCT gender FROM gold.dim_customers;
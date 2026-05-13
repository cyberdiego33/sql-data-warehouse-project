CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key, -- Our Surrogate key from Gold layer dim_products table
	cu.customer_key, -- Our Surrogate key from Gold layer dim_customers table
 /* sd.sls_prd_key, */
 /*	sd.sls_cust_id, */
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details AS sd
-- Now we went and Joined this table with the dim_customers & dim_products using our own surrogate keys we created for each of them
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.customer_id


/* Check the quality of the View */
/*
SELECT * 
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
LEFT JOIN gold.dim_products AS dp
ON dp.product_key = fs.product_key
WHERE fs.customer_key IS NULL OR dp.product_key IS 
-- Clean and Good
*/
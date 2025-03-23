-- Проверка количества записей
SELECT 'stg.orders' AS table_name, COUNT(*) AS record_count FROM stg.orders
UNION ALL
SELECT 'dw.sales_fact', COUNT(*) FROM dw.sales_fact;

-- Проверка целостности данных
SELECT 'Missing ship_ids' AS issue, COUNT(*) AS count
FROM dw.sales_fact f
LEFT JOIN dw.shipping_dim s ON f.ship_id = s.ship_id
WHERE s.ship_id IS NULL
UNION ALL
SELECT 'Missing geo_ids', COUNT(*)
FROM dw.sales_fact f
LEFT JOIN dw.geo_dim g ON f.geo_id = g.geo_id
WHERE g.geo_id IS NULL
UNION ALL
SELECT 'Missing prod_ids', COUNT(*)
FROM dw.sales_fact f
LEFT JOIN dw.product_dim p ON f.prod_id = p.prod_id
WHERE p.prod_id IS NULL
UNION ALL
SELECT 'Missing cust_ids', COUNT(*)
FROM dw.sales_fact f
LEFT JOIN dw.customer_dim c ON f.cust_id = c.cust_id
WHERE c.cust_id IS NULL;
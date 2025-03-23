-- Проверка отсутствия дубликатов
SELECT customer_id, COUNT(*)
FROM dw.customer_dim
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Проверка ссылочной целостности
SELECT COUNT(*) 
FROM dw.sales_fact f
LEFT JOIN dw.customer_dim c ON f.cust_id = c.cust_id
WHERE c.customer_id IS NULL;
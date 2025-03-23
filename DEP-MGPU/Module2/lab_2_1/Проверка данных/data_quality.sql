-- 1. Количество записей

-- Проверка количества записей в источнике и приемнике
SELECT COUNT(*) FROM stg.orders;
SELECT COUNT(*) FROM dw.sales_fact;

-- Проверка распределения данных
SELECT category, COUNT(*) 
FROM dw.product_dim 
GROUP BY category;

-- 2. Целостность данных

-- Проверка отсутствия дубликатов
SELECT customer_id, COUNT(*)
FROM dw.customer_dim
GROUP BY customer_id
HAVING COUNT(*) > 1;

--получилась пустая таблица, поэтому в решении её нет

-- Проверка ссылочной целостности
SELECT COUNT(*) 
FROM dw.sales_fact f
LEFT JOIN dw.customer_dim c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 3. Корректность расчетов

-- Проверка корректности агрегатов
SELECT 
    SUM(sales) as total_sales,
    SUM(profit) as total_profit
FROM stg.orders;

SELECT 
    SUM(sales) as total_sales,
    SUM(profit) as total_profit
FROM dw.sales_fact;

--Значения в двух таблицах равны
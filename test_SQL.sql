-- 1) Количество покупателей из Италии и Франции
SELECT
    ctry.country_name,
    COUNT(DISTINCT cust.customer_id) AS CustomerCountDistinct
FROM
    Customers cust
JOIN
    Countries ctry 
	ON cust.country_code = ctry.country_code
WHERE
    ctry.country_name IN ('France', 'Italy')
GROUP BY ctry.country_name

-- 2) ТОП 10 покупателей по расходам
WITH CustomerRevenue AS (
    SELECT 
        c.customer_name, 
        SUM(o.quantity * i.item_price) AS Revenue,
        dense_rank() OVER (ORDER BY SUM(o.quantity * i.item_price) DESC) AS RevenueRank
    FROM Orders o
    JOIN Customers c ON o.customer_id = c.customer_id
    JOIN Items i ON o.item_id = i.item_id
    GROUP BY c.customer_name
)
SELECT customer_name, Revenue
FROM CustomerRevenue
WHERE RevenueRank <= 10
ORDER BY Revenue DESC;

-- Альтернатива
SELECT
    cust.customer_name,
    SUM(ord.quantity * itm.item_price) AS Revenue
FROM
    Orders ord
JOIN
    Customers cust ON ord.customer_id = cust.customer_id
JOIN
    Items itm ON ord.item_id = itm.item_id
GROUP BY
    cust.customer_name
ORDER BY Revenue DESC
LIMIT 10




-- 3. Общая выручка USD по странам, если нет дохода, вернуть NULL
SELECT co.country_name, 
       CASE 
           WHEN SUM(o.quantity * i.item_price) IS NULL THEN 'NULL'
           ELSE SUM(o.quantity * i.item_price)
       END AS RevenuePerCountry
FROM Orders o
LEFT JOIN Customers c ON co.country_code = c.country_code
LEFT JOIN Orders o ON c.customer_id = o.customer_id
LEFT JOIN Items i ON o.item_id = i.item_id
GROUP BY co.country_name



-- 4. Самый дорогой товар, купленный одним покупателем
SELECT c.customer_id, c.customer_name, i.item_name AS MostExpensiveItemName
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Items i ON o.item_id = i.item_id
WHERE (o.customer_id, i.item_price) IN (
    SELECT o.customer_id, MAX(i.item_price)
    FROM Orders o
    JOIN Items i ON o.item_id = i.item_id
    GROUP BY o.customer_id
)

-- 5. Ежемесячный доход
SELECT TO_CHAR(o.date_time, 'MM') AS Month, SUM(o.quantity * i.item_price) AS TotalRevenue
FROM Orders o
JOIN Items i ON o.item_id = i.item_id
GROUP BY TO_CHAR(o.date_time, 'MM')
ORDER BY Month

-- 6. Найти дубликаты
SELECT o.date_time, o.customer_id, o.item_id, COUNT(*) AS DuplicateCount
FROM Orders o
GROUP BY o.date_time, o.customer_id, o.item_id
HAVING COUNT(*) > 1


-- 7. Найти "важных" покупателей
WITH FirstOrder AS (
    SELECT customer_id, MIN(date_time) AS first_order_time
    FROM Orders
    GROUP BY customer_id
)
SELECT o.customer_id, COUNT(*) AS TotalOrdersCount
FROM Orders o
JOIN FirstOrder fo ON o.customer_id = fo.customer_id
WHERE o.date_time > fo.first_order_time
GROUP BY o.customer_id
ORDER BY TotalOrdersCount DESC

-- 8. Найти покупателей с "ростом" за последний месяц
WITH MonthlyRevenue AS (
    SELECT customer_id, 
           TO_CHAR(date_time, 'YYYY-MM') AS month, 
           SUM(quantity * item_price) AS monthly_revenue
    FROM Orders o
    JOIN Items i ON o.item_id = i.item_id
    GROUP BY customer_id, TO_CHAR(date_time, 'YYYY-MM')
),
AverageRevenue AS (
    SELECT customer_id, AVG(monthly_revenue) AS avg_revenue
    FROM MonthlyRevenue
    GROUP BY customer_id
)
SELECT mr.customer_id, mr.monthly_revenue AS TotalRevenue
FROM MonthlyRevenue mr
JOIN AverageRevenue ar ON mr.customer_id = ar.customer_id
WHERE mr.month = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM')
  AND mr.monthly_revenue > ar.avg_revenue

#Список клиентов с непрерывной историей

WITH filtered_trans AS (
    SELECT 
        ID_client,
        Sum_payment,
        Id_check,
        DATE_FORMAT(STR_TO_DATE(date_new, '%d/%m/%Y'), '%Y-%m-01') as month_date,
        STR_TO_DATE(date_new, '%d/%m/%Y') as real_date
    FROM transactions_info
)
, continuous_clients AS (
    SELECT ID_client
    FROM filtered_trans
    WHERE real_date >= '2015-06-01' AND real_date <= '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month_date) = 13
)
SELECT 
    t.ID_client,
    AVG(t.Sum_payment) AS avg_check,
    SUM(t.Sum_payment) / 12 AS avg_monthly_sum,
    COUNT(t.Id_check) AS total_operations
FROM transactions_info t
JOIN continuous_clients cc ON t.ID_client = cc.ID_client
WHERE STR_TO_DATE(t.date_new, '%d/%m/%Y') >= '2015-06-01' 
  AND STR_TO_DATE(t.date_new, '%d/%m/%Y') <= '2016-06-01'
GROUP BY t.ID_client;

# Информация в разрезе месяцев (Средние показатели)
SELECT 
    DATE_FORMAT(STR_TO_DATE(date_new, '%d/%m/%Y'), '%Y-%m') AS month,
    AVG(Sum_payment) AS avg_check_monthly,
    COUNT(Id_check) / COUNT(DISTINCT ID_client) AS avg_ops_per_client,
    COUNT(DISTINCT ID_client) AS active_clients
FROM transactions_info
WHERE STR_TO_DATE(date_new, '%d/%m/%Y') BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month
ORDER BY month;

# Доли операций и суммы по месяцам
WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(STR_TO_DATE(date_new, '%d/%m/%Y'), '%Y-%m') AS month,
        COUNT(Id_check) AS m_ops,
        SUM(Sum_payment) AS m_sum
    FROM transactions_info
    WHERE STR_TO_DATE(date_new, '%d/%m/%Y') BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month
)
SELECT 
    month,
    m_ops * 100.0 / SUM(m_ops) OVER() AS share_ops_annual, # Доля операций за год
    m_sum * 100.0 / SUM(m_sum) OVER() AS share_sum_annual  # Доля суммы за год
FROM monthly_data;

#Соотношение M/F/NA и доли их затрат по месяцам
SELECT 
    DATE_FORMAT(STR_TO_DATE(t.date_new, '%d/%m/%Y'), '%Y-%m') AS month,
    COUNT(CASE WHEN c.Gender = 'M' THEN 1 END) * 100.0 / COUNT(*) AS pct_M,
    COUNT(CASE WHEN c.Gender = 'F' THEN 1 END) * 100.0 / COUNT(*) AS pct_F,
    COUNT(CASE WHEN c.Gender IS NULL OR c.Gender = '' THEN 1 END) * 100.0 / COUNT(*) AS pct_NA,
    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) AS spend_share_M,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) AS spend_share_F
FROM transactions_info t
LEFT JOIN customer_info c ON t.ID_client = c.Id_client
WHERE STR_TO_DATE(t.date_new, '%d/%m/%Y') BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

# Возрастные группы и кварталы
SELECT 
    CASE 
        WHEN c.Age IS NULL THEN 'No Data'
        ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
    END AS age_group,
    YEAR(STR_TO_DATE(t.date_new, '%d/%m/%Y')) AS yr,
    QUARTER(STR_TO_DATE(t.date_new, '%d/%m/%Y')) AS qrt,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(t.Id_check) AS total_ops,
    AVG(t.Sum_payment) AS avg_check,
    SUM(t.Sum_payment) * 100.0 / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY YEAR(STR_TO_DATE(t.date_new, '%d/%m/%Y')), QUARTER(STR_TO_DATE(t.date_new, '%d/%m/%Y'))) AS pct_of_quarter_sum
FROM transactions_info t
LEFT JOIN customer_info c ON t.ID_client = c.Id_client
WHERE STR_TO_DATE(t.date_new, '%d/%m/%Y') BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group, yr, qrt
ORDER BY yr, qrt, age_group;

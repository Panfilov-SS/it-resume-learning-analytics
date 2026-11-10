-- Динамика числа попыток пользователей компании company_id = 1.
-- Сравниваются текущий и предыдущий месяцы с попытками.
-- Месяцы без попыток пропускаются, падение до нуля не отражается.
-- GOOD / BAD обозначают увеличение / уменьшение числа попыток.
-- Рост числа попыток сам по себе не означает улучшения обучения.

WITH attempts AS
(
SELECT
cs.user_id,
date_trunc('month', cs.created_at) AS month,
COUNT(*) AS attempts
FROM codesubmit cs
INNER JOIN users u
ON cs.user_id = u.id
WHERE u.company_id = 1
GROUP BY
cs.user_id,
date_trunc('month', cs.created_at)
),

lag_attempts AS
(
SELECT
user_id,
month,
attempts,
LAG(attempts) OVER
(
PARTITION BY user_id
ORDER BY month
) AS prev_attempts
FROM attempts
)

SELECT
user_id,
month,
attempts,
prev_attempts,
CASE
WHEN prev_attempts IS NULL THEN 'FIRST MONTH'
WHEN attempts > prev_attempts THEN 'GOOD'
WHEN attempts < prev_attempts THEN 'BAD'
ELSE 'STAGNATION'
END AS classification
FROM lag_attempts
ORDER BY
user_id,
month;


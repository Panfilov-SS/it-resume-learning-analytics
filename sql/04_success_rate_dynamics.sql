-- Динамика доли успешных попыток пользователей компании company_id = 1.
-- Сравниваются текущий и предыдущий месяцы с попытками.
-- Месяцы без попыток пропускаются.
-- Сравнение выполняется после округления долей до двух знаков.
-- GOOD / BAD обозначают рост / снижение показателя, а не доказанное улучшение / ухудшение качества обучения.

WITH curr_success_rate AS
(
SELECT
cs.user_id,
date_trunc('month', cs.created_at) AS month,
COUNT(*) AS attempts,
COUNT(CASE WHEN cs.is_false = 0 THEN 1 END) AS success,
ROUND(
COUNT(CASE WHEN cs.is_false = 0 THEN 1 END) * 1.0
/ NULLIF(COUNT(*), 0),
2
) AS success_rate
FROM codesubmit cs
INNER JOIN users u
ON cs.user_id = u.id
WHERE u.company_id = 1
GROUP BY
cs.user_id,
date_trunc('month', cs.created_at)
),

final_res AS
(
SELECT
user_id,
month,
LAG(success_rate) OVER
(
PARTITION BY user_id
ORDER BY month
) AS prev_success_rate,
success_rate
FROM curr_success_rate
)

SELECT
user_id,
month,
prev_success_rate,
success_rate,
CASE
WHEN prev_success_rate IS NULL THEN 'FIRST MONTH'
WHEN success_rate > prev_success_rate THEN 'GOOD'
WHEN success_rate < prev_success_rate THEN 'BAD'
ELSE 'STAGNATION'
END AS classification_diff
FROM final_res
ORDER BY
user_id,
month;


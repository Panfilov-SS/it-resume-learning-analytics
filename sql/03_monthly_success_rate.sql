-- Успешность попыток пользователей компании company_id = 1 по месяцам.
-- success_rate — доля успешных попыток пользователя за месяц.
-- Месяцы без попыток в результат не входят.
-- При малом числе попыток показатель может быть нестабильным.

SELECT
cs.user_id AS user_id,
date_trunc('month', cs.created_at) AS month,
count(*) AS attempts,
count(CASE WHEN cs.is_false = 0 THEN 1 END) AS success,
round(count(CASE WHEN cs.is_false = 0 THEN 1 END) * 1.0 / count(*), 2) AS success_rate
FROM codesubmit AS cs
INNER JOIN users AS u
ON cs.user_id = u.id
WHERE u.company_id = 1
GROUP BY
cs.user_id,
date_trunc('month', cs.created_at)
ORDER BY success_rate ASC;


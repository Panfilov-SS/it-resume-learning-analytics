-- Анализ успешности когорт пользователей компании company_id = 1.
-- Когорты сформированы по календарному месяцу регистрации.
-- success_rate — доля успешных попыток когорты за месяц её жизни.
-- early_rate — среднее доступных месячных долей для возраста 0 и 1.
-- late_rate — доля успешных попыток в последнем месяце с попытками.
-- Ранний и поздний периоды могут пересекаться у молодых когорт.
-- Состав активных пользователей между периодами может меняться.
-- Динамика показателя не доказывает изменение навыков студентов.

WITH cohort_users AS
(
SELECT
id AS user_id,
date_trunc('month', date_joined) AS month_reg
FROM users
WHERE company_id = 1
),

active AS
(
SELECT
user_id,
date_trunc('month', created_at) AS activity_month,
COUNT(*) AS attempts,
COUNT(CASE WHEN is_false = 0 THEN 1 END) AS success
FROM codesubmit
GROUP BY 1, 2
),

base AS
(
SELECT
cu.month_reg,
a.user_id,
(
(EXTRACT(YEAR FROM a.activity_month) - EXTRACT(YEAR FROM cu.month_reg)) * 12 +
(EXTRACT(MONTH FROM a.activity_month) - EXTRACT(MONTH FROM cu.month_reg))
) AS cohort_age,
a.attempts,
a.success
FROM active a
JOIN cohort_users cu
ON a.user_id = cu.user_id
),

cohort_rates AS
(
SELECT
month_reg,
cohort_age,
SUM(success)::float / NULLIF(SUM(attempts),0) AS success_rate
FROM base
GROUP BY 1,2
),

cohort_summary AS
(
SELECT
month_reg,

AVG(CASE WHEN cohort_age IN (0,1) THEN success_rate END) AS early_rate,

AVG(CASE WHEN cohort_age IN (
SELECT MAX(cohort_age)
FROM cohort_rates c2
WHERE c2.month_reg = cohort_rates.month_reg
) THEN success_rate END) AS late_rate

FROM cohort_rates
GROUP BY month_reg
)

SELECT
month_reg,
early_rate,
late_rate,
(late_rate - early_rate) AS delta,
CASE
    WHEN early_rate IS NULL OR late_rate IS NULL
        THEN 'insufficient_data'
    WHEN late_rate < early_rate
        THEN 'declining'
    WHEN late_rate > early_rate
        THEN 'improving'
    ELSE 'unchanged'
END AS trend
FROM cohort_summary
ORDER BY delta ASC;

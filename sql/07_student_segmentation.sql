-- Сегментация пользователей компании company_id = 1 по активности.
-- Активный день — день хотя бы с одной попыткой решения.
-- Порог сегментации — медиана активных дней по всем парам «пользователь — месяц» с попытками.
-- low_activity: активных дней меньше медианы; иначе normal_activity.
-- Средняя сложность рассчитана по попыткам, а не уникальным задачам.
-- Динамика сравнивает соседние месяцы с попытками.
-- Сегментация не доказывает влияние активности на успешность.

WITH student_month AS
(
SELECT
cs.user_id,
date_trunc('month', cs.created_at) AS month,
count(*) AS attempts,
avg(CASE WHEN cs.is_false = 0 THEN 1 ELSE 0 END) AS success_rate,
avg(p.complexity) AS complexity_level,
count(DISTINCT date(cs.created_at)) AS active_days
FROM codesubmit cs
JOIN users u
ON cs.user_id = u.id
JOIN problem p
ON cs.problem_id = p.id
WHERE u.company_id = 1
GROUP BY
cs.user_id,
date_trunc('month', cs.created_at)
),

median_activity AS
(
SELECT
percentile_cont(0.5)
WITHIN GROUP (ORDER BY active_days) AS median_active_days
FROM student_month
),

student_trend AS
(
SELECT
sm.*,

row_number() OVER (
PARTITION BY user_id
ORDER BY month
) AS rn,

lag(complexity_level) OVER (
PARTITION BY user_id
ORDER BY month
) AS prev_complexity,

lag(success_rate) OVER (
PARTITION BY user_id
ORDER BY month
) AS prev_success

FROM student_month sm
)

SELECT
st.user_id,
st.month,

st.attempts,
st.active_days,
st.success_rate,
st.complexity_level,

st.complexity_level - st.prev_complexity
AS diff_complexity,

st.success_rate - st.prev_success
AS diff_success,

CASE
WHEN st.active_days < ma.median_active_days
THEN 'low_activity'
ELSE 'normal_activity'
END AS activity_segment

FROM student_trend st
CROSS JOIN median_activity ma
ORDER BY
user_id,
month;


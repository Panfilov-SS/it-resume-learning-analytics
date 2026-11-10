-- Онбординг пользователей компании company_id = 1.
-- Для каждой когорты регистрации считаются пользователи, совершившие первые действия в том же календарном месяце.
-- Этап test_users отражает начало тестирования.
-- Последовательность этапов по времени не проверяется.

WITH reg_users AS
(
SELECT
id AS user_id,
date_trunc('month', date_joined) AS month,
1 AS registered
FROM users
WHERE company_id = 1
),

first_attempt AS
(
SELECT
cs.user_id,
date_trunc('month', MIN(cs.created_at)) AS month
FROM codesubmit cs
INNER JOIN users u
ON cs.user_id = u.id
WHERE u.company_id = 1
GROUP BY cs.user_id
),

first_success AS
(
SELECT
cs.user_id,
date_trunc('month', MIN(cs.created_at)) AS month
FROM codesubmit cs
INNER JOIN users u
ON cs.user_id = u.id
WHERE
u.company_id = 1
AND cs.is_false = 0
GROUP BY cs.user_id
),

first_test AS
(
SELECT
ts.user_id,
date_trunc('month', MIN(ts.created_at)) AS month
FROM teststart ts
INNER JOIN users u
ON ts.user_id = u.id
WHERE u.company_id = 1
GROUP BY ts.user_id
)

SELECT
r.month,
COUNT(DISTINCT r.user_id) AS registered_users,
COUNT(DISTINCT fa.user_id) AS attempt_users,
COUNT(DISTINCT fs.user_id) AS success_users,
COUNT(DISTINCT ft.user_id) AS test_users
FROM reg_users r
LEFT JOIN first_attempt fa
ON r.user_id = fa.user_id
AND r.month = fa.month
LEFT JOIN first_success fs
ON r.user_id = fs.user_id
AND r.month = fs.month
LEFT JOIN first_test ft
ON r.user_id = ft.user_id
AND r.month = ft.month
GROUP BY
r.month
ORDER BY
r.month;


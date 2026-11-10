-- Анализ попыток решения задач пользователями компании company_id = 1.
-- success_rate — доля успешных попыток среди всех попыток.
-- Учитываются задачи с числом попыток больше 10.
-- Результат помогает выделить задачи для дополнительного анализа.

SELECT
problem_id,
p.complexity,
count(*) AS attempts,
count(CASE WHEN is_false = 0 THEN 1 END) AS success,
round(count(CASE WHEN is_false = 0 THEN 1 END) * 1.0 / NULLIF(count(*), 0), 2) AS success_rate
FROM codesubmit AS cs
INNER JOIN users AS u
ON cs.user_id = u.id
INNER JOIN problem AS p
ON cs.problem_id = p.id
WHERE u.company_id = 1
GROUP BY
problem_id,
p.complexity
HAVING count(*) > 10
ORDER BY success_rate ASC;


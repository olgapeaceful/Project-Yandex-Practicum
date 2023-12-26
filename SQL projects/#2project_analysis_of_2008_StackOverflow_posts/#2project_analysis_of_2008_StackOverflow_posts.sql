-- Проект выполняется в интерактивном тренажере на платформе Яндекс.Практикума --

/*  1. Найдите количество вопросов, которые набрали больше 300 очков
 или как минимум 100 раз были добавлены в «Закладки». */
 
SELECT COUNT(p.id)
FROM stackoverflow.posts AS p
WHERE (p.favorites_count >= 100
       OR p.score > 300)
  AND p.post_type_id = 1
  
/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно?
 Результат округлите до целого числа. */
 
SELECT ROUND(AVG(count_id), 0)
FROM
  (SELECT COUNT(p.id) AS count_id
   FROM stackoverflow.posts AS p
   INNER JOIN stackoverflow.post_types AS p_t ON p_t.id = p.post_type_id
   WHERE (CAST(p.creation_date AS date) BETWEEN '2008-11-01' AND '2008-11-18')
     AND p_t.type = 'Question'
   GROUP BY CAST(p.creation_date AS date)) AS tb1

/* 3. Сколько пользователей получили значки сразу в день регистрации?
Выведите количество уникальных пользователей. */

SELECT count(distinct(u.id))
FROM stackoverflow.users AS u
JOIN stackoverflow.badges AS b ON b.user_id = u.id
WHERE cast(u.creation_date AS date) = cast(b.creation_date AS date)

/* 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

WITH tb1 AS
  (SELECT distinct(v.post_id) AS post_id,
          COUNT(v.id) AS cnt
   FROM stackoverflow.votes AS v
   GROUP BY v.post_id),
     tb2 AS
  (SELECT DISTINCT(p.id) AS idd
   FROM stackoverflow.posts AS p
   JOIN stackoverflow.users AS u ON u.id = p.user_id
   JOIN tb1 ON tb1.post_id = p.id
   WHERE u.display_name = 'Joel Coehoorn')
SELECT COUNT(DISTINCT tb2.idd)
FROM tb2

/* 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank,
 в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id. */

SELECT *,
       ROW_NUMBER() OVER (
                          ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

/* 6.
Отберите 10 пользователей, которые поставили больше всего голосов типа Close.
 Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
 Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя. */

SELECT distinct(v.user_id),
       count(v.id) over(PARTITION BY user_id) AS count_v
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
ORDER BY count_v DESC,
         user_id DESC
LIMIT 10

/* 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

SELECT b.user_id AS id_user,
       count(b.id) AS coun_b,
       DENSE_RANK() OVER (
                          ORDER BY COUNT (id) DESC)
FROM stackoverflow.badges AS b
WHERE CAST(b.creation_date AS DATE) BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY id_user
ORDER BY coun_b DESC,
         id_user
LIMIT 10

/* 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT p.title,
       p.user_id,
       p.score,
       round(avg(score) over(PARTITION BY user_id), 0)
FROM stackoverflow.posts AS p
WHERE p.title IS NOT NULL
  AND score != 0

/* 9. Отобразите заголовки постов, которые были написаны пользователями, 
получившими более 1000 значков. Посты без заголовков не должны попасть в список. */

SELECT title
FROM stackoverflow.posts
WHERE title IS NOT NULL
  AND user_id IN
    (SELECT user_id
     FROM stackoverflow.badges
     GROUP BY user_id
     HAVING COUNT(id) > 1000) ;

/* 10.
Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada).
 Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу. */

SELECT id,
       VIEWS,
       CASE
           WHEN VIEWS < 100 THEN 3
           WHEN VIEWS >= 100
                AND VIEWS < 350 THEN 2
           ELSE 1
       END AS GROUP
FROM stackoverflow.users
WHERE LOCATION Like '%Canada%'
  AND VIEWS > 0


/* 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей,
которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров.
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

WITH tb1 AS
  (SELECT u.id,
          u.views,
          CASE
              WHEN u.views < 100 THEN 3
              WHEN u.views >= 100
                   AND u.views < 350 THEN 2
              ELSE 1
          END AS GROUP
   FROM stackoverflow.users AS u
   WHERE u.location LIKE '%Canada%'
     AND u.views > 0 ),
     tb2 AS
  (SELECT tb1.id AS user_id,
          tb1.views AS views_cnt,
          tb1.group AS groups,
          MAX(tb1.views) OVER (PARTITION BY tb1.group
                               ORDER BY tb1.views DESC) AS max_views
   FROM tb1)
SELECT tb2.user_id,
       tb2.groups,
       tb2.views_cnt
FROM tb2
WHERE tb2.views_cnt = tb2.max_views
ORDER BY tb2.views_cnt DESC,
         tb2.user_id;


/* 12.Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года.
Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением. */

WITH tb1 AS
  (SELECT CAST(DATE_TRUNC('day', creation_date) AS date) AS days,
          COUNT(id) AS users_cnt
   FROM stackoverflow.users
   GROUP BY CAST(DATE_TRUNC('day', creation_date) AS date)
   ORDER BY CAST(DATE_TRUNC('day', creation_date) AS date))
SELECT RANK() OVER (
                    ORDER BY days), users_cnt,
                                    SUM(users_cnt) OVER (
                                                         ORDER BY days)::int AS cum
FROM tb1
WHERE CAST(DATE_TRUNC('day', days) AS date) BETWEEN '2008-11-01' AND '2008-11-30';

/* 13.Для каждого пользователя, который написал хотя бы один пост,
найдите интервал между регистрацией и временем создания первого поста. Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом. */

WITH p AS
  (SELECT user_id,
          creation_date,
          RANK() OVER (PARTITION BY user_id
                       ORDER BY creation_date) AS first_pub
   FROM stackoverflow.posts
   ORDER BY user_id)
SELECT user_id,
       p.creation_date - u.creation_date AS delta
FROM p
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE first_pub = 1
  
/* 14. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года.
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить.
Результат отсортируйте по убыванию общего количества просмотров. */

SELECT DATE_TRUNC('month', creation_date)::date AS month_date,
       SUM(views_count) AS total_views
FROM stackoverflow.posts
WHERE EXTRACT(YEAR
              FROM creation_date) = 2008
GROUP BY DATE_TRUNC('month', creation_date)
ORDER BY SUM(views_count) DESC;

/* 15. Выведите имена самых активных пользователей, которые в первый месяц после регистрации
 (включая день регистрации) дали больше 100 ответов.
 Вопросы, которые задавали пользователи, не учитывайте.
 Для каждого имени пользователя выведите количество уникальных значений user_id. 
 Отсортируйте результат по полю с именами в лексикографическом порядке. */

SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id=u.id
JOIN stackoverflow.post_types AS pt ON pt.id=p.post_type_id
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month')
  AND pt.type LIKE 'Answer'
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name

/* 16. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей,
 которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года.
 Отсортируйте таблицу по значению месяца по убыванию. */
 
 WITH users AS
  (SELECT u.id
   FROM stackoverflow.posts AS p
   JOIN stackoverflow.users AS u ON p.user_id=u.id
   WHERE (u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30')
     AND (p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31')
   GROUP BY u.id)
SELECT DATE_TRUNC('month', p.creation_date)::date AS MONTH,
       COUNT(p.id)
FROM stackoverflow.posts AS p
WHERE p.user_id IN
    (SELECT *
     FROM users)
  AND DATE_TRUNC('year', p.creation_date)::date = '2008-01-01'
GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY DATE_TRUNC('month', p.creation_date)::date DESC

/*  17. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей,
 а данные об одном и том же пользователе — по возрастанию даты создания поста.*/
 
SELECT distinct(p.user_id) AS id,
       p.creation_date,
       p.views_count,
       sum(p.views_count) over(PARTITION BY p.user_id
                               ORDER BY creation_date)
FROM stackoverflow.posts AS p
ORDER BY id ASC,
         p.creation_date

/* 18. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно
 пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни,
 в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число
 — не забудьте округлить результат. */
 
SELECT round(avg(count_d))
FROM
  (SELECT distinct(user_id),
          count(dt) over(PARTITION BY user_id) AS count_d
   FROM
     (SELECT distinct(p.user_id),
             DATE_TRUNC('day', p.creation_date)::date AS dt,
             COUNT(p.id) over(PARTITION BY user_id) AS posts_number
      FROM stackoverflow.posts AS p
      WHERE p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-07') AS tb1
   WHERE posts_number >=1) AS tb2

/* 19. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года?
Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным.
Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число,
округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric. */
 
SELECT *,
       ROUND((posts_count::numeric/LAG(posts_count) OVER()-1)*100, 2)
FROM
  (SELECT extract(MONTH
                  FROM p.creation_date::date) AS mnth,
          count(p.id) AS posts_count
   FROM stackoverflow.posts AS p
   WHERE EXTRACT(MONTH
                 FROM creation_date)::int BETWEEN 9 AND 12
   GROUP BY mnth) AS tb1

/* 20. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации.
Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе. */

SELECT distinct(extract(WEEK
                        FROM p.creation_date::date)) AS week_creation,
       MAX(p.creation_date) AS creation_date
FROM stackoverflow.posts AS p
WHERE (p.user_id) in
    (SELECT pid
     FROM
       (SELECT DISTINCT(p.user_id) AS pid,
               COUNT(p.id) AS num_posts
        FROM stackoverflow.posts AS p
        GROUP BY p.user_id) AS tb1
     WHERE num_posts =
         (SELECT MAX(num_posts)
          FROM
            (SELECT p.user_id,
                    COUNT(p.id) AS num_posts
             FROM stackoverflow.posts AS p
             GROUP BY p.user_id) AS tb2))
  AND extract(YEAR
              FROM p.creation_date::date) = 2008
  AND extract(MONTH
              FROM p.creation_date::date) = 10
GROUP BY week_creation
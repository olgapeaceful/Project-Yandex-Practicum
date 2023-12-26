-- Проект выполняется в интерактивном тренажере на платформе Яндекс.Практикума --
/* Состоит из 23 заданий на составление запросов к БД (PostgreSQL) на основе датасета Startup Investments с Kaggle (https://www.kaggle.com/justinas/startup-investments) */


/* 1.Отобразите все записи из таблицы company по компаниям, которые закрылись. */

SELECT *
FROM company
WHERE status = 'closed'

/* 2. Отобразите количество привлечённых средств для новостных компаний США.
Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total.*/

SELECT funding_total
FROM company
WHERE category_code = 'news'
  AND country_code = 'USA'
ORDER BY funding_total DESC


/* 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах.
Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.*/

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
  AND EXTRACT(YEAR
              FROM acquired_at) IN (2011,
                                    2012,
                                    2013);

/* 4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username,
у которых названия аккаунтов начинаются на 'Silver'.*/

SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'


/* 5. Выведите на экран всю информацию о людях,
у которых названия аккаунтов в поле network_username содержат подстроку 'money',
а фамилия начинается на 'K'.*/

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
  AND last_name LIKE 'K%'
  
/* 6. Для каждой страны отобразите общую сумму привлечённых инвестиций,
которые получили компании, зарегистрированные в этой стране.
Страну, в которой зарегистрирована компания, можно определить по коду страны.
Отсортируйте данные по убыванию суммы.*/
 
SELECT country_code,
       sum(funding_total)
FROM company
GROUP BY country_code
ORDER BY sum(funding_total) DESC
 
 
/* 7. Составьте таблицу, в которую войдёт дата проведения раунда,
а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи,
в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.*/

SELECT funded_at,
       min(raised_amount) AS min_raised,
       max(raised_amount) AS max_raised
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) NOT IN (0,
                                  MAX(raised_amount))


/* 8. Создайте поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями.*/
 
SELECT *,
       CASE
           WHEN invested_companies > 100 THEN 'high_activity'
           WHEN invested_companies >= 20
                AND invested_companies < 100 THEN 'middle_activity'
           ELSE 'low_activity'
       END
FROM fund

/* 9. Для каждой из категорий, назначенных в предыдущем задании,
посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов,
в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов.
Отсортируйте таблицу по возрастанию среднего.*/

SELECT CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       round(avg(investment_rounds)) AS avg_rounds
FROM fund
GROUP BY activity
ORDER BY avg_rounds ASC

/* 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний,
в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно.
Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу
по среднему количеству компаний от большего к меньшему.
Затем добавьте сортировку по коду страны в лексикографическом порядке.*/

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM
  (SELECT *
   FROM fund
   WHERE EXTRACT (YEAR
                  FROM founded_at) BETWEEN 2010 AND 2012) AS f
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC
LIMIT 10;
 
/* 11. Отобразите имя и фамилию всех сотрудников стартапов.
Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.*/

SELECT pep.first_name,
       pep.last_name,
       ed.instituition
FROM people AS pep
LEFT JOIN education AS ed ON pep.id=ed.person_id

/* 12. Для каждой компании найдите количество учебных заведений,
которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений.
Составьте топ-5 компаний по количеству университетов.*/

SELECT c.name,
       count(distinct(e.instituition)) AS pole
FROM company AS c
INNER JOIN people AS p ON c.id=p.company_id
INNER JOIN education AS e ON p.id=e.person_id
GROUP BY c.name
ORDER BY pole DESC
LIMIT 5

/* 13. Составьте список с уникальными названиями закрытых компаний,
для которых первый раунд финансирования оказался последним.*/
 
select
distinct(c.name)
from company as c
Left join funding_round as fr on c.id = fr.company_id
where status like 'closed'
and is_last_round = 1
and is_first_round = 1


/* 14. Составьте список уникальных номеров сотрудников,
которые работают в компаниях, отобранных в предыдущем задании.*/
 
WITH name_of_company AS
  (SELECT distinct(c.name)
   FROM company AS c
   LEFT JOIN funding_round AS fr ON c.id = fr.company_id
   WHERE status like 'closed'
     AND is_last_round = 1
     AND is_first_round = 1)
SELECT distinct(p.id)
FROM people AS p
INNER JOIN company AS c ON p.company_id = c.id
INNER JOIN name_of_company ON name_of_company.name = c.name

/* 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников
из предыдущей задачи и учебным заведением, которое окончил сотрудник. */
 
WITH my_tb AS
  (WITH name_of_company AS
     (SELECT distinct(c.name)
      FROM company AS c
      LEFT JOIN funding_round AS fr ON c.id = fr.company_id
      WHERE status like 'closed'
        AND is_last_round = 1
        AND is_first_round = 1) SELECT distinct(p.id)
   FROM people AS p
   INNER JOIN company AS c ON p.company_id = c.id
   INNER JOIN name_of_company ON name_of_company.name = c.name)
SELECT distinct(person_id) AS pp.id,
       count(instituition) AS count_inst
FROM education AS e
INNER JOIN my_tb ON my_tb.id = e.person_id
GROUP BY pp.id,
         count_inst
HAVING count_inst IS NOT NULL;

/* 16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания.
При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды. */
 
SELECT DISTINCT p.id,
                COUNT(ed.instituition)
FROM company AS com
INNER JOIN people AS p ON com.id=p.company_id
LEFT JOIN education AS ed ON p.id=ed.person_id
WHERE STATUS LIKE '%closed%'
  AND com.id IN
    (SELECT company_id
     FROM funding_round
     WHERE is_first_round = 1
       AND is_last_round = 1)
  AND ed.instituition IS NOT NULL
GROUP BY p.id

/* 17. Дополните предыдущий запрос и выведите среднее число учебных заведений
(всех, не только уникальных), которые окончили сотрудники разных компаний.
Нужно вывести только одну запись, группировка здесь не понадобится. */

WITH my_tb AS
  (SELECT DISTINCT p.id,
                   COUNT(ed.instituition)
   FROM company AS com
   INNER JOIN people AS p ON com.id=p.company_id
   LEFT JOIN education AS ed ON p.id=ed.person_id
   WHERE STATUS LIKE '%closed%'
     AND com.id IN
       (SELECT company_id
        FROM funding_round
        WHERE is_first_round = 1
          AND is_last_round = 1)
     AND ed.instituition IS NOT NULL
   GROUP BY p.id)
SELECT avg(COUNT)
FROM my_tb

/* 18. Напишите похожий запрос: выведите среднее число учебных заведений 
(всех, не только уникальных), которые окончили сотрудники Socialnet. */

WITH my_tb AS
  (SELECT DISTINCT p.id,
                   COUNT(ed.instituition)
   FROM company AS com
   INNER JOIN people AS p ON com.id=p.company_id
   LEFT JOIN education AS ed ON p.id=ed.person_id
   WHERE name LIKE 'Facebook'
     AND ed.instituition IS NOT NULL
   GROUP BY p.id)
SELECT avg(COUNT)
FROM my_tb

/* 19. Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов,
а раунды финансирования проходили с 2012 по 2013 год включительно. */

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
LEFT JOIN company AS c ON i.company_id=c.id
LEFT JOIN fund AS f ON i.fund_id=f.id
LEFT JOIN funding_round AS fr ON i.funding_round_id=fr.id
WHERE i.company_id IN
    (SELECT id
     FROM company
     WHERE milestones > 6)
  AND EXTRACT(YEAR
              FROM funded_at) IN (2012,
                                  2013);

/* 20. Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций,
округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. 
Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей,
а затем по названию купленной компании в лексикографическом порядке.
Ограничьте таблицу первыми десятью записями. */

WITH buyer AS
  (SELECT c.name AS buyer_name,
          a.price_amount AS price,
          a.id AS key1
   FROM acquisition AS a
   LEFT JOIN company AS c ON a.acquiring_company_id = c.id
   WHERE a.price_amount > 0 ),
     bought AS
  (SELECT c.name AS bought_name,
          c.funding_total AS inv,
          a.id AS key2
   FROM acquisition AS a
   LEFT JOIN company AS c ON a.acquired_company_id = c.id
   WHERE c.funding_total > 0 )
SELECT buyer_name,
       price,
       bought_name,
       inv,
       ROUND(price / inv)
FROM buyer
JOIN bought ON buyer.key1 = bought.key2
ORDER BY price DESC,
         bought_name
LIMIT 10

/* 21. Выгрузите таблицу, в которую войдут названия компаний из категории social,
получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю.
Выведите также номер месяца, в котором проходил раунд финансирования. */

SELECT c.name,
       EXTRACT(MONTH
               FROM fr.funded_at)
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id=fr.company_id
WHERE c.category_code = 'social'
  AND EXTRACT(YEAR
              FROM fr.funded_at) BETWEEN 2010 AND 2013
  AND fr.raised_amount <> 0;

/* 22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды.
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце. */

WITH fundings AS
  (SELECT EXTRACT(MONTH
                  FROM fr.funded_at) AS funding_month,
          COUNT(DISTINCT f.id) AS id_fund
   FROM fund AS f
   LEFT JOIN investment AS i ON f.id=i.fund_id
   LEFT JOIN funding_round AS fr ON i.funding_round_id=fr.id
   WHERE f.country_code = 'USA'
     AND EXTRACT(YEAR
                 FROM CAST (fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
   GROUP BY funding_month),
     acquisitions AS
  (SELECT EXTRACT (MONTH
                   FROM acquired_at) AS funding_month,
                  COUNT(acquired_company_id) AS acquired,
                  SUM(price_amount) AS sum_total
   FROM acquisition
   WHERE EXTRACT(YEAR
                 FROM acquired_at) BETWEEN 2010 AND 2013
   GROUP BY funding_month)
SELECT fnd.funding_month,
       fnd.id_fund,
       acq.acquired,
       acq.sum_total
FROM fundings AS fnd
LEFT JOIN acquisitions AS acq ON fnd.funding_month=acq.funding_month


/* 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран,
в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах.
Данные за каждый год должны быть в отдельном поле.
Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.*/

WITH a AS
  (SELECT country_code,
          AVG(funding_total) AS totalavg_2011
   FROM company
   WHERE EXTRACT(YEAR
                 FROM CAST(founded_at AS DATE)) = 2011
   GROUP BY country_code),
     b AS
  (SELECT country_code,
          AVG(funding_total) AS totalavg_2012
   FROM company
   WHERE EXTRACT(YEAR
                 FROM CAST(founded_at AS DATE)) = 2012
   GROUP BY country_code),
     c AS
  (SELECT country_code,
          AVG(funding_total) AS totalavg_2013
   FROM company
   WHERE EXTRACT(YEAR
                 FROM CAST(founded_at AS DATE)) = 2013
   GROUP BY country_code)
SELECT a.country_code,
       a.totalavg_2011,
       b.totalavg_2012,
       c.totalavg_2013
FROM a
INNER JOIN b ON a.country_code = b.country_code
INNER JOIN c ON a.country_code = c.country_code
ORDER BY totalavg_2011 DESC
 
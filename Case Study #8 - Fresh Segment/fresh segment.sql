------EDA-------
SELECT *
FROM fresh_segments.interest_metrics

SELECT DISTINCT(_year)
FROM fresh_segments.interest_metrics
WHERE _year IS NOT NULL

SELECT * 
FROM fresh_segments.interest_map

SELECT DISTINCT(id)
FROM fresh_segments.interest_map
ORDER BY id ASC

SELECT COUNT(id)
FROM fresh_segments.interest_map

SELECT DISTINCT(interest_name)
FROM fresh_segments.interest_map

---updating the month_year column to date type---
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN  month_year TYPE VARCHAR(10);

UPDATE fresh_segments.interest_metrics
SET month_year = TO_DATE(month_year, 'MM-YYYY')

ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'YYYY-MM');

---updating the interest_id column to int
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN  interest_id TYPE VARCHAR(5);
-----------------------
SELECT month_year,COUNT(*) count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY count DESC

----How many interest_id values exist in the interest_metrics table but not in the interest_map table
SELECT COUNT(*)
FROM fresh_segments.interest_metrics met
LEFT JOIN fresh_segments.interest_map map
	ON CAST(met.interest_id AS INT) = map.id
WHERE map.id IS NULL

-----Vice Versa-----
SELECT COUNT(*)
FROM fresh_segments.interest_metrics met
RIGHT JOIN fresh_segments.interest_map map
	ON CAST(met.interest_id AS INT) = map.id
WHERE met.interest_id IS NULL

-----checking for values where the month_year value is before the created_at 

SELECT *
FROM
	(SELECT met._month,
		met._year,
		met.month_year,
		met.interest_id,
		met.composition,
		met.index_value,
		met.ranking,
		met.percentile_ranking,
		map.interest_name,
		map.interest_summary,
		map.created_at,
		map.last_modified
FROM fresh_segments.interest_metrics met
JOIN fresh_segments.interest_map map
	ON CAST(met.interest_id AS INT) = map.id
WHERE met.interest_id = '21246')
WHERE month_year < created_at

-----INTEREST ANALYSIS-----
--1.Which interests have been present in all month_year dates in the dataset
SELECT interest_id
FROM
	(SELECT interest_id, COUNT(DISTINCT(month_year)) AS month_year_count
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id)
WHERE month_year_count = (SELECT COUNT(DISTINCT(month_year)) 
						  FROM fresh_segments.interest_metrics)
						  
--2.Using this same total_months measure - calculate the cumulative percentage of all records 
---starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH month_count AS (
	SELECT 
		interest_id,
		COUNT(DISTINCT(month_year)) AS total_month
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
),
interest_count AS (
	SELECT 
		total_month,
		COUNT(DISTINCT(interest_id)) AS int_count
	FROM month_count
	GROUP BY total_month
),
cummulative_percentage AS (
	SELECT 
		*,
		ROUND(100 *SUM(int_count) OVER (ORDER BY total_month DESC)/
		 (SELECT SUM(int_count) FROM interest_count),2) AS cummulative_perc
	FROM interest_count
	GROUP BY total_month, int_count
)
SELECT *
FROM cummulative_percentage 
WHERE cummulative_perc >= 90

--3.If we were to remove all interest_id values which are lower than the total_months value
----we found in the previous question - how many total data points would we be removing?

WITH previous AS (
	SELECT 
		interest_id, 
		COUNT(DISTINCT month_year)
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) < 6
)
SELECT COUNT(interest_id) AS point_to_be_removed
FROM fresh_segments.interest_metrics
WHERE interest_id IN (SELECT interest_id FROM previous)

--4.Does this decision make sense to remove these data points from a business perspective? 
----Use an example where there are all 14 months present to a removed interest example for your arguments

WITH present AS(              -- -----14months present
	SELECT month_year,COUNT(interest_id) AS present_interest
	FROM fresh_segments.interest_metrics
	WHERE month_year IS NOT NULL
	GROUP BY month_year
),
month_count AS (
	SELECT interest_id, COUNT(DISTINCT month_year)
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) < 6
),
to_be_removed AS (
		SELECT month_year,COUNT(interest_id) AS interest_to_be_removed
		FROM fresh_segments.interest_metrics
		WHERE interest_id IN (SELECT interest_id FROM month_count)
		GROUP BY month_year
)
SELECT 
	p.month_year,
	p.present_interest,
	t.interest_to_be_removed,
	ROUND(t.interest_to_be_removed*100.00 / p.present_interest,3) AS perc_to_be_removed,
	p.present_interest - t.interest_to_be_removed
FROM present p
JOIN to_be_removed t
	ON p.month_year = t.month_year

--5.After removing these interests - how many unique interests are there for each month?
WITH month_count AS (
    SELECT interest_id
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) < 6
)
SELECT month_year, COUNT(DISTINCT interest_id) AS unique_interests
FROM fresh_segments.interest_metrics AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM month_count AS mc
    WHERE mc.interest_id = m.interest_id
)
GROUP BY month_year;

-----SEGMENT ANALYSIS------

--1.Using our filtered dataset by removing the interests with less than 6 months worth of data, 
---which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
--Only use the maximum composition value for each interest but you must keep the corresponding month_year

----creating a temp table from the filtered data---
CREATE TEMP TABLE filtered_table AS 
SELECT *
FROM fresh_segments.interest_metrics AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM (
        SELECT interest_id
        FROM fresh_segments.interest_metrics
        GROUP BY interest_id
        HAVING COUNT(DISTINCT month_year) < 6
    ) AS mc
    WHERE mc.interest_id = m.interest_id
);
---top 10 interests--
WITH max_composition AS (
		SELECT interest_id,
		MAX(composition) AS max_comp
		FROM filtered_table
		GROUP BY interest_id
)
SELECT f.month_year,
		m.interest_name,
		mc.max_comp
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id :: INT = m.id
JOIN max_composition mc
	ON f.interest_id = mc.interest_id
WHERE 
	EXISTS (
        SELECT 1
        FROM 
            max_composition
        WHERE 
            interest_id = f.interest_id AND max_comp = f.composition
    )
GROUP BY f.month_year,m.interest_name,mc.max_comp
ORDER BY mc.max_comp DESC
LIMIT 10

---bottom 10----
WITH max_composition AS (
		SELECT interest_id,
		MAX(composition) AS max_comp
		FROM filtered_table
		GROUP BY interest_id
)
SELECT f.month_year,
		m.interest_name,
		mc.max_comp
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id :: INT = m.id
JOIN max_composition mc
	ON f.interest_id = mc.interest_id
WHERE 
	EXISTS (
        SELECT 1
        FROM 
            max_composition
        WHERE 
            interest_id = f.interest_id AND max_comp = f.composition
    )
GROUP BY f.month_year,m.interest_name,mc.max_comp
ORDER BY mc.max_comp ASC
LIMIT 10

--2.Which 5 interests had the lowest average ranking value?
SELECT f.interest_id,
		m.interest_name,
		ROUND(AVG(f.ranking),2) AS avg_ranking
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id :: INT = m.id
GROUP BY f.interest_id, m.interest_name
ORDER BY avg_ranking ASC
LIMIT 5

--3.Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT f.interest_id,
		m.interest_name,
		STDDEV(percentile_ranking) AS standard_deviation
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id :: INT = m.id
GROUP BY f.interest_id, m.interest_name
ORDER BY standard_deviation DESC
LIMIT 5 

--4.For the 5 interests found in the previous question 
-- what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month

WITH std_percentile_ranking AS (
    SELECT 
        f.interest_id,
        m.interest_name,
        STDDEV(percentile_ranking) AS standard_deviation
    FROM 
        filtered_table f
    JOIN 
        fresh_segments.interest_map m ON f.interest_id::INT = m.id
    GROUP BY 
        f.interest_id, m.interest_name
    ORDER BY 
        standard_deviation DESC
    LIMIT 5
),
max_ranking AS (
    SELECT DISTINCT ON (f.interest_id) 
        f.interest_id,
        f.month_year AS max_month_year,
        f.percentile_ranking AS max_ranking
    FROM 
        filtered_table f
    JOIN 
        std_percentile_ranking s ON f.interest_id = s.interest_id
    ORDER BY 
        f.interest_id, f.percentile_ranking DESC
),
min_ranking AS (
    SELECT DISTINCT ON (f.interest_id) 
        f.interest_id,
        f.month_year AS min_month_year,
        f.percentile_ranking AS min_ranking
    FROM 
        filtered_table f
    JOIN 
        std_percentile_ranking s ON f.interest_id = s.interest_id
    ORDER BY 
        f.interest_id, f.percentile_ranking ASC
)
SELECT 
    m.interest_id,
	m.interest_name,
    max.max_month_year,
    max.max_ranking AS max_percentile_ranking,
    min.min_month_year,
    min.min_ranking AS min_percentile_ranking
FROM 
    std_percentile_ranking m
JOIN 
    max_ranking max ON m.interest_id = max.interest_id
JOIN 
    min_ranking min ON m.interest_id = min.interest_id;

------INDEX ANALYSIS-----

--1.What is the top 10 interests by the average composition for each month?
---creating a new column in the filtered table for average composition
ALTER TABLE filtered_table
ADD COLUMN avg_composition double precision;

UPDATE filtered_table
SET avg_composition = composition/index_value

---top 10 interest---
WITH rank AS (
	SELECT
	f.month_year,
	m.interest_name,
	RANK() OVER(PARTITION BY f.month_year ORDER BY avg_composition DESC) AS ranks
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id::INT  = m.id
)
SELECT *
FROM rank
WHERE ranks <=10

--2.for all of these top 10 interests - which interest appears the most often?
WITH rank AS (
	SELECT
	f.month_year,
	m.interest_name,
	RANK() OVER(PARTITION BY f.month_year ORDER BY avg_composition DESC) AS ranks
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id::INT  = m.id
)
SELECT interest_name,
		COUNT(interest_name) AS count
FROM rank
WHERE ranks <=10
GROUP BY interest_name
ORDER BY count DESC

--4.What is the average of the average composition for the top 10 interests for each month?

WITH rank AS (
	SELECT
	f.month_year,
	m.interest_name,
	f.avg_composition,
	RANK() OVER(PARTITION BY f.month_year ORDER BY avg_composition DESC) AS ranks
FROM filtered_table f
JOIN fresh_segments.interest_map m
	ON f.interest_id::INT  = m.id
)
SELECT month_year,
	interest_name,
	ROUND(AVG(avg_composition :: NUMERIC),2) AS average
FROM rank
WHERE ranks <=10
GROUP BY month_year, interest_name
ORDER BY average DESC

--5.What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 
--and include the previous top ranking interests in the same output shown below.

WITH max_average_composition AS (
					SELECT month_year,
					MAX(avg_composition) AS max_avg_composition
					FROM filtered_table 
					GROUP BY month_year

),
three_rolling_average AS (
	SELECT f.interest_id,
		f.month_year,
		m.interest_name,
		mc.max_avg_composition,
		ROUND(AVG(max_avg_composition :: NUMERIC) OVER(ORDER BY f.month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS three_months_rolling
	FROM filtered_table f
	JOIN fresh_segments.interest_map m
		ON f.interest_id :: INT = m.id
	JOIN max_average_composition mc
		ON f.month_year = mc.month_year
	WHERE f.avg_composition = max_avg_composition
),
one_month_before AS(
	SELECT 
		*,
		LAG(interest_name) OVER(ORDER BY month_year) ||': '||
		ROUND(LAG(max_avg_composition :: NUMERIC) OVER(ORDER BY month_year),2)  AS one_month_ago
	FROM three_rolling_average

)
SELECT 
	*,
	LAG(one_month_ago) OVER(ORDER BY month_year) AS two_months_ago
FROM one_month_before
WHERE month_year BETWEEN '2018-10-01' AND '2019-09-01'		


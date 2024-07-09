-------DATA CLEANING--------
----In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
----Convert the week_date to a DATE format
----Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
----Add a month_number with the calendar month for each week_date value as the 3rd column
----Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
----Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--segment	age_band
--1 Young Adults
--2 Middle Aged
--3 or4 Retirees
---Add a new demographic column using the following mapping for the first letter in the segment values:
--segment	demographic
--C	Couples
--F	Families
---Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

CREATE TABLE clean_weekly_sales AS
	SELECT week_date :: DATE AS week_date,
		DATE_PART('week' ,week_date :: DATE) AS week_num,
		DATE_PART('month', week_date :: DATE) || ' ' ||TO_CHAR( week_date :: DATE, 'Month') AS month_num,
		DATE_PART('year', week_date :: DATE) AS year,
		region,
		platform,
		segment,
		CASE
			WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
			WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
			WHEN RIGHT(segment,1) IN ('3','4')THEN 'Retirees'
			ELSE 'Unknown' END AS age_band,
		CASE
			WHEN LEFT(segment,1) = 'C' THEN 'Couples'
			WHEN LEFT(segment,1) = 'F' THEN 'Families'
			ELSE 'Unknown' END AS demographic,
		customer_type,
		transactions,
		sales,
		ROUND(sales/transactions, 2) AS avg_transaction
	FROM data_mart.weekly_sales
	
SELECT * FROM clean_weekly_sales

---------DATA EXPLORATION--------

---1.What day of the week is used for each week_date value?
SELECT DISTINCT(TO_CHAR(week_date, 'Day')) AS day_of_wk
FROM clean_weekly_sales

---2.What range of week numbers are missing from the dataset?
SELECT *
FROM generate_series(1,52)
WHERE generate_series NOT IN
		(SELECT DISTINCT week_num
		FROM clean_weekly_sales)

---3.How many total transactions were there for each year in the dataset?
SELECT year, COUNT(*) AS transactions
FROM clean_weekly_sales
GROUP BY year
ORDER BY transactions DESC

-----What is the total sales for each region for each month?
SELECT region,
	month_num, 
	SUM(sales)  AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_num,sales
ORDER BY total_sales DESC

-----What is the total count of transactions for each platform
SELECT platform, COUNT(*) AS transaction
FROM clean_weekly_sales
GROUP BY platform
ORDER BY transaction DESC

-----What is the percentage of sales for Retail vs Shopify for each month?
SELECT month_num,
	ROUND
		(SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)*100/
		SUM(sales),0) AS retail_prcnt,
	ROUND
		(SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END)*100/
		SUM(sales),0) AS shopify_prcnt
FROM clean_weekly_sales
GROUP BY month_num

-----What is the percentage of sales by demographic for each year in the dataset?
SELECT 
	year,
	ROUND
		(SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END)*100/
		SUM(sales),0) AS couples,
	ROUND
		(SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END)*100/
		SUM(sales),0) AS families,
	ROUND
		(SUM(CASE WHEN demographic = 'Unknown' THEN sales ELSE 0 END)*100/
		SUM(sales),0) AS unknown
FROM clean_weekly_sales
GROUP BY year

-----Which age_band and demographic values contribute the most to Retail sales?
SELECT
	age_band,
	demographic,
	ROUND
		(SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)*100/
		(SELECT SUM(sales) 
		 FROM clean_weekly_sales
		 WHERE platform = 'Retail'),0) AS retail_prcnt
FROM clean_weekly_sales
GROUP BY age_band,demographic
ORDER BY retail_prcnt DESC
		
-----Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
	year,
	SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)/
	SUM(CASE WHEN platform = 'Retail' THEN transactions ELSE 0 END) AS retail,
	SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END)/
	SUM(CASE WHEN platform = 'Shopify' THEN transactions ELSE 0 END) AS shopify
FROM clean_weekly_sales
GROUP BY year


------Before & After Analysis-----
----Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
----We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
----Using this analysis approach - answer the following questions:

---1.What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

SELECT  
	DISTINCT (week_date - interval '4 weeks') AS weeks_before, ------4 weeks before baselind date
	week_date + interval '4 weeks' AS weeks_after ---4 weeks after baseline date
FROM clean_weekly_sales
WHERE week_date = '2020-06-15'

WITH before_after AS(
	SELECT
		*,
	CASE 
		WHEN week_date < '2020-06-15' THEN 'Before'
		WHEN week_date >='2020-06-15' THEN 'After' END AS period
	FROM clean_weekly_sales
)
SELECT 	
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-05-18' THEN sales END) AS sales_before, ----sales before 4 weeks of baseline
	SUM(CASE WHEN period = 'After'  AND week_date <= '2020-07-13' THEN sales END) AS sales_after,---sales after 4 weeks of baseline
	(SUM(CASE WHEN period = 'After'  AND week_date <= '2020-07-13' THEN sales END) -
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-05-18' THEN sales END)) AS sales_difference,
	(SUM(CASE WHEN period = 'After'  AND week_date <= '2020-07-13' THEN sales END) -
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-05-18' THEN sales END))* 100/
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-05-18' THEN sales END) AS prcnt_change
FROM before_after
---2.What about the entire 12 weeks before and after?

SELECT  
	DISTINCT (week_date - interval '12 weeks') AS weeks_before, ------12 weeks before baselind date
	week_date + interval '12 weeks' AS weeks_after ---12 weeks after baseline date
FROM clean_weekly_sales
WHERE week_date = '2020-06-15'

WITH before_after AS(
	SELECT
		*,
	CASE 
		WHEN week_date <  '2020-06-15' THEN 'Before'
		WHEN week_date >=  '2020-06-15' THEN 'After' END AS period
	FROM clean_weekly_sales
)
SELECT 	
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-03-23' THEN sales END) AS sales_before, ----sales before 12 weeks of baseline
	SUM(CASE WHEN period = 'After'  AND week_date <= '2020-09-07' THEN sales END) AS sales_after,---sales after 12 weeks of baseline
	(SUM(CASE WHEN period = 'After'  AND week_date <= '2020-09-07' THEN sales END) -
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-03-23' THEN sales END)) AS sales_difference,
	(SUM(CASE WHEN period = 'After'  AND week_date <= '2020-09-07' THEN sales END) -
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-03-23' THEN sales END))* 100/
	SUM(CASE WHEN period = 'Before' AND week_date >='2020-03-23' THEN sales END) AS prcnt_change
FROM before_after

---3.How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
SELECT DISTINCT week_num
FROM clean_weekly_sales
WHERE week_date = '2020-06-15' ---to figure out the corresponding week with 2018 and 2019

WITH before_after AS(
	SELECT 
	 *,
	 CASE
		WHEN week_num < 25 THEN 'Before'
		WHEN week_num >= 25 THEN 'After' END AS period
	FROM clean_weekly_sales
	WHERE week_num BETWEEN 21 AND 28 
)
SELECT 
	year,
	SUM(CASE WHEN period = 'Before' THEN sales END) AS sales_before,----4 weeks before change corresponding to the baseline week numb in 2020
	SUM(CASE WHEN period = 'After' THEN sales END) AS sales_after, ---4 weeks after change corresponding to the baseline week numb in 2020
	(SUM(CASE WHEN period = 'After' THEN sales END) -
	SUM(CASE WHEN period = 'Before' THEN sales END)) AS sales_difference,
	(SUM(CASE WHEN period = 'After' THEN sales END) -
	SUM(CASE WHEN period = 'Before' THEN sales END)) *100/
	SUM(CASE WHEN period = 'Before' THEN sales END) AS prcnt_change
FROM before_after
GROUP BY year

---NB date before change: 2020-06-08, date after change: 2020-06-15


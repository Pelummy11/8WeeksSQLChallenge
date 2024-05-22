-------------------ANALAYSIS-----------------------------------------
-----------Digital Analysis-----------------------
--------1.How many users are there?

SELECT 
	COUNT(DISTINCT user_id) AS tot_users 
FROM clique_bait.users

--------2.How many cookies does each user have on average?

WITH cookie_count AS(
	SELECT 
		user_id,
		COUNT(cookie_id) AS cookies
	FROM clique_bait.users
	GROUP BY user_id
)
SELECT 
	user_id,
	ROUND(AVG(cookies),0) AS avg_cookies
FROM cookie_count
GROUP BY user_id

--------3.What is the unique number of visits by all users per month?

SELECT 
	EXTRACT('MONTH' FROM event_time) AS month,
	COUNT(DISTINCT visit_id) AS visits
FROM clique_bait.events
GROUP BY EXTRACT('MONTH' FROM event_time)
ORDER BY visits DESC
	
--------4.What is the number of events for each event type?

SELECT 
	event_name,
	COUNT(e.event_type) AS num_of_events
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei
	ON e.event_type = ei.event_type
GROUP BY event_name
ORDER BY num_of_events DESC

--------5.What is the percentage of visits which have a purchase event?

WITH purchase_visit AS (
	SELECT 
		COUNT(DISTINCT visit_id) AS visits
	FROM clique_bait.events
	WHERE event_type = 3
)
SELECT 
 	ROUND(visits :: numeric/(
	SELECT COUNT(DISTINCT visit_id)
	FROM clique_bait.events) *100, 3)
FROM purchase_visit

--------6.What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH checkout_page AS (
	SELECT 
		COUNT(DISTINCT visit_id) AS visits
	FROM clique_bait.events e
	JOIN clique_bait.page_hierarchy p
		ON e.page_id = p.page_id
	WHERE page_name = 'Checkout'
	AND event_type != 3
)
SELECT 
 	ROUND(visits :: numeric/(
	SELECT COUNT(DISTINCT visit_id)
	FROM clique_bait.events) *100, 3)
FROM checkout_page

--------7.What are the top 3 pages by number of views?

SELECT 
	page_name,
	COUNT(visit_id) AS views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy p
	ON e.page_id = p.page_id
GROUP BY page_name
ORDER BY views DESC
LIMIT 3
	
--------8.What is the number of views and cart adds for each product category?
SELECT
	product_category,
	SUM(CASE WHEN event_name :: TEXT = 'Page View' THEN 1 ELSE 0 END) AS Pageview,
	SUM(CASE WHEN event_name :: TEXT = 'Add to Cart' THEN 1 ELSE 0 END) AS Cart
FROM clique_bait.event_identifier ei
JOIN clique_bait.events e
	 ON ei.event_type = e.event_type
JOIN clique_bait.page_hierarchy p
	ON e.page_id = p.page_id
WHERE product_category IS NOT NULL
GROUP BY product_category



------------ PRODUCT FUNNEL ANALYSIS-----------
-----Using a single SQL query - create a new output table which has the following details:
-------How many times was each product viewed?
-------How many times was each product added to cart?
-------How many times was each product added to a cart but not purchased (abandoned)?
-------How many times was each product purchased?

CREATE TABLE products AS(     --------- creating a table
WITH viewed_cart AS (       --------products viewed and added to cart
	SELECT 	
		visit_id,
		page_name,
		SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS viewed,  ------views
		SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) as cart   ------cart_add
	FROM clique_bait.event_identifier ei
	JOIN clique_bait.events e
		ON ei.event_type = e.event_type
	JOIN clique_bait.page_hierarchy p
		ON e.page_id = p.page_id
	WHERE product_id IS NOT NULL
	GROUP BY visit_id,page_name
),
p1 AS (         -----creating an id for purchases since purchased items have null product_id
	SELECT 
		DISTINCT(visit_id) AS purchase_id
	FROM clique_bait.event_identifier ei
	JOIN clique_bait.events e
		ON ei.event_type = e.event_type
	WHERE event_name = 'Purchase'
),
p2 AS(       ----------- creating the purchased item column
	SELECT
		*,
		CASE WHEN purchase_id IS NOT NULL THEN 1 ELSE 0  END AS purchase
	FROM p1
	RIGHT JOIN viewed_cart vc
		ON purchase_id = visit_id
),
p3 AS (                --------bringing it all together
	SELECT 
		page_name AS product_name,
		SUM(viewed) AS views,  -----views
		SUM(cart) AS cart_add,      -----cart_add
		SUM(CASE WHEN cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned, -----card add but not purchased
		SUM(CASE WHEN cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchased  -----purchased  
	FROM p2
	GROUP BY page_name	
)
SELECT *
FROM p3
)
SELECT *
FROM products


-------Additionally, create another table which further aggregates 
--the data for the above points but this time for each product category instead of individual products.

CREATE TABLE product_category AS(
WITH viewed_cart AS (       --------product_category viewed and added to cart
	SELECT 	
		visit_id,
		product_category,
		SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS viewed, ----views
		SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) as cart -----cart_add
	FROM clique_bait.event_identifier ei
	JOIN clique_bait.events e
		ON ei.event_type = e.event_type
	JOIN clique_bait.page_hierarchy p
		ON e.page_id = p.page_id
	WHERE product_id IS NOT NULL
	GROUP BY visit_id,product_category
),
p1 AS (         -----creating an id for purchases since purchased items have null product_id
	SELECT 
		DISTINCT(visit_id) AS purchase_id
	FROM clique_bait.event_identifier ei
	JOIN clique_bait.events e
		ON ei.event_type = e.event_type
	WHERE event_name = 'Purchase'
),
p2 AS(       ----------- creating the purchased item column
	SELECT
		*,
		CASE WHEN purchase_id IS NOT NULL THEN 1 ELSE 0  END AS purchase
	FROM p1
	RIGHT JOIN viewed_cart vc
		ON purchase_id = visit_id
),
p3 AS (                --------bringing it all together
	SELECT 
		product_category,
		SUM(viewed) AS viewed, ----- views
		SUM(cart) AS cart,     ------cart_add
		SUM(CASE WHEN cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,-----cart add but not purchased
		SUM(CASE WHEN cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchased -----purchased
	FROM p2
	GROUP BY product_category
)
SELECT *
FROM p3
)
SELECT *
FROM product_category


------Use your 2 new output tables - answer the following questions:

----1.Which product had the most views, cart adds and purchases?
SELECT 
	product_name,
	MAX(views) AS views  ----most views
FROM products
GROUP BY product_name
ORDER BY views DESC
LIMIT 1

SELECT 
	product_name,
	MAX(cart_add) AS cart_add  -----most cart adds
FROM products
GROUP BY product_name
ORDER BY cart_add DESC
LIMIT 1

SELECT 
	product_name,
	MAX(purchased) AS purchase  ----most purchased
FROM products
GROUP BY product_name
ORDER BY purchase DESC
LIMIT 1

----2.Which product was most likely to be abandoned?
SELECT 
	product_name
FROM products
GROUP BY product_name
ORDER BY MIN(abandoned) DESC
LIMIT 1

----3.Which product had the highest view to purchase percentage?
SELECT
	product_name,
	ROUND((purchased/views) * 100,2) AS view_pur_pcnt
FROM products
GROUP BY product_name,purchased, views

----4.What is the average conversion rate from view to cart add?
SELECT
	ROUND(AVG(cart_add/views) * 100,2) AS avg_view_cart
FROM products

----5.What is the average conversion rate from cart add to purchase?
SELECT
	ROUND(AVG(purchased/cart_add) * 100,2) AS avg_cart_pur
FROM products
	

---------CAMPAIGN ANALYSIS-------
----Generate a table that has 1 single row for every unique visit_id record and has the following columns:
----user_id
-----visit_id
---visit_start_time: the earliest event_time for each visit
----page_views: count of page views for each visit
----cart_adds: count of product cart add events for each visit
-----purchase: 1/0 flag if a purchase event exists for each visit
---campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-----impression: count of ad impressions for each visit
-----click: count of ad clicks for each visit
---(Optional column) cart_products: a comma separated text value with products
---added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

CREATE TABLE campaign AS (
WITH cte AS (
	SELECT
		DISTINCT visit_id,
		user_id,
		MIN(event_time ) AS visit_start_time,
		CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END AS purchase,
		SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS views, 
		SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) As cart_add,
		SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
		SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
		CASE 
			WHEN MIN(event_time) BETWEEN '2020-01-01 00:00:00' AND '2020-01-14 00:00:00'
			THEN 'BOGOF - Fishing For Compliments'
			WHEN MIN(event_time) BETWEEN '2020-01-15 00:00:00' AND '2020-01-28 00:00:00'
			THEN '25% OFF - Living The Lux Life'
			WHEN MIN(event_time) BETWEEN '2020-02-01 00:00:00' AND '2020-03-31 00:00:00'
			THEN 'Half Off - Treat Your Shellf(ish)' ELSE NULL
			END AS campaign_name
	FROM clique_bait.event_identifier ei
	JOIN clique_bait.events e
		ON ei.event_type = e.event_type
	JOIN clique_bait.page_hierarchy p
		ON e.page_id = p.page_id
	JOIN clique_bait.users u
		ON u.cookie_id = e.cookie_id
	GROUP BY visit_id,user_id,event_name
)
SELECT
	user_id,
	visit_id,
	visit_start_time,
	views,
	cart_add,
	purchase,
	campaign_name,
	impression,
	click
FROM cte
)
SELECT *
FROM campaign


## CASE STUDY #8
![image](https://github.com/Pelummy11/Fresh-Segments/assets/47598173/8ef6ffeb-3b1b-4f0e-9ca6-52083f21a2ff)


## Fresh-Segments
Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.
Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.
Case Study : https://8weeksqlchallenge.com/case-study-8/

#### Available Data
For this case study there is a total of 2 datasets which will used to solve the questions.

#### Interest Metrics
This table contains information about aggregated interest metrics for a specific major client of Fresh Segments which makes up a large proportion of their customer base.

Each record in this table represents the performance of a specific interest_id based on the client’s customer base interest measured through clicks and interactions with specific targeted advertising content.

targeted advertising content.

In July 2018, the composition metric is 11.89, meaning that 11.89% of the client’s customer list interacted with the interest interest_id = 32486 - we can link interest_id to a separate mapping table to find the segment name called “Vacation Rental Accommodation Researchers”

The index_value is 6.19, means that the composition value is 6.19x the average composition value for all Fresh Segments clients’ customer for this particular interest in the month of July 2018.

The ranking and percentage_ranking relates to the order of index_value records in each month year.

#### Interest Map
This mapping table links the interest_id with their relevant interest information. You will need to join this table onto the previous interest_details table to obtain the interest_name as well as any details about the summary information.

#### Interest Analysis
Which interests have been present in all month_year dates in our dataset?

Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

After removing these interests - how many unique interests are there for each month?

#### Segment Analysis
Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

Which 5 interests had the lowest average ranking value?

Which 5 interests had the largest standard deviation in their percentile_ranking value?

For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

#### Index Analysis
The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

What is the top 10 interests by the average composition for each month?

For all of these top 10 interests - which interest appears the most often?

What is the average of the average composition for the top 10 interests for each month?

What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.


## CASE STUDY #7
![image](https://github.com/Pelummy11/8WeeksSQLChallenge/assets/47598173/7a814869-cc83-4a9b-824f-561b1de7bb92)

## BALANCED TREE CLOTHING COMPANY
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

#### Available Data
For this case study there is a total of 4 datasets for this case study - however you will only need to utilise 2 main tables to solve all of the regular questions, and the additional 2 tables are used only for the bonus challenge question!

Product Details
balanced_tree.product_details includes all information about the entire range that Balanced Clothing sells in their store.
Product Sales
balanced_tree.sales contains product level information for all the transactions made for Balanced Tree including quantity, price, percentage discount, member status, a transaction ID and also the transaction timestamp.
Product Hierarcy & Product Price
Thes tables are used only for the bonus question where we will use them to recreate the balanced_tree.product_details table.
balanced_tree.product_hierarchy
balanced_tree.product_prices.

#### High Level Sales Analysis
What was the total quantity sold for all products?
What is the total generated revenue for all products before discounts?
What was the total discount amount for all products?

#### Transaction Analysis
How many unique transactions were there?

What is the average unique products purchased in each transaction?

What are the 25th, 50th and 75th percentile values for the revenue per transaction?

What is the average discount value per transaction?

What is the percentage split of all transactions for members vs non-members?

What is the average revenue for member transactions and non-member transactions?

#### Product Analysis
What are the top 3 products by total revenue before discount?

What is the total quantity, revenue and discount for each segment?

What is the top selling product for each segment?

What is the total quantity, revenue and discount for each category?

What is the top selling product for each category?

What is the percentage split of revenue by product for each segment?

What is the percentage split of revenue by segment for each category?

What is the percentage split of total revenue by category?

What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

#### Reporting Challenge
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

#### Bonus Challenge
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

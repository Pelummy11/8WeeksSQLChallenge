
![image](https://github.com/Pelummy11/8WeeksSQLChallenge/assets/47598173/7a814869-cc83-4a9b-824f-561b1de7bb92)

## BALANCED TREE CLOTHING COMPANY
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

Case Study : (https://8weeksqlchallenge.com/case-study-7/)

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

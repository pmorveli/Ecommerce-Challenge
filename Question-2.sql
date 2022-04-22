-- What characteristics do the most successful merchant share?
-- The criteria to define a successful merchant will be based on the number of orders and the total amount generated
-- The weight for the total amount will be 60% and 40% for the number of orders

-- First I'll get a list of the 5 more successful merchants based on the previously stated criterias
with number_orders as(
select MERCHANT_ID, count(distinct order_id) as total_orders,
DENSE_RANK() over(order by count(distinct order_id)) as score
from orders
group by MERCHANT_ID),
total_amount as(
select MERCHANT_ID, sum(TOTAL_COST) as total_amount,
DENSE_RANK() over(order by sum(TOTAL_COST)) as score
from orders
where DUPLICATED_ORDER = 'No'
group by MERCHANT_ID),
weighted_table as (
select n.MERCHANT_ID, n.score*0.4 + t.score*0.6 as weighted_score,
DENSE_RANK() over(order by n.score*0.4 + t.score*0.6 desc) as ranking
from number_orders n
join total_amount t
on n.MERCHANT_ID = t.MERCHANT_ID)
select * from weighted_table
where ranking <= 5
go

-- Now that I have the list I want to see the characteristics these 5 Merchants share
-- First, I want to know how many shops do these merchants have
select MERCHANT_ID, count(distinct SHOP_ID) as number_of_shops
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID

select avg(number_of_shops*1.0) as avg_num_shops
from
(select MERCHANT_ID, count(distinct SHOP_ID) as number_of_shops
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID) as a
go
-- Insight: The 5 most successful merchants work with less than 5 shops and on average have less than 2 shops.

-- Now, I want to see what is the country that these merchants had orders from
with orders_per_merchant_and_country as(
select MERCHANT_ID,ADDRESS_TO_COUNTRY, count(distinct ORDER_ID) as orders_per_country
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID, ADDRESS_TO_COUNTRY), 
ranked_orders as(
select *, DENSE_RANK() over(partition by merchant_id order by orders_per_country desc) as ranking
from orders_per_merchant_and_country)
select MERCHANT_ID,ADDRESS_TO_COUNTRY,orders_per_country
from ranked_orders
where ranking = 1
go
-- Insight 2: The 5 most successful merchants have more clients in the US than in any other country.

-- I want to know the number of days in avg these merchants take to fulfill an order
select MERCHANT_ID, avg(DATEDIFF(day,ORDER_DT,FULFILLED_DT)*1.0) as avg_days_per_order
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID
-- Based on the the previous table I want to know the overall average of days to fulfill an order 
select avg(avg_days_per_order) as total_avg
from (select MERCHANT_ID, avg(DATEDIFF(day,ORDER_DT,FULFILLED_DT)*1.0) as avg_days_per_order
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID) as a
go
-- Insight 3: THe 5 most successful merchants spend, on average, less than 5 days to fulfill an order

-- Finding out the percentage of reprinted orders for these merchants
with reprinted as
(select MERCHANT_ID, count(distinct ORDER_ID) as orders_reprinted
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
and REPRINT_FLAG = 'True'
group by MERCHANT_ID),
total as(
select MERCHANT_ID, count(distinct order_id) as total_orders
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by MERCHANT_ID),
percentage_reprinted as(
select t.MERCHANT_ID, isnull(r.orders_reprinted*1.00/t.total_orders*100,0) as pctg_reprinted_orders
from total t
left join reprinted r
on t.MERCHANT_ID = r.MERCHANT_ID)
select avg(pctg_reprinted_orders) as avg_pctg_rerprinted
from percentage_reprinted
go
-- Insight 4: On average, the 5 most successful merchants have a 0.7365% of change of reprinting an order

-- I want to know the sales_channel_types that were used the most by these merchants
select MERCHANT_ID,SALES_CHANNEL_TYPE_ID
from
	(select MERCHANT_ID, SALES_CHANNEL_TYPE_ID, count(SALES_CHANNEL_TYPE_ID) as times_used,
	rank() over(partition by MERCHANT_ID order by count(SALES_CHANNEL_TYPE_ID) desc) as ranking
	from orders
	where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
	group by MERCHANT_ID, SALES_CHANNEL_TYPE_ID) as a
where ranking = 1
go
-- Insight 5: The SALES_CHANNEL_TYPE_ID most used by the 5 most successful merchants are 1, 2 and 6, 1 being used the most by several of these merchants

-- I'd like to know how long have these merchants been working with Printify
select distinct MERCHANT_ID, year(MERCHANT_REGISTERED_DT) as registration_year
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
go
-- there's not  a common pattern for this specific piece of information

--finding out if these merchants are subscribed to any subscription plan, and if so to which.
select distinct MERCHANT_ID, SUB_IS_ACTIVE_FLAG
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')

select distinct MERCHANT_ID, SUB_PLAN
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
go
-- Insight 6: the 5 most successful merchants are all subscribed to the business_account_3 plan except for one, who is subscribed to Plan 4.

-- I want to know what's the shipment carrier most used by these merchants
with orders_per_merchant_and_carrier as(
select MERCHANT_ID, SHIPMENT_CARRIER, count(distinct ORDER_ID) as orders_per_carrier
from orders
where MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
and SHIPMENT_CARRIER is not null
group by MERCHANT_ID, SHIPMENT_CARRIER), 
ranked_orders as(
select *, DENSE_RANK() over(partition by merchant_id order by orders_per_carrier desc) as ranking
from orders_per_merchant_and_carrier)
select MERCHANT_ID, SHIPMENT_CARRIER, orders_per_carrier
from ranked_orders
where ranking = 1
go
-- Insight 7: The shipment carrier most used by the 5 most successful merchants is USPS

-- I want to know the most used print providers these merchants worked with
with print_provider_per_merchant as(
select o.MERCHANT_ID, l.PRINT_PROVIDER_ID, count(distinct o.ORDER_ID) as orders_per_provider
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where o.MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by o.MERCHANT_ID, l.PRINT_PROVIDER_ID), 
ranked_providers as(
select *, DENSE_RANK() over(partition by merchant_id order by orders_per_provider desc) as ranking
from print_provider_per_merchant)
select MERCHANT_ID, PRINT_PROVIDER_ID, orders_per_provider
from ranked_providers
where ranking = 1
order by 2
go
-- Insight 8: The print providers' ids the 5 most successful merchants worked with are 25, 29, 30 and 45

-- I want to know the brands that are most sold among these merchants
with quant_per_merchant as(
select o.MERCHANT_ID, l.PRODUCT_BRAND, sum(l.QUANTITY) as quant_per_brand
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where o.MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by o.MERCHANT_ID, l.PRODUCT_BRAND), 
ranked_brands as(
select *, DENSE_RANK() over(partition by merchant_id order by quant_per_brand desc) as ranking
from quant_per_merchant)
select MERCHANT_ID, PRODUCT_BRAND, quant_per_brand
from ranked_brands
where ranking = 1
go
-- Insight 9: the brands most sold among the 5 most successful merchants are Generic brand (2), Gildan (2) and Next Level (1)

-- I want to know the product types that are most sold among these merchants
with quant_per_merchant as(
select o.MERCHANT_ID, l.PRODUCT_TYPE, sum(l.QUANTITY) as quant_per_type
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where o.MERCHANT_ID in ('6433350', '5755049', '6118692', '7019548', '7027744')
group by o.MERCHANT_ID, l.PRODUCT_TYPE), 
ranked_types as(
select *, DENSE_RANK() over(partition by merchant_id order by quant_per_type desc) as ranking
from quant_per_merchant)
select MERCHANT_ID, PRODUCT_TYPE, quant_per_type
from ranked_types
where ranking = 1
go
-- Insight 10: the product types most sold among the 5 most successful merchants are T-Shirt (2), Hoodie (1), Mug (1) and Sweatshirt (1)

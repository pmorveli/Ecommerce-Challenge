-- 1. Write a query returning all ORDER_IDs with the time the merchant has been active at the time of the order, 
-- the rank of the merchant by order count for the previous month, and the merchant's primary sales channel for the previous month
-- Assumption: To determine the primary sales channel of a merchant the criteria was the amount of orders per channel (the highest the better)

with tenth_month as(
select MERCHANT_ID, count(distinct ORDER_ID) as orders_count, month(order_dt) as month,
dense_rank() over(partition by month(order_dt) order by count(distinct ORDER_ID) desc) as ranking
from orders
where month(ORDER_DT) = 10
group by MERCHANT_ID, month(order_dt)),
eleventh_month as(
select MERCHANT_ID, count(distinct ORDER_ID) as orders_count, month(order_dt) as month,
dense_rank() over(partition by month(order_dt) order by count(distinct ORDER_ID) desc) as ranking
from orders
where month(ORDER_DT) = 11
group by MERCHANT_ID, month(order_dt)),
twelveth_month as(
select MERCHANT_ID, count(distinct ORDER_ID) as orders_count, month(order_dt) as month,
dense_rank() over(partition by month(order_dt) order by count(distinct ORDER_ID) desc) as ranking
from orders
where month(ORDER_DT) = 12
group by MERCHANT_ID, month(order_dt)),
prev_month_rank as(
select *, NULL as prev_rank
from tenth_month
Union ALL
select e.*, t.ranking as prev_rank
from eleventh_month e
left join tenth_month t
on e.merchant_id = t.merchant_id
Union ALL
select tw.*, el.ranking as prev_rank
from twelveth_month tw
left join eleventh_month el
on tw.merchant_id = el.merchant_id),
--select * from prev_month_rank
sales_channels as(
select MERCHANT_ID, month(order_dt) as month, SALES_CHANNEL_TYPE_ID, count(distinct ORDER_ID) as num_orders,
DENSE_RANK() over(partition by MERCHANT_ID, month(order_dt) order by count(distinct ORDER_ID)) as ranking
from orders
group by MERCHANT_ID, month(order_dt), SALES_CHANNEL_TYPE_ID),
tenth_channel as(
select MERCHANT_ID, month, SALES_CHANNEL_TYPE_ID
from sales_channels
where ranking = 1 and month = 10),
eleventh_channel as(
select MERCHANT_ID, month, SALES_CHANNEL_TYPE_ID
from sales_channels
where ranking = 1 and month = 11),
twelveth_channel as (
select MERCHANT_ID, month, SALES_CHANNEL_TYPE_ID
from sales_channels
where ranking = 1 and month = 12),
pre_month_channel as (
select *, null as prev_channel
from tenth_channel
union all
select e.*,t.SALES_CHANNEL_TYPE_ID as prev_channel
from eleventh_channel e
left join tenth_channel t
on e.MERCHANT_ID=t.MERCHANT_ID
union all
select tw.*,el.SALES_CHANNEL_TYPE_ID as prev_channel
from twelveth_channel tw
left join eleventh_channel el
on tw.MERCHANT_ID=el.MERCHANT_ID)
select o.ORDER_ID, DATEDIFF(day,o.MERCHANT_REGISTERED_DT, o.ORDER_DT) as merchant_time_active,month(o.order_dt) as month, 
m.prev_rank as previous_month_rank, c.prev_channel as previous_month_primary_sales_channel
from orders o
left join prev_month_rank m
on o.MERCHANT_ID = m.MERCHANT_ID and month(o.order_dt) = m.month
left join pre_month_channel c
on o.MERCHANT_ID = c.MERCHANT_ID and month(o.order_dt) = c.month
order by 3
go

-- 2. Write a statement to create a table containing print providers with average production time, reprint percent, 
-- last order timestamp, and primary shipping carrier

with total_orders as(
select l.PRINT_PROVIDER_ID, count(distinct o.ORDER_ID) as total_orders
from line_items l
join orders o
on l.ORDER_ID = o.ORDER_ID
where o.DUPLICATED_ORDER = 'No'
group by l.PRINT_PROVIDER_ID),
reprinted_orders as(
select l.PRINT_PROVIDER_ID, count(distinct o.ORDER_ID) as reprinted_orders
from line_items l
join orders o
on l.ORDER_ID = o.ORDER_ID
where o.DUPLICATED_ORDER = 'No' and o.REPRINT_FLAG = 'True'
group by l.PRINT_PROVIDER_ID),
reprint_percent as(
select t.PRINT_PROVIDER_ID, r.reprinted_orders*100.0/t.total_orders as pct_reprinted
from total_orders t
left join reprinted_orders r
on t.PRINT_PROVIDER_ID = r.PRINT_PROVIDER_ID),
last_order_timestamp as(
select l.PRINT_PROVIDER_ID, max(o.ORDER_DT) last_order_dt
from line_items l
join orders o
on l.ORDER_ID = o.ORDER_ID
group by l.PRINT_PROVIDER_ID),
primary_shipping_carrier as(
select PRINT_PROVIDER_ID, SHIPMENT_CARRIER
from
(select l.PRINT_PROVIDER_ID, o.SHIPMENT_CARRIER, count(distinct o.ORDER_ID) as number_of_orders,
DENSE_RANK() over(partition by l.PRINT_PROVIDER_ID order by count(distinct o.ORDER_ID) desc) as ranking
from line_items l
join orders o
on l.ORDER_ID = o.ORDER_ID
where o.SHIPMENT_CARRIER is not null
group by l.PRINT_PROVIDER_ID, o.SHIPMENT_CARRIER) as a
where ranking = 1),
temp_table as(
select l.PRINT_PROVIDER_ID, avg(DATEDIFF(day,o.ORDER_DT,o.FULFILLED_DT)*1.0) as avg_production_time,
r.pct_reprinted as reprint_percent, t.last_order_dt as last_order_timestamp,
c.SHIPMENT_CARRIER as primary_shipping_carrier
from reprint_percent r
left join line_items l
on r.PRINT_PROVIDER_ID = l.PRINT_PROVIDER_ID
left join orders o
on l.ORDER_ID = o.ORDER_ID
left join last_order_timestamp t
on r.PRINT_PROVIDER_ID = t.PRINT_PROVIDER_ID
left join primary_shipping_carrier c
on r.PRINT_PROVIDER_ID = c.PRINT_PROVIDER_ID
where o.DUPLICATED_ORDER = 'No'
group by l.PRINT_PROVIDER_ID, r.pct_reprinted, t.last_order_dt, c.SHIPMENT_CARRIER)
select * 
into Bonus_SQL_Excercise_two
from temp_table
go

select * from Bonus_SQL_Excercise_two
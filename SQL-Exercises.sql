-- 1. Write a query returning total sales, orders, and count of merchants by month
-- Assumption: Sales refer to the total_cost values in the orders table
-- Since I know there are duplicated orders that can mess up aggregations I will filter them out for this query
select SUM(Total_cost) as total_sales, count(ORDER_ID) as total_oders,
COUNT(merchant_id) as count_of_merchants, MONTH(order_dt) as month
from orders
where DUPLICATED_ORDER = 'No'
group by MONTH(order_dt)
order by 3
go

-- 2. Write a query returning merchants total sales, product count, and order count ordered by order count for merchants with more than 5 orders
-- Since I know there are duplicated orders that can mess up aggregations I will filter them out for this query
select merchant_id, sum(o.Total_cost) as merchants_total_sales, sum(l.QUANTITY) as product_count, 
count(o.order_id) as order_count
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where DUPLICATED_ORDER ='No'
and o.MERCHANT_ID in 
	(select merchant_id
	from orders
	where DUPLICATED_ORDER ='No'
	group by MERCHANT_ID
	having count(order_id) > 5)
group by MERCHANT_ID
order by 4
go
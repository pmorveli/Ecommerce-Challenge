-- What are the top two shipping carriers? Why should or shouldn’t we try to use those two for all orders?
-- the first criteria for this ranking will be based on the shipping cost (the lower the better)
-- the second criteria for this ranking will be based on the average days of delivery (SHIPMENT_DELIVERD_DT - FULFILLED_DT), the lower the better
-- Assumption 1: for a shipping carrier to be considered, all the items in the order must have a 'shipment_delivered' status
-- Assumption 2: The shipping cost is payed by the end consumer and not by Printify nor merchants
-- Assumption 3: Because of the 1st asumption, the delivery duration is greatly valued by the end consumer, and by extension, by Printify
-- Based on those asumptions, the first criteria will have a weight of 35% and the second one a weight of 65%

with criteria_shipping_cost as(
select o.SHIPMENT_CARRIER, avg(o.TOTAL_SHIPPING) as avg_shipping_cost_per_carrier,
dense_rank() over(order by avg(o.TOTAL_SHIPPING) desc) as score
from orders o 
join line_items l
on o.ORDER_ID = l.ORDER_ID
where l.ITEM_STATUS = 'shipment_delivered'
and o.SHIPMENT_CARRIER is not null
group by o.SHIPMENT_CARRIER
),
criteria_shipping_lead_time as(
select o.SHIPMENT_CARRIER, avg(DATEDIFF(day,FULFILLED_DT,SHIPMENT_DELIVERD_DT)) as avg_shipping_lead_time,
dense_rank() over(order by avg(DATEDIFF(day,FULFILLED_DT,SHIPMENT_DELIVERD_DT)) desc) as score
from orders o 
join line_items l
on o.ORDER_ID = l.ORDER_ID
where l.ITEM_STATUS = 'shipment_delivered'
and o.SHIPMENT_CARRIER is not null and FULFILLED_DT is not null and SHIPMENT_DELIVERD_DT is not null
group by o.SHIPMENT_CARRIER
), weighted_carriers as(
select c.SHIPMENT_CARRIER, c.avg_shipping_cost_per_carrier as avg_shipp_cost, c.score as cost_score, d.avg_shipping_lead_time as avg_lead_time,
d.score as duration_score, c.score*0.35 + d.score*0.65 as weighted_score
,DENSE_RANK() over(order by c.score*0.35 + d.score*0.65 desc) as final_rank
from criteria_shipping_cost c
join criteria_shipping_lead_time d
on c.SHIPMENT_CARRIER = d.SHIPMENT_CARRIER)
select SHIPMENT_CARRIER,avg_shipp_cost, avg_lead_time, final_rank
from weighted_carriers
where final_rank <=2
go
-- Answer: the top two shipping carriers, based in the previously explained criterias, are DPD and USPS.

-- Before answering the second part of this question, and since most of the orders go to the US,
-- I'd like to know how these 2 carriers perform on the previously chosen criterias both inside and outside the US

-- Finding out the average shipping cost and shipping lead time OUTSIDE the US
select o.SHIPMENT_CARRIER, avg(o.TOTAL_SHIPPING) as avg_shipping_cost, a.avg_delivery_lead_time
from orders o
join
	(select SHIPMENT_CARRIER, avg(DATEDIFF(day,FULFILLED_DT,SHIPMENT_DELIVERD_DT)) as avg_delivery_lead_time
	from orders
	where SHIPMENT_CARRIER = 'DPD' or SHIPMENT_CARRIER = 'USPS' and ADDRESS_TO_COUNTRY != 'US'
	group by SHIPMENT_CARRIER) as a
on o.SHIPMENT_CARRIER = a.SHIPMENT_CARRIER
where o.SHIPMENT_CARRIER = 'DPD' or o.SHIPMENT_CARRIER = 'USPS' and o.ADDRESS_TO_COUNTRY != 'US'
group by o.SHIPMENT_CARRIER, a.avg_delivery_lead_time
order by 1
go

-- Finding out the average shipping cost and shipping lead time INSIDE the US
select o.SHIPMENT_CARRIER, avg(o.TOTAL_SHIPPING) as avg_shipping_cost, a.avg_delivery_lead_time
from orders o
join
	(select SHIPMENT_CARRIER, avg(DATEDIFF(day,FULFILLED_DT,SHIPMENT_DELIVERD_DT)) as avg_delivery_lead_time
	from orders
	where SHIPMENT_CARRIER = 'DPD' or SHIPMENT_CARRIER = 'USPS' and ADDRESS_TO_COUNTRY = 'US'
	group by SHIPMENT_CARRIER) as a
on o.SHIPMENT_CARRIER = a.SHIPMENT_CARRIER
where o.SHIPMENT_CARRIER = 'DPD' or o.SHIPMENT_CARRIER = 'USPS' and o.ADDRESS_TO_COUNTRY = 'US'
group by o.SHIPMENT_CARRIER, a.avg_delivery_lead_time
order by 1
go

--When excecuting the 3 queries at once I can compare the performance on the criterias, and based on that comparisson I can answer the question:
-- DPD should be used, if possible, for all orders, because it consistently performs well in shipping cost and lead time inside and outside the US
-- USPS should not be used outside the US because its shipping cost and lead time skyrockets, but inside the US it performs really well.
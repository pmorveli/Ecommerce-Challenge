-- Print Providers control the print quality, stock of items, and production time (the time from ordered to fulfilled). 
-- We want to provide a discount to the two best Print Providers and end our contracts with the worst two. Which do you choose and why?

-- Based on what the Print Providers control and the data available, the criterias to determine what makes a provider better over other are:
-- Print Quality, the number of times an order had to be reprinted (the lower the better).
-- Production Time, meaning difference between ORDER_DT and FULFILLED_DT (the lower the better).
-- The weights for these criterias are 0.6 for Print Quality and 0.4 for Production Time.

-- Geting the ranking of the print_providers
with quality_criteria as(
select l.PRINT_PROVIDER_ID, count(distinct o.ORDER_ID) as count_reprint,
DENSE_RANK() over(order by count(distinct o.ORDER_ID) desc) as ranking_quality
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where o.REPRINT_FLAG = 'True' 
group by l.PRINT_PROVIDER_ID),
prod_time_criteria as(
select l.PRINT_PROVIDER_ID, avg(DATEDIFF(day,o.ORDER_DT,o.FULFILLED_DT)*1.0) as avg_production_time,
DENSE_RANK() over(order by avg(DATEDIFF(day,o.ORDER_DT,o.FULFILLED_DT)*1.0) desc) as ranking_prod_time
from orders o
join line_items l
on o.ORDER_ID = l.ORDER_ID
where l.ITEM_STATUS ='fulfilled'
group by l.PRINT_PROVIDER_ID),
weighted_providers as(
select q.PRINT_PROVIDER_ID, q.count_reprint, p.avg_production_time,
q.ranking_quality*0.6 + p.ranking_prod_time*0.4 as weighted_criteria,
DENSE_RANK() over( order by q.ranking_quality*0.6 + p.ranking_prod_time*0.4 desc) as final_ranking
from quality_criteria q
join prod_time_criteria p
on q.PRINT_PROVIDER_ID = p.PRINT_PROVIDER_ID)
select PRINT_PROVIDER_ID,count_reprint as number_of_reprints, avg_production_time, final_ranking as ranking_position
from weighted_providers

--Answer: The 2 best print providers to receive a discount should be the ones with ID 7 and ID 30 because they have the least amount of reprints
-- and because their average production time to fulfill an order is the lowest.
-- the two worst print providers that we should end our contracts with are ID 3 and 59. For ID 3 is because it has a lot of reprints.
-- For ID 59 is because it has the longest average production time.
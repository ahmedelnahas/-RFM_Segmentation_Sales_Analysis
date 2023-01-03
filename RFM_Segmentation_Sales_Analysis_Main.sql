-- inspecting Data
select * from sales_data_sample 

-- update the ORDERDATE from string to Date 
UPDATE sales_data_sample2 
SET sales_data_sample2.ORDERDATE=CONVERT(date, ORDERDATE);
SELECT ORDERDATE FROM sales_data_sample2


--checking unique values
select distinct STATUS FROM sales_data_sample -- Nice one to plot
select distinct year_id from sales_data_sample 
select distinct PRODUCTLINE from sales_data_sample -- Nice to plot
select distinct country from sales_data_sample -- Nice to plot
select distinct TERRITORY FROM sales_data_sample -- Nice to plot 


--Analysis
-- lets start by grouping sales by productline 
select PRODUCTLINE , SUM(SALES) Revenue FROM sales_data_sample
GROUP BY PRODUCTLINE
order by 2 DESC

-- check the most year revenue
select year_id, sum(sales) Revenue_by_year from sales_data_sample
GROUP by YEAR_ID
ORDER by 2 DESC

-- checking why 2005 is the lowest revenu ???
select Distinct MONTH_id from sales_data_sample
where year_id  = 2005


select Distinct month_id from sales_data_sample
where YEAR_ID = 2004


select Distinct month_id from sales_data_sample
where YEAR_ID = 2003

-- check most of size to buy 
select dealsize , sum(sales) revenue_by_size from sales_data_sample
GROUP by DEALSIZE
ORDER by 2 DESC

-- check most of the country to buy 
select country, sum(sales) revenue_by_country from sales_data_sample
GROUP by COUNTRY
ORDER by 2 DESC

 --  what is the best month for sales in a specific year ? how much was earned that year ?
 select month_id , sum(sales) revenue ,count(ORDERNUMBER) frequency from sales_data_sample
 where year_id = 2003
 GROUP by MONTH_ID
 ORDER by 2 DESC
 
 -- november is the best month so what product do they sale in November ?
 select MONTH_ID, PRODUCTLINE, SUM(SALES) REVENUE, COUNT(ORDERNUMBER) FREQUENCY FROM sales_data_sample
 WHERE YEAR_ID = 2003 AND  MONTH_ID = 11
 GROUP BY PRODUCTLINE , MONTH_ID
 ORDER BY 3 DESC

-- RFM  IS AWY OF SEGMENTING CUSTOMER USING THREE KESY  METRICS :  
-- 1 RECENCY (HOW LONG AGO THEIR LAST PURCHASE WAS) -- LAST ORDER DATE
-- 2 FREQUENCY (HOW OFTEN THEY PRUCHASE)-- COUNT OF TOTAL ORDERS
-- MONETARY VALUE (HOW MUCH THEY SPENT) -- TOTAL SPEND

--- who is our best customer (this could be the best answer with RFM)
DROP TABLE IF EXISTS #rfm
; WITH rfm AS
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sales_data_sample2)  max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample2)) Recency
	from sales_data_sample2
	group by CUSTOMERNAME

),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
    into #rfm

from rfm_calc c



select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--What products are most often sold together? 
--select * from sales_data_sample where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data_sample2 p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample2
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from sales_data_sample2
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
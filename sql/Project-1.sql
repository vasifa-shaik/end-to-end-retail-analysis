create database retail;
use retail;


-- Customers ---------------------------------------
alter table customers_cleaned
modify customer_id varchar(20),
modify first_name varchar(100),
modify last_name varchar(100),
modify gender varchar(20),
modify age varchar(10),
modify signup_date varchar(20),
modify region varchar(50);

-- Products ------------------------------------------
alter table products_cleaned
modify product_id varchar(20),
modify product_name varchar(150),
modify category varchar(100),
modify brand varchar(100),
modify cost_price varchar(50),
modify unit_price varchar(50),
modify margin_pct varchar(50);

-- Returns ------------------------------------------------------
alter table returns_cleaned1
modify return_id varchar(20),
modify order_id varchar(20),
modify return_date varchar(20),
modify return_reason varchar(150);

-- Sales_data -----------------------------------------------------
alter table sales_cleaned
modify order_id varchar(20),
modify order_date varchar(20),
modify customer_id varchar(20),
modify product_id varchar(20),
modify store_id varchar(20),
modify sales_channel varchar(50),
modify quantity varchar(20),
modify unit_price varchar(50),
modify discount_pct varchar(50),
modify total_amount varchar(50);

-- Stores ------------------------------------------------------
alter table stores_cleaned
modify store_id varchar(20),
modify store_name varchar(150),
modify store_type varchar(100),
modify region varchar(100),
modify city varchar(100),
modify operating_cost varchar(50);

-- Adding primary keys to tables -------------------------------------
alter table customers_cleaned
add primary key (customer_id);

alter table products_cleaned
add primary key (product_id);

alter table stores_cleaned
add primary key (store_id);

-- For tables that refer them --------------------------------------
alter table sales_cleaned
add index idx_customer_id (customer_id),
add index idx_product_id (product_id),
add index idx_store_id (store_id);

alter table returns_cleaned1
add index idx_order_id (order_id);

-- Relationships ------------------------------------------------------
alter table sales_cleaned
add constraint fk_sales_customer
foreign key (customer_id)
references customers_cleaned(customer_id);

alter table sales_cleaned
add constraint fk_sales_product
foreign key (product_id)
references products_cleaned(product_id);

-- ----------------------------------------------------------------
select distinct store_id
from sales_cleaned
where store_id not in (select store_id from stores_cleaned)
or store_id is null
or store_id = '';

set foreign_key_checks = 0;

alter table sales_cleaned 
add constraint fk_sales_store
foreign key (store_id)
references stores_cleaned(store_id);

set foreign_key_checks = 1;
-- -----------------------------------------------------
alter table sales_cleaned
add index idx_order_id (order_id);

alter table returns_cleaned1
add constraint fk_returns_order
foreign key (order_id)
references sales_cleaned(order_id);


--                        BUSINESS QUESTIONS                      ---


-- 1. what is the total revenue generated in last 12 months?--

 select
      round(sum(total_amount), 2) as total_revenue_last_12_months
	from sales_cleaned
    where order_date between date_sub(curdate(),interval 12 month) and curdate();
    
    
  --  2. Which are the top 5 best-selling products by quantity?--
  
  select
       p.product_id,
	   p.product_name,
	  sum(s.quantity) as total_quantity_sold
   from
      sales_cleaned s 
   join products_cleaned p
		on s.product_id = p.product_id
   group by p.product_id,p.product_name
   order by total_quantity_sold desc
   limit 5;
   
   
  -- 3. How many customers are from each region? --
  
  select
        region,
        count(*) as customer_count
  from
      customers_cleaned
group by
       region
order by
       customer_count desc;
       
-- 4. Which store has the highest profit in the past year?  --

select
     s.store_id,
     st.store_name,
     round(sum(s.total_amount) - st.operating_cost, 2) as total_profit
from sales_cleaned s
join stores_cleaned st
     on s.store_id = st.store_id
where s.order_date between date_sub(curdate(), interval 12 month) and curdate()
group by s.store_id,st.store_name,st.operating_cost
order by total_profit desc
limit 1;

-- 5. What is the return rate by product category? --

select
     p.category,
     count(distinct r.order_id) as returned_orders,
     count(distinct s.order_id) as total_orders,
     Round((count(distinct r.order_id) / count(distinct s.order_id)) * 100, 2) as return_rate_percentage
from sales_cleaned s
join products_cleaned p 
     on s.product_id = p.product_id
left join returns_cleaned1 r 
     on s.order_id = r.order_id
group by p.category
order by return_rate_percentage desc;

-- 6. What is the average revenue per customer by age group?--

 select
     case
        when c.age between 18 and 25 then '18-25'
        when c.age between 26 and 35 then '26-35'
        when c.age between 36 and 45 then '36-45'
        when c.age between 46 and 55 then '46-55'
        when c.age between 56 and 65 then '56-65'
        else '65+'
	end as age_group,
    round(sum(s.total_amount) / count(distinct c.customer_id), 2) as avg_revenue_per_customer
from sales_cleaned s 
join customers_cleaned c 
     on s.customer_id = c.customer_id
group by age_group
order by age_group;

 
 -- 7. Which sales channel (Online vs In-Store) is more profitable on average? --
 
 select
       s.sales_channel,
       round(avg(s.total_amount), 2) as avg_revenue_per_order,
       count(distinct s.order_id) as total_orders
from sales_cleaned s 
where s.order_date between date_sub(curdate(), interval 12 month) and curdate()
group by s.sales_channel
order by avg_revenue_per_order desc;


-- 8. How has monthly profit changed over the last 2 years by region? --

select
      st.region,
      date_format(s.order_date, '%y%m') as month,
      round(sum(s.total_amount) - sum(st.operating_cost)/count(distinct s.store_id), 2) as total_profit
from sales_cleaned s 
join stores_cleaned st 
     on s.store_id = st.store_id
where s.order_date between date_sub(curdate(), interval 24 month) and curdate()
group by st.region, month
order by month, st.region;


-- 9. Identify the top 3 products with the highest return rate in each category.--

WITH ProductReturnRates AS (
    SELECT
        P.category,
        P.product_name,
        COUNT(DISTINCT R.order_id) / COUNT(DISTINCT S.order_id) AS return_rate,
        RANK() OVER (
            PARTITION BY P.category
            ORDER BY COUNT(DISTINCT R.order_id) / COUNT(DISTINCT S.order_id) DESC
        ) AS rank_in_category
    FROM
        sales_cleaned S
    JOIN
        products_cleaned P ON S.product_id = P.product_id
    LEFT JOIN
        returns_cleaned1 R ON S.order_id = R.order_id
    GROUP BY
        P.category, P.product_name
)
SELECT
    category,
    product_name,
    return_rate
FROM
    ProductReturnRates
WHERE
    rank_in_category <= 3
ORDER BY
    category, return_rate DESC;
    
    
 -- 10. Which 5 customers have contributed the most to total profit, and what is their tenure with the company? --   
    
   SELECT
    C.customer_id,
    C.first_name,
    C.last_name,
    ROUND(SUM(S.total_amount - (P.cost_price * S.quantity)), 2) AS total_profit,
    ROUND(DATEDIFF(CURDATE(), STR_TO_DATE(C.signup_date, '%d-%m-%Y')) / 365.25, 1) AS customer_tenure_years
FROM
    sales_cleaned S
JOIN
    products_cleaned P ON S.product_id = P.product_id
JOIN
    customers_cleaned C ON S.customer_id = C.customer_id
GROUP BY
    C.customer_id, C.first_name, C.last_name, C.signup_date
ORDER BY
    total_profit DESC
LIMIT 5;











# CREATING THE DATABASE.
create database Ecommerce_sales;

# USING THE NEWLY MADE DATABASE.
use Ecommerce_sales;

-- EXPLAINATION :- IS TO ENSURE THAT WE ARE SATARTING WITH A FRESH DATABASE 
--                 BY CREATING AND USING DATABASE(Ecommerce_sales).

-----------------------------------------------------------------------------------------------------------

# RENAMEING COLUMNS of THE Tables.

ALTER TABLE orders_dataset
rename column order_purchase_timestamp to purchase_date,
rename column order_delivered_customer_date to delivered_date,
rename column order_estimated_delivery_date to estimated_delivery_date;
 
ALTER TABLE customers
rename column customer_zip_code_prefix to zip_code,
rename column customer_city to city,
rename column customer_state to state;

alter table product_category_name
rename column ï»¿product_category_name to product_category_name; 

-- EXPLAINATION :- WE USED THE ALTER TABLE(RENAME) FUNCTION TO RENAME THE COLUMNS WHICH 
--                 HAS INAPPROPRIATE NAMES. 


# DROPING UNWANTED COLUMNS FROM THE TABLES.
 
ALTER TABLE orders_dataset
drop column order_approved_at,
drop column order_delivered_carrier_date;

ALTER TABLE products
drop column product_name_lenght,
drop column product_description_lenght,
drop column product_photos_qty;

-- EXPLAINATION :- HERE WE USED THE DATA CLEAING PROCCESS BY DROPING UNWANTED COLUMNS AND 
--                 RENAMING THE COLUMNS.

-----------------------------------------------------------------------------------------------------------

# FURTHER WE CHECKS FOR THE DUPLICATES IN EACH TABLE

select customer_id, count(*)
from customers
group by customer_id
having count(*) > 1; -- showing the DUPLICATES.

select order_id, count(*)
from order_payments
group by order_id
having count(*) > 1; --  showing the DUPLICATES.

select order_id, count(*)
from orders
group by order_id
having count(*) > 1; --  showing the DUPLICATES.

select order_id, count(*)
from orders
group by order_id
having count(*) > 1; --  showing the DUPLICATES.

select order_id, count(*)
from orders_dataset
group by order_id
having count(*) > 1; --  showing the DUPLICATES.

select product_id, count(*)
from products
group by product_id
having count(*) > 1; --  showing the DUPLICATES.

select seller_id, count(*)
from sellers
group by seller_id
having count(*) > 1; --  showing the DUPLICATES

select order_id, count(*)
from order_items
group by order_id
having count(*) > 1; --  showing the DUPLICATES.

-- EXPLAINATION :- WE ARE CHECKING FOR THE DUPLICATES IN EACH COLUMNS OF EVERY TABLE BY USING 
--                 THE GROUPING BY THE ID (UNIQUE IDENTIFICATION) COLUMN AND THEN SIMPLY GIVING
--                 THE OUTPUT WHERE THE COUNT(*) > 1 IN THE HAVING CLAUSE WHICH GIVES ONLY THE 
--                 ROWS WHO'S COUNT IS MORE THAN ONE.
 
-----------------------------------------------------------------------------------------------------------

# REMOVING THE DUPLICATE ROWS.

create table customers_temp as
select * from (select *, row_number() over (partition by customer_unique_id,zip_code,city,state order by customer_id) as row_num 
from customers
) as temp
where row_num = 1;
drop table customers;
alter table customers_temp rename to customers;


create table order_payments_temp as
select * from (select *, row_number() over (partition by payment_sequential,
			   payment_type, payment_installments, payment_value order by order_id) as row_num 
from order_payments
) as temp
where row_num = 1;
drop table order_payments;
alter table order_payments_temp rename to order_payments;


create table orders_temp as
select * from (select *, row_number() over (partition by order_item_id,
			   product_id, seller_id, shipping_limit_date, price, freight_value order by order_id) as row_num 
from orders
) as temp
where row_num = 1;
drop table orders;
alter table orders_temp rename to orders;


create table orders_dataset_temp as
select * from (select *, row_number() over (partition by customer_id,
			   order_status, purchase_date, delivered_date, estimated_delivery_date order by order_id) as row_num 
from orders_dataset
) as temp
where row_num = 1;
drop table orders_dataset;
alter table orders_dataset_temp rename to orders_dataset;


create table products_temp as
select * from (select *, row_number() over (partition by product_id,
			   product_category_name, product_weight_g, product_length_cm, product_height_cm, product_width_cm order by product_id) as row_num 
from products
) as temp
where row_num = 1;
drop table products;
alter table products_temp rename to products;


create table sellers_temp as
select * from (select *, row_number() over (partition by seller_id, seller_zip_code_prefix, seller_city, seller_state
										    order by seller_id) as row_num 
from sellers
) as temp
where row_num = 1;
drop table sellers;
alter table sellers_temp rename to sellers;

-- EXPLAINATION :- FIRST OF ALL WE USE THE ROW_NUMBER() TO  ASSIGN THE 
--                 UNIQUE NUMBER TO EACH DUPLICATE GROUP BASED ON THE  
--                 COLUMN NAMES WHICH ONLY KEEPS THE FIRST OCCUERENCE (ROW_NUM = 1). 
--                 THEN WE REPLACED THE MAIN TABLES WITH THE CLEANED DATA.  


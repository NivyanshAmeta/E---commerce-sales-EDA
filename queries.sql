# 1) What are the top 10 most frequently ordered products?

with most_order_product as(
select pcn.product_category_name_english as product_names, 
count(oi.order_id) as total_orders
from order_items as oi
join products as p
on oi.product_id = p.product_id
join product_category_name as pcn
on p.product_category_name = pcn.product_category_name
group by pcn.product_category_name_english
)
select product_names, total_orders
from most_order_product
order by total_orders desc
limit 10;
-- EXPLANATION :- This CTE query first calculates the total order count for each product category by joining
--                the order_items and product_category_name tables. It then uses this temporary result to identify
--                and display the top 10 most frequently ordered product categories by using order by desc and limit. 

-------------------------------------------------------------------------------------------------------------------------------------------------------------

# 2) What is the trend of orders per month or year?

select 
year(purchase_date) as purchase_year,
monthname(purchase_date) as purchase_month,
count(order_id) as total_orders
from orders
group by year(purchase_date), monthname(purchase_date)
order by purchase_year, purchase_month;

-- EXPLANATION :- This query looks at your order dates, pulls out the year and the name of the month for each order.
--                Then, it counts how many orders happened in each specific month of each year and lists them from the 
--                earliest to the latest which helps to identify the order trends according to year and month.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 3) What is the total revenue generated by each product?

select
p.product_category_name as product_name,
round(sum(o.price + o.freight_value),2) as revenue
from order_items o
join products p  
on o.product_id = p.product_id
group by p.product_category_name
order by revenue desc;

-- EXPLANATION :- This query calculates the total revenue for each product by adding up the price and shipping cost
--                for every item sold. It then groups these totals by product category and sort them from highest to 
--                lowest revenue.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 4) What is the average delivery time by seller?

select
round(avg(datediff(delivered_date, purchase_date)),0) as avg_delivery_time 
from orders;

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 5) What’s the percentage of orders delivered late? 

select 
round(sum(case when delivered_date > estimated_delivery_date then 1 else 0 end) * 100/ count(*),2)
as late_delivery_percentage
from orders;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 6) How has sales evolved over time (yearly and monthly)?

select
year(o1.purchase_date) as sales_year,
monthname(o1.purchase_date) as months,
round(sum(o2.payment_value),2) as total_sales
from order_payments o2
join orders o1
on o2.order_id = o1.order_id
group by year(o1.purchase_date),
monthname(o1.purchase_date),
month(o1.purchase_date)
order by sales_year, month(o1.purchase_date);

-- EXPLANATION :- The query calculates the total sales for each month, categorized by year.
--                It does this by joining orders information with order_payment,
--                then summing up payment_values and grouping them by year and month.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 7)  Calculate the Month-over-Month Sales Growth Percentage.

WITH MonthlySales AS (
    SELECT
        monthname(purchase_date) AS SalesMonth,
        ROUND(SUM(T2.payment_value),2) AS TotalSales
    FROM
        orders AS T1
	
	JOIN
        order_payments AS T2 ON T1.order_id = T2.order_id
    GROUP BY
        monthname(purchase_date)
),
SalesGrowth AS (
    SELECT
        SalesMonth,
        TotalSales,
        ROUND(LAG(TotalSales, 1, 0) OVER (ORDER BY SalesMonth),2) AS PreviousMonthSales
    FROM
        MonthlySales
)
SELECT
    SalesMonth,
    TotalSales,
    PreviousMonthSales,
    CASE
        WHEN PreviousMonthSales = 0 THEN NULL -- Avoid division by zero for the first month
        ELSE ROUND((TotalSales - PreviousMonthSales) * 100.0 / PreviousMonthSales,2)
    END AS GrowthPercentage
FROM
    SalesGrowth
ORDER BY
    SalesMonth;
    
-- EXPLANATION :- This query first totals sales for each month. 
--                Then, it compares each month's sales to the 
--                previous month's sales to calculate the percentage change.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 8) Identify the Top 3 Products by Total Revenue within Each Product Category
SELECT * FROM PRODUCTS;
select * from order_items;
SELECT
    ProductCategory
    product_id,
    ProductTotalRevenue
FROM (
    SELECT
        pct.product_category_name_english AS ProductCategory,
        p.product_id,
        round(SUM(oi.price),2) AS ProductTotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY pct.product_category_name_english ORDER BY SUM(oi.price) DESC) AS Rank_With_Category
    FROM
        order_items AS oi
    JOIN
        products AS p 
        ON oi.product_id = p.product_id
    LEFT JOIN
        product_category_name AS pct 
        ON p.product_category_name = pct.product_category_name
    WHERE
        pct.product_category_name_english IS NOT NULL -- Exclude products without a category translation
    GROUP BY
        pct.product_category_name_english,
        p.product_id
) AS RankedProducts
WHERE
    Rank_With_category <= 3
ORDER BY
    ProductCategory, ProductTotalRevenue DESC;
    
--  EXPLANATION :- This query calculates each product's revenue within its category and ranks them.
--                 It then selects only the top 3 ranked products from each category.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 9) Find customers who placed multiple orders in the same month

WITH Customer_Monthly_Orders AS (
    SELECT DISTINCT
        customer_id,
        CAST(DATE_FORMAT(purchase_date, '%Y-%m-01') AS DATE) AS Order_Month -- Used to convert start of month
    FROM
        orders
    WHERE
        order_status NOT IN ('canceled', 'unavailable') -- Consider only relevant orders
),
Cons_Months AS (
    SELECT
        customer_id,
        Order_Month,
        count(*) as order_count
    FROM
        Customer_Monthly_Orders
        group by customer_id, order_month
)
SELECT *
FROM Cons_Months
WHERE order_count >= 1;
    
-- EXPANATION :- This query identifies each customer's unique purchase months. It then checks for customers
--               where an order month is exactly one and two months after their previous two order months.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 10) Determine the Average Payment Value per Payment Type, showing its deviation 
--    from the overall average payment value across all types for each year.

WITH avg_Payment_Type AS (
    SELECT
        YEAR(T1.purchase_date) AS SalesYear,
        T2.payment_type,
        round(AVG(T2.payment_value),2) AS AvgPaymentValueType
    FROM
        orders AS T1
    JOIN
        order_payments AS T2 ON T1.order_id = T2.order_id
    GROUP BY
        YEAR(T1.purchase_date),
        T2.payment_type
),

Yearly_Overall_Avg AS (
    SELECT
        YEAR(T1.purchase_date) AS SalesYear,
        round(AVG(T2.payment_value),2) AS OverallAvgPaymentValue
    FROM
        orders AS T1
    INNER JOIN
        order_payments AS T2 ON T1.order_id = T2.order_id
    GROUP BY
        YEAR(T1.purchase_date)
)
SELECT
    YPT.SalesYear,
    YPT.payment_type,
    YPT.AvgPaymentValueType,
    YOA.OverallAvgPaymentValue,
    round((YPT.AvgPaymentValueType - YOA.OverallAvgPaymentValue),2) AS diff_overall_avg
FROM
    avg_Payment_Type AS YPT
JOIN
    Yearly_Overall_Avg AS YOA ON YPT.SalesYear = YOA.SalesYear
ORDER BY
    YPT.SalesYear, YPT.payment_type;
    
-- EXPLANATION :- This query first calculates the average payment value for each payment type per year. 
--                It then compares these averages to the overall average payment value for all types in
--                that year, showing the difference.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 11)  Rank Sellers by Their Total Revenue from Delivered Orders
select* from orders;
select* from sellers;

WITH Delivered_Revenue AS (
    SELECT
        oi.seller_id,
        round(SUM(oi.price),2) AS Total_Delivered_Revenue,
        round(COUNT(DISTINCT oi.order_id),2) AS Delivered_Orders_Count
    FROM
        orders o
    JOIN
        order_items oi ON o.order_id = oi.order_id
    WHERE
        o.order_status = 'delivered'
    GROUP BY
        oi.seller_id
)
SELECT
    seller_id,
    Total_Delivered_Revenue,
    Delivered_Orders_Count,
    RANK() OVER (ORDER BY Total_Delivered_Revenue DESC) AS Seller_Rank
FROM
    Delivered_Revenue
ORDER BY
    Seller_Rank;
    
-- EXPANATION :- This query calculates the total revenue and count of delivered orders for each seller. 
--               It then ranks sellers based on their total revenue from these delivered orders.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 12) Determine regions with potential for logistics improvement based on late delivery rates.

SELECT
    RegionDeliveryStats.state AS Region,
    RegionDeliveryStats.TotalDeliveredOrders,
    RegionDeliveryStats.LateDeliveredOrders,
    CASE
        WHEN RegionDeliveryStats.TotalDeliveredOrders > 0 THEN 
        round(CAST(RegionDeliveryStats.LateDeliveredOrders AS DECIMAL(10, 2)) * 100 / RegionDeliveryStats.TotalDeliveredOrders,2)
        ELSE 0
    END AS LateDeliveryRatePercentage
FROM
    (
        SELECT
            c.state,
            COUNT(o.order_id) AS TotalDeliveredOrders,
            SUM(CASE
                    WHEN o.delivered_date > o.estimated_delivery_date THEN 1
                    ELSE 0
                END) AS LateDeliveredOrders
        FROM
            orders AS o
        JOIN
            customers c ON o.customer_id = c.customer_id
        WHERE
            o.order_status = 'delivered'
            AND o.delivered_date IS NOT NULL
            AND o.estimated_delivery_date IS NOT NULL
        GROUP BY
            c.state
    ) AS RegionDeliveryStats
ORDER BY
    LateDeliveryRatePercentage DESC;
    
-- EXPANATION :- This query first calculates the total and late delivered orders for each state in an inner query.
--               The outer query then uses these counts to compute and display the late delivery rate for each state.
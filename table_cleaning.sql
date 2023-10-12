--Data Cleaning & Transformation 

--#1 cleaned_customer_orders

SELECT 
    order_id,
    customer_id,
    pizza_id,
    CASE
        WHEN exclusions = 'null' or exclusions = '' THEN null
        ELSE exclusions
    END as exclusions,
    CASE
        WHEN extras = 'null' OR extras = '' THEN null    
        ELSE extras
    END as extras,
    order_time
INTO clean_customer_orders
FROM pizza_runner.customer_orders


--#2 cleaned_runnner_orders 
SELECT 
    order_id,
    runner_id,
    cast(CASE 
        WHEN pickup_time = '' OR pickup_time = 'null' THEN null
        ELSE pickup_time
    END as TIMESTAMP) as pickup_time,
    cast(CASE 
        WHEN distance = 'null' THEN null
        ELSE TRIM('km' from distance)
    END as float) as distance,
    cast(CASE
        WHEN duration = 'null' THEN null
        ELSE SUBSTRING(duration, 1, 2)
    END as int) as duration,
    CASE
        WHEN cancellation in ('null', '') THEN null
        ELSE cancellation
END as cancellation
INTO cleaned_runner_orders
FROM pizza_runner.runner_orders; 

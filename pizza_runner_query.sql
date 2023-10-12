--A. Pizza Metrics 

--#1 How many pizzas were ordered?
SELECT COUNT( order_id) AS total_pizzas
FROM clean_customer_orders;  

--#2 How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM clean_customer_orders; 

--#3 How many successful orders were delivered by each runner?
SELECT runner_id, COUNT (order_id) AS successful_orders 
FROM cleaned_runner_orders
WHERE cancellation IS NULL 
GROUP BY runner_id; 

--#4 How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(co.pizza_id)
FROM clean_customer_orders AS co
JOIN pizza_runner.pizza_names AS pn 
ON co.pizza_id = pn.pizza_id
JOIN cleaned_runner_orders AS ro 
ON co.order_id = ro.order_id
WHERE cancellation IS NULL 
GROUP BY 1;

--#5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(co.pizza_id)
FROM clean_customer_orders AS co
JOIN pizza_runner.pizza_names AS pn 
ON co.pizza_id = pn.pizza_id
GROUP BY 1,2
ORDER BY 1;

--#6 What was the maximum number of pizzas delivered in a single order?
SELECT co.order_id, COUNT (co.pizza_id) AS num_pizzas
FROM clean_customer_orders AS co 
JOIN cleaned_runner_orders AS ro 
ON co.order_id = ro.order_id
WHERE cancellation IS NULL 
GROUP BY co.order_id 
ORDER BY num_pizzas DESC 
LIMIT 1;  

--#7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id, COUNT(co.pizza_id) AS num_pizzas, 
	   CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 'Changes'
       ELSE 'No Change' END AS order_changes 
FROM clean_customer_orders AS co 
JOIN cleaned_runner_orders AS ro 
ON co.order_id = ro.order_id
WHERE cancellation IS NULL 
GROUP BY 1, 3
ORDER BY 1;

--#8 How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT (co.order_id) AS orders_changed
FROM clean_customer_orders AS co 
JOIN cleaned_runner_orders AS ro 
ON co.order_id = ro.order_id
WHERE cancellation IS NULL AND exclusions IS NOT NULL AND extras IS NOT NULL;

--#9 What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS time_ordered,
		COUNT(order_id) as total_number_of_pizza
FROM clean_customer_orders
GROUP BY 1
ORDER by 1

--#10 What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'Day') as day_of_week,
	COUNT(pizza_id) as total_orders
FROM clean_customer_orders 
GROUP BY 1;


--B. Runner and Customer Experience 
--#1 How many runners signed up for each 1 week period?  (i.e. week starts 2021-01-01)
SELECT  EXTRACT(WEEK FROM registration_date + 3) as week_registered, -- +3 is for iso date normalisation
		COUNT(runner_id) AS runners
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1; 

--#2  What was the average time in minutes it took 
--for each runner to arrive at the Pizza Runner HQ to pick up the order?
SELECT runner_id, 
ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60)) AS minutes_difference 
FROM clean_customer_orders cc
JOIN cleaned_runner_orders cr 
ON cc.order_id = cr.order_id  
GROUP BY 1 
ORDER BY 1; 

/*3. Is there any relationship between 
the number of pizzas and how long the order takes to prepare? */

CREATE VIEW delivered_orders AS
SELECT * FROM clean_customer_orders
JOIN cleaned_runner_orders
USING (order_id)
WHERE distance IS NOT NULL
                         
WITH orders_group AS (
   SELECT order_id, count(order_id) AS pizza_count, 
      (pickup_time - order_time) AS time_diff 
   FROM delivered_orders
   GROUP BY order_id, pickup_time, order_time
   ORDER BY order_id
 )
                         
 SELECT pizza_count, AVG(time_diff) 
 FROM orders_group
 GROUP BY pizza_count;                         
                                 
                         
CREATE VIEW delivered_orders AS
SELECT * FROM clean_customer_orders
JOIN cleaned_runner_orders
USING (order_id)
WHERE distance IS NOT NULL
WITH orders_group AS (
   SELECT order_id, count(order_id) AS pizza_count,
      (pickup_time - order_time) AS time_diff
   FROM delivered_orders
   GROUP BY order_id, pickup_time, order_time
   ORDER BY order_id
 )
 SELECT pizza_count, AVG(time_diff)
 FROM orders_group
 GROUP BY pizza_count
 ORDER BY 1;
 
 
CREATE VIEW delivered_orders AS
SELECT * FROM clean_customer_orders
JOIN cleaned_runner_orders
USING (order_id)
WHERE distance IS NOT NULL
WITH orders_group AS (
   SELECT order_id, count(order_id) AS pizza_count,
      (pickup_time - order_time) AS time_diff,
  	(pickup_time - order_time)/ COUNT(pizza_id) AS time_taken_per_pizza

   FROM delivered_orders
   GROUP BY order_id, pickup_time, order_time
   ORDER BY order_id
 )
 SELECT pizza_count, ROUND(AVG(EXTRACT(EPOCH FROM (time_diff))/60)), 
 ROUND(AVG(EXTRACT(EPOCH FROM (time_taken_per_pizza))/60))
 FROM orders_group
 GROUP BY pizza_count
 ORDER BY 1;
 
 --4. What was the average distance travelled for each customer?
 SELECT customer_id, ROUND(AVG(distance)) as avg_distance_covered
 FROM delivered_orders
 GROUP BY 1
 ORDER BY 1
 
 --5. What was the difference between the longest
   --and shortest delivery times for all orders?
  SELECT MAX(duration),MIN(duration),(MAX(duration)-MIN(duration)) AS diff_in_duration
  FROM delivered_orders
  
 /* 6. What was the 'average speed' for each runner for each delivery and do you notice any trend for these values? */
 
  SELECT runner_id,order_id,
  ROUND(CAST(distance/(duration)*60 AS NUMERIC),2) AS avg_speed
  FROM delivered_orders
  GROUP BY 1,2,3
  ORDER BY 1,2;
  
  --7. What is the 'successful delivery' percentage for 'each runner'?
 WITH cancelled_orders AS (
	  SELECT runner_id,COUNT(pickup_time) as successful
  FROM cleaned_runner_orders
	  --WHERE cancellation IS NULL
  GROUP BY runner_id),
    total_orders AS (
	SELECT runner_id,COUNT(*) as total
  FROM cleaned_runner_orders
  GROUP BY runner_id
	)
	SELECT runner_id,ROUND(successful::numeric/total*100) AS success
	FROM cancelled_orders
	JOIN total_orders
	USING(runner_id)
	GROUP BY 1,2


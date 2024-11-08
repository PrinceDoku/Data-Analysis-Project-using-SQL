DROP DATABASE IF EXISTS
CREATE DATABASE dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');





-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price) AS Total_amount_spent
FROM sales AS s
JOIN menu AS m
	ON m.product_id = s.product_id
GROUP BY customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Number_of_days_visted 
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH Tem AS 
(SELECT customer_id,product_name,
ROW_NUMBER () OVER(PARTITION BY customer_id ORDER BY order_date) AS Rm
FROM sales AS s
JOIN menu AS m
	ON m.product_id=s.product_id
)
SELECT customer_id,product_name
FROM Tem
WHERE Rm = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 product_name, COUNT(product_name) AS Most_purchased_item
FROM sales AS s
JOIN menu AS m
	ON m.product_id =s.product_id
	GROUP BY product_name
	ORDER BY COUNT(product_name) DESC;


-- 5. Which item was the most popular for each customer?
WITH Most_Popular AS(
SELECT customer_id,product_name, COUNT(*) AS Popular_sale,
RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS Rm
FROM sales as s
JOIN menu as m
	ON m.product_id= s.product_id
GROUP BY customer_id,product_name
)
SELECT customer_id,product_name
FROM Most_Popular
WHERE Rm = 1;


-- 6. Which item was purchased first by the customer after they became a member?
WITH First_item AS(
SELECT s.customer_id,m.product_name,order_date,join_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS RN
FROM sales AS s
JOIN menu AS m
	ON m.product_id =S.product_id	
JOIN members AS mb
ON mb.customer_id = s.customer_id
WHERE order_date > join_date
)
SELECT customer_id,product_name
FROM First_item
WHERE RN =1;


-- 7. Which item was purchased just before the customer became a member?
WITH First_item AS(
SELECT s.customer_id,m.product_name,order_date,join_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS RN
FROM sales AS s
JOIN menu AS m
	ON m.product_id =S.product_id	
JOIN members AS mb
ON mb.customer_id = s.customer_id
WHERE order_date < join_date
)
SELECT customer_id,product_name
FROM First_item
WHERE RN =1;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,COUNT(m.product_name) AS Total_item,SUM(price) AS Total_amount_spent
FROM sales AS s
JOIN menu AS m
	ON s.product_id=m.product_id
JOIN members AS mb
	ON s.customer_id=mb.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id;


-- 9.  If each $1 spent equals to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH Customer_points AS(
SELECT s.customer_id,m.product_name,price,
	CASE
	WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
	ELSE m.price * 10
END AS points
FROM sales AS s
JOIN menu AS m
	ON s.product_id=m.product_id
)
SELECT customer_id,SUM(points) AS Total_points
FROM Customer_points
GROUP BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer 
--A and B have at the end of January?
WITH Points_earned AS(
SELECT s.customer_id,m.product_name,m.price,order_date,join_date,
	CASE
	WHEN s.order_date BETWEEN mb.join_date AND  DATEADD(DAY,7,mb.join_date) THEN m.price * 10 * 2 
	WHEN m.product_name ='sushi' THEN m.price * 10 * 2
	ELSE m.price * 10
	END AS points
FROM menu AS m
JOIN sales AS s
	ON m.product_id = s.product_id
JOIN members AS mb
	ON s.customer_id =mb.customer_id
WHERE order_date < '2021-02-01'
)
SELECT customer_id,SUM(points) AS total_points_earned
FROM Points_earned
WHERE customer_id IN ('A','B')
GROUP BY customer_id;
	
	

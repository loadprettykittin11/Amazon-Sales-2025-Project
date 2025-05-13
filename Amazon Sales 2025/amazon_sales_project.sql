/*

	Dataset: Amazon sales 2025
	Data Source: https://www.kaggle.com/datasets/zahidmughal2343/amazon-sales-2025

*/

-- ตรวจสอบข้อมูล
SELECT *
FROM amazon_sales;

-- ตรวจสอบค่าที่หายไป
SELECT COUNT(*) AS null_count
FROM amazon_sales
WHERE order_id IS NULL OR
	date IS NULL OR
	product IS NULL OR
	category IS NULL OR
	price IS NULL OR
	quantity IS NULL OR
	total_sales IS NULL OR
	customer_name IS NULL OR
	customer_location IS NULL OR
	payment IS NULL OR
	status IS NULL;

-- เฉลี่ยลูกค้าแต่ละคนซื้อสินค้าปริมาณเท่าใด
SELECT 
	customer_name,
	COUNT(*) AS total_orders,
	ROUND(AVG(quantity), 2) AS avg_quantity
FROM amazon_sales
WHERE status = 'Completed'
GROUP BY customer_name
ORDER BY avg_quantity DESC;

-- จำนวนการสั่งซื้อสินค้าแต่ละประเภท และ รายได้ของแต่ละประเภท
SELECT 
	category,
	COUNT(*) AS total_order,
	SUM(total_sales) AS sum_total_sales,
	ROUND(AVG(total_sales), 2) AS avg_total_sales
FROM amazon_sales 
WHERE status = 'Completed'
GROUP BY category
ORDER BY sum_total_sales DESC;

-- จำนวนการชำระเงินที่มีการยกเลิกการชำระเงิน
WITH status_cancelled AS (
	SELECT 
		order_id,
		payment,
		CASE WHEN status = 'Cancelled' THEN 1
			ELSE 0 END AS cancelled_order
	FROM amazon_sales
)

SELECT payment, 
	SUM(cancelled_order) AS total_cancelled
FROM status_cancelled
GROUP BY payment
ORDER BY total_cancelled DESC

-- จำนวนประเภทการชำระเงินที่นิยมมากที่สุด

-- อาจให้โปรโมชั่นส่วนลดถ้าชำระเงินด้วยวิธี Paypal + Amazon เพราะยอดชำระสำเร็จมากและการยกเลิกก็น้อย

SELECT payment, SUM(total_completed) AS total_payment_complete
FROM (SELECT payment,
			status,
			CASE WHEN status = 'Completed' THEN 1
				ELSE 0 END AS total_completed
	 FROM amazon_sales) 
GROUP BY payment
ORDER BY total_payment_complete DESC;

-- แต่ละรัฐนิยมใช้วิธีการชำระเงินแบบไหน เป็นอัตราเท่าไหร่ของแต่ละรัฐ

WITH location_popular_payment AS (
	SELECT 
		customer_location,
		payment,
		status,
		CASE WHEN status IN ('Completed', 'Pending', 'Cancelled') THEN 1
			ELSE 0 END AS total_payment
	FROM amazon_sales
),
location_payment_group AS (
	SELECT 
		customer_location,
		payment,
		SUM(total_payment) AS total_payment
	FROM location_popular_payment
	GROUP BY customer_location, payment
	ORDER BY customer_location ASC, payment ASC
)

SELECT customer_location,
	payment,
	total_payment,
	ROUND((total_payment / SUM(total_payment) OVER(PARTITION BY customer_location)) * 100.0, 2) AS state_payment_type_rate
FROM location_payment_group 
ORDER BY customer_location ASC, payment ASC

-- ประเภทสินค้าที่มีอัตราการยกเลิกมากที่สุด
-- Electronics มียอดสั่งซื้อมากก็จริง แต่ก็มียอดยกเลิกมากเช่นกัน

WITH category_cancelled_rate AS (
SELECT 
	category, 
	COUNT(*) AS total_order_cancelled,
	(SELECT COUNT(*)
	 FROM amazon_sales) AS total_order
FROM amazon_sales 
WHERE status = 'Cancelled'
GROUP BY category
)

SELECT category,
	total_order_cancelled,
	ROUND((total_order_cancelled * 1.0 / total_order) * 100.0, 2) AS cancelled_rate
FROM category_cancelled_rate
ORDER BY cancelled_rate DESC;
-- =====================================================================
-- 06 — Predictive Modeling (BigQuery ML)
-- =====================================================================
-- Purpose: Predict whether a customer becomes high-value (top spend
--          quartile) from acquisition channel + demographics.
--
-- Key finding:
--   * Model AUC = 0.52 -> essentially no better than chance.
--   * This IS the finding: customer value is NOT predictable at
--     acquisition from who customers are or how they arrived.
--     Value is created post-acquisition, through retention.
--   * Redirects strategy away from upfront targeting toward retention.
--
-- Note: replace <PROJECT_ID> with your own project id.
-- Dataset and public data must share a location (US multi-region).
-- =====================================================================

-- Step 1: build the training table in your own dataset
CREATE OR REPLACE TABLE `<PROJECT_ID>.marketing_ml.customer_training_data` AS
WITH customer_spend AS (
  SELECT
    u.id AS user_id,
    u.traffic_source,
    u.country,
    u.age,
    u.gender,
    ROUND(SUM(oi.sale_price), 2) AS total_spend
  FROM `bigquery-public-data.thelook_ecommerce.users` AS u
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi ON u.id = oi.user_id
  JOIN `bigquery-public-data.thelook_ecommerce.orders`      AS o  ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped', 'Processing')
    AND o.created_at <= CURRENT_TIMESTAMP()
  GROUP BY u.id, u.traffic_source, u.country, u.age, u.gender
),
labeled AS (
  SELECT *, NTILE(4) OVER (ORDER BY total_spend) AS spend_quartile
  FROM customer_spend
)
SELECT
  traffic_source, country, age, gender,
  IF(spend_quartile = 4, 1, 0) AS is_high_value
FROM labeled;

-- Step 2: train a logistic regression model
CREATE OR REPLACE MODEL `<PROJECT_ID>.marketing_ml.customer_value_model`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['is_high_value'],
  auto_class_weights = TRUE
) AS
SELECT traffic_source, country, age, gender, is_high_value
FROM `<PROJECT_ID>.marketing_ml.customer_training_data`;

-- Step 3: evaluate (AUC ~ 0.52, near chance)
SELECT *
FROM ML.EVALUATE(MODEL `<PROJECT_ID>.marketing_ml.customer_value_model`);

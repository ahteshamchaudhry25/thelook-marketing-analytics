-- =====================================================================
-- 04 — RFM Customer Segmentation
-- =====================================================================
-- Purpose: Score every customer on Recency, Frequency, Monetary value and
--          group them into named, targetable segments.
--
-- Key finding:
--   * "Champions" = 26% of customers but 44% of revenue (concentration).
--   * "At Risk" + "Cant Lose Them" hold ~34% of revenue but haven't
--     purchased in 1.5-3.7 years -> major win-back opportunity.
--
-- Method: NTILE(4) splits customers into quartiles per dimension.
--   Recency sorted DESC so recent buyers score high; F and M sorted ASC.
-- =====================================================================

WITH customer_rfm AS (
  SELECT
    o.user_id,
    DATE_DIFF(CURRENT_DATE(), DATE(MAX(o.created_at)), DAY) AS recency_days,
    COUNT(DISTINCT o.order_id)                              AS frequency,
    ROUND(SUM(oi.sale_price), 2)                            AS monetary
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
    ON o.order_id = oi.order_id
  WHERE o.status IN ('Complete', 'Shipped', 'Processing')
    AND o.created_at <= CURRENT_TIMESTAMP()
  GROUP BY o.user_id
),
rfm_scored AS (
  SELECT
    *,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(4) OVER (ORDER BY frequency ASC)     AS f_score,
    NTILE(4) OVER (ORDER BY monetary ASC)      AS m_score
  FROM customer_rfm
),
rfm_segments AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 3 AND (f_score + m_score) >= 6 THEN 'Champions'
      WHEN r_score >= 3 AND (f_score + m_score) >= 4 THEN 'Loyal Customers'
      WHEN r_score >= 3                              THEN 'Recent Customers'
      WHEN r_score = 2 AND (f_score + m_score) >= 5  THEN 'At Risk'
      WHEN r_score = 1 AND (f_score + m_score) >= 5  THEN 'Cant Lose Them'
      WHEN r_score <= 2                              THEN 'Hibernating'
      ELSE 'Others'
    END AS segment
  FROM rfm_scored
)
SELECT
  segment,
  COUNT(*)                          AS customers,
  ROUND(AVG(recency_days), 0)       AS avg_recency_days,
  ROUND(AVG(frequency), 2)          AS avg_frequency,
  ROUND(AVG(monetary), 2)           AS avg_monetary,
  ROUND(SUM(monetary), 2)           AS total_revenue,
  ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;

-- =====================================================================
-- 05 — Cohort & Retention Analysis
-- =====================================================================
-- Purpose: Group customers by first-purchase month, then track repeat
--          purchasing in each subsequent month (retention decay).
--
-- Key finding:
--   * Month-1 repeat-purchase rate is only 1-2%, flat through month 6.
--   * Retention is NOT improving across cohorts.
--   * The business is effectively one-and-done; growth relies on
--     acquisition rather than repeat revenue. (Real-world ecommerce
--     month-1 retention is typically 20-30%, for benchmark context.)
-- =====================================================================

WITH first_orders AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(MIN(created_at)), MONTH) AS cohort_month
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status IN ('Complete', 'Shipped', 'Processing')
    AND created_at <= CURRENT_TIMESTAMP()
  GROUP BY user_id
),
activity AS (
  SELECT
    f.cohort_month,
    f.user_id,
    DATE_DIFF(DATE_TRUNC(DATE(o.created_at), MONTH), f.cohort_month, MONTH) AS month_offset
  FROM first_orders f
  JOIN `bigquery-public-data.thelook_ecommerce.orders` o
    ON f.user_id = o.user_id
  WHERE o.status IN ('Complete', 'Shipped', 'Processing')
    AND o.created_at <= CURRENT_TIMESTAMP()
)
SELECT
  cohort_month,
  COUNT(DISTINCT user_id) AS cohort_size,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 1, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m1_pct,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 2, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m2_pct,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 3, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m3_pct,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 4, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m4_pct,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 5, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m5_pct,
  ROUND(100.0 * COUNT(DISTINCT IF(month_offset = 6, user_id, NULL)) / COUNT(DISTINCT user_id), 1) AS m6_pct
FROM activity
WHERE cohort_month >= '2024-01-01' AND cohort_month < '2025-01-01'
GROUP BY cohort_month
ORDER BY cohort_month;

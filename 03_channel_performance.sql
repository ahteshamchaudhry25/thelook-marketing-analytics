-- =====================================================================
-- 03 — Channel Performance & Statistical Test
-- =====================================================================
-- Purpose: Compare acquisition channels on per-customer value (not just
--          volume), then test whether differences are statistically real.
--
-- Key finding:
--   * All 5 channels deliver near-identical value (~$122 revenue/customer,
--     ~$86 AOV, ~1.4 orders/customer).
--   * 95% confidence intervals overlap across every channel
--     -> differences are NOT statistically significant.
--   * Search dominates total revenue on VOLUME, not value.
--   * Implication: optimize for acquisition cost (CAC), not channel.
--     (Dataset lacks spend, so true CAC/ROAS would be added with cost data.)
-- =====================================================================

-- Per-customer value by channel
SELECT
  u.traffic_source,
  COUNT(DISTINCT oi.user_id)                                       AS customers,
  COUNT(DISTINCT oi.order_id)                                      AS orders,
  ROUND(SUM(oi.sale_price), 2)                                     AS total_revenue,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2)       AS avg_order_value,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.user_id), 2)        AS revenue_per_customer,
  ROUND(COUNT(DISTINCT oi.order_id) / COUNT(DISTINCT oi.user_id),2) AS orders_per_customer
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o ON oi.order_id = o.order_id
JOIN `bigquery-public-data.thelook_ecommerce.users`  AS u ON oi.user_id  = u.id
WHERE o.status IN ('Complete', 'Shipped', 'Processing')
  AND o.created_at <= CURRENT_TIMESTAMP()
GROUP BY u.traffic_source
ORDER BY total_revenue DESC;

-- 95% confidence interval on mean item price per channel
-- (overlapping intervals => no significant difference)
SELECT
  u.traffic_source,
  COUNT(*)                                                                     AS n_items,
  ROUND(AVG(oi.sale_price), 2)                                                 AS mean_item_price,
  ROUND(AVG(oi.sale_price) - 1.96 * STDDEV(oi.sale_price) / SQRT(COUNT(*)), 2) AS ci_low,
  ROUND(AVG(oi.sale_price) + 1.96 * STDDEV(oi.sale_price) / SQRT(COUNT(*)), 2) AS ci_high
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o ON oi.order_id = o.order_id
JOIN `bigquery-public-data.thelook_ecommerce.users`  AS u ON oi.user_id  = u.id
WHERE o.status IN ('Complete', 'Shipped', 'Processing')
  AND o.created_at <= CURRENT_TIMESTAMP()
GROUP BY u.traffic_source
ORDER BY mean_item_price DESC;

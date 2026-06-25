-- =====================================================================
-- 02 — Conversion Funnel Analysis
-- =====================================================================
-- Purpose: Measure session-level conversion through the journey and find
--          the biggest drop-off.
--
-- Key finding:
--   * Of sessions that add to cart, only ~42% purchase
--     -> 58% cart abandonment is the single biggest funnel leak.
--   * Overall session-to-purchase rate ~26.5% (high because synthetic data;
--     real-world ecommerce is typically 2-3%).
--
-- Method note: counts are per SESSION (not raw events). A first naive
-- attempt counting distinct users per event_type produced an invalid
-- "widening" funnel; the session-flag approach below is the correct fix.
-- =====================================================================

WITH session_stages AS (
  SELECT
    session_id,
    MAX(IF(event_type = 'product',  1, 0)) AS hit_product,
    MAX(IF(event_type = 'cart',     1, 0)) AS hit_cart,
    MAX(IF(event_type = 'purchase', 1, 0)) AS hit_purchase
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
)
SELECT
  COUNT(*)                                       AS all_sessions,
  SUM(hit_product)                               AS viewed_product,
  SUM(hit_cart)                                  AS added_to_cart,
  SUM(hit_purchase)                              AS purchased,
  ROUND(100.0 * SUM(hit_purchase) / COUNT(*), 2) AS overall_conversion_pct,
  ROUND(100.0 * SUM(hit_cart)     / SUM(hit_product), 1) AS view_to_cart_pct,
  ROUND(100.0 * SUM(hit_purchase) / SUM(hit_cart),    1) AS cart_to_purchase_pct
FROM session_stages;

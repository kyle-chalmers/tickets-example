-- DEMO-14 — Top full-length video by net subscribers gained & by views gained
--            over rolling 1-month (30d) and 3-month (90d) windows.
-- Source: BigQuery only — primeval-node-478707-e9.youtube_analytics.
-- Output grain: 1 row per (window, measure); the single winning video. ≤ 4 rows.
-- Single-statement (anchor via `params` CTE) so `bq --format=csv` exports cleanly.
-- Anchor = latest snapshot_date (all three partitioned tables share the same max).
WITH
params AS (
  SELECT MAX(snapshot_date) AS anchor
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
),
-- Full-length universe (classification + title) from video_metadata's OWN latest snapshot,
-- decoupled from the stats anchor so a metadata lag can't silently empty the result.
full_length AS (
  SELECT m.video_id, m.title
  FROM `primeval-node-478707-e9.youtube_analytics.video_metadata` m
  WHERE m.snapshot_date = (
          SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`)
    AND m.video_type = 'full_length'
),
windows AS (
  SELECT '1mo (30d)' AS window_label, 30 AS days
  UNION ALL SELECT '3mo (90d)', 90
),
-- Measure 1: net subscribers gained = SUM(gained - lost) of daily flows in window.
subs AS (
  SELECT w.window_label, a.video_id,
         SUM(a.subscribers_gained - a.subscribers_lost) AS metric_value
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics` a
  JOIN full_length f USING (video_id)
  CROSS JOIN windows w
  CROSS JOIN params p
  WHERE a.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL w.days - 1 DAY) AND p.anchor
  GROUP BY w.window_label, a.video_id
),
-- Measure 2: views gained = last - first cumulative view_count within window.
views AS (
  SELECT w.window_label, s.video_id,
         ARRAY_AGG(s.view_count ORDER BY s.snapshot_date DESC LIMIT 1)[OFFSET(0)]
       - ARRAY_AGG(s.view_count ORDER BY s.snapshot_date ASC  LIMIT 1)[OFFSET(0)] AS metric_value
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s
  JOIN full_length f USING (video_id)
  CROSS JOIN windows w
  CROSS JOIN params p
  WHERE s.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL w.days - 1 DAY) AND p.anchor
  GROUP BY w.window_label, s.video_id
),
ranked AS (
  SELECT window_label, 'net_subscribers_gained' AS measure, video_id, metric_value,
         ROW_NUMBER() OVER (PARTITION BY window_label ORDER BY metric_value DESC, video_id) AS rn
  FROM subs
  UNION ALL
  SELECT window_label, 'views_gained', video_id, metric_value,
         ROW_NUMBER() OVER (PARTITION BY window_label ORDER BY metric_value DESC, video_id) AS rn
  FROM views
)
SELECT r.window_label, r.measure, r.video_id, f.title, r.metric_value
FROM ranked r JOIN full_length f USING (video_id)
WHERE r.rn = 1
ORDER BY r.window_label, r.measure;

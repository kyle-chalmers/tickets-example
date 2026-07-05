-- QC2: anchor equality across the 3 tables, full-length universe size, per-window/source
-- coverage of full-length videos, and a negative-views sanity count.
-- Single-statement (anchor via `params` CTE, no DECLARE) so it runs in DataGrip / JDBC,
-- the BigQuery console, and the bq CLI identically.
WITH params AS (
  SELECT MAX(snapshot_date) AS anchor
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
),
fl AS (  -- full-length universe from the latest metadata snapshot
  SELECT m.video_id
  FROM `primeval-node-478707-e9.youtube_analytics.video_metadata` m
  CROSS JOIN params p
  WHERE m.snapshot_date = p.anchor AND m.video_type = 'full_length'
),
views_win AS (  -- per-video views_gained for the negative check (90d superset)
  SELECT s.video_id,
         ARRAY_AGG(s.view_count ORDER BY s.snapshot_date DESC LIMIT 1)[OFFSET(0)]
       - ARRAY_AGG(s.view_count ORDER BY s.snapshot_date ASC  LIMIT 1)[OFFSET(0)] AS vg
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s
  JOIN fl USING (video_id)
  CROSS JOIN params p
  WHERE s.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor
  GROUP BY s.video_id
)
SELECT
  p.anchor,
  (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`) AS max_analytics,
  (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`)        AS max_metadata,
  (SELECT COUNT(*) FROM fl) AS full_length_universe,
  (SELECT COUNT(DISTINCT a.video_id)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics` a JOIN fl USING (video_id)
     WHERE a.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 29 DAY) AND p.anchor) AS fl_in_analytics_30d,
  (SELECT COUNT(DISTINCT s.video_id)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s JOIN fl USING (video_id)
     WHERE s.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 29 DAY) AND p.anchor) AS fl_in_stats_30d,
  (SELECT COUNT(*) FROM views_win WHERE vg < 0) AS negative_views_gained_videos
FROM params p;

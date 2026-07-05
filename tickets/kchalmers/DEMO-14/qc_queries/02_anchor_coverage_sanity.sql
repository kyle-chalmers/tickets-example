-- QC2: anchor equality across the 3 tables, full-length universe size, per-window/source
-- coverage of full-length videos, and a negative-views sanity count.
DECLARE anchor DATE DEFAULT (
  SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`);

WITH fl AS (
  SELECT video_id FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`
  WHERE snapshot_date = anchor AND video_type = 'full_length'
),
views_win AS (  -- per-video views_gained for negative check (90d superset)
  SELECT s.video_id,
         ARRAY_AGG(s.view_count ORDER BY s.snapshot_date DESC LIMIT 1)[OFFSET(0)]
       - ARRAY_AGG(s.view_count ORDER BY s.snapshot_date ASC  LIMIT 1)[OFFSET(0)] AS vg
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s
  JOIN fl USING (video_id)
  WHERE s.snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor
  GROUP BY s.video_id
)
SELECT
  anchor,
  (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`) AS max_analytics,
  (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`)        AS max_metadata,
  (SELECT COUNT(*) FROM fl) AS full_length_universe,
  (SELECT COUNT(DISTINCT a.video_id)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics` a JOIN fl USING (video_id)
     WHERE a.snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor) AS fl_in_analytics_30d,
  (SELECT COUNT(DISTINCT s.video_id)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s JOIN fl USING (video_id)
     WHERE s.snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor) AS fl_in_stats_30d,
  (SELECT COUNT(*) FROM views_win WHERE vg < 0) AS negative_views_gained_videos;

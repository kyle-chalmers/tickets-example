-- QC1 (primary): duplicate detection on the grain key (video_id, snapshot_date)
-- across the full 90-day window for the two fact tables, and (video_id) on the latest
-- metadata snapshot. Expect dup_keys = 0 everywhere.
-- Single-statement (anchor via `params` CTE, no DECLARE) so it runs in DataGrip / JDBC,
-- the BigQuery console, and the bq CLI identically.
WITH params AS (
  SELECT MAX(snapshot_date) AS anchor
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
)
SELECT 'daily_video_analytics' AS tbl, COUNT(*) AS dup_keys FROM (
  SELECT a.video_id, a.snapshot_date
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics` a
  CROSS JOIN params p
  WHERE a.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor
  GROUP BY a.video_id, a.snapshot_date HAVING COUNT(*) > 1)
UNION ALL
SELECT 'daily_video_stats', COUNT(*) FROM (
  SELECT s.video_id, s.snapshot_date
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s
  CROSS JOIN params p
  WHERE s.snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor
  GROUP BY s.video_id, s.snapshot_date HAVING COUNT(*) > 1)
UNION ALL
SELECT 'video_metadata_latest', COUNT(*) FROM (
  SELECT m.video_id
  FROM `primeval-node-478707-e9.youtube_analytics.video_metadata` m
  CROSS JOIN params p
  WHERE m.snapshot_date = p.anchor GROUP BY m.video_id HAVING COUNT(*) > 1)
ORDER BY tbl;

-- QC1 (primary): duplicate detection on the grain key (video_id, snapshot_date)
-- across the full 90-day window for the two fact tables, and (video_id) on the latest
-- metadata snapshot. Expect dup_keys = 0 everywhere.
DECLARE anchor DATE DEFAULT (
  SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`);

SELECT 'daily_video_analytics' AS tbl, COUNT(*) AS dup_keys FROM (
  SELECT video_id, snapshot_date
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`
  WHERE snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor
  GROUP BY video_id, snapshot_date HAVING COUNT(*) > 1)
UNION ALL
SELECT 'daily_video_stats', COUNT(*) FROM (
  SELECT video_id, snapshot_date
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
  WHERE snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor
  GROUP BY video_id, snapshot_date HAVING COUNT(*) > 1)
UNION ALL
SELECT 'video_metadata_latest', COUNT(*) FROM (
  SELECT video_id
  FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`
  WHERE snapshot_date = anchor GROUP BY video_id HAVING COUNT(*) > 1)
ORDER BY tbl;

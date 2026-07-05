-- QC4 (independent re-derivation): recompute each of the 4 winners' metric by a SECOND
-- method (scalar subqueries with explicit MIN/MAX snapshot_date, not ARRAY_AGG/ROW_NUMBER).
-- recomputed must equal expected for every row.
-- Single-statement (anchor via `params` CTE, no DECLARE) so it runs in DataGrip / JDBC,
-- the BigQuery console, and the bq CLI identically.
WITH params AS (
  SELECT MAX(snapshot_date) AS anchor
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
)
SELECT '1mo net_subscribers_gained' AS cell, '2hiELj4Yavw' AS video_id,
  (SELECT SUM(subscribers_gained - subscribers_lost)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`
     WHERE video_id = '2hiELj4Yavw'
       AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 29 DAY) AND p.anchor) AS recomputed,
  17 AS expected
FROM params p
UNION ALL
SELECT '3mo net_subscribers_gained', 'WRvgMzYaIVo',
  (SELECT SUM(subscribers_gained - subscribers_lost)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor), 45
FROM params p
UNION ALL
SELECT '1mo views_gained', 'WRvgMzYaIVo',
  (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 29 DAY) AND p.anchor))
  - (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MIN(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 29 DAY) AND p.anchor)),
  1182
FROM params p
UNION ALL
SELECT '3mo views_gained', 'WRvgMzYaIVo',
  (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor))
  - (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MIN(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(p.anchor, INTERVAL 89 DAY) AND p.anchor)),
  6158
FROM params p
ORDER BY cell;

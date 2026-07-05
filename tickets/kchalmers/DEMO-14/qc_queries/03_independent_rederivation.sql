-- QC4 (independent re-derivation): recompute each of the 4 winners' metric by a SECOND
-- method (scalar subqueries with explicit MIN/MAX snapshot_date, not ARRAY_AGG/ROW_NUMBER).
-- recomputed must equal expected for every row.
DECLARE anchor DATE DEFAULT (
  SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`);

-- helper macros inlined per row
SELECT '1mo net_subscribers_gained' AS cell, '2hiELj4Yavw' AS video_id,
  (SELECT SUM(subscribers_gained - subscribers_lost)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`
     WHERE video_id = '2hiELj4Yavw'
       AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor) AS recomputed,
  17 AS expected
UNION ALL
SELECT '3mo net_subscribers_gained', 'WRvgMzYaIVo',
  (SELECT SUM(subscribers_gained - subscribers_lost)
     FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor), 45
UNION ALL
SELECT '1mo views_gained', 'WRvgMzYaIVo',
  (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor))
  - (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MIN(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor)),
  1182
UNION ALL
SELECT '3mo views_gained', 'WRvgMzYaIVo',
  (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor))
  - (SELECT view_count FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
     WHERE video_id = 'WRvgMzYaIVo'
       AND snapshot_date = (SELECT MIN(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`
                            WHERE video_id='WRvgMzYaIVo' AND snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor)),
  6158
ORDER BY cell;

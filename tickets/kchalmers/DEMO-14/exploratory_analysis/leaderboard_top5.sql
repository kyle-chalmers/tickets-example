-- Context / QC3: top-5 leaderboard per (window, measure). Confirms each deliverable winner
-- is genuinely the max (rank 1) and shows the runners-up + margin.
DECLARE anchor DATE DEFAULT (
  SELECT MAX(snapshot_date) FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats`);

WITH
full_length AS (
  SELECT video_id, title FROM `primeval-node-478707-e9.youtube_analytics.video_metadata`
  WHERE snapshot_date = anchor AND video_type = 'full_length'),
windows AS (SELECT '1mo (30d)' AS window_label, 30 AS days UNION ALL SELECT '3mo (90d)', 90),
subs AS (
  SELECT w.window_label, 'net_subscribers_gained' AS measure, a.video_id,
         SUM(a.subscribers_gained - a.subscribers_lost) AS metric_value
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_analytics` a
  JOIN full_length f USING (video_id) CROSS JOIN windows w
  WHERE a.snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL w.days - 1 DAY) AND anchor
  GROUP BY w.window_label, a.video_id),
views AS (
  SELECT w.window_label, 'views_gained' AS measure, s.video_id,
         ARRAY_AGG(s.view_count ORDER BY s.snapshot_date DESC LIMIT 1)[OFFSET(0)]
       - ARRAY_AGG(s.view_count ORDER BY s.snapshot_date ASC  LIMIT 1)[OFFSET(0)] AS metric_value
  FROM `primeval-node-478707-e9.youtube_analytics.daily_video_stats` s
  JOIN full_length f USING (video_id) CROSS JOIN windows w
  WHERE s.snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL w.days - 1 DAY) AND anchor
  GROUP BY w.window_label, s.video_id),
allm AS (SELECT * FROM subs UNION ALL SELECT * FROM views),
ranked AS (
  SELECT window_label, measure, video_id, metric_value,
         ROW_NUMBER() OVER (PARTITION BY window_label, measure ORDER BY metric_value DESC, video_id) AS rnk
  FROM allm)
SELECT r.window_label, r.measure, r.rnk, r.video_id, SUBSTR(f.title,0,50) AS title, r.metric_value
FROM ranked r JOIN full_length f USING (video_id)
WHERE r.rnk <= 5
ORDER BY r.window_label, r.measure, r.rnk;

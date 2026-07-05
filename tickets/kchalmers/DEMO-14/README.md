# DEMO-14: Question: Top full-length video by net subscribers gained and by views gained (rolling 1mo & 3mo)

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DEMO-14
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** None
- **Assignee:** Unassigned (folder owner: kchalmers)

## Business Context
For the YouTube channel, identify which **full-length** video was most popular over each rolling
window, on each of two measures — reporting up to four videos (one per measure per window) with the
underlying numbers.

**Measures**
- **Net subscribers gained** — `SUM(subscribers_gained - subscribers_lost)` over the window, from
  `daily_video_analytics`.
- **Views gained** — cumulative delta: last minus first `view_count` in the window, from
  `daily_video_stats`. Do **not** use traffic-sources daily views.

**Windows** (rolling, anchored to the latest `snapshot_date`)
- Past 1 month — rolling 30 days
- Past 3 months — rolling 90 days

**Scope:** full-length only — `video_metadata.video_type = 'full_length'`; exclude Shorts.
**Source:** BigQuery only (`primeval-node-478707-e9.youtube_analytics`). No vidIQ, YouTube Studio,
YouTube Analytics API, or any other source.
**Caveat:** YouTube analytics lag ~2–3 days, so the most recent days in each window are partial.

## Answer
Anchor = latest `snapshot_date` **2026-07-04**. Full-length universe = 28 videos.

| Window | Measure | Winner (video_id) | Title | Value |
|---|---|---|---|---|
| Past 1 month (30d) | Net subscribers gained | `2hiELj4Yavw` | Why Gartner Says This Layer Is Critical for AI! | **+17** |
| Past 1 month (30d) | Views gained | `WRvgMzYaIVo` | Claude Code vs Manual Jira Ticket Work | **1,182** |
| Past 3 months (90d) | Net subscribers gained | `WRvgMzYaIVo` | Claude Code vs Manual Jira Ticket Work | **+45** |
| Past 3 months (90d) | Views gained | `WRvgMzYaIVo` | Claude Code vs Manual Jira Ticket Work | **6,158** |

"Claude Code vs Manual Jira Ticket Work" wins three of the four cells. Runner-up margins (see
`exploratory_analysis/leaderboard_top5.sql`): the two **subscriber** races are tight — 1mo 17 vs 16
(`bn9wnNjG-gc`), 3mo 45 vs 43 — so the partial last ~2–3 days could still nudge those; both **views**
races are decisive. Numbers reflect data as of 2026-07-04 (recent days partial).

## Investigation Scope
*Objects in play (all in `primeval-node-478707-e9.youtube_analytics`, partitioned by `snapshot_date` DAY):*

| Object | Role | Key columns |
|---|---|---|
| `video_metadata` | full-length filter + titles | `video_id`, `video_type`, `title`, `snapshot_date` |
| `daily_video_analytics` | net subscribers | `video_id`, `snapshot_date`, `subscribers_gained`, `subscribers_lost` |
| `daily_video_stats` | views gained | `video_id`, `snapshot_date`, `view_count` (cumulative) |

- **Join key:** `(video_id, snapshot_date)` — both `STRING`/`DATE`, no cast needed. Grain verified 1
  row per `(video_id, snapshot_date)` (0 duplicate keys on the latest partition in all three tables).
- **Latest `snapshot_date` = 2026-07-04** (today) in all three tables → the rolling-window anchor.
- **Coverage:** `daily_video_stats` and `video_metadata` start 2026-02-17; `daily_video_analytics`
  starts 2025-10-16. Both the 30-day and 90-day windows (back to ~2026-04-05) sit fully inside all
  three tables, so no coverage gap for this question.
- **`video_type` literal confirmed:** exactly `full_length` (28 full-length videos) vs `short`.
- **Metric mechanics differ:** subscriber columns are daily *flows* (SUM them); `view_count` is a
  cumulative *stock* (last − first). The ticket's definitions already encode this correctly.

**Prior art (recall):** none — `tickets/INDEX.md` lists 0 tickets; this is the first ticket in the
repo. Nothing to reuse.

**Domain pack:** `documentation/` has no knowledge pack yet (only the AI-layer index). `/refresh
context` would build one; not a blocker here since the ticket carries its own definitions.

## Assumptions Made
*Decided in the spec ([specs/DEMO-14-top-full-length-video.md](../../../specs/DEMO-14-top-full-length-video.md)) under a delegated "complete the chain"; documented per policy `reduce_assumptions`.*

1. **Scope/Time Window**: Window anchor is the single global latest `snapshot_date` (2026-07-04);
   "rolling 30/90 days" = `snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL N-1 DAY) AND anchor`
   (inclusive, N calendar days).
   - **Reasoning**: Ticket says "rolling … from the latest `snapshot_date`."
   - **Open**: inclusive-N vs half-open interval; global anchor vs per-table max snapshot.
2. **Data Interpretation (views gained)**: "first" and "last" `view_count` = the earliest and latest
   in-window snapshots *for that video* (a video newer than the window start is measured from its
   first in-window snapshot).
   - **Open**: whether to seed "first" from the snapshot at/just-before the window start instead.
3. **Source Selection (full-length)**: `video_type = 'full_length'` taken from the latest
   `video_metadata` snapshot per video.
4. **Data Quality**: recent 2–3 days are partial (analytics lag); results reported as-is with that
   caveat, not trimmed to the last "complete" day.
5. **Output Format**: up to four winner rows (measure × window), each with video title, `video_id`,
   and the underlying metric value; a video may win more than one cell.

## Deliverables
*Numbered in review order; filenames carry record counts.*
1. [`final_deliverables/01_top_full_length_video.sql`](final_deliverables/01_top_full_length_video.sql)
   — the answer query (single-statement, parameterized anchor, explicit `ORDER BY`).
2. [`final_deliverables/01_top_full_length_video_4rows.csv`](final_deliverables/01_top_full_length_video_4rows.csv)
   — the 4 winners (one per window × measure) with underlying numbers.
- Supporting: [`qc_queries/`](qc_queries/) (3 gate scripts) ·
  [`exploratory_analysis/leaderboard_top5.sql`](exploratory_analysis/leaderboard_top5.sql) (top-5 context).

## Quality Control
Validation pyramid — all gates **PASS** (self-check during build; independent `/review` pass next):

| # | Gate | Result |
|---|---|---|
| ① | Dialect lint / dry-run | ✓ valid; 0.12 MB scanned |
| ② | **Duplicate detection** on `(video_id, snapshot_date)` (90d, all 3 tables) | ✓ 0 dup keys |
| ③ | Reconciliation — anchor equal across 3 tables; universe = 28; coverage 27/28 (subs 30d), 28/28 (views 30d) | ✓ (the 1 analytics-absent video is `2nBUItHz96c`, a recent upload with no flow rows yet → not rankable on subs, expected) |
| ④ | Independent re-derivation of all 4 winners (scalar min/max method) | ✓ 17 / 1182 / 45 / 6158 match exactly |
| ⑤ | Anti-pattern sweep — no `SELECT *`, explicit `ORDER BY`, params at top, views deltas ≥ 0 (0 negatives) | ✓ |

Winners confirmed rank-1 via the top-5 leaderboard. **Caveat carried to the answer:** the two
subscriber races are within 1–2 subs of the runner-up and the last ~2–3 days are partial.

**Data-quality note:** `view_count` is non-monotonic for 8 video-windows (small YouTube revisions),
so views gained uses date-ordered **last − first** (`ARRAY_AGG … ORDER BY snapshot_date`), not
`MAX − MIN`; none of the 4 winners are affected. Independent `/review` verdict:
[`qc_queries/04_review_verdict.md`](qc_queries/04_review_verdict.md) — **APPROVE**.

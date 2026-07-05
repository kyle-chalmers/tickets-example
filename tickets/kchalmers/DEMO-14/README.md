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
*Proposed — to be confirmed/refined in `/spec-and-build` before building (policy `reduce_assumptions`).*

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
*Numbered in review order; filenames carry record counts. — pending `/spec-and-build`.*

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns). — pending.*

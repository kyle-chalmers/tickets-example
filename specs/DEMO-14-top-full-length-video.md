# Spec — DEMO-14: Top full-length video by net subscribers gained & by views gained (rolling 1mo & 3mo)

> The committed blueprint `/spec-and-build build` executes. Front-loads decisions before code.
> **Confidence (1–10): 8** — ticket definitions are precise; data verified in priming; one
> documented interpretation on the views window edge (below).

## Operation
- **Type:** new (analysis / question — no persisted object) · **Scope:** multiple objects (read-only)
- **Target layer / dev env:** none — pure `SELECT`; deliverable is a CSV answer. No DDL/DML, so the
  `db_write_requires_approval` gate does not apply.

## Data grain
- Source grain (all three tables): **1 row per `(video_id, snapshot_date)`** — verified, 0 duplicate
  keys on the latest partition in all three tables.
- Output grain: **1 row per `(window, measure)`** — the single winning video, so ≤ 4 rows
  (2 windows × 2 measures; a video may win more than one cell).

## Sources & joins
| Source object | Key(s) | Cast/filter rules | Notes |
|---|---|---|---|
| `video_metadata` | `video_id` (+ `snapshot_date`) | `video_type = 'full_length'`; classify + title from the **latest** snapshot (2026-07-04) | 28 full-length videos; literal `'full_length'` confirmed |
| `daily_video_analytics` | `(video_id, snapshot_date)` | `snapshot_date` in window | daily **flow** cols `subscribers_gained`, `subscribers_lost` → SUM |
| `daily_video_stats` | `(video_id, snapshot_date)` | `snapshot_date` in window | `view_count` is cumulative **stock** → last − first |

- Join key `(video_id, snapshot_date)` is `STRING`/`DATE` on both sides — **no cast needed**.
- Anchor = **latest `snapshot_date` = 2026-07-04** (equal across all three tables).

## Transformation logic
**Windows** (rolling, inclusive N calendar days ending at the anchor):
- 1 month (30d): `snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 29 DAY) AND anchor` → `[2026-06-05, 2026-07-04]`.
- 3 months (90d): `snapshot_date BETWEEN DATE_SUB(anchor, INTERVAL 89 DAY) AND anchor` → `[2026-04-06, 2026-07-04]`.

**Full-length universe:** `video_id`s (with title) where `video_type = 'full_length'` in the
2026-07-04 `video_metadata` snapshot.

**Measure 1 — Net subscribers gained** (per video, per window):
`SUM(subscribers_gained - subscribers_lost)` over `daily_video_analytics` rows in window, restricted
to full-length videos. Winner = MAX (may be negative if the channel net-lost subs on that video).

**Measure 2 — Views gained** (per video, per window):
`last_view_count − first_view_count`, where `last`/`first` are the `view_count` at the **latest** and
**earliest** `snapshot_date` within the window for that video (via `ARRAY_AGG(... ORDER BY
snapshot_date)` — robust to any non-monotonic revision, unlike `MAX−MIN`). Winner = MAX.

**Winner selection:** per `(window, measure)`, `ORDER BY metric DESC, video_id ASC LIMIT 1`
(deterministic tiebreak). Emit `window, measure, video_id, title, metric_value`.

## Validation gates (the QC the build MUST pass)
1. **Duplicate detection** on `(video_id, snapshot_date)` across the full 90-day window for all three
   tables → expect 0 (primary test).
2. **Record-count reconciliation:** count of full-length videos in the universe (expect 28); count of
   those with ≥1 row in analytics / stats within each window; report any full-length video absent
   from a source in a window (it simply can't win there).
3. **Cross-source join-match:** every winning `video_id` resolves to a title in the 2026-07-04
   metadata snapshot (100%).
4. **Independent re-derivation:** recompute each of the 4 winners' metric by a second method
   (explicit min/max `snapshot_date` self-join for views; direct SUM filter for subs) and confirm the
   number matches the main query bit-for-bit.
5. **Sanity/anti-pattern sweep:** views deltas ≥ 0 (flag + explain any negative); no `SELECT *` on
   wide tables; explicit `ORDER BY` on the export; window bounds parameterized at top.

## Downstream impact
None — read-only analytical answer; no object is created or altered, nothing consumes an output
table. Deliverable is a CSV + the answer written to the ticket README and (gated) a Jira comment.

## Open questions (resolved as documented defaults — delegated "complete the chain")
- **Views window edge:** using the ticket-literal "last − first `view_count` **in the window**"
  → the delta spans the video's in-window snapshots (≈ N−1 day-boundaries for a video present all
  window; a video first seen mid-window is measured from its first in-window snapshot). Not seeding
  the baseline from the pre-window snapshot. *Documented, not silently chosen.*
- **Partial recent days:** anchor stays at the true latest `snapshot_date` (2026-07-04) per the
  ticket; the ~2–3 day analytics lag makes the last days partial → noted as a caveat on the answer,
  not trimmed.

## Closest prior analogs
- None — DEMO-14 is the first ticket in the repo (`tickets/INDEX.md` = 0 tickets). No SQL/QC to reuse.

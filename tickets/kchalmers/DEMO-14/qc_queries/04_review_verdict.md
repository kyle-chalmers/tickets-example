# QC Review Verdict — DEMO-14

**Verdict: APPROVE** (independent second-context `qc-reviewer` pass; merge call is the human's).

**Summary:** All four winners and their exact values reproduce independently; the deliverable query
re-runs **byte-identical** to the committed CSV; grain is clean (0 dups); anchor and universe check
out; the tight subscriber margins are real and stable under alternative window readings. No Critical
or Should-fix findings.

**Pyramid:** ① dialect lint ok · ② counts & dedup ok · ③ reconcile ok · ④ re-run diff identical ·
⑤ output & docs ok.

## Reproduced independently
- Anchor = **2026-07-04**, identical MAX across all three tables. Full-length universe = **28**
  (118 short, 0 other).
- Grain: 0 duplicate `(video_id, snapshot_date)` keys in both fact tables over 90d; 0 duplicate
  `video_id` in the latest metadata.
- Winners re-derived with a *different* formulation (`FIRST_VALUE`/`RANK` window funcs for views vs
  the deliverable's `ARRAY_AGG`; filtered `SUM` for subs): 1mo subs `2hiELj4Yavw` 17 (vs 16
  `bn9wnNjG-gc`); 1mo views `WRvgMzYaIVo` 1182 (vs 996); 3mo subs `WRvgMzYaIVo` 45 (vs 43); 3mo views
  `WRvgMzYaIVo` 6158 (vs 3303). All rank-1 confirmed.
- Coverage: 27/28 full-length in analytics (30d & 90d), 28/28 in stats (30d). The one analytics-absent
  video is **`2nBUItHz96c`** (recent upload, no subscriber-flow rows yet) — correctly unrankable on subs.
- Re-ran the deliverable SQL end-to-end; `diff` vs committed CSV = **IDENTICAL**.

## Edge sweep
- **Window boundary** sensitivity on the tight 1mo subs race: winner `2hiELj4Yavw` holds under
  inclusive-30 (17 vs 16), inclusive-31 (18 vs 16), and half-open (17 vs 16). Margin is real, not a
  boundary artifact.
- **Views last−first vs max−min:** differ for 8 video-windows (non-monotonic `view_count`) — this
  *validates* the spec's `ARRAY_AGG` last−first choice over `MAX−MIN`. None of the 4 winners affected.
- **Negatives:** 0 negative view deltas; net-subs may be negative by design, `MAX` still picks top.

## Findings (both [Review]-tier, non-blocking)
1. **Anchor coupling** — `01_top_full_length_video.sql`: `params` anchor came from `daily_video_stats`
   only and was reused to filter `video_metadata`; harmless now (all three share MAX) but a latent
   silent-empty risk if metadata lagged. **→ Addressed:** `full_length` now classifies from
   `video_metadata`'s own latest snapshot (behavior-preserving; CSV re-verified byte-identical).
2. **Data-quality note** — non-monotonic `view_count` on 8 video-windows; already handled by the
   last−first method. **→ Addressed:** noted in the README QC section.

No hard-halt conditions met (no count mismatch, no dup gap, no reconciliation break, clean re-run diff).

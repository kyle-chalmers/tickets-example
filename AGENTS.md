# AI Agent Instructions — tickets-example

> Rendered from the Ticketwright starter kit by `/ticketwright:setup`. Tool specifics live in
> `.claude/config/stack.yaml` + `adapters/`; this file is the always-loaded **global rules** tier.

## Role
Ticket-driven data work — analysis-first, quality-first. **KISS / YAGNI.** One folder per ticket
under `tickets/{assignee}/{id}`.

**You are a senior engineer** doing ticket-driven work, analysis-first and quality-first.
- Emphasize: clear assumptions written down, reproducible steps, a tidy ticket folder.
- QC focus: correctness, input-vs-output record-count reconciliation, no silently-swallowed failures.

## How work flows (plan → build → check → ship)
`/ticket <id>` (opens the ticket + auto-loads its context and prior art) → `/spec-and-build`
(blueprint, then build) → `/review` (independent check) → `/ship` (gated delivery). Recurring work
→ `/productize`. Knowledge maintenance → `/refresh` (ticket catalog + domain pack).

## The stack (this repo)
| Seam | Tool | Adapter |
|---|---|---|
| Tracker | jira | `adapters/tracker/jira.md` |
| Warehouse | bigquery | `adapters/warehouse/bigquery.md` |
| Chat | — (deferred) | add with `/ticketwright:setup chat` |
| Docstore | — (deferred) | add with `/ticketwright:setup docstore` |
| VCS | github | `adapters/vcs/github.md` |

Ticket-id prefix `DEMO`; done state `Done`. Skills target abstract verbs and resolve them through
the adapter for the configured tool — **never hardcode a tool, CLI, or ID in a skill**; put it in
the config/adapter.

## Permission hierarchy
**No permission needed (internal):** read queries / data exploration; reading/searching/writing files
in the repo; local analysis + output.
**Explicit permission required (external/destructive):** any DB write (UPDATE/ALTER/DROP/DELETE/
INSERT/CREATE OR REPLACE/TRUNCATE/DDL); commits/pushes/PRs; tracker comments; chat messages; docstore
backups. **DB-write protocol:** show the exact SQL → explain the change → wait for `yes` → run. This
is enforced mechanically by the `db_write_guard` PreToolUse hook (wired by the plugin) — it asks
before any destructive warehouse statement, including SQL hidden in a `-f` file — so the rule holds
even if the agent forgets it.

## The 9 policies (inherited by every skill, from stack.yaml)
1. **hard_halt_before_external_posts** — pause for human go before any tracker/chat/docstore write.
2. **db_write_requires_approval** — show SQL, explain, wait.
3. **chat_default_draft** — draft, don't send, unless told "send it".
4. **hyperlink_everything** — every ticket id / file / PR is a smart link.
5. **commandify_everything** — recurring work becomes a `/productize` skill.
6. **reduce_assumptions** — ask before building; still document every assumption in the ticket README.
7. **commit_plan_before_implement** — `/spec-and-build` commits the spec before building (blame-free retry).
8. **system_evolution** — a failure fixes the AI layer (rule/context/command/adapter), not just the ticket.
9. **deterministic_outputs** — explicit `ORDER BY` on exports; productized skills ship golden-replay diffs.

## Ticket folder
```
tickets/{assignee}/{id}/
├── README.md            # business context + ALL assumptions + QC results
├── source_materials/    # attachments / inputs
├── final_deliverables/  # numbered in review order; filenames carry record counts
├── qc_queries/          # numbered QC + the /review verdict
└── exploratory_analysis/
```

## Communication (limits)
Tracker comment <100 words · chat <100 · PR <200 · new ticket <200. Tracker comments: business-first,
segmented with counts/%/$, link the specific docstore file. Chat: hyperlink everything; default to
draft; add your stakeholders (configure names when you add the chat seam).

## Quality control (the validation pyramid)
Every deliverable: ① dialect lint → ② counts & dedup (duplicate detection is the primary test) →
③ cross-source reconciliation → ④ independent re-run + anti-pattern sweep → ⑤ human sign-off.
Run `/review` before `/ship`.

## Git
Branch = ticket id off `main`. Semantic commits/PRs (`feat|fix|docs|refactor|chore|test|ci`).
Stage only files you changed. Co-Authored-By trailer on commits.

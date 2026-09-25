---
name: looker-to-bi-app-migration
description: "Migrates one Looker dashboard to the Holidu BI App: usage and duplicate check, bi_gold source mapping, rebuild, validation against filtered Looker output, in-dashboard Migration Notes. Use when a user shares a Looker dashboard URL and asks to migrate, move or port it to the BI App. Not for building new BI App dashboards."
---

# Looker to BI App dashboard migration

Looker is being sunset (contract ends June 2027; no new Looker builds or fixes). This skill moves ONE Looker dashboard to the BI App by rebuilding its functionality (views, filters, visualisations) on governed gold-layer sources. It does NOT port Looker SQL as-is.

> **Status: under test.** Owner: Thomas Freundt (BI). Report issues or feedback on Slack to @thomas.freundt.

## Ground rules

- Talk to the user concisely and without technical jargon. The only exception is the Migration Notes inside the dashboard, which stay precise and technical.
- Every **STOP** below is a hard stop: wait for the user's answer, never auto-continue.
- For the BI App build itself (dashboard authoring, queries, catalog search), follow the BI App MCP's own guidance (`search` first, `get_dashboard_authoring_guide`). If the data-analyst skill is available, use its conventions rather than inventing new ones.
- Never fix fragile Looker logic inline. Migrate it as-is.
- Never file anything to the BI team without explicit user consent.
- Keep query results small, since they are the main driver of token use: aggregate in SQL, return only the rows needed for the comparison (totals plus a few sample periods, not full raw tables), and don't re-fetch results you already have.
- Keep the chat uncluttered:
  - Never call `view_dashboard`: it embeds the whole dashboard in the chat. Give the dashboard link instead, and after saving check the BI App's query log for charts that failed.
  - Never paste `search` result lists back into the chat. Mention only the few relevant hits, one line each.
  - Combine check and validation queries: one query per metric family, not many small ones.
- Keep a running count of your tool calls. After every 50, give the user a one-line progress update (phases done, metric families left) and ask whether to continue.
- Announce every phase change on its own line, e.g. "**Phase 1/7 complete: Access and duplicate check.** Next: Is it worth migrating?" Phases 1-7 are counted; Phase 0 (set expectations) is not. If a phase ends at a STOP, put the announcement at the top of that message, before the question.

## Phase 0: Set expectations

1. If you are not running on Opus, say so and suggest switching before continuing (most tests of this workflow were run on Opus, and any model above Opus would be too costly).
2. Tell the user in one or two sentences: a migration takes around 30 minutes and a large number of tokens, you will ask a few questions and for permission to run queries, and a couple of follow-up prompts may be needed to fix inaccuracies. Also mention that this skill is still under test and that issues or feedback can go to @thomas.freundt on Slack.

## Phase 1: Access and duplicate check

3. Ask for the Looker dashboard URL if it was not provided.
4. Confirm you can reach it via the Looker MCP (`get_dashboard`). If you cannot, stop and point the user to the setup guide: https://holidu.atlassian.net/wiki/x/CICGnQE (see Troubleshooting).
   Check which Looker MCP is connected. If the explore toolbox is available (tools that run ad-hoc queries, e.g. `looker-toolbox-explore__query`), prefer it for System Activity (step 6) and filtered tile re-runs (step 13). Otherwise use the viewer-only path and its fallbacks.
5. Search the BI App for an existing migrated version of this dashboard. If one exists, give the link. **STOP**: ask whether to continue.

## Phase 2: Is it worth migrating?

6. Usage: pull dashboard runs and distinct viewers over the last 30 days from Looker System Activity. If ad-hoc querying is unavailable (viewer-only API), fall back to `view_count` from `get_dashboard` and report it as lifetime views only.
7. Related dashboards: search the BI App library by subject (title, description, fields, tables), not only exact name matches.
8. Show both results. Say plainly, and ask whether they still want to migrate, if ANY of these hold:
   - distinct viewers <= 5 AND runs <= 20 (30 days)
   - most runs come from one person (name them)
   - a related BI App dashboard already covers similar ground
   For clear low-usage cases, suggest retiring the dashboard instead of migrating.
   **STOP**: wait for an explicit go / no-go.

## Phase 3: Structure and scope check

9. Read the dashboard structure: its tiles, and `result_maker.filterables` to see which tiles bind which filter. Don't run any tile queries yet.
10. Merged results: tiles with `element_type: merge_result` return neither data nor definition on a viewer-only API. Flag each as unmigratable and tell the user.
    LookML fallback: if filter bindings are missing or a tile is a merge_result, ask the user to open the dashboard in Looker, use "Get LookML" from the gear menu, and paste the Dashboard tab contents. That YAML carries `listen:` blocks and merged-query definitions. It has no model definitions and no figures, so it does not replace validation.
11. Group tiles into metric families (the same metric at day/week/month grain is one family) and work per family, not per tile.
12. In ONE message, ask:
    - which parts of the dashboard are actually used, and whether anything should be dropped (if usage is concentrated on one person, suggest checking with them first)
    - if the same metric appears at several grains as separate tiles (e.g. day/week/month): combine them into one chart with a granularity selector, or keep separate views as in Looker?
    **STOP**: wait for the answers. Everything after this covers only the tiles being kept.

## Phase 4: Source mapping and baselines

13. Filters: Looker's `run_dashboard` IGNORES dashboard filters. Re-run each kept tile's query with the filter values from step 9 applied. That filtered output is the ONLY valid validation baseline. If you cannot re-run tile queries with filters, validate against unfiltered output and record that in the Migration Notes.
14. Source every field from the gold layer, in this order:
    1. `bi_gold` on the Athena source, found via the BI App catalog/schema search
    2. `models/3_gold/` in github.com/holidu/dbt-bi (read the repo if catalog search is inconclusive)
    3. only if no gold equivalent exists: a silver or legacy table, flagged as a data gap
15. Up to 4 subagents may resolve the mapping in parallel. Verify every premise before handing it over: subagents repeat your mistakes, and their agreement will look like corroboration.

## Phase 5: Build

16. Rebuild the kept views, filters and visualisations on the mapped sources, following the scope and granularity answers from step 12. Do not copy Looker SQL.

## Phase 6: Validate and annotate

17. Validate every figure against the filtered Looker baseline from step 13.
18. Add a visible **Migration Notes** section inside the dashboard itself (not a separate artifact), listing per affected field/chart:
    - **Data gaps**: fields/tables with no gold equivalent, and what they fall back to
    - **Unjustified discrepancies**: figures that don't match Looker and can't be explained
    - **Validation caveats**: e.g. validated against unfiltered output, unmigratable merge_result tiles
    Add a small inline marker next to each affected KPI/chart title pointing to its note.
    At the top of the Migration Notes, record the **clean-view rate**: the number and share of views (charts/KPIs in the migrated dashboard) with no flag in any category, e.g. "12 of 16 views (75%) have no open data issues". This is a recorded figure, not a pass/fail threshold.

## Phase 7: Hand-over

19. Tell the user the migration is done and give the dashboard link. Encourage them to go through it now and change anything they want, given the BI App's flexibility.
    - If the Migration Notes contain open flags: say the dashboard has not been signed off by the BI team and its figures must not be shared as final until it is. Put the same banner at the TOP of the dashboard so it travels with the link.
    - If validation produced no flags, say so plainly.
    - State the clean-view rate from step 18.
20. Draft (do not file) a BI-team feedback report:
    - `message`: written as the user, two or three sentences stating the problem plainly, ending with a line that the AI summary below explains it in detail
    - `title`: prefixed with `[Looker migration]` so the BI team can filter these
    - `ai_summary`: all flags from step 18, the clean-view rate, the usage numbers from step 6, and, if relevant, why existing related dashboards didn't cover the need. End it with a **Test run** block (the skill is under test, so the owner uses these to calibrate it):
      - source Looker dashboard URL and number of tiles / metric families
      - Looker MCP used: viewer-only or explore toolbox
      - wall time and total tool-call count
      - token use: ask the user to read it from Settings > Usage, or `/cost` in Claude Code; if they don't provide it, write "not provided" (you cannot measure it yourself)
      - subagents used
      - follow-up prompts the user needed to fix inaccuracies
      - which STOP points were hit, and any red flags triggered
      - where the run struggled or what the user had to correct
    - `type`: `data_availability_issue`
    - `happy`: ask the user; if they don't say, use false when open flags exist
    - `context.resourceUrl`: the finished dashboard link
    Show the draft and ask whether to file it. **STOP**: file only on an explicit yes. Mention that for anything urgent, #bi-app-users or the responsible BI team member is faster than the queue.
21. Run the self-review in "Success criteria" below and report the result in two or three plain sentences.
22. Next step: suggest a **dashboard review session**. Don't start it in this chat. Explain in one or two sentences that the migration reproduced what the Looker dashboard did, and that a short review is how to make it better than a copy. Recommend running it in a new chat so this run's cost doesn't grow further, and give this ready-to-paste prompt with the dashboard link filled in:
    > Let's review my migrated BI App dashboard: <link>. Read its Migration Notes first. Then go through it one section at a time. For each section, ask me what I use it for and what I like or dislike about it, then suggest concrete improvements (drop it, merge it with another, add a filter or breakdown, change the chart type, or switch to a governed BI App metric). Wait for my answer before moving to the next section, and don't change anything until I've approved the final list.

## Success criteria

Use these to judge whether a migration is going well, during the run (self-check) and afterwards (BI team review in the BI App). Aspirational targets, not hard thresholds.

### A. Process: is the run on track?

- [ ] Stopped and waited at every STOP (duplicate found, go/no-go, scope and granularity question, filing)
- [ ] The scope question was asked before any Looker baselines were collected, and no baselines were collected for dropped tiles
- [ ] Nothing was built before the source mapping (Phase 4) was complete
- [ ] The go/no-go showed 30-day usage (or lifetime views, labelled as such) AND related dashboards
- [ ] At most 4 subagents; premises verified before delegation
- [ ] User-facing messages stayed short and jargon-free
- [ ] No embedded dashboard previews or pasted search result lists; check queries combined per metric family
- [ ] Every phase change was announced (Phase X/7 complete, next phase named)
- [ ] The review session was suggested as a next step, with the ready-to-paste prompt, and not started in the same chat

### B. Sourcing

- [ ] Every field maps to `bi_gold`, or is listed as a data gap with its fallback
- [ ] No Looker SQL was copy-pasted as the backend
- [ ] Tiles were grouped into metric families; per-grain tiles were built the way the user chose in step 12 (granularity selector or separate views)

### C. Validation

- [ ] Baseline came from tile queries re-run WITH filters applied (or the Notes say otherwise)
- [ ] Every figure was compared; each mismatch is either explained or listed as an unjustified discrepancy
- [ ] Every merge_result tile is flagged as unmigratable

### D. Dashboard output

- [ ] Migration Notes section is visible inside the dashboard, covering the applicable categories from step 18 (data gaps, unjustified discrepancies, validation caveats) and the clean-view rate
- [ ] Every affected KPI/chart has an inline marker pointing to its note
- [ ] "Not yet signed off by BI" banner at the top if any flag is open; absent only if there were no flags
- [ ] The original dashboard's views and filters are all present, or their removal was agreed in Phase 3

### E. Feedback report

- [ ] Drafted, shown, and filed only after an explicit yes
- [ ] Message is 2-3 sentences, human-readable and free of excessive technical jargon
- [ ] ai_summary contains the flags, clean-view rate, usage numbers, related-dashboard reasoning and the Test run block; resourceUrl is set
- [ ] Title carries the `[Looker migration]` prefix; `type` is `data_availability_issue`; `happy` is set

### F. Efficiency (quantitative)

- Wall time around 30 minutes for a typical dashboard
- At most 2 follow-up prompts needed to fix inaccuracies after hand-over
- No retry loops: the same failing MCP call is not repeated more than twice
- Tool-call count stays under about 150 for a typical dashboard
- Few user corrections or redirections during the run

### Red flags: pause and check in with the user

- The run is clearly exceeding the expected time (well over 30 minutes), has passed 150 tool calls, or the conversation context has had to be compacted/summarised, OR the same query keeps failing: suggest splitting the dashboard into smaller pieces rather than pushing through
- The same metric still doesn't match Looker after two attempts: stop adjusting and log it as an unjustified discrepancy for the BI team to review
- Clean-view rate below 50%: don't call the migration a failure or say the dashboard isn't ready. Tell the user plainly that most views need BI review before the figures are used
- Most figures show unjustified discrepancies: stop validating tile by tile and check the mapping premise first

## Troubleshooting

**Cannot reach the dashboard via the Looker MCP.** Usual causes:
1. The Looker MCP isn't set up: https://holidu.atlassian.net/wiki/spaces/BI2/pages/6937804808/Looker+MCP+Setup+for+Claude+Desktop+Code
2. The user lacks view access to the dashboard (the agent can only see what the user can)
3. The session is the BI App's own agent, which has no Looker MCP: use Claude Desktop or Claude Code
Stop and explain; do not continue without access.

**System Activity queries fail (viewer-only API).** Fall back to `view_count` from `get_dashboard`; label it as lifetime views.

**Filter bindings missing / merge_result tiles.** Request the "Get LookML" Dashboard tab contents (step 10).

**No gold equivalent for a field.** Check dbt-bi `models/3_gold/`; if still nothing, use the silver/legacy table and log a data gap.

**Numbers differ after a proper rebuild.** A small, explained difference is expected and can be the improvement working as intended. Record it; don't force-match Looker.

## Examples

Should trigger:
- "Migrate this Looker dashboard to the BI App: https://holidu.looker.com/dashboards/1234"
- "Can you move my Looker dashboard over to the BI App?" (then ask for the URL)
- "Port this Looker dash before the sunset" + URL

Should NOT trigger:
- "Build me a bookings dashboard in the BI App" (new build: data-analyst)
- "Fix this chart in my BI App dashboard"
- "What does this Looker explore contain?"
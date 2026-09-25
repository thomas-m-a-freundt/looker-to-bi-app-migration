# Looker → BI App dashboard migration skill

A Claude skill that migrates **one** Looker dashboard to the Holidu BI App. It rebuilds the dashboard's views, filters and charts on governed `bi_gold` sources rather than copying Looker SQL, validates every figure against the filtered Looker output, and records any gaps in a Migration Notes section inside the new dashboard.

> **Status: under test.** Owner: Thomas Freundt (BI). Issues and feedback: Slack @thomas.freundt.
> Background and reasoning: [Migrating Dashboards: Looker → BI App](https://holidu.atlassian.net/wiki/spaces/BI2/pages/7805567177) (Confluence).

## Before you start

- **Claude Desktop or Claude Code**, using **Opus**
- The **Looker MCP** installed ([setup guide](https://holidu.atlassian.net/wiki/x/CICGnQE)), and view access to the dashboard you want to migrate
- The **Holidu BI App** connector enabled
- Around 30+ minutes and a fair number of tokens per dashboard

The skill checks usage and existing BI App dashboards first, so it may recommend **not** migrating. That's intended.

## Install

**Claude Desktop / claude.ai**

1. Download the latest `looker-to-bi-app-migration.zip` from this repo's Releases (or build it with `./scripts/package.sh`)
2. Claude → **Customize > Skills** → **+** → **Create skill** → upload the zip
3. To update, delete the old version and upload the new zip

**Claude Code (as a skill)**

```bash
git clone https://github.com/holidu/looker-to-bi-app-migration.git ~/src/looker-to-bi-app-migration
ln -s ~/src/looker-to-bi-app-migration/skills/looker-to-bi-app-migration ~/.claude/skills/looker-to-bi-app-migration
# update later with: git -C ~/src/looker-to-bi-app-migration pull
```

**Claude Code (as a plugin)**

```
/plugin marketplace add holidu/looker-to-bi-app-migration
/plugin install looker-to-bi-app-migration@holidu-bi-looker-migration
```

## Use

In a new chat: *"Migrate this Looker dashboard to the BI App: <link>"*, or type `/looker-to-bi-app-migration`.

The run goes through seven phases and announces each one: access and duplicate check → is it worth migrating → structure and scope → source mapping → build → validate → hand-over. It stops for your answer at every decision point and never files anything to the BI team without your yes.

When it offers to file a feedback report at the end, please say yes: the report includes a **Test run** block (time, tool calls, where it struggled) that's used to tune the skill.

## Repo layout

```
skills/looker-to-bi-app-migration/SKILL.md   the skill itself (the only file Claude reads)
.claude-plugin/                               plugin + marketplace manifests for Claude Code
scripts/package.sh                            builds the zip for Claude Desktop upload
CHANGELOG.md                                  version history
```

## Changing the skill

1. Edit `skills/looker-to-bi-app-migration/SKILL.md` on a branch and open a pull request
2. Keep the frontmatter `name` and `description`; the description decides when the skill triggers
3. Bump `version` in `.claude-plugin/plugin.json` and add a line to `CHANGELOG.md`
4. After merging, build the zip and attach it to a new GitHub release

Internal to Holidu. Not licensed for external use.

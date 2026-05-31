# Issue-linked work: `wip/` branch + optional worktree

**Policy:** All work tied to a **numbered GitHub issue** is implemented on **`wip/<issue-slug>`** before landing on `next` / `main`. See [.cursor/rules/github-issue-workflow.mdc](../../.cursor/rules/github-issue-workflow.mdc) and `PROJECT_RULES.md` → Git Workflow.

## Create a dedicated worktree (recommended)

From your **primary** clone (not inside another worktree), with `next` up to date:

```bash
cd /path/to/sixlayer
git fetch all next
git worktree add /path/to/sixlayer-wip-<ISSUE> -b wip/<ISSUE>-<short-slug> next
cd /path/to/sixlayer-wip-<ISSUE>
```

- Use a path **outside** the main repo tree (sibling directory is fine).
- **Branch name** should include the issue number (e.g. `wip/280-agent-wip-worktree-checklist`).

**Temp checkout, durable remote:** worktree directories are ephemeral (multi-machine, wiped on reset). Commit and push on the `wip/` branch after every edit; do not rely on local-only state in the worktree path.

## Day-to-day on the `wip/` checkout

```bash
# All commits for this issue happen here; message footer: Refs #280 / Fixes #280
git add <paths>
git commit -m "type(scope): …

Refs #280"
git push all HEAD   # pushes current wip branch
```

## Land on `next` (primary clone)

When the `wip/` branch is ready:

```bash
cd /path/to/sixlayer          # primary clone
git checkout next
git pull all next
git merge --no-ff wip/280-agent-wip-worktree-checklist -m "Merge wip/280-agent-wip-worktree-checklist

Refs #280"
git push all next
```

Then follow **Worklist closure** in `github-issue-workflow.mdc` (rename `wip/` → `done/`, remove temp worktree if used, final issue comment + close).

## Remove the worktree (after merge + rename)

```bash
cd /path/to/sixlayer
git worktree remove /path/to/sixlayer-wip-<ISSUE>
```

Do **not** delete `DerivedData` manually; use Xcode clean or `xcodebuild clean` if needed.

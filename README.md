# Basic Memory Gardener

A single, **LLM-driven maintenance skill** for a **Git-backed** [Basic Memory](https://github.com/basicmachines-co/basic-memory) knowledge corpus. It improves existing notes by consolidating session findings, splitting unwieldy authored notes, curating relationships, checking freshness and provenance, and preserving historical knowledge. All edits happen in an isolated Git worktree and are merged only after review/approval.

**Current phase: Git-only, worktree-isolated LLM gardening with a bundled read-only discovery script.** No service, database, external state manifest, hashing pipeline, resource budgets, or scheduling framework. The agent reviews the committed worktree snapshot; its PowerShell helper finds notes changed since their per-note `last_gardened_at` timestamp.

## Start here

- **[memory-garden skill](skills/memory-garden/SKILL.md)** — the complete operational instructions.
- **[Customized memory-capture skill](skills/memory-capture/SKILL.md)** — upstream capture behavior with safeguards against silently reactivating archived checkpoints; ordinary notes omit `archived`.
- **[Global Copilot retrieval instructions](snippets/copilot-global-instructions.md)** — a copy-ready, always-on section for searches, bounded reads, graph navigation, freshness, and archive-aware answers.
- **[Related community work and archiving notes](docs/ecosystem-and-archiving.md)** — projects, upstream behavior, and limitations.
- **[Bundled candidate inventory script](skills/memory-garden/scripts/Find-GardenCandidates.ps1)** — shipped and installed with the gardener skill; lists notes without a gardening watermark or modified since their last review, with no private state file.

### Install the GitHub Copilot CLI plugin

Prerequisites: a **local Git-backed Basic Memory corpus**, Git worktree support, a working Basic Memory MCP connection for read-only discovery, PowerShell for the bundled inventory helper, and a Copilot CLI
build supporting Agent Plugins 1.0. The root `plugin.json` packages both
`memory-garden` and the archive-aware `memory-capture` from `skills/`, including
the gardener's inventory helper. No hooks, MCP server, extension, service,
dependency install, or automatic corpus-maintenance job is added.

```powershell
copilot plugin install joniba/basic-memory-gardener
copilot plugin list --json
copilot skill list --json
```

Verify the plugin is enabled and `memory-garden` is discovered from the installed
plugin. Its directory must contain `scripts\Find-GardenCandidates.ps1`.
In an already-open conversation, reload the skills catalog if your CLI requires
it, then invoke the skill by name. Cloning the repository alone does not load it.

### Update skills from the repository

The installed plugin retains its GitHub source. Fetch published skill updates:

```powershell
copilot plugin update basic-memory-gardener
copilot skill list --json
```

Reload the current conversation's skill catalog after updating if needed.
Direct GitHub plugins are not guaranteed to auto-update on every upstream push;
the explicit update command avoids maintaining copied skill files. Do not use
an extension reload to refresh skills.

If this repo was previously registered with `copilot skill add`, unregister
that specific custom directory after installing the plugin to avoid duplicate
discovery. Pass the exact directory path, not a skill name: removing by name
can delete a standalone skill. Unregistering a custom directory does not remove
the source checkout.

### Use the archive-aware memory-capture skill

The existing [Copilot capture bridge](https://github.com/joniba/basic-memory-copilot-bridge)
calls the skill named `memory-capture`; it does **not** write notes itself. The
plugin includes a **modified copy of upstream `memory-capture` with the same
skill name**. It preserves upstream capture behavior but refuses to overwrite
an explicitly archived checkpoint without authorization. New checkpoints omit
`archived`.

Installing the plugin does not delete or overwrite existing personal skills.
A higher-precedence standalone `memory-capture` may still win. Inspect the
effective path with `copilot skill list --json`; do not claim the archive-aware
copy is active unless that path points into this plugin. Preserve/back up a
standalone copy and obtain the applicable approval before retiring it. The
gardener itself protects live checkpoints regardless of which capture copy is
active. Do not change the bridge extension, thresholds, or timers to resolve a
skill-precedence issue.

**Retrieval:** unmarked notes are unarchived. Ordinary searches have no archive metadata filter and exclude any `archived: true` hits from current answers. Searching specifically for archived notes is reserved for explicit historical requests and internal gardening. The bundled PowerShell helper reads `last_gardened_at` from note frontmatter; no external state is maintained.

For consistent **ordinary memory retrieval** across all Copilot sessions, copy the section in [`snippets/copilot-global-instructions.md`](snippets/copilot-global-instructions.md) into your existing user-level/global Copilot instructions. Keep that section always-on and concise; the larger `memory-garden` skill is loaded only for explicit maintenance work. The snippet uses the same canonical-vs-source and `archived: true` conventions as the gardener. It is not automatically installed by the plugin.

### Default gardening workflow

1. **Fail fast** unless the BM project is inside a local Git repository with committed, tracked corpus files. Inspect `git status --porcelain=v1 --untracked-files=all` for the **entire repository**, even when gardening one folder. If dirty, stop and ask the user to commit or resolve it; never auto-commit/stash/reset.
2. Create a **new Git worktree and `garden/...` branch** from the verified main/base branch, outside the live BM checkout. Do not switch branches in the live checkout.
3. Run the **bundled inventory script against the worktree BM directory**, then garden the worktree files. BM MCP search may help with discovery, but **all writes must use local file tools on the worktree**; BM MCP write tools still point to the live project and must not be used.
4. Verify changed paths, note links, provenance, and diff; commit only authorized corpus paths on the gardening branch.
5. Show the diff/summary for approval. The user can review locally or authorize pushing a branch and opening a GitHub PR. **No automatic push, PR, or merge.**
6. **After explicit approval**, merge safely. A GitHub PR can merge remotely without touching the live checkout. The local BM checkout must be synchronized **only when safe from concurrent captures**; then BM can reindex and verify the changes. For local-only Git, wait for a clean checkout and safe merge window.

The initial clean-state check happens **before** creating the worktree. Captures may continue modifying the live checkout **afterward** without contaminating gardening commits. The worktree contains the committed snapshot, not later live captures.

### Bundled candidate inventory

The gardener automatically invokes its installed `scripts/Find-GardenCandidates.ps1` against the **worktree's BM project root** when PowerShell is available. For manual testing, locate the actual installed plugin's skill directory using `copilot skill list --json`, then run:

~~~powershell
$skillDir = '<actual installed plugin>/skills/memory-garden'
& (Join-Path $skillDir 'scripts/Find-GardenCandidates.ps1') -Root '<BM project directory inside gardening worktree>' -Folder 'engineering'
~~~

The helper returns notes with missing/outdated `last_gardened_at`, plus size and archive status. Use `-IncludeUnchanged` for a complete inventory. It never edits files or makes semantic gardening decisions. A watermark-only write advances mtime, so the helper allows a small tolerance; it is intentionally approximate. The gardener never stamps potentially live session checkpoints or immutable sources merely to mark them processed.

### Example requests

- "Garden Basic Memory project **main**. Prepare a reviewable gardening branch and show me the diff."
- "Garden Basic Memory project **main**, limited to **personal/sessions/**. Show what reusable knowledge you found; ask before expanding write scope."
- "Use memory-garden on project **engineering**, folder **investigations/**. Review contradictions, oversized notes, duplicate findings, relationships, and archival candidates."
- "Open a GitHub PR for the completed gardening branch in project **main** so I can review it."

Project/folder names are examples, not defaults. **Specify the target BM project**, and optionally a path within that project. A folder scope constrains *writes*; the skill may inspect relevant neighboring notes read-only for context.

## Principles

1. **One project, optionally one folder, per run.** No cross-project migration or automatic broad sweep.
2. **Never delete knowledge.** Preserve original evidence, historical decisions, and completed work.
3. **Do not disrupt live session capture.** The separate [Copilot bridge](https://github.com/joniba/basic-memory-copilot-bridge) remains responsible for checkpointing.
4. **Archive in place initially.** Only genuine historical/superseded notes get `archived: true`; absence of the field means not archived. Do not move notes just to archive them. This is a *convention*, not a native default search exclusion.
5. **Promote durable knowledge without copying entire sources.** Preserve author, source dates, and source pointers.
6. **Git-only, worktree-isolated, reviewable changes.** Fail fast without Git or a clean committed baseline. Never merge before approval; verify BM indexing after safe local sync.

## Scope of this repository

This is the gardener's home. It is **not** the Basic Memory corpus. Do not commit private memory notes, source documents, credentials, or run logs into this public repository. The read-only candidate inventory script is bundled inside the `memory-garden` skill; it never modifies the Basic Memory corpus. Further automation is optional.

The earlier [bridge integration proposal](https://github.com/joniba/basic-memory-copilot-bridge/issues/2) remains useful background, but its hash-based manifest, queue, budgets, and scheduling pipeline are **not part of this simpler skill**. Instead, the per-note `last_gardened_at` watermark, bundled script, and Git worktree review provide lightweight incremental discovery and safe isolation.

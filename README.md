# Basic Memory Gardener

A single, **LLM-driven maintenance skill** for a [Basic Memory](https://github.com/basicmachines-co/basic-memory) knowledge corpus. It improves the usefulness of existing notes by consolidating session findings, splitting unwieldy authored notes, curating relationships, checking freshness and provenance, and preserving historical knowledge.

**Current phase: BM-native, LLM-driven gardening with a bundled read-only discovery script.** The gardener uses the registered Basic Memory project's MCP search, graph, and note-editing capabilities, not a separate Git worktree, duplicate project index, or filesystem-only editing engine. No service, database, external state manifest, hashing pipeline, resource budgets, or scheduling framework. For local broad passes, the script compares canonical note frontmatter `modified` with `last_gardened_at`, without using filesystem or Git modification times.

## Start here

- **[memory-garden skill](skills/memory-garden/SKILL.md)** — the complete operational instructions.
- **[Customized memory-capture skill](skills/memory-capture/SKILL.md)** — upstream capture behavior with safeguards against silently reactivating archived checkpoints; ordinary notes omit `archived`.
- **[Global Copilot retrieval instructions](snippets/copilot-global-instructions.md)** — a copy-ready, always-on section for searches, bounded reads, graph navigation, freshness, and archive-aware answers.
- **[Related community work and archiving notes](docs/ecosystem-and-archiving.md)** — projects, upstream behavior, and limitations.
- **[Bundled candidate inventory script](skills/memory-garden/scripts/Find-GardenCandidates.ps1)** — shipped with the skill; reads explicit canonical `modified` and `last_gardened_at` from frontmatter without a private state file or filesystem/Git timestamp comparison.

### Install the GitHub Copilot CLI plugin

Prerequisites: a working local Basic Memory MCP connection and a Copilot CLI
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

**Retrieval:** unmarked notes are unarchived. Ordinary searches have no archive metadata filter and exclude any `archived: true` hits from current answers. Searching specifically for archived notes is reserved for explicit historical requests and internal gardening. The bundled PowerShell helper reads `modified` and `last_gardened_at` from note frontmatter; no external state is maintained.

For consistent **ordinary memory retrieval** across all Copilot sessions, copy the section in [`snippets/copilot-global-instructions.md`](snippets/copilot-global-instructions.md) into your existing user-level/global Copilot instructions. Keep that section always-on and concise; the larger `memory-garden` skill is loaded only for explicit maintenance work. The snippet uses the same canonical-vs-source and `archived: true` conventions as the gardener. It is not automatically installed by the plugin.

### Find candidates without model calls

For a broad local pass, resolve the installed plugin skill directory and run its bundled helper against the **registered BM project root**:

```powershell
$skillDir = '<absolute installed memory-garden skill directory>'
& (Join-Path $skillDir 'scripts\Find-GardenCandidates.ps1') -Root 'C:\path\to\bm-project' -Folder 'engineering'
```

The helper reads only top-level frontmatter `modified`, `last_gardened_at`, and `archived` plus file sizes/paths. A note is normally skippable when both timestamps are valid, explicit and offset-aware, and `modified <= last_gardened_at`. Missing or ambiguous `modified` is **unknown**, not unchanged; it remains eligible. BM exposes canonical frontmatter `modified` as indexed `updated_at`, but for notes lacking explicit `modified` it may fall back to filesystem mtime. The gardener does **not** use that fallback to certify a note as unchanged.

Use `-IncludeUnchanged` for a full inventory. For targeted work, BM compact search/recent activity may be cheaper than a broad scan. If the script cannot run, the gardener falls back to BM directory/search/metadata tools. It never stamps live session checkpoints or immutable source documents just to record review.

### BM-native operations and safe edits

The gardener uses `search_notes(compact=True)`, paged `list_directory` and `recent_activity` for discovery, `read_note(include_content=False)` for cheap identity/checksum checks, bounded `read_note(start_line, end_line)` for selected evidence, and `build_context(compact=True, depth=1)` for relevant relations. It uses guarded `edit_note`/`write_note` for changes, avoiding full note reads and rewrites unless the task genuinely requires them.

All writes target the **already registered BM project**. The skill does not create Git worktrees, register a second BM project, or trigger a duplicate full-corpus index. A first run defaults to read-only planning. For apply, coordinate with concurrent session capture (ideally a maintenance window), use revision checks, verify BM indexing, and inspect a private Git diff when available. No automatic branch switching, Git commit, merge, or change to the capture bridge.

### Example requests

- "Use memory-garden to audit Basic Memory project **main**. Preview improvements only."
- "Garden Basic Memory project **main**, limited to **personal/sessions/**. Promote durable findings into the existing project only after I approve the plan."
- "Use memory-garden on project **engineering**, folder **investigations/**. Review contradictions, oversized notes, duplicate findings, relationships, and archival candidates."
- "Apply the previously approved gardening changes to project **main** and verify search, provenance, and links."

Project/folder names are examples, not defaults. **Specify the target BM project**, and optionally a path within that project. A folder scope constrains *writes*; the skill may inspect relevant neighboring notes read-only for context.

## Principles

1. **One project, optionally one folder, per run.** No cross-project migration or automatic broad sweep.
2. **Never delete knowledge.** Preserve original evidence, historical decisions, and completed work.
3. **Do not disrupt live session capture.** The separate [Copilot bridge](https://github.com/joniba/basic-memory-copilot-bridge) remains responsible for checkpointing.
4. **Archive in place initially.** Only genuine historical/superseded notes get `archived: true`; absence of the field means not archived. Do not move notes just to archive them. This is a *convention*, not a native default search exclusion.
5. **Promote durable knowledge without copying entire sources.** Preserve author, source dates, and source pointers.
6. **Reviewable changes, evidence-based edits, and verification.** Prefer a preview on the first run.

## Scope of this repository

This is the gardener's home. It is **not** the Basic Memory corpus. Do not commit private memory notes, source documents, credentials, or run logs into this public repository. The read-only candidate inventory script is bundled inside the `memory-garden` skill; it never modifies the Basic Memory corpus. Further automation is optional.

The earlier [bridge integration proposal](https://github.com/joniba/basic-memory-copilot-bridge/issues/2) remains useful background, but its hash-based manifest, queue, budgets, and scheduling pipeline are **not part of this simpler skill**. Instead, the per-note `last_gardened_at` watermark and bundled skill script provide lightweight incremental discovery.

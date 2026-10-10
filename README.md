# Basic Memory Gardener

A single, **LLM-driven maintenance skill** for a [Basic Memory](https://github.com/basicmachines-co/basic-memory) knowledge corpus. It improves the usefulness of existing notes by consolidating session findings, splitting unwieldy authored notes, curating relationships, checking freshness and provenance, and preserving historical knowledge.

**Current phase: LLM-driven gardening with optional lightweight scripts.** No service, database, external state manifest, hashing pipeline, resource budgets, or scheduling framework. The agent performs the substantive review; a read-only PowerShell helper can cheaply find notes changed since their per-note `last_gardened_at` timestamp.

## Start here

- **[memory-garden skill](skills/memory-garden/SKILL.md)** — the complete operational instructions.
- **[Customized memory-capture skill](skills/memory-capture/SKILL.md)** — upstream capture behavior with safeguards against silently reactivating archived checkpoints; ordinary notes omit `archived`.
- **[Global Copilot retrieval instructions](snippets/copilot-global-instructions.md)** — a copy-ready, always-on section for searches, bounded reads, graph navigation, freshness, and archive-aware answers.
- **[Related community work and archiving notes](docs/ecosystem-and-archiving.md)** — projects, upstream behavior, and limitations.
- **[Read-only candidate inventory helper](scripts/Find-GardenCandidates.ps1)** — lists notes without a gardening watermark or modified since their last review; no private state file.

### Use with GitHub Copilot CLI

Prerequisites: a working local Basic Memory MCP connection and a Copilot CLI installation that discovers SKILL.md skills. On Windows, copy the skill directory to your user skills directory:

~~~powershell
New-Item -ItemType Directory -Force "$HOME\.copilot\skills\memory-garden" | Out-Null
Copy-Item ".\skills\memory-garden\SKILL.md" "$HOME\.copilot\skills\memory-garden\SKILL.md" -Force
copilot skill list --json
~~~

Restart or reload Copilot if necessary, and verify that the skill is discovered. Installing this skill does not change the Basic Memory MCP configuration or session capture extension.

### Use the archive-aware memory-capture skill

The existing [Copilot capture bridge](https://github.com/joniba/basic-memory-copilot-bridge) calls the skill named `memory-capture`; it does **not** write notes itself. This repository includes a **modified copy of upstream `memory-capture` with the same skill name**. It preserves upstream capture behavior but refuses to overwrite a checkpoint explicitly marked `archived: true` without authorization. New checkpoints do **not** need an `archived` field. Install/activate this copy in place of the previously active capture skill if you want that safeguard; cloning alone does not change capture behavior.

For a user-level installation, first back up any existing `memory-capture` skill and confirm which source Copilot CLI is loading (including possible plugin-provided copies). Then install the customized copy:

~~~powershell
$target = Join-Path $HOME '.copilot\skills\memory-capture'
if (Test-Path $target) {
  $backup = "$target.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $target $backup -Recurse -Force
}
New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item '.\skills\memory-capture\SKILL.md' (Join-Path $target 'SKILL.md') -Force
copilot skill list --json
~~~

If multiple `memory-capture` skills remain discoverable, resolve the duplicate/precedence using your installed Copilot CLI's skill configuration; do **not** assume the customized copy wins. Restart or reload the session and perform a safe test capture: verify the note retains its original `thread_id` and provenance, and that a second capture updates the same note. An ordinary new note should **omit** `archived`. Do not change the bridge extension, its thresholds, or its timers.

**Retrieval:** unmarked notes are unarchived. Ordinary searches have no archive metadata filter and exclude any `archived: true` hits from current answers. Searching specifically for archived notes is reserved for explicit historical requests and internal gardening. The optional PowerShell helper reads `last_gardened_at` from note frontmatter; no external state is maintained.

For consistent **ordinary memory retrieval** across all Copilot sessions, copy the section in [`snippets/copilot-global-instructions.md`](snippets/copilot-global-instructions.md) into your existing user-level/global Copilot instructions. Keep that section always-on and concise; the larger `memory-garden` skill is loaded only for explicit maintenance work. The snippet uses the same canonical-vs-source and `archived: true` conventions as the gardener. It is not automatically installed by the PowerShell commands above.

### Find candidates without model calls

```powershell
.\scripts\Find-GardenCandidates.ps1 -Root 'C:\path\to\bm-project' -Folder 'engineering'
```

The helper returns notes with missing or outdated `last_gardened_at`, plus their size and archive status. It does not make gardening decisions. A watermark-only write advances file mtime, so the helper allows a small tolerance; it is intentionally approximate. The gardener must not stamp potentially live session checkpoints or immutable sources just to mark them processed.

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

This is the gardener's home. It is **not** the Basic Memory corpus. Do not commit private memory notes, source documents, credentials, or run logs into this public repository. The optional read-only candidate inventory script lives here; it never modifies the Basic Memory corpus. Further automation is optional.

The earlier [bridge integration proposal](https://github.com/joniba/basic-memory-copilot-bridge/issues/2) remains useful background, but its hash-based manifest, queue, budgets, and scheduling pipeline are **not part of this simpler skill**. Instead, the per-note `last_gardened_at` watermark and optional script provide lightweight incremental discovery.

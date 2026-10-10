# Basic Memory Gardener

A single, **LLM-driven maintenance skill** for a [Basic Memory](https://github.com/basicmachines-co/basic-memory) knowledge corpus. It improves the usefulness of existing notes by consolidating session findings, splitting unwieldy authored notes, curating relationships, checking freshness and provenance, and preserving historical knowledge.

**Current phase: skill-only proof of concept.** No service, scheduled job, additional MCP server, index, deterministic scanner, or automation framework. The agent does the reasoning and uses the Basic Memory tools already available in its session. Token usage is deliberately not optimized away yet: first validate whether gardening produces enough value.

## Start here

- **[memory-garden skill](skills/memory-garden/SKILL.md)** — the complete operational instructions.
- **[Customized memory-capture skill](skills/memory-capture/SKILL.md)** — upstream capture behavior with explicit `archived: false` on new/re-captured notes, plus safeguards against silently reactivating archived checkpoints.
- **[Global Copilot retrieval instructions](snippets/copilot-global-instructions.md)** — a copy-ready, always-on section for searches, bounded reads, graph navigation, freshness, and archive-aware answers.
- **[Related community work and archiving notes](docs/ecosystem-and-archiving.md)** — projects, upstream behavior, and limitations.

### Use with GitHub Copilot CLI

Prerequisites: a working local Basic Memory MCP connection and a Copilot CLI installation that discovers SKILL.md skills. On Windows, copy the skill directory to your user skills directory:

~~~powershell
New-Item -ItemType Directory -Force "$HOME\.copilot\skills\memory-garden" | Out-Null
Copy-Item ".\skills\memory-garden\SKILL.md" "$HOME\.copilot\skills\memory-garden\SKILL.md" -Force
copilot skill list --json
~~~

Restart or reload Copilot if necessary, and verify that the skill is discovered. Installing this skill does not change the Basic Memory MCP configuration or session capture extension.

### Use the archive-aware memory-capture skill

The existing [Copilot capture bridge](https://github.com/joniba/basic-memory-copilot-bridge) calls the skill named `memory-capture`; it does **not** write notes itself. This repository includes a **modified copy of upstream `memory-capture` with the same skill name**. To make the bridge write `archived: false` on new and re-captured checkpoints, you must **install/activate this copy in place of the previously active capture skill**. Merely cloning this repository will not change capture behavior.

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

If multiple `memory-capture` skills remain discoverable, resolve the duplicate/precedence using your installed Copilot CLI's skill configuration; do **not** assume the customized copy wins. Restart or reload the session and perform a safe test capture: verify the resulting YAML contains the **Boolean** `archived: false`, retains the original `thread_id`, and preserves the bridge's other metadata. A second capture should update the same note. Do not change the bridge extension, its thresholds, or its timers.

**Transition:** active-only searches with `metadata_filters={"archived": False}` will miss existing notes that lack the field. New capture notes are classified by this skill; legacy captures are classified when safely re-captured; the gardener classifies authorized reviewed notes. Until coverage is sufficient, use the unfiltered legacy-safe retrieval fallback in the global instructions. Historical notes remain available via unfiltered or `archived: True` searches.


For consistent **ordinary memory retrieval** across all Copilot sessions, copy the section in [`snippets/copilot-global-instructions.md`](snippets/copilot-global-instructions.md) into your existing user-level/global Copilot instructions. Keep that section always-on and concise; the larger `memory-garden` skill is loaded only for explicit maintenance work. The snippet uses the same canonical-vs-source and `archived: true` conventions as the gardener. It is not automatically installed by the PowerShell commands above.

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
4. **Archive in place initially.** Use frontmatter archived: true for genuine historical/superseded material; do not move notes just to archive them. This is a *convention*, not a native default search exclusion.
5. **Promote durable knowledge without copying entire sources.** Preserve author, source dates, and source pointers.
6. **Reviewable changes, evidence-based edits, and verification.** Prefer a preview on the first run.

## Scope of this repository

This is the gardener's home. It is **not** the Basic Memory corpus. Do not commit private memory notes, source documents, credentials, or run logs into this public repository. Any future scripts, tests, configuration, or scheduling can be added here only after the skill-only approach has been evaluated.

The earlier [bridge integration proposal](https://github.com/joniba/basic-memory-copilot-bridge/issues/2) remains useful background, but its suggested scanner, state manifest, and scheduling pipeline are **deferred**, not prerequisites.

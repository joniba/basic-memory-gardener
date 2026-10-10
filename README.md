# Basic Memory Gardener

A single, **LLM-driven maintenance skill** for a [Basic Memory](https://github.com/basicmachines-co/basic-memory) knowledge corpus. It improves the usefulness of existing notes by consolidating session findings, splitting unwieldy authored notes, curating relationships, checking freshness and provenance, and preserving historical knowledge.

**Current phase: skill-only proof of concept.** No service, scheduled job, additional MCP server, index, deterministic scanner, or automation framework. The agent does the reasoning and uses the Basic Memory tools already available in its session. Token usage is deliberately not optimized away yet: first validate whether gardening produces enough value.

## Start here

- **[memory-garden skill](skills/memory-garden/SKILL.md)** — the complete operational instructions.
- **[Related community work and archiving notes](docs/ecosystem-and-archiving.md)** — projects, upstream behavior, and limitations.

### Use with GitHub Copilot CLI

Prerequisites: a working local Basic Memory MCP connection and a Copilot CLI installation that discovers SKILL.md skills. On Windows, copy the skill directory to your user skills directory:

~~~powershell
New-Item -ItemType Directory -Force "$HOME\.copilot\skills\memory-garden" | Out-Null
Copy-Item ".\skills\memory-garden\SKILL.md" "$HOME\.copilot\skills\memory-garden\SKILL.md" -Force
copilot skill list --json
~~~

Restart or reload Copilot if necessary, and verify that the skill is discovered. Installing this skill does not change the Basic Memory MCP configuration or session capture extension.

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

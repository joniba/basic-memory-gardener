# Related work, archiving, and first-phase decisions

Research notes for the **Git-only, worktree-isolated LLM-first skill with bundled lightweight scripts** version of Basic Memory Gardener (October 2026). These are design references, not dependencies. Check the installed Basic Memory version before assuming a specific tool signature.

## Existing efforts

| Project / upstream work | What already exists | What we can reuse | Why it is not the entire answer |
| --- | --- | --- | --- |
| [Basic Memory's canonical skills](https://github.com/basicmachines-co/basic-memory/tree/main/skills) | memory-reflect, memory-defrag, memory-curate, memory-lifecycle, memory-metadata-search, memory-notes, memory-capture | The bulk of the gardening reasoning and note syntax | They are separate workflows, with assumptions about MEMORY.md, daily notes, folder lifecycle, and sometimes age-based deletion that do not fit this corpus |
| [llucax/opencode-basic-memory-curation](https://github.com/llucax/opencode-basic-memory-curation) | A comprehensive curation policy, small-note conventions, source pointers, compact search, a layout checker, and an OpenCode session-context plugin | Evidence that oversized retrieval and provenance matter; examples of explicit policy and validation | Tailored to OpenCode, a strict index.md hierarchy, and a separate activity-log project; not a drop-in gardener for Copilot CLI with mutable personal/sessions/ captures |
| [escoffier-labs/brigade — Memory Care](https://github.com/escoffier-labs/brigade/blob/main/docs/memory-care.md) | Read-only scanner for stale, undersourced, orphaned, oversized, contradictory, and incomplete cards; review queue and receipts | Useful later if deterministic auditing becomes worth building | Its card model and runtime are not Basic Memory; its scanner does not itself perform full semantic consolidation |
| [Basic Memory issue #1118](https://github.com/basicmachines-co/basic-memory/issues/1118) | Upstream discussion of Brigade-inspired receipts, review-gated promotion, bounded context packs, and memory care | Strong signal that upstream is exploring this same territory | An exploration issue, not proof that all capabilities are shipped |
| [Basic Memory issue #1588](https://github.com/basicmachines-co/basic-memory/issues/1588) | Explicit request to surface stale/superseded status in core, beyond optional lifecycle skills | Confirms an important native gap | Does not make archive exclusion a current core search guarantee |
| [Basic Memory issue #125](https://github.com/basicmachines-co/basic-memory/issues/125) | Request for agentic bulk operations and workflow automation | Potential upstream direction to monitor | Not a replacement for a working policy skill |

**Conclusion:** We are not first to attempt memory curation. The highest-value first experiment is to **orchestrate existing BM functionality with one tailored skill**, not write a second memory engine. In the community work reviewed, no directly reusable, end-to-end Copilot CLI gardener for a single existing BM project/folder was verified. This is a scoped finding, not a claim that no such project exists anywhere.

## Archiving: what a folder does and does not do

Upstream [memory-lifecycle](https://github.com/basicmachines-co/basic-memory/blob/main/skills/memory-lifecycle/SKILL.md) uses active/ and archive/ folders, and says same-project move_note normally retains permalinks unless update_permalinks_on_move is enabled. The folder is **a human and agent convention**; it does not by itself prove that all BM search results exclude archive/. An agent must explicitly constrain discovery or inspect paths.

Upstream [metadata-search](https://github.com/basicmachines-co/basic-memory/blob/main/docs/metadata-search.md) supports querying custom YAML frontmatter through search_notes metadata_filters. Important distinctions:

- archived: true is queryable as a Boolean metadata value (subject to confirming the installed version).
- archived: false matches **only** notes that explicitly carry false; it does **not** match legacy notes where the field is missing.
- A null filter is documented for missing or explicitly null fields, but it is not equivalent to "anything except true"; it also excludes non-Markdown indexed sources.
- The documented filter language has version-specific differences. The current source may expose additional operators not yet reflected in a deployed version. Do not assume a universal OR/NOT filter exists.
- A filter on search_notes should **not be assumed to propagate into build_context relation expansion**. Inspect neighbor metadata separately.
- Neither a same-project archive/ folder nor a frontmatter marker automatically establishes current-vs-historical *truth*.

**Decision for v1:** Use **metadata-only archiving in place**. Ordinary notes omit the archive field; **missing `archived` means not archived**. Only a deliberately retired note receives:

~~~yaml
archived: true
archived_at: <actual archive decision date>
archive_reason: <why no longer current>
knowledge_status: superseded
~~~

`knowledge_status: superseded` is appropriate only when a verified successor exists; otherwise describe the actual reason. The [customized capture skill](../skills/memory-capture/SKILL.md) does **not** add `archived: false`; it guards against overwriting a checkpoint that has been explicitly archived. The [gardener skill](../skills/memory-garden/SKILL.md) handles archiving of safe, non-live notes, preserving original sources and relations.

**Ordinary retrieval:** search without an archive equality filter, then exclude `archived: true` hits from current answers. `metadata_filters={"archived": False}` would hide normal unmarked notes. Explicit archived:true searches are **discouraged except when the user specifically requests historical information, old-vs-new comparison, or another historical perspective**. The gardener's own internal maintenance review is a separate exception. If archived notes dominate results, use alternate queries/pagination or combine separate missing-field and explicit-false searches; don't silently fall back to archived notes as current authority.

**Lightweight incremental review:** the gardener stamps editable, successfully reviewed authored notes with `last_gardened_at`. Because a fresh Git worktree gives files new filesystem mtimes, the [bundled PowerShell script](../skills/memory-garden/scripts/Find-GardenCandidates.ps1) instead compares that watermark with each note's **last committed Git modification time**, using a small tolerance for the gardening commit itself. There is no hash manifest or private database. Live checkpoints and immutable source documents are not stamped without special authorization. This is deliberately approximate.

This is the **lowest-risk identity/relationship policy**: metadata changes without moves leave paths and link targets stable. All gardening edits happen in a separate Git worktree/branch, not the registered live BM checkout. Verify worktree files and links before approval; verify **BM indexing and graph only after approved merge and safe local sync**. Archive state is not automatically propagated to graph expansion.

### Why not a sibling archive project now?

Cross-project moves and relation identity are harder to prove than same-project metadata edits. Basic Memory [issue #1607](https://github.com/basicmachines-co/basic-memory/issues/1607) describes cross-project move detection and its false positives in v0.23.2. A second project may help search separation but requires a fixture-tested migration and cross-project link validation. It is not needed for this initial skill.

### Why not an archive/ folder now?

It could improve human browsing, but it adds file movement without solving default search ranking. Upstream move_note normally retains permalinks, but project settings and path-based references can complicate it. We can revisit folder moves **only if a demonstrated retrieval or navigation benefit outweighs the churn**.

## Practical retrieval checks to run before relying on the policy

Use temporary non-sensitive notes or a safe existing fixture, not production-wide migration:

1. Create a normal Markdown note **without** archived and another with archived:true. Confirm both appear in an ordinary text search.
2. Confirm metadata_filters={"archived": true} finds the historical note.
3. Confirm metadata_filters={"archived": false} does **not** find the unmarked note.
4. Confirm the installed BM version's documented missing-field filter behaves as expected; do not extrapolate it to non-Markdown sources.
5. Link a current note to the archived note. Confirm build_context still returns the historical neighbor and inspect whether it exposes archival metadata.
6. Change archived metadata via a supported BM edit operation; verify permalink, incoming/outgoing relations, and search remain intact.
7. Check whether an archived note outranks a current note for a representative query; if so, evaluate a client-side retrieval rule or future native search filter.
8. Confirm folder-scoped gardening never edits notes outside the authorized subtree, even when the search index returns them.
9. Confirm a successfully stamped, unchanged authored note is skipped by the **Git commit-time** inventory helper even in a fresh worktree; a later committed substantive edit makes it eligible. Verify the small stamp-to-commit tolerance.
10. Confirm the gardener never stamps an active checkpoint merely to record a review.
11. Confirm non-Git projects and dirty repositories (including changes outside the requested folder) fail fast, without committing or stashing.
12. Confirm live capture continues modifying the original checkout while gardening changes remain isolated in a different Git worktree.
13. Confirm BM MCP write tools are never used against the live project during gardening, and unmerged worktree edits are not falsely described as indexed.
14. Confirm PR publication and merge require approval; after remote merge, the local checkout is only synced when safe from concurrent capture writes.

## Deliberately deferred

- Background Windows service, scheduler, and automatic restart catch-up.
- External state manifest, hash-based processing queue, and deterministic semantic-gardening engine. A read-only timestamp inventory helper is included.
- Cross-project archival or mass folder restructuring.
- Changing the Copilot checkpoint bridge's runtime or triggers. A customized **copy of the upstream memory-capture skill** is included to protect deliberately archived checkpoints.
- A new vector database, custom MCP server, or automated LLM ingestion pipeline.

The [bridge issue #2](https://github.com/joniba/basic-memory-copilot-bridge/issues/2) records the earlier broader pipeline proposal. Treat it as future options; evaluate this simpler skill first.

## Evaluation criteria

After several real gardening passes, judge:
- Did the gardener extract genuinely reusable knowledge from session checkpoints?
- Did it improve correct/current answers, provenance, and discovery of related material?
- Did it reduce the need to read large notes, without losing context?
- Did it preserve historical facts and avoid duplicate canonical accounts?
- Were the LLM token costs and review burden tolerable?
- Does the bundled Git-history-based timestamp inventory script meaningfully reduce unnecessary repeat review?
- Which repeated mistakes, if any, justify additional scripting without introducing a new state system?

Only build a service/pipeline for problems demonstrated by these trials.

# Related work, archiving, and first-phase decisions

Research notes for the **BM-native, LLM-first skill with a lightweight read-only inventory helper** version of Basic Memory Gardener (October 2026). These are design references, not dependencies. Check the installed Basic Memory version before assuming a specific tool signature.

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

## Capture continuity versus canonical knowledge

The [capture and gardening design](capture-lifecycle-design.md) distinguishes a
mutable session handoff from reusable canonical knowledge. The gardener
preserves original capture bodies, including completed sources, and reports
topic outcomes rather than using line removals as a success metric. A
capture, active or finished, can receive successful review metadata while its
body, identity and path remain unchanged. Capture files do not shrink; the
benefit is that future questions can read smaller reusable subject notes.

One gardener maintains subject notes; sessions maintain their own captures.
No new completion/resumption workflow, writer compaction feature or lock
protocol is needed. Existing capture status labels are preserved, not used to
relax body protection. The owning writer keeps normal same-note synthesis and
preserves `last_gardened_at`, advancing `modified` for its actual updates.
Role metadata guides retrieval but must not exclude legacy notes. Imported
evidence stays immutable. A draft/unmerged note or self-declared current marker
does not prove successful processing; deferred or unverified work leaves the
source review stamp unchanged. No snapshot service or separate archive project
is introduced.

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

`knowledge_status: superseded` is appropriate only when a verified successor exists; otherwise describe the actual reason. The [customized capture skill](../skills/memory-capture/SKILL.md) does **not** add `archived: false`; it guards against overwriting a checkpoint that has been explicitly archived. The [gardener skill](../skills/memory-garden/SKILL.md) handles archiving of ordinary editable non-capture notes, preserving original sources and relations. Capture retirement is outside this gardening version.

**Ordinary retrieval:** search without an archive equality filter, then exclude `archived: true` hits from current answers. `metadata_filters={"archived": False}` would hide normal unmarked notes. Explicit archived:true searches are **discouraged except when the user specifically requests historical information, old-vs-new comparison, or another historical perspective**. The gardener's own internal maintenance review is a separate exception. If archived notes dominate results, use alternate queries/pagination or combine separate missing-field and explicit-false searches; don't silently fall back to archived notes as current authority.

**Lightweight incremental review:** Basic Memory's canonical note timestamp is top-level YAML frontmatter `modified`, projected as indexed `updated_at`. For legacy notes without explicit `modified`, BM may derive `updated_at` from filesystem mtime; the indexed value alone does not prove the note carries a canonical timestamp ([BM domain model](https://github.com/basicmachines-co/basic-memory/blob/main/docs/DOMAIN_MODEL.md)). The gardener compares **explicit, valid, offset-aware `modified`** with its own `last_gardened_at` watermark, not filesystem mtime or Git commit dates. Missing/invalid/duplicate canonical timestamps remain eligible; do not invent historic timestamps to make notes skippable. The [bundled PowerShell script](../skills/memory-garden/scripts/Find-GardenCandidates.ps1) reads only frontmatter and file sizes/paths for local broad inventories; no hash manifest or private database. Successfully processed authored captures, including active ones, receive a metadata-only review stamp; preserve their complete bodies. Set real edit/review times consistently so the stamp itself does not trigger endless re-review. Immutable sources and already archived captures are not stamped without separate authority. Capture writers preserve the stamp and maintain real `modified` for their updates.

This is the **lowest-risk identity/relationship policy**: metadata changes without moves leave paths and link targets stable. Gardening uses the **already registered BM project's** MCP read/search/graph/edit operations, not a second project or worktree; verify BM indexing and graph after edits. Archive state is not automatically propagated to graph expansion. Run one gardener and preserve capture bodies; BM revision preconditions protect individual edits but do not make a multi-note pass atomic.

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
9. Confirm a successfully stamped, unchanged authored note with explicit canonical `modified` is skipped by the helper; a later substantive edit that advances `modified` makes it eligible. No filesystem/Git timestamp or post-stamp tolerance is used.
10. Confirm successful full processing stamps an active capture without changing its body; partial, deferred or failed processing leaves its old stamp unchanged. A later capture update preserves the stamp and advances `modified`.
11. Confirm a note missing explicit `modified` remains eligible even if BM indexed `updated_at` is present (it may be an mtime fallback); invalid/naive timestamps are not silently assumed comparable.
12. Confirm compact `search_notes` and compact `build_context` omit note bodies, `read_note(include_content=False)` provides identity/checksum without body, and bounded `read_note` reads just the required lines.
13. Confirm guarded BM `edit_note` refuses a stale `expected_checksum` and a successful change becomes searchable/linked after indexing catches up.
14. Confirm no Git worktree, duplicate BM project/index, branch switch, or automatic Git commit is created by the gardener.

## BM-native retrieval and mutation cost

For gardening, **discover before loading note bodies**:

- `search_notes(compact=True, page_size=...)` returns identities, metadata, relations, scores, and pagination without content/matched chunks; use text/title/permalink search for exact anchors and hybrid/vector only for conceptual discovery when enabled.
- `list_directory` and `recent_activity` provide paged orientation. For a local broad inventory, the bundled PowerShell helper reads top-level frontmatter rather than all note bodies.
- `read_note(include_content=False, output_format="json")` returns the note's title, permalink, path, full checksum, and indexed `updated_at`, **not** its complete frontmatter. Use a small `read_note(start_line=1, end_line=...)` to confirm explicit `modified`, and bounded ranges or `bm grep` for targeted evidence.
- `build_context(depth=1, compact=True, max_related=...)` explores the relevant graph neighborhood without loading note bodies or observation lists.
- `edit_note` supports targeted section/phrase edits, merged frontmatter metadata, and `expected_checksum` for revision-safe updates. Use `write_note` for new notes or necessary whole-note rewrites; verify readback and index/relations.

These optimizations reduce **LLM context volume**, not necessarily the number of server-side operations. Do not issue extra searches/reads if a modest single read would be cheaper. Use the installed BM version's actual tool schema.

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
- Does the canonical-frontmatter timestamp inventory script meaningfully reduce unnecessary repeat review without misclassifying missing timestamps?
- Which repeated mistakes, if any, justify additional scripting without introducing a new state system?

Only build a service/pipeline for problems demonstrated by these trials.

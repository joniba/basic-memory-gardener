# Captures, subject notes, and incremental gardening

**Status:** simplified policy candidate for review. It replaces the earlier
completion/resumption and writer-compaction proposal. External ChatGPT
consultation is pending because the available routes require authentication;
no review material was delivered. Source checks and independent code review
are not a claim of successful gardening in a real Basic Memory corpus.

## 1. Whole-system design

Two existing LLM skills share one Basic Memory corpus. `memory-capture` maintains
one resumable account of a working thread. `memory-garden` extracts reusable
knowledge into canonical topic notes and maintains those notes over time.
Ordinary retrieval chooses the appropriate role rather than treating every
matching note as an equally authoritative current account.

Sessions maintain their own captures; one gardener maintains reusable subject
notes. The gardener preserves every capture body, active or finished. Its only
capture edit is successful review metadata, so unchanged sources can be
skipped later. It never replaces a capture with a pointer-only stub. A
navigation companion is optional, not a third mandatory storage layer.

Capture files do not shrink. The benefit is that future questions can read a
smaller subject note instead of a whole session. Normal capture synthesis
continues, but shortening captures because knowledge was extracted is outside
this gardening version.

No service, MCP server, new database, snapshot store, mutation engine, periodic
job, or bridge-trigger change is introduced. The bundled PowerShell helper is
read-only discovery; it reports advisory capture-body protection, not permission
to edit.

| Component | Responsibility | Not its responsibility |
| --- | --- | --- |
| Capture writer | Same-thread synthesis; preserve review stamp; update real modification time | Gardening, advancing review stamps, new completion/resumption workflow |
| Gardener | Topic coverage, subject-note maintenance, successful review timestamps | Changing capture bodies/paths, shortening captures, overwriting imported evidence |
| Retrieval guidance | Canonical-first current questions; capture-first continuation/history | Certifying truth from role, archive metadata, or search rank |
| Inventory helper | Explicit timestamp comparison and advisory identity/protection hints | Editing notes, deciding knowledge quality or granting write authority |

## 2. Backward-compatible identity and metadata

New captures use `note_role: session_capture`.
New topical notes may use `note_role: canonical_topic`; imported evidence can
use `note_role: source_evidence`. Established role conventions and paths are
preserved rather than mass-normalized.

The stable `thread_id` belongs only to its capture. Topical notes can refer to
the source with `source_thread_id` and an exact source link, never copy the
capture's thread key. A legacy `thread_capture_and_project_index` remains a
capture, not an automatically writable subject note.

Legacy `capture_status` fields are preserved, not created or transitioned.
Whether a source says active, completed, something unfamiliar, or nothing
does not change its body protection or require a special resumption decision.
The helper reports raw legacy status only as a compatibility hint.

Role, currency, retirement and review are different:

- `note_role` describes intended use, not verified truth.
- `knowledge_status` describes currency supported by evidence.
- `archived: true` records deliberate retirement from current use.
- `modified` and `last_gardened_at` retain their existing timestamp meanings.

No default `archived: false`, lifecycle backfill, or duplicated project is added.

## 3. Capture review timestamps

Reuse `last_gardened_at`; do not introduce a second `gardened_at` convention.
Compare it with explicit top-level `modified`, using valid offset-aware times:

| Stored state | Ordinary next pass |
| --- | --- |
| `modified <= last_gardened_at` | Skip deep re-review, including equality and equivalent offsets |
| `modified > last_gardened_at` | Review the changed capture |
| Missing, invalid or duplicate timestamp | Keep eligible; do not guess |
| Unterminated frontmatter | Keep eligible and resolve the malformed header before editing |

Do not use filesystem modification time, Git time or an indexed `updated_at`
that may be a fallback for missing canonical `modified`. Relevant changed
evidence or an explicit deep request may justify revisiting an unchanged note.

In apply mode, stamp an authored, unarchived capture only after its whole
in-scope processing and destination verification succeed. An already-covered
topic counts after inspecting its actual home. Partial, deferred, failed,
sampled or proposal-only work leaves the source stamp unchanged. Audit and
plan never stamp. Keep outcomes in the report, not in the capture body.

Use a metadata-only BM edit with supported revision preconditions. Preserve the
complete body, identity, path and unrelated metadata. The stamp is itself a
real edit: set `modified` and `last_gardened_at` consistently to its actual
offset-aware edit/review time where supported, then read back and verify the
body and `modified <= last_gardened_at`. A writer-generated modification time
must not cause an endless review loop. If the writer cannot save a consistent
pair, report the limitation and keep the note eligible; never invent past or
future dates to make it skippable.

The capture writer preserves an existing gardening stamp exactly and advances
`modified` for its actual summary updates. It never creates, advances or clears
the review stamp. This makes later content changes eligible again. Missing
timestamps on legacy notes remain unknown until a real edit provides them.

Imported evidence remains immutable, including sources with capture-like
metadata. Already archived captures are read-only without separate authority.
Neither ordinary capture nor gardening silently unarchives or duplicates them.

## 4. Topic decomposition is required reasoning, not file churn

For an explicit deep review of a mixed capture, inspect all substantive topics
in the selected scope. Progressive reads are preferred, but a sample is not a
complete review. Each independently useful topic receives one outcome:

1. Already covered: name and verify the existing canonical home.
2. Update: integrate into an inspected existing canonical home.
3. Create: add a focused note only when the topic has no suitable home.
4. Defer: state the evidence, scope, conflict, or uncertainty blocking promotion.

Routine activity can be explicitly judged not durable. Topic notes preserve
decisions, rationale, exceptions, limitations, and evidence rather than just
headlines. Canonical identity belongs to a topic across sessions; do not create
a duplicate set per discovering thread.

The report lists topic outcomes and actual coverage. It is not a new permanent
manifest and must not be written into an active capture by the gardener.
Large-note size is a discovery signal, not a splitting threshold or deletion
target. A long, focused note can remain focused and complete.

## 5. Verify useful subject notes

Before claiming successful processing, read the actual destination in the
registered authoritative BM project. Verify relevant content, rationale,
limitations, source identity and links; confirm indexing and answer a realistic
topic question without reading the whole capture. A `current` marker, link,
accepted write, proposed file or unmerged PR alone is not enough. Compare
relevant changed evidence rather than assuming a newer timestamp proves truth.

Preserve source dates and observed revision metadata; re-read relevant source
material when revision data is missing. Never invent a historical timestamp.
Verification decides whether work succeeded and can be stamped, not whether
the gardener may prune a source. Capture bodies stay complete in all cases.

## 6. Simple ownership and preservation

Run one gardener at a time. No capture pause, maintenance-window requirement,
new locking protocol or capture completion/resumption workflow is introduced.
Still use supported checksum checks for individual edits. On an actual
conflict, ambiguous identity or failed indexing, stop that edit and report
unfinished work without a new source stamp; never force an overwrite.

Ordinary editable non-capture notes can be deliberately archived in place when
genuinely superseded. Gardening does not archive captures. Separate explicit
capture retirement is outside this version. Imported originals remain
immutable; no source deletion, move, pointer-only replacement, automatic
unarchive or Git-history-only provenance is introduced.

## 7. Retrieval contract

For current-topic questions, prefer verified canonical topic notes; inspect
relevant source passages when needed. For continuation, history, or why a
decision changed, identify the correct capture or evidence source.

Do not use a role equality filter that hides legacy notes. A canonical note
can be older than its source, and a source can have stale assertions; compare
authority, dates, revisions, and uncertainty. Follow evidence rather than
declaring everything in an original true.

Search and graph expansion can return archived notes. Current answers exclude
archived authority on inspection, while explicitly historical requests may use
it. The helper and policy do not change BM's search ranking or filtering.

## 8. Implementation increments and rollout

Align both skills, helper, retrieval guidance, README and fictional inputs with
this design. Run helper and policy regressions; obtain independent code and
public-privacy reviews before publishing the feature branch. Keep operational
BM acceptance, installation, migration and merge separately reviewable.

The plugin packages the skills but does not overwrite a higher-priority
standalone capture skill. Deployment must inspect effective paths before
claiming this metadata contract is active. Updating public source is not
permission to replace installed skills or edit real BM records.

## 9. Validation and remaining consultation

Automated tests exercise the read-only helper against synthetic frontmatter,
timestamp comparisons, legacy metadata, script immutability, bundled paths, and
cross-document policy consistency. They do **not** prove LLM semantic
decomposition or lossless promotion.

The [recorded source-only tabletop review](../tests/capture-lifecycle-scenarios.md#recorded-source-only-tabletop-review-2026-10-12)
exercises fictional topic coverage and an earlier conditional handoff. That
handoff is historical, not part of this simplified version. It is a
same-author reasoning check, not independent consultation or operational BM
verification. It preserves uncertainty about unregistered/unmerged destinations
and documents remaining acceptance rather than treating helper tests as proof.

The current manual scenarios test unchanged capture bodies, successful stamps,
ordinary repeat-run skipping, later capture updates, incomplete work, immutable
sources, archive guards and useful retrieval. A successful operational trial
must account for all useful topics, preserve source bodies, demonstrate smaller
realistic reads and verify real BM metadata/index behavior. No live corpus
trial is claimed by helper tests.

Independent ChatGPT critique remains an unmet consultation step, not a signoff
requirement or permission gate that transfers decisions away from the
maintainer. Questions to resolve when authentication is available:

- Are subject notes complete enough to answer useful questions and retain why?
- Does the simple review-stamp rule avoid skipped unfinished work and repeat loops?
- Is source/subject-note authority clear enough to avoid duplicate current truth?

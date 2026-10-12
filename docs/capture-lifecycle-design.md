# Capture lifecycle and canonical knowledge

**Status:** implemented policy candidate for review. External ChatGPT
consultation is pending because the research browser requires authentication;
no source documents or prompt have been submitted. This document records the
maintainer's decisions, not a claimed external endorsement.

## 1. Whole-system design

Two existing LLM skills share one Basic Memory corpus. `memory-capture` maintains
one resumable account of a working thread. `memory-garden` extracts reusable
knowledge into canonical topic notes and maintains those notes over time.
Ordinary retrieval chooses the appropriate role rather than treating every
matching note as an equally authoritative current account.

The gardener preserves capture originals. The capture writer may synthesize
its own active account, retaining important unpromoted information while
replacing repeated, verified topical explanations with concise context and
links. Completed sources remain complete; they are not replaced by pointer-only
stubs. A navigation companion is optional, not a third mandatory storage layer.

No service, MCP server, new database, snapshot store, mutation engine, periodic
job, or bridge-trigger change is introduced. The bundled PowerShell helper is
read-only discovery; it reports advisory role/lifecycle protection, not permission
to edit.

| Component | Responsibility | Not its responsibility |
| --- | --- | --- |
| Capture writer | Same-thread continuity, current synthesis, explicit completion/resumption | Automatic topic integration, archive decisions, changes to other threads |
| Gardener | Topic coverage, promotion, canonical maintenance, deliberate non-live retirement | Mutating potentially active captures or overwriting source evidence |
| Retrieval guidance | Canonical-first current questions; capture-first continuation/history | Certifying truth from role, archive metadata, or search rank |
| Inventory helper | Canonical timestamps and conservative role/lifecycle hints | Detecting all live writers or implementing promotion |
| User/owning writer | Completion/resumption authority and maintenance coordination | Being silently replaced by a timestamp heuristic |

## 2. Backward-compatible identity and metadata

New captures use `note_role: session_capture` and `capture_status: active`.
New topical notes may use `note_role: canonical_topic`; imported evidence can
use `note_role: source_evidence`. Established role conventions and paths are
preserved rather than mass-normalized.

The stable `thread_id` belongs only to its capture. Topical notes can refer to
the source with `source_thread_id` and an exact source link, never copy the
capture's thread key. A legacy `thread_capture_and_project_index` remains a
capture, not an automatically writable canonical note.

`capture_status` has two valid values: `active` and `completed`. Reopening is
a transition to `active`, not a permanent third state. A missing, invalid, or
unfamiliar status on a capture means **potentially active**. Never infer
completion from age, process absence, a task marked done, a directory, a
gardening watermark, or the end of a model turn.

Lifecycle, authority, currency, and retirement are independent:

- `capture_status` describes thread continuity.
- `note_role` describes intended use, not verified truth.
- `knowledge_status` describes currency supported by evidence.
- `archived: true` records deliberate retirement from current use.
- `modified` and `last_gardened_at` retain their existing timestamp meanings.

No default `archived: false`, lifecycle backfill, or duplicated project is added.

## 3. Ownership and lifecycle transitions

| Existing capture | Current instruction | Allowed behavior |
| --- | --- | --- |
| Active or unknown | Ordinary authorized capture | Same-note synthesis by its writer |
| Active or unknown | Gardener apply | Read/extract only; no body, metadata, stamp, rename, move, or archive |
| Active | Explicit completion confirmation with coordination | Writer records completed; turn completion alone is insufficient |
| Completed, unarchived | Gardening with confirmed writer coordination | Preserve complete body; promote and apply approved lifecycle/review metadata |
| Completed, unarchived | Explicit user request to resume that thread | Recheck revision, set active, synthesize same identity |
| Completed, unarchived | Automatic checkpoint only | Stop with a lifecycle diagnostic; no silent reopen or duplicate |
| Archived | Normal capture or automatic checkpoint | Stop; no overwrite, unarchive, or duplicate |
| Archived | Explicit reactivation authority | Preserve identity/provenance, clear retirement deliberately, set active |

Completion does not imply archival. A completed thread may remain useful as
continuity or decision evidence. If writer coordination is uncertain, the
gardener stays plan-only on that capture. Even completed notes can be reopened:
explicit status is not a substitute for checking concurrent changes.

The existing archived-capture guard remains stronger than ordinary resumption:
"continue" does not silently authorize unarchiving a deliberately retired
record. Exact thread lookup includes archived notes so it cannot create a
second capture by hiding the first.

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

## 5. Verified promotion and safe writer compaction

Promotion is available for compaction only after the writer verifies:

- The exact destination exists in the registered authoritative BM project,
  rather than only a proposed branch, patch, pending write, or unmerged PR.
- The note is not archived and its relevant content actually covers the source
  topic, including important rationale, uncertainty, and boundaries.
- Provenance identifies the source capture and, where practical, the relevant
  section and actual source revision metadata. Record only observed values.
- Readback and indexing succeed, important links resolve, and a realistic topic
  question can be answered without reading the entire capture.
- Relevant source or destination changes since review have been considered;
  a changed timestamp alone neither invalidates nor certifies every fact.

A `current` marker, link, watermark, receipt, Git commit, or accepted tool write
alone is not sufficient. An indexed `updated_at` can be an mtime fallback.
Missing source revision data requires re-reading the relevant source material,
not inventing a historic `modified` or building a hash queue.

The capture writer can then keep a compact, substantive handoff:

- What the thread concerns and its latest settled outcome.
- Canonical links with enough context to make the handoff useful.
- Open work, blockers, constraints, action-specific authority, and next step.
- Unique evidence, exceptions, or reasoning not safely represented elsewhere.

The writer synthesizes its own active account; it does not turn it into a
pointer-only list or run the gardener automatically. A destination that is
missing, archived, stale for the claim, still draft/unmerged, or incompletely
indexed blocks pruning of that material. So does unresolved unique evidence.
Keep the needed substance and state the limitation rather than trimming for
size. Partial promotion permits compaction only of the verified portions.

**Retention boundary:** "preserve the complete original" forbids the gardener
from replacing its input capture with summaries or pointers. It does not turn
the writer's already-mutable current-state synthesis into an immutable
transcript. Normal writer synthesis can remove obsolete working state and
verified repetition, but not silently discard intentionally retained unique
evidence. If safe preservation is uncertain, leave that material intact. This
version does not promise snapshots of every intermediate capture revision.

## 6. Completed-source retention and archival

On a completed capture, promote useful topics while preserving the complete
source body and stable identifiers. Keep a capture current for continuation
only where that role is still justified; do not confuse that with canonical
topic authority.

Retire only with explicit scope, a reason, non-live coordination, and verified
destinations for knowledge that current retrieval should use. Use in-place
archive metadata and meaningful source/successor links; do not claim that one
topic note supersedes every topic of a multi-topic capture. Where coverage is
partial, retain the source and document what is still unmatched.

No source deletion, move, pointer-only replacement, automatic unarchive,
source-date fabrication, or Git-history-only provenance is introduced.

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

1. Record this contract and keep lifecycle unknown-by-default for legacy notes.
2. Update gardener decomposition/coverage and preserve-original instructions.
3. Expose advisory capture/source protection in read-only inventory.
4. Update capture creation, promotion-aware synthesis, completion/resumption and
   existing archive guard; keep stable lookup and unrelated metadata.
5. Align retrieval snippet, README, ecosystem rationale, and synthetic scenarios.
6. Run helper and policy-consistency regressions, then a reviewed LLM scenario.
7. Obtain independent privacy review of outgoing public content/metadata, publish
   a feature PR, and leave activation/migration/merge separately reviewable.

The plugin packages the skills but does not overwrite a higher-priority
standalone capture skill. Deployment must inspect effective paths before
claiming the coordinated contract is active. Updating public source is not
permission to replace installed skills or edit real BM records.

## 9. Validation and remaining consultation

Automated tests exercise the read-only helper against synthetic frontmatter,
timestamp/lifecycle compatibility, script immutability, bundled paths, and
cross-document policy consistency. They do **not** prove LLM semantic
decomposition or lossless promotion.

The [recorded source-only tabletop review](../tests/capture-lifecycle-scenarios.md#recorded-source-only-tabletop-review-2026-10-12)
exercises fictional topic coverage and a conditional handoff. It is a
same-author reasoning check, not independent consultation or operational BM
verification. It preserves uncertainty about unregistered/unmerged destinations
and documents remaining acceptance rather than treating helper tests as proof.

The manual synthetic scenarios test active/unknown/completed/reopened/archived
captures, partial and unavailable promotion, changing evidence, concurrency,
and retrieval. A successful LLM trial must account for all useful topics,
preserve original evidence, and demonstrate smaller realistic reads. No live
corpus trial is claimed by helper tests.

Independent ChatGPT critique remains an unmet consultation step, not a signoff
requirement or permission gate that transfers decisions away from the
maintainer. Questions to resolve when authentication is available:

- Is explicit completion/resumption clear without confusing automatic checkpoints?
- Does the writer/gardener retention boundary preserve useful history without
  forcing a new snapshot system?
- Are promotion checks sufficient for draft or mutable destinations?
- Is source/canonical authority clear enough to avoid duplicate current truth?
- Can any metadata or procedure be removed without losing the safety boundary?

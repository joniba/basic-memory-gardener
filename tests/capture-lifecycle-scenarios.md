# Synthetic capture lifecycle acceptance

These scenarios contain no real corpus records or user/machine identifiers.
They are a manual LLM review specification, **not an automated LLM acceptance
result**. `test_policy.py` verifies helper behavior and policy consistency only.
Do not claim these scenarios ran merely because those tests passed.

## 1. Active multi-topic source

Input: `Find-GardenCandidates-tests/captures/active.md`, expanded with three
synthetic topics: a retry decision, timeout measurement, and unresolved rollback authority.
The owner is still working. The canonical retry note covers only the first.

Expected: inspect every topic; verify the retry home, promote the timeout
finding if justified, and defer unresolved authority explicitly. Do not change
the original capture body, metadata, path or thread key. Do not certify full
coverage from the single canonical match. Record the outcome per topic.

## 2. Writer-owned partial compaction

Input: same source, an authorized current writer, a verified retry canonical
available in the registered corpus, and an unmerged timeout proposal.

Expected: the writer can replace repeated retry exposition with concise
context/link. Retain the timeout substance, unique evidence, open authority,
and next step. The result is a useful handoff, not a pointer-only stub.
An unmerged PR is not a promotion receipt.

## 3. Completed source

Input: `Find-GardenCandidates-tests/captures/completed.md`, explicit owner
confirmation and no overlapping writer. Two reusable topics lack canonical homes.

Expected: promote into topic-based homes, never one duplicate set per session.
Keep the complete source body. Completion does not archive it automatically.
Re-read/index targets and demonstrate a realistic retrieval answer.

## 4. Legacy, invalid, and conflicting lifecycle

Input: legacy role, no status, unfamiliar `reopened`, duplicate active/completed
fields, conflicting archive markers, or an unterminated frontmatter header.

Expected: potentially active and read-only to the gardener. Do not infer
completion from age, process absence, a timestamp or a task marked done.
The helper's `Protection` is a warning, not a substitute for writer coordination.

## 5. Resumption

Input: completed unarchived capture and an explicit request to resume that
thread, followed separately by an automatic checkpoint with no resume request.

Expected: explicit resumption rechecks revision and changes status to active
while retaining identity/provenance. Automatic capture stops with a lifecycle
diagnostic rather than silently reopening or creating a duplicate. Reassess
relevant canonical claims if the resumed thread changes the evidence.

## 6. Deliberate retirement

Input: completed capture, verified topic destinations and owner-coordinated
retirement with rationale.

Expected: metadata-only archival in place; full source and exact identity
remain retrievable. Record unmatched coverage and do not claim one topic
supersedes an entire mixed source. Normal notes omit archived rather than false.

## 7. Archived checkpoint

Input: `Find-GardenCandidates-tests/captures/archived.md` and automatic capture.

Expected: exact thread lookup still finds it. Stop before write; no overwrite,
silent unarchive, or duplicate thread key. Explicit archive reactivation is a
separate authority from ordinary continuation.

## 8. Evidence and destination changes

Input: a target marked current whose supporting source changed after the
earlier review, or whose indexing/readback now fails.

Expected: compare relevant evidence, not just dates. A marker/receipt alone
does not justify pruning. Re-read affected source material when revision
metadata is absent; do not invent timestamps or automatically invalidate every
unrelated claim. Preserve needed capture content and report the limitation.

## 9. Concurrent write

Input: source/target changes between inspection and mutation.

Expected: stale checksum is rejected where supported. Without revision
preconditions, recheck exact identity/content and stop conflicting edits.
No multi-note atomicity is claimed; preserve originals and truthful partial
results rather than marking incomplete work gardened.

## 10. Imported evidence and retrieval

Input: `Find-GardenCandidates-tests/sources/evidence.md` and canonical notes
linked to archived historical evidence.

Expected: imported original unchanged; derive a targeted guide only where useful.
Current-topic questions prefer canonical authority with relevant source
drill-down; continuation/history queries use the capture/evidence. Inspect
archive state on graph neighbors; no role filter hides legacy knowledge.

## Required reviewed-run record

For any actual LLM trial report the scenario, exact source/destination identities,
topic outcomes, preserved unique rationale/caveats, unchanged protected inputs,
actual retrieval result, and deferred actions. Record what the writer did
separately from what the gardener did. Keep synthetic outputs separate from
production knowledge and do not infer deployment from source tests.

## Recorded source-only tabletop review (2026-10-12)

The implementation assistant applied the candidate contract to fictional inputs.
This is a same-author LLM reasoning exercise, not an independent assessment,
ChatGPT consultation, registered-project run, or executed MCP mutation trial.
Fixture bodies were expanded as test setup before the review; their normalized
content was unchanged during the review. No real corpus records were used.

### Concrete topic coverage

The source is `Find-GardenCandidates-tests/captures/active.md`
(Active synthetic investigation). The existing content candidate is
`Find-GardenCandidates-tests/topics/canonical.md` (Synthetic canonical retry decision).
Reading both confirms that the candidate
covers the retry conditions, limits, rejected alternative, rationale and write
authority boundary, but not the other two topics.

| Source topic | Observed plan outcome | Home or retained limitation |
| --- | --- | --- |
| Retry decision | Defer authoritative verification; do not duplicate | The existing candidate covers the content, but repository presence/provenance is not BM registration, indexing or a promotion receipt. |
| Initialization deadline | Create a topic proposal, not an applied note | A reusable budgets topic should retain 18/10/30-second fictional evidence, separate initialization from tool execution, and avoid claiming the original cause or config authority. Its unmerged state blocks pruning. |
| Rollback authority | Defer resolution; preserve source | Write completion is unknown. Retain partial output and the read-only receipt check followed by owner approval; do not turn the read policy into write/rollback permission. |

No outcome certifies the capture as fully promoted. The active source is not
stamped, renamed, archived or replaced by the gardener.

### Smaller-note question

Question: "In this fictional policy, when can a read retry, how many times, and
does that permit replaying a write?"

Answer from the content candidate alone: retry an idempotent read only after
a connection reset before any response bytes. Use three attempts total with
100 ms and 200 ms waits. Do not retry invalid requests, permission denials,
missing resources, writes or partial responses. This does not authorize write
replay or rollback; the limits prevent mixed streams and unbounded retry cost.

The LF-normalized source is 2,251 bytes and the candidate 1,019 bytes: a 54.7%
smaller complete-file read for this question. This is a fixture content
measurement, not token/latency evidence, a production benchmark, or proof of
BM discovery/indexing.

### Partial writer handoff

Only for this hypothetical branch, the trusted test setup stipulates that the
retry destination passed authoritative readback/index/link verification and
has not changed. This is not a receipt asserted by the source, and no such
checks were performed against a real BM project. The timeout proposal remains
unmerged and rollback outcome/authority remain unresolved.

The writer's resulting **body preview**, not a saved note, is:

> This thread settled the read retry policy in [[Synthetic canonical retry
> decision]]; use that note for conditions, limits and rationale. It does not
> authorize write replay.
>
> The unmerged initialization finding remains here: fictional readiness after
> 18 seconds exceeded a 10-second budget, while 30 seconds worked. This proves
> that fixture's boundary, not the unrelated original cause. Initialization
> and tool budgets differ; no real configuration change is authorized.
>
> The export write was accepted but its completion is unknown. Retain partial
> output, check the receipt read-only, and obtain owner approval before write
> retry, deletion or rollback. Read/timeout permission does not grant that
> authority.

Only verified retry repetition is compacted in this preview. The timeout
finding, limits on causal claims, unknown write outcome and exact next-step
authority remain substantive. An actual authorized writer must preserve the
same identity and unrelated frontmatter, maintain the real edit time, and not
create a gardening stamp as a side effect. The gardener did not write this
preview into the active source.

### Lifecycle and error decisions

These are reviewed policy decisions under the listed test inputs, not evidence
of executed mutations or complete semantic promotion for every scenario.

| Scenario | Review disposition |
| --- | --- |
| Completed source | The lifecycle fixture alone lacks the two topics' substance; defer that promotion, preserve its full body and do not infer archive. |
| Legacy/malformed lifecycle | Potentially active or protected retirement, never edit authority. The actual helper regressions cover duplicate fields and unterminated headers. |
| Explicit resumption | Would recheck the same identity/revision and transition to active; an automatic checkpoint alone stops instead. |
| Deliberate retirement | Requires justified coverage and coordination; only a metadata proposal is warranted without actual destination verification. |
| Archived checkpoint | Stop before write, retain the original lookup identity, require explicit reactivation rather than duplicate or silently unarchive. |
| Changed evidence | Re-read affected source/target claims and retain needed detail; a prior marker is insufficient, and unrelated claims are not automatically invalidated. |
| Concurrent write | Stop a conflicting edit; use atomic preconditions only where supported and do not represent immediate rechecks as atomicity. |
| Imported evidence/retrieval | Keep the imported fixture unchanged; prefer verified canonical authority for current questions and inspect archived graph neighbors separately. |

### Preservation and remaining acceptance

After the review, LF-normalized SHA-256 comparisons confirmed no change to the
active source, retry candidate, archived capture or imported evidence. Paths
below are relative to `Find-GardenCandidates-tests/`:

| Fixture | SHA-256 |
| --- | --- |
| captures/active.md | d3dd60a020b66021d47c7e66d90f7fbdd4fc64504e047e9b0c1807481e08db08 |
| topics/canonical.md | 21e5aa154fbaf7bec903cf3c1f6d6577f6418141822b3aa8a4df5f8d6a5f1707 |
| captures/archived.md | e410f63bbc57cae58cca9cb6b2c1cf00ec7cd1d8eba8942f8d399c706f76facf |
| sources/evidence.md | c31ac848420c60c1b914db0f876349e4cb64e26543133e166a313a0332fe5572 |

The truthful result is a reviewed coverage plan, a bounded content answer and
a conditional handoff, not verified live promotion. ChatGPT critique and an
authorized operational BM trial remain unperformed. Do not infer installation,
real archive/resumption behavior or a complete deep-gardening pass from this
exercise.

# Synthetic capture lifecycle acceptance

These scenarios contain no real corpus records or user/machine identifiers.
They are a manual LLM review specification, **not an automated LLM acceptance
result**. `test_policy.py` verifies helper behavior and policy consistency only.
Do not claim these scenarios ran merely because those tests passed.

## 1. Active multi-topic source

Input: `fixtures/captures/active.md`, expanded with three synthetic topics:
a retry decision, timeout measurement, and unresolved rollback authority.
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

Input: `fixtures/captures/completed.md`, explicit owner confirmation and no
overlapping writer. Two reusable topics lack canonical homes.

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

Input: `fixtures/captures/archived.md` and automatic capture.

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

Input: `fixtures/sources/evidence.md` and canonical notes linked to archived
historical evidence.

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

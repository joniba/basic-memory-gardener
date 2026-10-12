---
title: Active synthetic investigation
note_role: session_capture
thread_id: example-active-thread
capture_status: active
modified: '2026-01-02T10:00:00Z'
last_gardened_at: '2026-01-01T10:00:00Z'
---

All identities, timings and events below are fictional test inputs, not
observations from an actual service or corpus.

## Retry decision

Retry an idempotent read only when a connection resets before any response
byte is received. Permit three attempts total, with waits of 100 ms and
200 ms before the second and third attempts. Do not retry invalid requests,
permission denials, missing resources, writes, or interrupted partial responses.

The byte boundary matters: repeating a partially consumed response could mix
two result streams. Unlimited retries were rejected because they hide persistent
failure and consume the caller's whole work budget. This is a read policy, not
authority to replay a write.

The existing Synthetic canonical retry decision covers this policy. A
verification result for that destination is stipulated only in the partial
compaction tabletop scenario, not asserted by this source note.

## Initialization deadline finding

In a fictional controlled fixture, readiness after 18 seconds exceeded a
10-second initialization deadline. A 30-second deadline let the same fixture
initialize. This establishes the budget boundary for that fixture; it does not
identify the cause of an unrelated original failure.

Initialization and tool-execution budgets are different. A tool timeout must
not be assumed to extend initialization without measuring the actual client.
The topic proposal is still unmerged and unavailable in the authoritative
corpus. No real configuration change has been authorized.

## Unresolved rollback authority

A separate fictional export write timed out after the server accepted the
request. Its completion is unknown. Read retry permission does not authorize
write replay, deletion of partial output, or rollback.

Retain the partial result. The next step is a read-only receipt check, then
owner approval for any consequential operation. Do not reinterpret approval
to adjust a timeout as rollback authority. The owner still needs this uncertainty
and the authority boundary to resume safely.

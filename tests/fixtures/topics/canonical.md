---
title: Synthetic canonical retry decision
note_role: canonical_topic
source_thread_id: example-active-thread
modified: '2026-01-01T10:00:00Z'
last_gardened_at: '2026-01-02T10:00:00Z'
---

This is a fictional test destination, not a registered or verified BM note.
It refers to its source thread but does not own the capture identity.

## Read retry policy

For idempotent reads, retry a connection reset only before receiving any
response bytes: three attempts total, waiting 100 ms then 200 ms.
Do not retry invalid requests, permission denials, missing resources, writes,
or partial responses. Repeating a partial response risks mixing result streams;
unlimited retries hide persistent failure and exhaust the caller's work budget.
This rule does not authorize write replay or rollback.

## Provenance

The source is [[Active synthetic investigation]], section Retry decision,
with synthetic `source_thread_id: example-active-thread`.
That relationship is test input, not evidence that BM indexed or verified it.

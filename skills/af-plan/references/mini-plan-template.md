# Mini-Plan: <topic>

## Goal

Describe the intended outcome.

## Key decisions

- Decision 1: resolved direction and rationale

## Scope

- In scope

## Non-goals

- Out of scope

## Intended edits

- Repo or service
- Main change points

## Sequence diagram

Use a Mermaid sequence diagram when it clarifies request flow, ownership handoffs, rollout order, or system interactions. If a diagram would add no value, say so explicitly.

```mermaid
sequenceDiagram
    participant User
    participant Service
    User->>Service: Request
    Service-->>User: Response
```

## Implementation references

- Version-sensitive technology notes
- Official docs to reuse during implementation

## Automated verification

- Check 1

## Manual verification

- Check 1

## Traceability and risk

Use 1-3 concrete bullets. Each bullet must map to at least one of:

- a requirement and its phase, file, or verification
- a failure action: continue with bounded drift | return to planning | return to research | stop and ask
- a privacy/security impact, or `None identified` with rationale

Delete this section when it adds no traceability or decision value.

## Success criteria and exit conditions

- Criterion 1

# Artifact-First Boundary Checklist

Use this checklist before declaring research complete.

- Which repos are in scope?
- Which service owns the user-visible behavior?
- Which repo owns each contract or schema?
- Which services emit, consume, or transform the data?
- Which runtime boundaries are synchronous calls versus async events?
- Which environment or rollout constraints matter?
- Which tests, docs, or configs prove the current behavior?
- Which manifests, lockfiles, images, or configs establish the relevant framework or library version?
- If repo evidence is insufficient for API behavior, which official version-matched docs confirm it?
- What is still unknown, and does that block planning?

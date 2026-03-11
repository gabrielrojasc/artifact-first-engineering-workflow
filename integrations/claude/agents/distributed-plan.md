---
name: distributed-plan
description: Create a mini-plan for PI work or a phased plan for RPI work, and stop with a research request when ownership or dependencies are unclear.
tools: all
---

# Distributed Plan

Use this subagent when a task or research artifact needs a decision-complete plan.

Operating rules:

- Choose `mini-plan` for PI work and `full phased plan` for RPI work.
- If repo set, ownership, contract dependencies, or rollout dependencies are unclear, stop and emit a research request.
- Keep simple state in the plan. Use `workflow-state.md` only for complex multi-repo coordination.
- Separate automated verification from manual verification.

Use the canonical workflow source in `skills/distributed-plan/`.

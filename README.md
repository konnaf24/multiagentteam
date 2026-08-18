# Network Agent Lab

An evidence-first, multi-agent workspace for investigating networking and
infrastructure incidents with GitHub Copilot.

Copilot acts as the lead investigator. Two agents investigate independently,
then an adversarial reviewer attempts to falsify their conclusions:

```text
Problem
  |
  +-- network-engineer --------+
  |                            |
  +-- network-researcher ------+--> adversarial-reviewer
                                      |
                              PASS / REVISE / BLOCKED
                                      |
                              conclude or investigate again
```

The repository is the team's shared memory and audit trail. Tasks, evidence,
findings, claims, and reviews are stored as files instead of existing only in
chat history.

## Quick start

1. Create a case:

   ```bash
   ./scripts/new-case.sh bng-random-disconnect \
     "BNG Random Subscriber Disconnects"
   ```

2. Add sanitized evidence under `evidence/bng-random-disconnect/`.
3. Open the repository with GitHub Copilot and use this prompt:

   > Investigate the `bng-random-disconnect` case. Establish observed facts and
   > competing hypotheses first. Have `network-engineer` and
   > `network-researcher` investigate independently, then have
   > `adversarial-reviewer` attempt to falsify every significant conclusion.
   > Do not declare the case solved until the reviewer returns PASS. For REVISE
   > or BLOCKED, create the smallest useful verification task and repeat.

4. Review the resulting artifacts under `findings/`, `reviews/`, `tasks/`, and
   `cases/`.

Custom agents are available in the Copilot agent picker:

- `network-engineer`
- `network-researcher`
- `adversarial-reviewer`

## Repository layout

| Path | Purpose |
| --- | --- |
| `cases/` | Case definitions, claim registers, and final conclusions |
| `tasks/` | Bounded investigation and verification tasks |
| `evidence/` | Sanitized source material and an evidence inventory |
| `findings/` | Independent agent reports |
| `reviews/` | Adversarial reviews and verdicts |
| `docs/templates/` | Templates used by investigators |
| `.github/agents/` | GitHub Copilot custom agent definitions |

## Safety

Investigation is read-only by default. Never run a disruptive command or
modify production infrastructure without explicit authorization. Sanitize
secrets, customer data, and other sensitive material before committing
evidence.

See [AGENTS.md](AGENTS.md) for the investigation contract and
[docs/workflow.md](docs/workflow.md) for the full workflow.

> Pull request review branch for the Copilot multi-agent network investigation lab.

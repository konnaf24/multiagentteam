# Network Agent Lab

[![Validate repository](https://github.com/konnaf24/multiagentteam/actions/workflows/validate.yml/badge.svg)](https://github.com/konnaf24/multiagentteam/actions/workflows/validate.yml)

An evidence-first, multi-agent workspace for investigating networking and
infrastructure incidents with GitHub Copilot.

The core idea: one giant agent guessing at a root cause is unreliable. Instead,
two agents investigate a problem *independently*, an adversarial reviewer tries
to *falsify* their conclusions, and nothing is called "solved" until a claim
survives review with cited evidence.

## Contents

- [How it works](#how-it-works)
- [Why files instead of chat](#why-files-instead-of-chat)
- [Quick start](#quick-start)
- [The agents](#the-agents)
- [Repository layout](#repository-layout)
- [Evidence discipline](#evidence-discipline)
- [Validation](#validation)
- [Safety](#safety)

## How it works

GitHub Copilot acts as the **lead investigator**. It defines the problem,
splits it into bounded tasks, and delegates. Two specialists investigate in
parallel without seeing each other's tentative conclusions, then an adversarial
reviewer attempts to break every significant claim.

```text
                         Problem
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      network-engineer            network-researcher
      (bounded technical          (independent, alternative
       investigation)              explanations & RFCs)
              │                           │
              └─────────────┬─────────────┘
                            ▼
                   adversarial-reviewer
                (attempts to falsify claims)
                            │
                  ┌─────────┼─────────┐
                  ▼         ▼         ▼
                PASS     REVISE     BLOCKED
                  │         │         │
             conclude    create smallest useful
                         verification task, repeat
```

A claim only becomes a **verified conclusion** after the reviewer returns
`PASS`. `REVISE` and `BLOCKED` verdicts loop back into the smallest useful
follow-up task.

## Why files instead of chat

The repository *is* the team's shared memory and audit trail. Tasks, evidence,
findings, claims, and reviews are stored as files rather than living only in
chat history. That makes every conclusion traceable to a cited artifact,
survives across sessions, and can be reviewed like any other change.

## Quick start

1. Create a case:

   ```bash
   ./scripts/new-case.sh bng-random-disconnect \
     "BNG Random Subscriber Disconnects"
   ```

   This scaffolds `cases/`, `tasks/`, `evidence/`, `findings/`, and `reviews/`
   directories for the slug and fills in the case, claims, and first task from
   the templates.

2. Add sanitized evidence under `evidence/bng-random-disconnect/` and record
   its provenance in that folder's inventory.

3. Open the repository with GitHub Copilot and use a prompt like:

   > Investigate the `bng-random-disconnect` case. Establish observed facts and
   > competing hypotheses first. Have `network-engineer` and
   > `network-researcher` investigate independently, then have
   > `adversarial-reviewer` attempt to falsify every significant conclusion.
   > Do not declare the case solved until the reviewer returns PASS. For REVISE
   > or BLOCKED, create the smallest useful verification task and repeat.

4. Review the resulting artifacts under `findings/`, `reviews/`, `tasks/`, and
   `cases/`.

## The agents

The custom agents below appear in the Copilot agent picker and are defined in
[`.github/agents/`](.github/agents). The lead-agent behavior is defined in
[`.github/copilot-instructions.md`](.github/copilot-instructions.md).

| Agent | Role |
| --- | --- |
| `network-engineer` | Primary technical investigator (BGP, EVPN/VXLAN, MPLS, BFD, PPPoE/BNG/RADIUS, Junos/Linux, captures and logs). |
| `network-researcher` | Independent second opinion focused on protocol behavior, RFCs, vendor docs, timing/races, and alternative explanations. |
| `adversarial-reviewer` | Skeptic that challenges causation, hidden assumptions, missing evidence, and untested failure modes. |

## Repository layout

| Path | Purpose |
| --- | --- |
| `cases/` | Case definitions, claim registers, and final conclusions |
| `tasks/` | Bounded investigation and verification tasks |
| `evidence/` | Sanitized source material and an evidence inventory |
| `findings/` | Independent agent reports |
| `reviews/` | Adversarial reviews and verdicts |
| `docs/templates/` | Templates used by investigators |
| `docs/workflow.md` | The full investigation workflow |
| `theory/` | Background reading and the design rationale behind the lab |
| `scripts/` | `new-case.sh` scaffolding and `validate.sh` structure checks |
| `.github/agents/` | GitHub Copilot custom agent definitions |

## Evidence discipline

Every important statement is classified as exactly one of:

- **OBSERVED FACT** — directly present in a cited artifact or real test output.
- **INFERENCE** — a reasoned interpretation of observed facts.
- **HYPOTHESIS** — a testable possible explanation.
- **ASSUMPTION** — an unverified condition currently treated as true.
- **VERIFIED CONCLUSION** — a claim supported by evidence *and* passed by review.

Agreement between agents is **not** verification. See [AGENTS.md](AGENTS.md) for
the full investigation contract.

## Validation

A GitHub Actions workflow (and the same script locally) checks that the
required structure, agent definitions, and case scaffolding stay consistent:

```bash
./scripts/validate.sh
```

## Safety

Investigation is read-only by default. Never run a disruptive command or modify
production infrastructure without explicit authorization. Sanitize secrets,
customer data, and other sensitive material before committing evidence.

See [AGENTS.md](AGENTS.md) for the investigation contract and
[docs/workflow.md](docs/workflow.md) for the full workflow.

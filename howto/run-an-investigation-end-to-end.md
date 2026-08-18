# How to run an investigation end to end

This guide walks through a complete case in the Network Agent Lab, from an empty
slug to a closed case with a verified conclusion. It uses a worked example —
`bng-random-disconnect`, "BNG Random Subscriber Disconnects" — so you can see
exactly what each step produces.

For the underlying rules see [`AGENTS.md`](../AGENTS.md); for the reference
workflow see [`docs/workflow.md`](../docs/workflow.md).

## The loop at a glance

```text
                         Problem
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      network-engineer            network-researcher
              │                           │
              └─────────────┬─────────────┘
                            ▼
                   adversarial-reviewer
                            │
                  ┌─────────┼─────────┐
                  ▼         ▼         ▼
                PASS     REVISE     BLOCKED
                  │         │         │
             conclude    create smallest useful
                         verification task, repeat
```

A claim only becomes a **VERIFIED CONCLUSION** after the reviewer returns
`PASS`. `REVISE` and `BLOCKED` loop back into the smallest useful follow-up
task.

## Step 1 — Scaffold a case

```bash
./scripts/new-case.sh bng-random-disconnect "BNG Random Subscriber Disconnects"
```

This creates matching directories and starter files:

```text
cases/bng-random-disconnect/CASE.md
cases/bng-random-disconnect/CLAIMS.md
tasks/bng-random-disconnect/TASK-001.md
evidence/bng-random-disconnect/README.md
findings/bng-random-disconnect/README.md
reviews/bng-random-disconnect/README.md
```

The slug must be lowercase letters, numbers, and single hyphens. Reuse it
everywhere for this case.

## Step 2 — Add sanitized evidence

Drop artifacts (logs, captures, config) under `evidence/<slug>/` and record
provenance in that folder's `README.md` inventory. **Sanitize secrets, customer
data, and IPs before committing.**

Example `evidence/bng-random-disconnect/radius-acct.log`:

```text
2026-08-18T09:14:02Z Acct-Status-Type=Start User=subA NAS=bng01 Session=A1
2026-08-18T09:44:02Z Acct-Status-Type=Stop  User=subA NAS=bng01 Session=A1 Cause=Idle-Timeout
2026-08-18T09:14:31Z Acct-Status-Type=Start User=subB NAS=bng01 Session=B7
2026-08-18T09:44:33Z Acct-Status-Type=Stop  User=subB NAS=bng01 Session=B7 Cause=Idle-Timeout
```

Inventory row:

```text
| radius-acct.log | bng01 RADIUS accounting | 2026-08-18T10:00Z | sha256 | yes | User/IP masked |
```

## Step 3 — Complete the case definition

Fill `cases/<slug>/CASE.md`: problem, scope, symptoms, timeline, known facts,
unknowns, and constraints. **Describe symptoms — do not assume a cause.** Only
list facts that are directly supported by evidence.

## Step 4 — Investigate independently

Open the repository in GitHub Copilot. Copilot acts as the lead investigator.
Use a prompt like:

> Investigate the `bng-random-disconnect` case. Establish observed facts and
> competing hypotheses first. Have `network-engineer` and `network-researcher`
> investigate independently, then have `adversarial-reviewer` attempt to
> falsify every significant conclusion. Do not declare the case solved until the
> reviewer returns PASS. For REVISE or BLOCKED, create the smallest useful
> verification task and repeat.

The lead agent then:

1. Establishes facts and at least two competing hypotheses.
2. Writes bounded tasks under `tasks/<slug>/TASK-00N.md` (one question, named
   inputs, an expected output, a completion criterion).
3. Runs `network-engineer` and `network-researcher` **independently** — each
   writes a separate report under `findings/<slug>/` using
   [`docs/templates/FINDING.md`](../docs/templates/FINDING.md). Neither agent
   sees the other's tentative conclusion.

Each finding classifies statements as `OBSERVED FACT`, `INFERENCE`,
`HYPOTHESIS`, or `ASSUMPTION`, and every hypothesis lists supporting evidence,
evidence against, alternatives, a falsification test, and the next verification
step.

## Step 5 — Register claims

Add each significant conclusion to `cases/<slug>/CLAIMS.md` with exact evidence
references (path plus line, timestamp, packet, command, or section). Start it as
a `HYPOTHESIS` with a `PENDING` verdict.

> Agent agreement is **not** verification. A claim is not upgraded because
> multiple agents concur.

## Step 6 — Adversarial review

`adversarial-reviewer` challenges each claim and writes a verdict under
`reviews/<slug>/` using [`docs/templates/REVIEW.md`](../docs/templates/REVIEW.md):

| Verdict | Meaning | Next action |
| --- | --- | --- |
| `PASS` | Evidence is sufficient and alternatives excluded | Claim may become a verified conclusion |
| `REVISE` | Plausible but insufficient | Improve reasoning or collect focused evidence |
| `BLOCKED` | Critical evidence is unavailable | Record the blocker and create an evidence task |

In the worked example the first review returns **REVISE**: the accounting log
shows the cause string `Idle-Timeout`, but the *configured* timer value is
unproven and a RADIUS CoA disconnect is not yet excluded. The reviewer proposes
the smallest next step — confirm the idle-timeout value and scan the auth log
for `Disconnect-Request`.

## Step 7 — Honor the loop

`REVISE`/`BLOCKED` spawns the smallest useful follow-up task (e.g. `TASK-002`).
Collect the focused evidence, write a new finding, and re-review.

In the example, new evidence (`Idle-Timeout = 1800`, zero CoA packets in the
window) earns a **PASS** on re-review. The claim's classification becomes
`VERIFIED CONCLUSION` and its verdict records the passing review reference.

## Step 8 — Close the case

Close only when **every** significant claim has passed. Set `Status: CLOSED` in
`CASE.md` and write the final conclusion identifying:

- verified conclusions,
- rejected hypotheses,
- residual risk and uncertainty,
- evidence and tests used,
- any recommended production change, clearly separated and flagged as requiring
  explicit authorization.

Worked-example conclusion: the "random" disconnects are the configured 1800s
RADIUS idle-timeout firing per session; users perceive it as random because the
timers are staggered by each login time. It is not a hardware or link fault, and
CoA is excluded for the examined window.

## Final artifact tree

```text
cases/bng-random-disconnect/CASE.md          # CLOSED, with final conclusion
cases/bng-random-disconnect/CLAIMS.md        # C-001 = VERIFIED CONCLUSION (PASS)
evidence/bng-random-disconnect/radius-acct.log
evidence/bng-random-disconnect/radius-profile.txt
evidence/bng-random-disconnect/README.md     # inventory
findings/bng-random-disconnect/FINDING-engineer.md
findings/bng-random-disconnect/FINDING-researcher.md
findings/bng-random-disconnect/FINDING-timeout-confirm.md
reviews/bng-random-disconnect/REVIEW-001.md  # REVISE
reviews/bng-random-disconnect/REVIEW-002.md  # PASS
tasks/bng-random-disconnect/TASK-001.md
tasks/bng-random-disconnect/TASK-002.md
```

## Validate anytime

```bash
./scripts/validate.sh
```

This checks required files, agent name/filename consistency, and case-template
integrity. The same check runs in CI on every push and pull request.

## Golden rules

- Describe symptoms, not causes, at intake.
- Keep the two investigators independent.
- Cite evidence precisely; never invent output, logs, captures, or results.
- Agreement is not verification — only a `PASS` review upgrades a claim.
- Stay read-only by default; production changes require explicit authorization.

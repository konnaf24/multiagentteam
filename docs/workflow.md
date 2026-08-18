# Investigation workflow

## 1. Intake

Create a case with `scripts/new-case.sh`. Complete its `CASE.md` before asking
agents to diagnose the issue. The problem statement should describe symptoms,
not assume a cause.

Inventory each supplied artifact in `evidence/<case>/README.md`. Record its
source, collection time, integrity information when available, and whether it
has been sanitized.

## 2. Decomposition

The lead agent creates bounded task files under `tasks/<case>/`. A useful task
has one question, named inputs, an expected output, and an explicit completion
criterion.

Run independent work in separate findings files. Independence reduces anchoring
and makes disagreements visible.

## 3. Claims

Add each significant conclusion to `cases/<case>/CLAIMS.md`. A claim must state
its classification, supporting evidence, competing explanations, and a
falsification test.

Do not use agent consensus as supporting evidence.

## 4. Adversarial review

The reviewer checks each claim and returns:

| Verdict | Meaning | Next action |
| --- | --- | --- |
| `PASS` | Evidence is sufficient | Claim may become a verified conclusion |
| `REVISE` | Plausible but insufficient | Improve reasoning or collect focused evidence |
| `BLOCKED` | Critical evidence is unavailable | Record the blocker and create an evidence task |

The reviewer should propose the smallest useful next step rather than a broad
request to "collect more data."

## 5. Closure

A case can close only when all significant claims have passed review. Its final
record must identify:

- verified conclusions
- rejected hypotheses
- residual risk and uncertainty
- evidence and tests used
- any recommended production change, clearly separated from investigation

Production changes are outside the default read-only workflow and require
explicit authorization.

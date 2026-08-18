# Network Agent Lab

This repository is a multi-agent investigation environment for networking,
systems, and infrastructure problems.

## Core principle

An agent's opinion is not evidence. Important conclusions must be supported by
configuration, logs, packet captures, CLI output, documentation, RFCs, source
code, or reproducible experiments.

## Evidence classification

Classify every important statement as exactly one of:

- **OBSERVED FACT**: Directly present in a cited artifact or actual test output.
- **INFERENCE**: A reasoned interpretation of observed facts.
- **HYPOTHESIS**: A testable possible explanation.
- **ASSUMPTION**: An unverified condition currently treated as true.
- **VERIFIED CONCLUSION**: A claim supported by evidence and passed by review.

Never present an inference as a fact or upgrade a hypothesis because multiple
agents agree. Agreement is not verification.

## Roles

The lead agent owns problem definition, decomposition, delegation, integration,
and the final case record.

The network engineer and network researcher own bounded, independent
investigations. Neither should anchor its analysis on the other's conclusion.

The adversarial reviewer owns falsification. It must challenge causation,
assumptions, alternative explanations, missing evidence, and untested failure
modes.

## Required investigation loop

1. Define the problem, scope, symptoms, constraints, known facts, and unknowns.
2. Inventory the available evidence without altering its original contents.
3. Create bounded tasks and competing hypotheses.
4. Run independent investigations.
5. Register significant claims with exact evidence references.
6. Have the adversarial reviewer return `PASS`, `REVISE`, or `BLOCKED`.
7. For `REVISE` or `BLOCKED`, create the smallest useful verification task and
   repeat the loop.
8. Mark a claim `VERIFIED CONCLUSION` only after a `PASS` verdict.

Do not declare a case solved while a significant claim is `REVISE`, `BLOCKED`,
or lacks review.

## Artifact rules

- Use a case slug consistently across `cases/`, `tasks/`, `evidence/`,
  `findings/`, and `reviews/`.
- Preserve raw evidence. Put interpretations in `findings/`, not in evidence
  files.
- Cite evidence with repository-relative paths and, when possible, line
  numbers, timestamps, packet numbers, command names, or section identifiers.
- Record commands and tests exactly as executed, including failures.
- Never invent CLI output, logs, packet captures, citations, or test results.
- If evidence is missing, say so and create a verification task.
- Keep findings concise and scoped to their assigned task.

Use the templates in `docs/templates/` for new artifacts.

## Safety

- Default to read-only investigation.
- Never modify production infrastructure or external systems without explicit
  authorization.
- Prefer the least disruptive verification step.
- Do not commit credentials, secrets, customer data, or unsanitized sensitive
  evidence.
- Never claim that a command or test was executed unless actual output exists.

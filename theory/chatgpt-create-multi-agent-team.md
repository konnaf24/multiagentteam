# Create Multi Agent Team

> Source: [Public ChatGPT shared conversation](https://chatgpt.com/share/6a840345-64a0-83ed-9f79-1d601c65e649)
>
> This transcript preserves the user and assistant messages from the shared
> conversation. Internal system, tool, and reasoning messages are excluded.

## User

read this and show me how to create one https://x.com/pvncher/status/2080707291603407077

## Assistant

I’ll read the X post first, then break down exactly what it built and give you a practical step-by-step way to create your own version.

## Assistant

The post is by urlEric Provencher (@pvncher)turn0search2 and is about **practical multi-agent orchestration in Codex**. The core idea appears to be creating a small team of specialized agents—described as **Sol** and **Terra**—that can **delegate tasks to each other and share updates through tools**, rather than one giant agent trying to do everything. citeturn0search2

This is very similar to the workflow you were asking about earlier: **one agent does the work, another challenges/reviews it, and they iterate until the result is robust.**

## What you would build

For networking, I would structure yours like this:

```text
                    YOU
                     │
                     ▼
              ┌─────────────┐
              │   ORCHESTRATOR │
              │   "Lead Agent" │
              └──────┬──────┘
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
     ┌────────┐ ┌────────┐ ┌────────┐
     │ NETWORK│ │ ADVERSARY│ │ RESEARCH│
     │ ENGINEER│ │ / REVIEWER│ │ AGENT  │
     └────┬───┘ └────┬─────┘ └────┬───┘
          │          │            │
          └──────────┼────────────┘
                     ▼
              Shared Workspace
              / Git Repository
                     │
                     ▼
                Final Answer
```

### The agents

**1. Lead / Orchestrator**

Its job is not necessarily to solve the networking problem itself.

It:

- breaks the problem into tasks
- delegates to specialists
- collects their findings
- decides when more investigation is needed
- asks the adversarial agent to challenge conclusions
- produces the final answer

**2. Network Engineer**

This agent actually designs or troubleshoots.

For example:

> "Why is EVPN multihoming failing when one MX304 loses connectivity?"

It investigates:

- BGP EVPN
- ESI-LAG
- MAC routes
- ARP/ND
- Junos configuration
- logs and packet captures

**3. Adversarial Reviewer**

This is the important part for your workflow.

Its system prompt could be:

> You are a hostile but technically rigorous reviewer. Assume the proposed solution may be wrong. Look for missing assumptions, incorrect protocol behavior, scaling problems, race conditions, vendor-specific limitations, and failure scenarios. Do not accept a conclusion merely because it sounds plausible.

So instead of:

```text
Engineer:
"The problem is caused by BGP."

Reviewer:
"Looks good."
```

You want:

```text
Engineer:
"The problem is caused by BGP."

Reviewer:
"What evidence proves that?"

Engineer:
"Route X disappears."

Reviewer:
"Could that be a consequence rather than the cause?
Check underlay reachability, EVPN route withdrawal,
BFD state, ESI state and MAC mobility."

Engineer:
"I checked those..."

Reviewer:
"You haven't tested what happens when the failure occurs
during convergence. Reproduce it and collect timestamps."
```

That is the **adversarial loop**.

---

# How I would create this for you

Since you already use Linux, Docker, networking labs, Claude/Codex-style agents and GitHub, I would start with a **very simple version** rather than building a complicated agent framework.

## Option 1 — The easiest: one orchestrator + subagents

Create a directory:

```text
network-agent/
├── AGENTS.md
├── tasks/
├── findings/
├── reviews/
├── evidence/
└── final/
```

The workflow becomes:

```text
User problem
     │
     ▼
Lead agent creates:
tasks/problem.md
     │
     ├──► engineer-agent
     │       │
     │       └── findings/engineering.md
     │
     ├──► research-agent
     │       │
     │       └── findings/research.md
     │
     └──► reviewer-agent
             │
             └── reviews/challenge.md
                     │
                     ▼
                Lead reads all
                     │
              unresolved?
                 │      │
                YES     NO
                 │       │
                 └──loop ▼
                      final/answer.md
```

The key idea is that **the filesystem becomes the shared memory**.

That means agents don't need a complicated database or message bus initially.

---

# Example: your networking use case

Suppose you give it:

> "Investigate why subscribers randomly disconnect on this BNG."

The orchestrator creates:

```text
tasks/
  01-analyse-logs.md
  02-check-radius.md
  03-check-pppoe.md
  04-check-bfd-and-routing.md
  05-reproduce-failure.md
```

Then it might tell the agents:

### Engineer

```text
You are the primary network troubleshooting engineer.

Analyse the evidence in evidence/.

Develop hypotheses, but distinguish clearly between:

- observed facts
- inferred conclusions
- assumptions
- things requiring verification

Write your findings to:

findings/engineering.md
```

### Researcher

```text
Independently investigate the issue.

Do not read the engineer's conclusion initially.

Look for alternative explanations and relevant
protocol/vendor behaviour.

Write findings to:

findings/research.md
```

### Adversary

```text
You are an adversarial technical reviewer.

Read:

findings/engineering.md
findings/research.md

Your job is to disprove their conclusions.

For every major claim ask:

1. What evidence supports this?
2. What alternative explanation exists?
3. What test would falsify the claim?
4. What failure mode has not been considered?
5. Is vendor-specific behaviour being assumed?
6. Could correlation be mistaken for causation?

Write your challenge to:

reviews/challenge.md
```

Then the lead agent reads:

```text
engineering.md
research.md
challenge.md
```

and decides:

```text
Reviewer found unresolved issues
        ↓
create new verification task
        ↓
engineer investigates
        ↓
reviewer challenges again
        ↓
confidence threshold reached
        ↓
FINAL ANSWER
```

---

## The important improvement: don't let agents just "talk"

This is where I think the approach in that post becomes useful.

You want agents to have **tools that create explicit artifacts**.

For example:

```text
create_task()
read_task()
submit_finding()
challenge_claim()
request_evidence()
mark_verified()
mark_rejected()
```

Conceptually:

```python
create_task(
    agent="network-engineer",
    task="Check EVPN route withdrawal during link failure"
)

submit_finding(
    claim="MAC route withdrawal precedes subscriber loss",
    evidence=[
        "bgp.log: timestamp...",
        "pcap: timestamp..."
    ]
)

challenge_claim(
    claim_id="claim-17",
    reason="No evidence distinguishes cause from consequence"
)

request_evidence(
    claim_id="claim-17",
    test="Reproduce failure while capturing BGP and PPPoE events"
)
```

This prevents the agents from producing a huge conversation full of opinions.

Instead, they build a **case file**.

---

# The architecture I recommend for you

I would build version 1 like this:

```text
                    ┌─────────────────────┐
                    │    YOU / TERMINAL   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  LEAD ORCHESTRATOR  │
                    │                     │
                    │ Plans / delegates   │
                    │ Tracks confidence   │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼───────────────────┐
          │                    │                   │
          ▼                    ▼                   ▼
 ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
 │ NETWORK EXPERT │  │ RESEARCH AGENT │  │ ADVERSARIAL    │
 │                │  │                │  │ REVIEWER       │
 │ Junos          │  │ Docs           │  │ Attack claims  │
 │ BGP/EVPN       │  │ RFCs           │  │ Find gaps      │
 │ BNG            │  │ Code           │  │ Demand proof   │
 └───────┬────────┘  └───────┬────────┘  └───────┬────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                  ┌──────────────────────┐
                  │ SHARED CASE FILE     │
                  │                      │
                  │ tasks/               │
                  │ evidence/            │
                  │ claims/              │
                  │ challenges/          │
                  │ conclusions/         │
                  └──────────────────────┘
```

## My recommendation

For your use case, **don't start with a complex multi-agent framework**.

Start with:

1. **Codex or Pi/Claude Code as the lead**
2. A shared Git repository/workspace
3. Three specialist agents:
   - Network Engineer
   - Independent Researcher
   - Adversarial Reviewer
4. Structured files or simple tools for:
   - claims
   - evidence
   - challenges
   - verification tasks
5. A loop:

```text
PROPOSE
   ↓
CHALLENGE
   ↓
TEST
   ↓
REVISE
   ↓
CHALLENGE AGAIN
   ↓
ACCEPT / REJECT
```

That would be especially useful for the kind of things you work on—**Junos, EVPN, BNG, RADIUS, BFD, packet captures and complex failure scenarios**—because the reviewer can force the engineering agent to prove its theory against actual logs and tests rather than confidently inventing an explanation.

If you want, I can next build the **actual first version of this project with you**: a ready-to-run folder structure, `AGENTS.md`, the three agent prompts, and the orchestration workflow for your Ubuntu VM. memcite

## User

Build the actual first version of this project with me

## Assistant

Yes. Let’s build **version 1 as a real, runnable project on your Ubuntu VM**.

I suggest we deliberately keep the first version simple:

- **Pi** as the interactive lead agent, since you were already exploring Pi.
- A normal project directory + Git as the **shared case file**.
- Three roles: **Engineer**, **Researcher**, and **Adversarial Reviewer**.
- The lead creates tasks; specialists write findings; the reviewer attacks claims; unresolved claims generate another task.

The first version will not require Kubernetes, a database, or a multi-agent framework. That gives us something you can actually run and improve.

## Assistant

One correction to my previous answer: I’ve now checked the post’s surrounding context and the implementation pattern is specifically about **native Codex multi-agent orchestration**, with Sol as the parent/orchestrator and Terra as the native subagent lane. Eric Provencher has also explicitly cautioned against forcing Luna into the native V2 subagent mechanism. citeturn0search0turn0search4

So let's build **our networking investigation project around that**, rather than inventing a generic framework.

# Phase 1: Create the project

On your Ubuntu machine:

```bash
mkdir -p ~/network-agent-lab
cd ~/network-agent-lab

git init

mkdir -p \
  cases \
  evidence \
  findings \
  reviews \
  tasks \
  scripts \
  docs \
  .codex/agents
```

Your project will look like:

```text
network-agent-lab/
├── AGENTS.md
├── README.md
├── cases/
├── tasks/
├── evidence/
├── findings/
├── reviews/
├── docs/
├── scripts/
└── .codex/
    └── agents/
```

The important design principle is:

> **Agents do not just have conversations. They leave evidence and conclusions in the repository.**

That makes the workflow inspectable and reproducible.

---

# Phase 2: Create the project contract

Create `AGENTS.md`:

```markdown
# Network Agent Lab

This repository is used for multi-agent investigation of networking,
systems, and infrastructure problems.

## Core principle

Do not treat an agent's statement as evidence.

Every important conclusion must distinguish between:

1. OBSERVED FACT
2. INFERENCE
3. ASSUMPTION
4. HYPOTHESIS
5. VERIFIED CONCLUSION

## Workflow

The parent agent owns:

- problem definition
- decomposition
- delegation
- integration
- final conclusions

Subagents own bounded investigations.

The reviewer must attempt to falsify significant conclusions.

## Evidence rules

A claim should reference evidence where possible:

- configuration
- logs
- packet captures
- CLI output
- source code
- documentation
- RFCs
- reproducible tests

Do not upgrade a hypothesis to a conclusion merely because
multiple agents agree.

Agreement is not verification.

## Investigation loop

PROBLEM
→ HYPOTHESIS
→ EVIDENCE
→ CHALLENGE
→ TEST
→ REVISED CONCLUSION

If a reviewer identifies an unresolved alternative explanation,
create a new verification task.

## File conventions

tasks/
    Active work items.

evidence/
    Raw evidence supplied or collected.

findings/
    Agent findings.

reviews/
    Adversarial challenges and review verdicts.

cases/
    Final case records.

## Safety

Do not modify production devices or external systems unless the
user explicitly authorizes the action.

Default investigation mode is read-only.

Never claim that a test was performed unless actual output exists.
```

This is the **constitution** of the agent team.

---

# Phase 3: Create our three agents

We don't actually need three independent personalities for the sake of it.

Each role should have a specific failure mode it protects against.

## 1. Network investigator

Create:

`.codex/agents/network_investigator.toml`

```toml
name = "network_investigator"
description = "Investigates bounded networking and infrastructure problems using evidence."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
You are the primary technical investigator.

Your job is to investigate a bounded networking or infrastructure
question.

Focus on:

- protocol behavior
- control plane
- forwarding plane
- configuration
- logs
- packet captures
- failure timing
- vendor-specific behavior

Separate every statement into:

OBSERVED FACT
INFERENCE
HYPOTHESIS
ASSUMPTION

Do not silently convert an inference into a fact.

For each hypothesis, state:

1. Supporting evidence
2. Alternative explanations
3. What evidence would disprove it
4. The next best verification step

Write concise findings to the assigned findings file.

Do not modify production systems.
Do not invent command output.
"""
```

---

## 2. Independent investigator

This one is important.

We want it to investigate the problem **without being anchored too strongly by the first agent's answer**.

Create:

`.codex/agents/independent_investigator.toml`

```toml
name = "independent_investigator"
description = "Performs an independent investigation and searches for alternative explanations."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
You are an independent investigator.

Do not assume that another investigator's conclusion is correct.

Construct your own explanation from the problem statement and evidence.

Specifically look for:

- alternative root causes
- hidden dependencies
- timing effects
- race conditions
- control-plane versus data-plane confusion
- vendor-specific behavior
- correlation mistaken for causation
- missing evidence

For every major hypothesis, define the experiment or observation
that would distinguish it from competing hypotheses.

Return a concise evidence-based report.
"""
```

---

## 3. The adversarial reviewer

This is the one closest to the workflow you originally described: **whatever the other agent becomes convinced of, this agent attacks it**.

Create:

`.codex/agents/adversarial_reviewer.toml`

```toml
name = "adversarial_reviewer"
description = "Attempts to falsify technical conclusions and expose missing evidence."
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
You are an adversarial technical reviewer.

Your purpose is not to be agreeable.

Assume that the proposed explanation may be wrong.

Attack the reasoning, not the person.

For every significant conclusion ask:

1. What exact evidence supports this?
2. Does the evidence prove causation or only correlation?
3. What alternative explanation also fits the evidence?
4. What assumption is hidden?
5. What failure scenario has not been tested?
6. Could protocol behavior differ on this vendor or version?
7. What observation would falsify the conclusion?

Classify each conclusion:

PASS
    Evidence is sufficient.

REVISE
    Plausible but insufficiently supported.

BLOCKED
    Important evidence is missing.

When possible, propose the smallest and cheapest test that could
resolve the uncertainty.

Do not invent evidence.
"""
```

There is one caveat: the exact custom-agent routing surface and model availability can vary with your current Codex version/account, so we should verify what your installed Codex actually supports rather than blindly assuming these TOML files will be routed exactly as written. The current Sol/Terra native multi-agent pattern is documented in the reference implementation I found. citeturn0search0turn0search5

# Phase 4: Create a case template

Each investigation gets its own case.

For example:

```bash
mkdir -p cases/bng-random-disconnect
```

Create:

`cases/bng-random-disconnect/CASE.md`

```markdown
# Case: BNG Random Subscriber Disconnects

## Problem

Describe exactly what is happening.

## Scope

What systems, devices, versions and protocols are involved?

## Symptoms

- 
- 
- 

## Timeline

| Time | Event | Evidence |
|---|---|---|
| | | |

## Known facts

Only facts directly supported by evidence.

## Unknowns

- 
- 
- 

## Constraints

Examples:

- Production system
- No disruptive testing
- Limited access
- No packet capture available
```

Then create:

`cases/bng-random-disconnect/CLAIMS.md`

```markdown
# Claims

## C-001

### Claim

...

### Status

HYPOTHESIS

### Supporting evidence

...

### Alternative explanations

...

### Falsification test

...

### Reviewer verdict

PENDING
```

This is important because instead of agents producing one giant essay, they build a **structured chain of claims**.

---

# Phase 5: The actual orchestration loop

The parent agent receives:

> Subscribers randomly disconnect from the BNG. Here are the logs and configuration.

It should do this:

```text
                    PARENT / SOL
                         │
                         │ Define problem
                         ▼
                    CREATE TASKS
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
       NETWORK AGENT          INDEPENDENT AGENT
              │                     │
              ▼                     ▼
         Findings A            Findings B
              │                     │
              └──────────┬──────────┘
                         ▼
                 ADVERSARIAL REVIEW
                         │
              ┌──────────┴──────────┐
              │                     │
             PASS                REVISE
              │                     │
              ▼                     ▼
         CONCLUSION          NEW TEST / TASK
                                    │
                                    └───────► loop
```

The crucial point is:

**The reviewer should be able to send the work backward.**

Not just say:

> "Interesting analysis. You might also consider..."

Instead:

> **BLOCKED:** The claim that RADIUS is causing the disconnect is unsupported. The timestamp shows RADIUS failure *after* PPP termination. Determine which event occurs first.

That becomes a new task.

---

# Phase 6: Add a simple task format

Create `tasks/TASK_TEMPLATE.md`:

```markdown
# Task ID

## Assigned role

network_investigator

## Question

What exactly must be determined?

## Input evidence

List files to inspect.

## Constraints

- Read-only
- No production changes

## Expected output

The agent must provide:

1. Observed facts
2. Hypotheses
3. Supporting evidence
4. Alternative explanations
5. Falsification tests
6. Recommended next action

## Completion criteria

The task is complete when the specific question can be answered
or when the missing evidence is explicitly identified.
```

For example:

`tasks/TASK-001-check-pppoe-timeline.md`

```markdown
# TASK-001

## Assigned role

network_investigator

## Question

Determine the event sequence leading to subscriber termination.

## Evidence

- evidence/bng.log
- evidence/radius.log
- evidence/pppoe.pcap

## Required output

Construct a timeline with millisecond precision where possible.

Determine:

1. What event happens first?
2. Which events are consequences?
3. Which component initiates termination?
4. What evidence remains ambiguous?
```

---

# Phase 7: Initialize Git

Now:

```bash
cd ~/network-agent-lab

git add .

git commit -m "Initial multi-agent network investigation framework"
```

From then on, each case becomes a traceable investigation.

For example:

```text
Commit 1
Initial hypothesis:
"RADIUS timeout causes disconnect"

          ↓ reviewer blocks it

Commit 2
Added timestamp evidence

          ↓

Commit 3
Hypothesis changed:
"

## User

repeat with copilot instead of pi

## Assistant

Yes. If you want to build this around **GitHub Copilot instead of Pi**, I’d change the design slightly.

The simplest useful setup is:

```text
                         YOU
                          │
                          ▼
                  ┌───────────────┐
                  │ Copilot       │
                  │ Lead Agent    │
                  └───────┬───────┘
                          │
             delegates / asks for review
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   Network Engineer   Researcher    Adversarial Reviewer
          │               │               │
          └───────────────┼───────────────┘
                          ▼
                   Git repository
                          │
                    evidence/
                    findings/
                    reviews/
                    tasks/
```

The nice thing is that **GitHub itself becomes the collaboration layer**: agents work against the same repository, and the history gives you an audit trail.

## 1. Create the repository

On your Ubuntu VM:

```bash
mkdir -p ~/network-agent-lab
cd ~/network-agent-lab

git init

mkdir -p \
  cases \
  evidence \
  findings \
  reviews \
  tasks \
  docs \
  scripts \
  .github/agents
```

If you want this on GitHub:

```bash
git add .
git commit -m "Initial network agent lab"
```

Then create a GitHub repository and push it.

---

# 2. Use Copilot custom agents

GitHub Copilot supports **custom agents** defined in `.github/agents/`.

So we'll make three.

### Network Engineer

Create:

```bash
nano .github/agents/network-engineer.agent.md
```

Put:

```markdown
---
name: network-engineer
description: Investigates networking and infrastructure problems using evidence.
---

# Network Engineer

You are the primary networking investigator.

You specialize in:

- BGP
- EVPN/VXLAN
- MPLS
- BFD
- PPPoE
- BNG
- RADIUS
- Ethernet switching
- routing
- Junos
- Linux networking
- packet captures
- network automation

## Investigation rules

Separate conclusions into:

- OBSERVED FACT
- INFERENCE
- HYPOTHESIS
- ASSUMPTION
- VERIFIED CONCLUSION

Never present an inference as a fact.

For every important hypothesis provide:

1. Supporting evidence
2. Alternative explanations
3. What would falsify the hypothesis
4. The next verification step

Never invent CLI output, logs, packet captures or test results.

If evidence is missing, explicitly say so.

Default to read-only investigation.

Write findings to the appropriate file under:

findings/
```

---

# 3. Create the independent researcher

```bash
nano .github/agents/network-researcher.agent.md
```

```markdown
---
name: network-researcher
description: Independently investigates networking problems and looks for alternative explanations.
---

# Independent Network Researcher

You are an independent investigator.

Your job is to develop an explanation independently rather than
simply agreeing with the primary network engineer.

Investigate:

- protocol behavior
- RFCs
- vendor documentation
- software versions
- known implementation limitations
- failure modes
- timing issues
- control-plane/data-plane interactions

Pay particular attention to:

- correlation versus causation
- hidden assumptions
- vendor-specific behavior
- race conditions
- convergence
- incomplete evidence

For each hypothesis explain:

1. Why it could be true
2. Evidence supporting it
3. Evidence against it
4. What experiment would distinguish it from alternatives

Do not assume another agent's conclusion is correct.

Never invent evidence.

Write your findings under:

findings/
```

---

# 4. Create the adversarial reviewer

This is the most important one for the workflow you described earlier.

```bash
nano .github/agents/adversarial-reviewer.agent.md
```

```markdown
---
name: adversarial-reviewer
description: Attempts to falsify networking conclusions and find missing evidence.
---

# Adversarial Network Reviewer

You are a hostile but technically rigorous reviewer.

Your job is to try to prove that the proposed explanation is WRONG.

Do not be agreeable.

Do not accept a conclusion merely because:

- it sounds technically plausible
- another agent believes it
- multiple agents agree
- it matches a familiar failure mode

For every important claim ask:

1. What exact evidence supports it?
2. Does the evidence establish causation or merely correlation?
3. What alternative explanation fits the same evidence?
4. What assumption is being made?
5. What evidence is missing?
6. What failure scenario has not been tested?
7. Could this be vendor/version specific?
8. What observation would falsify the claim?

Classify each important conclusion as:

PASS
REVISE
BLOCKED

PASS:
The evidence is sufficient.

REVISE:
The hypothesis is plausible but insufficiently demonstrated.

BLOCKED:
A critical piece of evidence is missing.

When rejecting a conclusion, specify the smallest useful
experiment or evidence collection required to resolve the issue.

Never invent evidence.

Write the review under:

reviews/
```

---

# 5. Create the project instructions

Now create:

```bash
nano AGENTS.md
```

```markdown
# Network Agent Lab

This repository is a multi-agent networking investigation environment.

## Core principle

An agent's opinion is not evidence.

Important conclusions must be supported by:

- configuration
- logs
- packet captures
- CLI output
- documentation
- RFCs
- source code
- reproducible experiments

## Evidence classification

Every important statement should be classified as:

OBSERVED FACT
INFERENCE
HYPOTHESIS
ASSUMPTION
VERIFIED CONCLUSION

## Investigation loop

PROBLEM
↓
HYPOTHESES
↓
EVIDENCE
↓
INDEPENDENT INVESTIGATION
↓
ADVERSARIAL REVIEW
↓
TEST
↓
REVISED CONCLUSION

If the reviewer identifies an unresolved alternative explanation,
create another investigation task.

## Safety

Default to read-only.

Never modify production infrastructure without explicit
authorization.

Never claim that a command was executed unless actual output
exists.
```

---

# 6. The shared workspace

We'll use:

```text
network-agent-lab/
│
├── AGENTS.md
│
├── .github/
│   └── agents/
│       ├── network-engineer.agent.md
│       ├── network-researcher.agent.md
│       └── adversarial-reviewer.agent.md
│
├── cases/
│
├── tasks/
│
├── evidence/
│
├── findings/
│
├── reviews/
│
└── docs/
```

This is deliberately boring.

That's good.

The **repository is the shared memory**.

---

# 7. Now give Copilot a real networking problem

For example, suppose you have:

```text
evidence/
├── bng.log
├── radius.log
├── pcap.pcap
├── bng.conf
└── topology.md
```

Start Copilot with:

> Investigate this BNG subscriber disconnect problem.
>
> Do not jump to a conclusion.
>
> First establish the observed facts and create competing hypotheses.
>
> Then delegate/ask the network-engineer and network-researcher agents to investigate independently.
>
> Finally have adversarial-reviewer attempt to falsify their conclusions.
>
> Do not declare the case solved until the reviewer either passes the conclusion or identifies the evidence/test required to resolve it.

The desired behavior is:

```text
                 COPILOT
                    │
                    ▼
              Define problem
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
   Network Engineer      Researcher
          │                   │
          ▼                   ▼
      findings/           findings/
          │                   │
          └─────────┬─────────┘
                    ▼
             Adversarial
               Reviewer
                    │
            ┌───────┴───────┐
            ▼               ▼
           PASS           BLOCKED
            │               │
            ▼               ▼
         CONCLUDE       New TASK
                            │
                            └──────► investigate again
```

## The important part

I **wouldn't make Copilot automatically trust the output of another agent**.

The useful architecture is:

```text
Agent A: "I think X."

Agent B: "I independently think Y."

Reviewer:
    "Both are wrong because evidence Z
     doesn't establish either conclusion."

Copilot:
    "Create TASK-004 to determine Z."

Agent A:
    investigates

Reviewer:
    attacks again
```

That gives you something much more interesting than simply running three LLMs.

You're effectively building a **networking investigation machine**.

### One thing I'd change from my previous design

I would **not** hard-code `gpt-5.6-terra` or `gpt-5.6-sol` into these agent definitions. With Copilot, let the available Copilot model/agent configuration determine the model. The important part is the **role separation and evidence loop**, not the model names.

If you want, the next step should be to make this **actually autonomous**: Copilot creates the task → invokes the engineer → invokes the independent researcher → invokes the adversarial reviewer → automatically creates another task when the reviewer says `BLOCKED`. That is where this starts becoming the system you were describing in your original question.

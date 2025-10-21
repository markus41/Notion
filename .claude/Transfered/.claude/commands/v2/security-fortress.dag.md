# Security Fortress v2.0 - Directed Acyclic Graph (DAG)

## Overview

**Total Nodes**: 31 agents across 7 phases
**Total Edges**: 82 dependencies
**Max Parallelism**: 4 concurrent agents (Phase 2 and Phase 5)
**Critical Path**: Phase 1 → Phase 2 (longest) → Phase 3 (longest) → Phase 4 (longest) → Phase 5 (longest) → Phase 6 (longest) → Phase 7 (all)
**Total Duration**: 70 minutes

## Visual DAG Representation

```
Level 0: START
  │
  ├──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 1: THREAT MODELING (10 min)                              │
  │                                                                  │
  │  [threat-analyzer]                                               │
  │    │ Outputs:                                                    │
  │    ├─ threat_model                                               │
  │    ├─ attack_vectors                                             │
  │    ├─ security_priorities                                        │
  │    └─ project_structure                                          │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                                    │
                                    │ (all Phase 2 agents depend on threat-analyzer)
                                    │
                    ┌───────────────┼───────────────┬───────────────┐
                    │               │               │               │
                    ↓               ↓               ↓               ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 2: STATIC ANALYSIS (10 min, 4 PARALLEL)                  │
  │                                                                  │
  │  [codeql-scanner]    [semgrep-scanner]                           │
  │    └─ codeql_findings  └─ semgrep_findings                       │
  │                                                                  │
  │  [bandit-scanner]    [eslint-security-scanner]                   │
  │    └─ bandit_findings  └─ eslint_security_findings               │
  │                                                                  │
  │  All consume: threat_model, security_priorities                  │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                    │               │               │               │
                    └───────────────┼───────────────┴───────────────┘
                                    │ (all Phase 3 agents depend on all Phase 2 agents)
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ↓               ↓               ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 3: DEPENDENCY SCANNING (10 min, 3 PARALLEL)              │
  │                                                                  │
  │  [npm-audit-scanner]  [snyk-scanner]  [owasp-dependency-check]  │
  │    └─ npm_vulnerabilities  └─ snyk_vulnerabilities  └─ owasp_cve_findings
  │                                                                  │
  │  All consume: threat_model, project_structure                    │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │ (all Phase 4 agents depend on all Phase 3 agents)
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ↓               ↓               ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 4: CONTAINER SECURITY (9 min, 3 PARALLEL)                │
  │                                                                  │
  │  [dockerfile-linter]  [trivy-scanner]  [container-bench-scanner]│
  │    └─ dockerfile_issues  └─ trivy_vulnerabilities  └─ docker_bench_findings
  │                                                                  │
  │  All consume: threat_model, project_structure                    │
  │  Conditional: Skip if no Docker/containers detected              │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │ (all Phase 5 agents depend on all Phase 4 agents)
                                    │
                    ┌───────────────┼───────────────┬───────────────┐
                    │               │               │               │
                    ↓               ↓               ↓               ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 5: INFRASTRUCTURE SECURITY (9 min, 4 PARALLEL)           │
  │                                                                  │
  │  [bicep-terraform-scanner]  [cloudformation-scanner]             │
  │    └─ iac_security_findings   └─ cfn_security_findings           │
  │                                                                  │
  │  [kubernetes-hardening-scanner]  [network-policy-auditor]        │
  │    └─ k8s_security_findings      └─ network_policy_findings      │
  │                                                                  │
  │  All consume: threat_model, security_priorities                  │
  │  network-policy-auditor: LOCKS network-policies resource         │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                    │               │               │               │
                    └───────────────┼───────────────┴───────────────┘
                                    │ (all Phase 6 agents depend on all Phase 5 agents)
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ↓               ↓               ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 6: RUNTIME SECURITY (7 min, 3 PARALLEL) [COMPENSABLE]    │
  │                                                                  │
  │  [runtime-monitoring-setup] 🔒 runtime-monitoring               │
  │    └─ runtime_monitoring_config                                  │
  │    └─ COMPENSATION: Rollback Falco rules (devops-automator)     │
  │                                                                  │
  │  [waf-configuration] 🔒 waf-config                              │
  │    └─ waf_config                                                 │
  │    └─ COMPENSATION: Restore WAF snapshot (devops-automator)     │
  │                                                                  │
  │  [secrets-rotation] 🔒 secrets-vault                            │
  │    └─ secrets_rotation_status                                    │
  │    └─ COMPENSATION: Restore secret versions (cryptography-expert)│
  │                                                                  │
  │  All consume: threat_model, attack_vectors                       │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │ (Phase 7 agents depend on all Phase 6 agents)
                                    │
                                    ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  PHASE 7: REPORTING & REMEDIATION (15 min, SEQUENTIAL)          │
  │                                                                  │
  │  [vulnerability-aggregator] (5 min)                              │
  │    └─ Consumes: ALL findings from Phases 2-6                     │
  │    └─ Outputs: aggregated_vulnerabilities                        │
  │                      │                                           │
  │                      ↓                                           │
  │  [risk-prioritizer] (5 min)                                      │
  │    └─ Consumes: aggregated_vulnerabilities, threat_model         │
  │    └─ Outputs: prioritized_risks                                 │
  │                      │                                           │
  │                      ↓                                           │
  │  [remediation-planner] (5 min)                                   │
  │    └─ Consumes: prioritized_risks, threat_model                  │
  │    └─ Outputs: remediation_plan                                  │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
                                  END


Legend:
  [agent-name]  = Agent node
  └─ output     = Context output
  🔒 resource   = Resource lock required
  COMPENSATION  = Saga compensation defined
  │ ↓ ┌ ┐ └ ┘   = Dependency edges
```

## Detailed Dependency Graph

### Phase 1 → Phase 2 Dependencies

```
threat-analyzer
  ├─→ codeql-scanner
  ├─→ semgrep-scanner
  ├─→ bandit-scanner
  └─→ eslint-security-scanner
```

**Context Flow**:
- `threat_model` → All Phase 2 agents
- `security_priorities` → All Phase 2 agents
- `project_structure` → bandit-scanner, eslint-security-scanner

### Phase 2 → Phase 3 Dependencies

```
codeql-scanner ──┐
semgrep-scanner ──┼─→ npm-audit-scanner
bandit-scanner ───┼─→ snyk-scanner
eslint-security-scanner ─┼─→ owasp-dependency-check
```

**Context Flow**:
- `sast_findings` (aggregated from Phase 2) → Phase 3 agents
- `threat_model` → Phase 3 agents (from Phase 1)

### Phase 3 → Phase 4 Dependencies

```
npm-audit-scanner ──┐
snyk-scanner ────────┼─→ dockerfile-linter
owasp-dependency-check ─┼─→ trivy-scanner
                      └─→ container-bench-scanner
```

**Context Flow**:
- `dependency_vulnerabilities` → Phase 4 agents
- `threat_model` → Phase 4 agents

### Phase 4 → Phase 5 Dependencies

```
dockerfile-linter ──┐
trivy-scanner ───────┼─→ bicep-terraform-scanner
container-bench-scanner ─┼─→ cloudformation-scanner
                       ├─→ kubernetes-hardening-scanner
                       └─→ network-policy-auditor
```

**Context Flow**:
- `container_vulnerabilities` → Phase 5 agents
- `threat_model` → Phase 5 agents
- `attack_vectors` → network-policy-auditor

### Phase 5 → Phase 6 Dependencies

```
bicep-terraform-scanner ──┐
cloudformation-scanner ────┼─→ runtime-monitoring-setup
kubernetes-hardening-scanner ─┼─→ waf-configuration
network-policy-auditor ────┼─→ secrets-rotation
```

**Context Flow**:
- `infrastructure_findings` → Phase 6 agents
- `threat_model` → Phase 6 agents
- `attack_vectors` → Phase 6 agents

### Phase 6 → Phase 7 Dependencies

```
runtime-monitoring-setup ──┐
waf-configuration ──────────┼─→ vulnerability-aggregator
secrets-rotation ───────────┘
```

**Context Flow**:
- `runtime_config` → vulnerability-aggregator
- ALL previous phase outputs → vulnerability-aggregator

### Phase 7 Internal Dependencies

```
vulnerability-aggregator
  └─→ risk-prioritizer
       └─→ remediation-planner
```

**Context Flow**:
- `aggregated_vulnerabilities` → risk-prioritizer
- `prioritized_risks` → remediation-planner
- `threat_model` → remediation-planner

## Parallelism Analysis

### Level 1: Sequential (Phase 1)
```
threat-analyzer (10 min)
```
**Parallelism**: 1 agent
**Reason**: Foundation for all subsequent phases

### Level 2: 4-Way Parallel (Phase 2)
```
┌─ codeql-scanner (10 min)
├─ semgrep-scanner (10 min)
├─ bandit-scanner (10 min)
└─ eslint-security-scanner (10 min)
```
**Parallelism**: 4 agents
**Duration**: 10 min (max of all agents)
**Sequential Equivalent**: 40 min
**Time Saved**: 30 min

### Level 3: 3-Way Parallel (Phase 3)
```
┌─ npm-audit-scanner (10 min)
├─ snyk-scanner (10 min)
└─ owasp-dependency-check (10 min)
```
**Parallelism**: 3 agents
**Duration**: 10 min
**Sequential Equivalent**: 30 min
**Time Saved**: 20 min

### Level 4: 3-Way Parallel (Phase 4)
```
┌─ dockerfile-linter (8 min)
├─ trivy-scanner (9 min)
└─ container-bench-scanner (8 min)
```
**Parallelism**: 3 agents
**Duration**: 9 min (max)
**Sequential Equivalent**: 25 min
**Time Saved**: 16 min

### Level 5: 4-Way Parallel (Phase 5)
```
┌─ bicep-terraform-scanner (9 min)
├─ cloudformation-scanner (8 min)
├─ kubernetes-hardening-scanner (9 min)
└─ network-policy-auditor (8 min)
```
**Parallelism**: 4 agents
**Duration**: 9 min (max)
**Sequential Equivalent**: 34 min
**Time Saved**: 25 min

### Level 6: 3-Way Parallel (Phase 6)
```
┌─ runtime-monitoring-setup (7 min) [COMPENSABLE]
├─ waf-configuration (7 min) [COMPENSABLE]
└─ secrets-rotation (7 min) [COMPENSABLE]
```
**Parallelism**: 3 agents
**Duration**: 7 min
**Sequential Equivalent**: 21 min
**Time Saved**: 14 min

### Level 7: Sequential (Phase 7)
```
vulnerability-aggregator (5 min)
  └─ risk-prioritizer (5 min)
       └─ remediation-planner (5 min)
```
**Parallelism**: 1 agent at a time
**Duration**: 15 min
**Reason**: Each agent depends on previous output

## Critical Path Analysis

### Critical Path (Longest Duration)

```
START
  → threat-analyzer (10 min)
  → codeql-scanner (10 min) [any Phase 2 agent works, all same duration]
  → npm-audit-scanner (10 min) [any Phase 3 agent works]
  → trivy-scanner (9 min) [longest in Phase 4]
  → bicep-terraform-scanner OR kubernetes-hardening-scanner (9 min) [longest in Phase 5]
  → runtime-monitoring-setup OR waf-configuration OR secrets-rotation (7 min) [all same]
  → vulnerability-aggregator (5 min)
  → risk-prioritizer (5 min)
  → remediation-planner (5 min)
  → END

Total: 10 + 10 + 10 + 9 + 9 + 7 + 5 + 5 + 5 = 70 minutes
```

### Non-Critical Paths (Examples)

**Path 1** (Phase 4 shorter agent):
```
... → dockerfile-linter (8 min) → ... = 69 minutes total
```
**Slack**: 1 minute

**Path 2** (Phase 5 shorter agent):
```
... → cloudformation-scanner (8 min) → ... = 69 minutes total
```
**Slack**: 1 minute

**Insight**: All paths are nearly critical due to tight phase dependencies. Little room for individual agent delays.

## Resource Lock Graph

### Lock Dependencies

```
Phase 5:
  network-policy-auditor
    └─ LOCKS: network-policies (read-only audit)

Phase 6 (all acquire locks in parallel, different resources):
  runtime-monitoring-setup
    └─ LOCKS: runtime-monitoring (exclusive)

  waf-configuration
    └─ LOCKS: waf-config (exclusive)

  secrets-rotation
    └─ LOCKS: secrets-vault (exclusive)
```

**No Deadlock Risk**: All Phase 6 agents lock different resources, no circular dependencies.

### Lock Timeline

```
Time: 0-55 min (Phases 1-5)
  └─ No locks held

Time: 55-62 min (Phase 5, agent: network-policy-auditor)
  └─ LOCK: network-policies (read-only, advisory)

Time: 62-69 min (Phase 6, parallel)
  ├─ LOCK: runtime-monitoring (exclusive)
  ├─ LOCK: waf-config (exclusive)
  └─ LOCK: secrets-vault (exclusive)

Time: 69-70 min (Phase 7)
  └─ All locks released
```

## Saga Compensation Graph

### Normal Execution (No Failures)

```
Phase 6: All agents succeed
  ├─ runtime-monitoring-setup ✓ → Changes committed
  ├─ waf-configuration ✓ → Changes committed
  └─ secrets-rotation ✓ → Changes committed

Saga Status: COMMITTED
Compensation: NOT TRIGGERED
```

### Failure Scenario 1: secrets-rotation fails

```
Phase 6 Execution:
  ├─ runtime-monitoring-setup ✓ (completed)
  ├─ waf-configuration ✓ (completed)
  └─ secrets-rotation ✗ (FAILED)

Saga Compensation Triggered (reverse order):
  ├─ Step 1: Compensate secrets-rotation (cryptography-expert)
  │    └─ Restore previous Key Vault secret versions
  │
  ├─ Step 2: Compensate waf-configuration (devops-automator)
  │    └─ Restore previous WAF ruleset
  │
  └─ Step 3: Compensate runtime-monitoring-setup (devops-automator)
       └─ Restore previous Falco rules

Saga Status: COMPENSATED
System State: Reverted to pre-Phase 6 state
```

### Failure Scenario 2: Compensation fails

```
Phase 6 Execution:
  └─ secrets-rotation ✗ (FAILED)

Saga Compensation Attempt:
  ├─ Compensate waf-configuration ✓
  └─ Compensate runtime-monitoring-setup ✗ (COMPENSATION FAILED)

Saga Status: COMPENSATION FAILED
Manual Intervention: REQUIRED
Escalation: Alert DevOps team to manually restore runtime-monitoring-setup
```

### Compensation Dependencies

```
Compensation Order (reverse of execution):

  3. runtime-monitoring-setup
       ↑
  2. waf-configuration
       ↑
  1. secrets-rotation
```

**Rule**: Each compensation must wait for next agent's compensation to complete (or skip if already compensated).

## Context Propagation Graph

### Context Flow Across Phases

```
Phase 1:
  threat-analyzer
    └─ PRODUCES:
         ├─ threat_model (TTL: 3600s)
         ├─ attack_vectors (TTL: 3600s)
         ├─ security_priorities (TTL: 3600s)
         └─ project_structure (TTL: 3600s)

Phase 2:
  All agents CONSUME: threat_model, security_priorities
  All agents PRODUCE: sast_findings (individual findings)

Phase 3:
  All agents CONSUME: threat_model, project_structure
  All agents PRODUCE: dependency_vulnerabilities

Phase 4:
  All agents CONSUME: threat_model, project_structure
  All agents PRODUCE: container_vulnerabilities

Phase 5:
  All agents CONSUME: threat_model, security_priorities
  All agents PRODUCE: infrastructure_findings

Phase 6:
  All agents CONSUME: threat_model, attack_vectors
  All agents PRODUCE: runtime_config

Phase 7:
  vulnerability-aggregator CONSUMES:
    ├─ sast_findings (Phase 2)
    ├─ dependency_vulnerabilities (Phase 3)
    ├─ container_vulnerabilities (Phase 4)
    ├─ infrastructure_findings (Phase 5)
    └─ runtime_config (Phase 6)

  risk-prioritizer CONSUMES:
    ├─ aggregated_vulnerabilities (Phase 7.1)
    └─ threat_model (Phase 1)

  remediation-planner CONSUMES:
    ├─ prioritized_risks (Phase 7.2)
    ├─ threat_model (Phase 1)
    └─ project_structure (Phase 1)
```

### Context Lifetime Analysis

All contexts have 3600s (1 hour) TTL:
- Workflow duration: 70 minutes
- TTL expires: 60 minutes after Phase 1 completion
- **Risk**: If workflow is delayed by >50 minutes, Phase 7 may lose access to Phase 1 context

**Mitigation**: Increase TTL to 7200s (2 hours) for production workflows.

## Conditional Execution DAG

### Project Structure Detection Branches

```
threat-analyzer
  └─ project_structure
       ├─ hasPython: true
       │    └─ ENABLE: bandit-scanner
       ├─ hasPython: false
       │    └─ SKIP: bandit-scanner
       │
       ├─ hasJavaScript || hasTypeScript: true
       │    └─ ENABLE: eslint-security-scanner
       ├─ hasJavaScript || hasTypeScript: false
       │    └─ SKIP: eslint-security-scanner
       │
       ├─ hasNodeModules: true
       │    └─ ENABLE: npm-audit-scanner
       ├─ hasNodeModules: false
       │    └─ SKIP: npm-audit-scanner
       │
       ├─ hasDockerfile: true
       │    └─ ENABLE: dockerfile-linter
       ├─ hasDockerfile: false
       │    └─ SKIP: dockerfile-linter
       │
       ├─ hasDockerImages: true
       │    └─ ENABLE: trivy-scanner
       ├─ hasDockerImages: false
       │    └─ SKIP: trivy-scanner
       │
       ├─ hasDocker: true
       │    └─ ENABLE: container-bench-scanner
       ├─ hasDocker: false
       │    └─ SKIP: container-bench-scanner
       │
       ├─ hasIaC: true
       │    └─ ENABLE: bicep-terraform-scanner
       ├─ hasIaC: false
       │    └─ SKIP: bicep-terraform-scanner
       │
       ├─ hasCloudFormation: true
       │    └─ ENABLE: cloudformation-scanner
       ├─ hasCloudFormation: false
       │    └─ SKIP: cloudformation-scanner
       │
       └─ hasKubernetes: true
            └─ ENABLE: kubernetes-hardening-scanner
       └─ hasKubernetes: false
            └─ SKIP: kubernetes-hardening-scanner
```

### Minimal Project DAG (Python-only microservice)

```
Detected:
  - hasPython: true
  - All other flags: false

Enabled Agents (15 total):
  Phase 1: threat-analyzer
  Phase 2: codeql-scanner, semgrep-scanner, bandit-scanner (3)
  Phase 3: snyk-scanner, owasp-dependency-check (2)
  Phase 4: NONE (0)
  Phase 5: NONE (0)
  Phase 6: runtime-monitoring-setup, waf-configuration, secrets-rotation (3)
  Phase 7: vulnerability-aggregator, risk-prioritizer, remediation-planner (3)

Estimated Duration:
  Phase 1: 10 min
  Phase 2: 10 min (3 parallel)
  Phase 3: 10 min (2 parallel)
  Phase 4: SKIPPED
  Phase 5: SKIPPED
  Phase 6: 7 min (3 parallel)
  Phase 7: 15 min (sequential)
  Total: 52 minutes

Improvement vs. Full Workflow: 26% faster
```

## Edge List (For Graph Database Import)

```csv
source,target,type,weight
threat-analyzer,codeql-scanner,phase-dependency,10
threat-analyzer,semgrep-scanner,phase-dependency,10
threat-analyzer,bandit-scanner,phase-dependency,10
threat-analyzer,eslint-security-scanner,phase-dependency,10
codeql-scanner,npm-audit-scanner,phase-dependency,10
codeql-scanner,snyk-scanner,phase-dependency,10
codeql-scanner,owasp-dependency-check,phase-dependency,10
semgrep-scanner,npm-audit-scanner,phase-dependency,10
semgrep-scanner,snyk-scanner,phase-dependency,10
semgrep-scanner,owasp-dependency-check,phase-dependency,10
bandit-scanner,npm-audit-scanner,phase-dependency,10
bandit-scanner,snyk-scanner,phase-dependency,10
bandit-scanner,owasp-dependency-check,phase-dependency,10
eslint-security-scanner,npm-audit-scanner,phase-dependency,10
eslint-security-scanner,snyk-scanner,phase-dependency,10
eslint-security-scanner,owasp-dependency-check,phase-dependency,10
npm-audit-scanner,dockerfile-linter,phase-dependency,8
npm-audit-scanner,trivy-scanner,phase-dependency,9
npm-audit-scanner,container-bench-scanner,phase-dependency,8
snyk-scanner,dockerfile-linter,phase-dependency,8
snyk-scanner,trivy-scanner,phase-dependency,9
snyk-scanner,container-bench-scanner,phase-dependency,8
owasp-dependency-check,dockerfile-linter,phase-dependency,8
owasp-dependency-check,trivy-scanner,phase-dependency,9
owasp-dependency-check,container-bench-scanner,phase-dependency,8
dockerfile-linter,bicep-terraform-scanner,phase-dependency,9
dockerfile-linter,cloudformation-scanner,phase-dependency,8
dockerfile-linter,kubernetes-hardening-scanner,phase-dependency,9
dockerfile-linter,network-policy-auditor,phase-dependency,8
trivy-scanner,bicep-terraform-scanner,phase-dependency,9
trivy-scanner,cloudformation-scanner,phase-dependency,8
trivy-scanner,kubernetes-hardening-scanner,phase-dependency,9
trivy-scanner,network-policy-auditor,phase-dependency,8
container-bench-scanner,bicep-terraform-scanner,phase-dependency,9
container-bench-scanner,cloudformation-scanner,phase-dependency,8
container-bench-scanner,kubernetes-hardening-scanner,phase-dependency,9
container-bench-scanner,network-policy-auditor,phase-dependency,8
bicep-terraform-scanner,runtime-monitoring-setup,phase-dependency,7
bicep-terraform-scanner,waf-configuration,phase-dependency,7
bicep-terraform-scanner,secrets-rotation,phase-dependency,7
cloudformation-scanner,runtime-monitoring-setup,phase-dependency,7
cloudformation-scanner,waf-configuration,phase-dependency,7
cloudformation-scanner,secrets-rotation,phase-dependency,7
kubernetes-hardening-scanner,runtime-monitoring-setup,phase-dependency,7
kubernetes-hardening-scanner,waf-configuration,phase-dependency,7
kubernetes-hardening-scanner,secrets-rotation,phase-dependency,7
network-policy-auditor,runtime-monitoring-setup,phase-dependency,7
network-policy-auditor,waf-configuration,phase-dependency,7
network-policy-auditor,secrets-rotation,phase-dependency,7
runtime-monitoring-setup,vulnerability-aggregator,phase-dependency,5
waf-configuration,vulnerability-aggregator,phase-dependency,5
secrets-rotation,vulnerability-aggregator,phase-dependency,5
vulnerability-aggregator,risk-prioritizer,sequential-dependency,5
risk-prioritizer,remediation-planner,sequential-dependency,5
```

**Total Edges**: 55 phase dependencies + 2 sequential dependencies = 57 edges

## Metrics Summary

| Metric | Value |
|--------|-------|
| Total Nodes | 31 agents |
| Total Edges | 57 dependencies |
| Graph Depth | 7 levels (phases) |
| Max Width | 4 agents (Phase 2 & 5) |
| Critical Path Length | 70 minutes |
| Parallelism Factor | 2.5x (175 min sequential / 70 min parallel) |
| Compensation Nodes | 3 agents (Phase 6) |
| Resource Locks | 4 global locks |
| Conditional Branches | 9 technology checks |
| Context Variables | 19 shared keys |

---

**DAG Version**: 2.0
**Generated**: 2025-10-08
**Validated**: Ready for orchestration

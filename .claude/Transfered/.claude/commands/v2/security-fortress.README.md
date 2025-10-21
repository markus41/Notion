# Security Fortress v2.0 Migration Guide

## Executive Summary

**Migration Date**: 2025-10-08
**Pattern**: Hierarchical Decomposition with Saga Compensation
**Migration From**: v1.0 (Sequential execution)
**Performance Improvement**: **60% faster** (105 minutes saved)

### Performance Comparison

| Metric | v1.0 (Sequential) | v2.0 (Hierarchical) | Improvement |
|--------|-------------------|---------------------|-------------|
| Total Duration | 175 minutes | 70 minutes | 60% faster |
| Total Agents | 31 | 31 | Same |
| Phases | 7 | 7 | Same |
| Parallelism | None | 4+3+3+4+3 agents | High |
| Rollback Support | None | Saga compensation | Critical |
| Resource Locking | None | 4 global locks | Prevents conflicts |

### Key Improvements

1. **Parallel Execution Within Phases**: Multiple security scanners run concurrently
2. **Saga Compensation**: Automatic rollback for runtime security changes
3. **Resource Locking**: Prevents concurrent modifications to critical infrastructure
4. **Conditional Execution**: Skip scans for non-applicable technologies
5. **Context Sharing**: Threat model guides all security phases
6. **Priority-Based Execution**: Critical infrastructure changes prioritized

## Architecture Overview

### Hierarchical Decomposition Pattern

```
Phase 1: Threat Modeling (Sequential, 10 min)
  └─ 1 agent: threat-analyzer

Phase 2: Static Analysis (Parallel, 10 min)
  ├─ codeql-scanner
  ├─ semgrep-scanner
  ├─ bandit-scanner
  └─ eslint-security-scanner

Phase 3: Dependency Scanning (Parallel, 10 min)
  ├─ npm-audit-scanner
  ├─ snyk-scanner
  └─ owasp-dependency-check

Phase 4: Container Security (Parallel, 9 min)
  ├─ dockerfile-linter
  ├─ trivy-scanner
  └─ container-bench-scanner

Phase 5: Infrastructure Security (Parallel, 9 min)
  ├─ bicep-terraform-scanner
  ├─ cloudformation-scanner
  ├─ kubernetes-hardening-scanner
  └─ network-policy-auditor

Phase 6: Runtime Security (Parallel, 7 min) [WITH COMPENSATION]
  ├─ runtime-monitoring-setup [COMPENSABLE]
  ├─ waf-configuration [COMPENSABLE]
  └─ secrets-rotation [COMPENSABLE]

Phase 7: Reporting & Remediation (Sequential, 15 min)
  ├─ vulnerability-aggregator
  ├─ risk-prioritizer
  └─ remediation-planner
```

### Performance Analysis

#### v1.0 Sequential Execution

```
Phase 1: 10 min (1 agent)
Phase 2: 40 min (4 agents × 10 min each, sequential)
Phase 3: 30 min (3 agents × 10 min each, sequential)
Phase 4: 25 min (3 agents, sequential)
Phase 5: 35 min (4 agents, sequential)
Phase 6: 20 min (3 agents, sequential)
Phase 7: 15 min (1 agent)
Total: 175 minutes
```

#### v2.0 Parallel Within Phases

```
Phase 1: 10 min (1 agent)
Phase 2: 10 min (4 agents parallel, longest takes 10 min)
Phase 3: 10 min (3 agents parallel, longest takes 10 min)
Phase 4: 9 min (3 agents parallel, longest takes 9 min)
Phase 5: 9 min (4 agents parallel, longest takes 9 min)
Phase 6: 7 min (3 agents parallel, longest takes 7 min)
Phase 7: 15 min (3 agents sequential, 5+5+5 min)
Total: 70 minutes
```

**Improvement**: 105 minutes saved, 60% faster execution

## Phase Details

### Phase 1: Threat Modeling & Attack Surface Analysis

**Duration**: 10 minutes
**Parallelism**: None (sequential)
**Agent**: threat-analyzer

**Purpose**: Establish security baseline by analyzing application architecture and identifying potential threat vectors using STRIDE methodology.

**Outputs**:
- `threat_model`: Comprehensive threat analysis
- `attack_vectors`: Prioritized attack vectors
- `security_priorities`: Security focus areas
- `project_structure`: Technology stack and architecture

**Deliverables**:
- `threat-model.md`: STRIDE-based threat analysis
- `attack-surface-analysis.md`: External and internal attack surfaces
- `security-priorities.json`: Risk-prioritized security checklist

**Why Sequential**: All subsequent phases depend on threat model context.

---

### Phase 2: Static Application Security Testing (SAST)

**Duration**: 10 minutes (was 40 minutes in v1.0)
**Parallelism**: 4 agents running concurrently
**Improvement**: **75% faster**

**Agents**:
1. **codeql-scanner**: GitHub CodeQL for deep semantic analysis
2. **semgrep-scanner**: Pattern-based security rule matching
3. **bandit-scanner**: Python-specific security checks (conditional)
4. **eslint-security-scanner**: JavaScript/TypeScript security (conditional)

**All agents consume**: `threat_model`, `security_priorities`
**All agents output**: Language-specific security findings

**Parallelism Strategy**: All SAST tools are independent and can run simultaneously. Each analyzes different aspects of the codebase.

**Conditional Execution**:
- `bandit-scanner`: Skipped if no Python code detected
- `eslint-security-scanner`: Skipped if no JS/TS code detected

**Deliverables**:
- SARIF format results for IDE integration
- Markdown summaries for human review
- Aggregated findings feed into Phase 7

---

### Phase 3: Dependency & Supply Chain Security

**Duration**: 10 minutes (was 30 minutes in v1.0)
**Parallelism**: 3 agents running concurrently
**Improvement**: **67% faster**

**Agents**:
1. **npm-audit-scanner**: Node.js dependency vulnerabilities
2. **snyk-scanner**: Multi-ecosystem vulnerability scanning
3. **owasp-dependency-check**: CVE database matching

**All agents consume**: `threat_model`, `project_structure`
**All agents output**: Dependency vulnerabilities with CVSS scores

**Parallelism Strategy**: Each tool scans the same dependency manifests but uses different vulnerability databases (npm, Snyk DB, NVD).

**Conditional Execution**:
- `npm-audit-scanner`: Skipped if no `package.json` found

**Deliverables**:
- JSON vulnerability reports
- Fix recommendations with upgrade paths
- License compliance reports

---

### Phase 4: Container & Image Security Scanning

**Duration**: 9 minutes (was 25 minutes in v1.0)
**Parallelism**: 3 agents running concurrently
**Improvement**: **64% faster**

**Agents**:
1. **dockerfile-linter**: Hadolint for Dockerfile best practices
2. **trivy-scanner**: Image vulnerability and misconfiguration scanning
3. **container-bench-scanner**: Docker CIS Benchmark compliance

**All agents consume**: `threat_model`, `project_structure`
**All agents output**: Container security findings

**Parallelism Strategy**: Dockerfile linting, image scanning, and runtime configuration are independent checks.

**Conditional Execution**:
- All agents skip if no Docker/container usage detected

**Deliverables**:
- Dockerfile security issues
- Image vulnerability reports (OS and app dependencies)
- CIS benchmark compliance report

---

### Phase 5: Infrastructure as Code Security

**Duration**: 9 minutes (was 35 minutes in v1.0)
**Parallelism**: 4 agents running concurrently
**Improvement**: **74% faster**

**Agents**:
1. **bicep-terraform-scanner**: Azure/Terraform IaC scanning
2. **cloudformation-scanner**: AWS CloudFormation security
3. **kubernetes-hardening-scanner**: K8s manifest security
4. **network-policy-auditor**: Network segmentation validation

**All agents consume**: `threat_model`, `security_priorities`
**All agents output**: Infrastructure security findings

**Parallelism Strategy**: Each agent targets different IaC formats/platforms. Network policy audit can run independently.

**Resource Locking**:
- `network-policy-auditor` locks `network-policies` resource (read-only analysis, but prevents concurrent modifications)

**Conditional Execution**:
- Agents skip if relevant IaC templates not detected

**Deliverables**:
- IaC misconfiguration reports
- Cloud security posture assessment
- Kubernetes hardening recommendations
- Network segmentation analysis

---

### Phase 6: Runtime Security Configuration

**Duration**: 7 minutes (was 20 minutes in v1.0)
**Parallelism**: 3 agents running concurrently
**Improvement**: **65% faster**

**Critical Feature**: **SAGA COMPENSATION ENABLED**

**Agents**:
1. **runtime-monitoring-setup**: Configure RASP and intrusion detection
2. **waf-configuration**: Update Web Application Firewall rules
3. **secrets-rotation**: Rotate credentials and API keys

**All agents consume**: `threat_model`, `attack_vectors`
**All agents output**: Runtime configuration state

**Why Compensation Needed**: These agents make destructive changes to production systems. If any agent fails or if the overall workflow fails, we must rollback changes.

#### Saga Compensation Details

##### runtime-monitoring-setup

**Change**: Deploys new Falco/Sysdig runtime monitoring rules

**Compensation**:
- **Agent**: devops-automator
- **Task**: "Rollback runtime monitoring configuration to previous state from backup"
- **Priority**: 1 (highest)
- **Deliverable**: `runtime-monitoring-rollback-log.md`

**Rollback Process**:
1. Restore previous Falco rules from Git/backup
2. Restart monitoring services
3. Verify alerts are functioning
4. Log rollback operations

##### waf-configuration

**Change**: Updates WAF rules, rate limits, IP filtering

**Compensation**:
- **Agent**: devops-automator
- **Task**: "Rollback WAF rules to previous configuration snapshot"
- **Priority**: 1 (highest)
- **Deliverable**: `waf-rollback-log.md`, `waf-config-restore-verification.md`

**Rollback Process**:
1. Retrieve previous WAF configuration from Azure/Cloudflare API
2. Restore ruleset to last known good state
3. Verify WAF is blocking test attacks
4. Validate no legitimate traffic blocked

##### secrets-rotation

**Change**: Rotates API keys, certificates, database credentials

**Compensation**:
- **Agent**: cryptography-expert
- **Task**: "Rotate back to previous secret versions from Key Vault version history"
- **Priority**: 1 (highest)
- **Deliverable**: `secrets-restore-log.md`, `credential-verification-report.md`

**Rollback Process**:
1. Query Azure Key Vault for previous secret versions
2. Promote previous versions to current
3. Update application references (if needed)
4. Verify all services can authenticate
5. Test database connections, API calls

#### Resource Locking

All Phase 6 agents require exclusive locks:

| Agent | Resource Lock | Priority | Timeout |
|-------|---------------|----------|---------|
| runtime-monitoring-setup | `runtime-monitoring` | 4 | 300s |
| waf-configuration | `waf-config` | 4 | 300s |
| secrets-rotation | `secrets-vault` | 4 | 300s |

**Purpose**: Prevent concurrent security changes that could cause conflicts or inconsistent state.

**Deliverables**:
- Runtime monitoring configuration files
- WAF rules and testing plans
- Secrets rotation logs and access reviews

---

### Phase 7: Reporting & Remediation Planning

**Duration**: 15 minutes
**Parallelism**: Sequential (3 agents with dependencies)

**Agents**:
1. **vulnerability-aggregator**: Consolidate all findings from phases 2-6
2. **risk-prioritizer**: Apply CVSS scoring and risk framework
3. **remediation-planner**: Create actionable remediation plan

**Sequential Execution Required**: Each agent depends on previous output.

#### vulnerability-aggregator

**Consumes** (all outputs from phases 2-6):
- `sast_findings` (Phase 2)
- `dependency_vulnerabilities` (Phase 3)
- `container_vulnerabilities` (Phase 4)
- `infrastructure_findings` (Phase 5)
- `runtime_config` (Phase 6)
- Plus 14 more granular outputs from individual scanners

**Task**: Deduplicate, normalize severity, create unified vulnerability database

**Output**: `aggregated_vulnerabilities`

**Deliverables**:
- `vulnerability-database.json`: Structured vulnerability data
- `aggregated-findings.md`: Human-readable summary
- `deduplication-report.md`: Shows duplicate findings across tools

#### risk-prioritizer

**Consumes**:
- `aggregated_vulnerabilities`
- `threat_model`
- `attack_vectors`
- `security_priorities`

**Task**: Apply CVSS v3.1 scoring, DREAD risk framework, and business impact analysis

**Output**: `prioritized_risks`

**Deliverables**:
- `risk-matrix.md`: Visual risk prioritization
- `prioritized-vulnerabilities.json`: Sorted by urgency
- `cvss-analysis.md`: CVSS score breakdown

#### remediation-planner

**Consumes**:
- `prioritized_risks`
- `threat_model`
- `project_structure`

**Task**: Create comprehensive remediation plan with timelines, owners, and acceptance criteria

**Output**: `remediation_plan`

**Deliverables**:
- `remediation-plan.md`: Detailed action items
- `executive-summary.md`: C-level overview
- `technical-remediation-guides/`: Step-by-step fix instructions
- `security-metrics-dashboard.md`: KPIs and tracking
- `compliance-checklist.md`: OWASP, CIS, PCI-DSS compliance

---

## Context Flow Diagram

```
Phase 1 (Threat Modeling)
  ↓ outputs: threat_model, attack_vectors, security_priorities, project_structure
  ↓
Phase 2 (SAST) ← consumes threat_model
  ↓ outputs: sast_findings (codeql, semgrep, bandit, eslint)
  ↓
Phase 3 (Dependencies) ← consumes threat_model
  ↓ outputs: dependency_vulnerabilities (npm, snyk, owasp)
  ↓
Phase 4 (Containers) ← consumes threat_model
  ↓ outputs: container_vulnerabilities (hadolint, trivy, docker-bench)
  ↓
Phase 5 (Infrastructure) ← consumes threat_model
  ↓ outputs: infrastructure_findings (iac, k8s, network)
  ↓
Phase 6 (Runtime) ← consumes threat_model, attack_vectors
  ↓ outputs: runtime_config
  ↓
Phase 7 (Reporting) ← consumes ALL outputs from phases 2-6
  ↓ outputs: remediation_plan
  ↓
COMPLETE
```

## Saga Compensation Flow

### Normal Execution (Success)

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 ✓
                                                      ↓
                                                  All changes committed
                                                  No compensation needed
```

### Failure During Phase 6

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 (runtime-monitoring-setup ✓)
                                                      ↓
                                                  waf-configuration ✓
                                                      ↓
                                                  secrets-rotation ✗ FAILS
                                                      ↓
                                              SAGA COMPENSATION TRIGGERED
                                                      ↓
                                    ┌─────────────────┴─────────────────┐
                                    ↓                                   ↓
                        Rollback secrets-rotation           Rollback waf-configuration
                        (cryptography-expert)                (devops-automator)
                                    ↓                                   ↓
                        Restore previous secrets            Restore previous WAF rules
                                    ↓                                   ↓
                                    └─────────────────┬─────────────────┘
                                                      ↓
                                    Rollback runtime-monitoring-setup
                                        (devops-automator)
                                                      ↓
                                    Restore previous Falco rules
                                                      ↓
                                              ALL CHANGES REVERTED
                                              System restored to pre-Phase 6 state
```

### Failure During Phase 7

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 ✓ → Phase 7 ✗ FAILS
                                                                      ↓
                                                          Phase 6 changes committed
                                                          Phase 7 is read-only (no compensation)
                                                                      ↓
                                                          Workflow marked as partial success
                                                          Manual review of Phase 7 required
```

**Key Insight**: Only Phase 6 has compensation because it's the only phase with destructive operations. Phases 2-5 are read-only scanning operations that don't modify infrastructure.

## Resource Locking Strategy

### Global Resource Locks

| Resource ID | Description | Max Concurrent | Protected Operations |
|-------------|-------------|----------------|----------------------|
| `waf-config` | WAF configuration | 1 | WAF rule updates |
| `secrets-vault` | Key Vault/Secrets Manager | 1 | Secret rotation |
| `runtime-monitoring` | Falco/Sysdig config | 1 | Monitoring rule updates |
| `network-policies` | Network security policies | 1 | Network policy audits |

### Lock Acquisition Order (Deadlock Prevention)

All Phase 6 agents acquire locks in parallel since they lock different resources. No deadlock risk.

**Phase 5** (`network-policy-auditor`) and **Phase 6** (`waf-configuration`) both work with network security but:
- Phase 5 runs first (dependency enforced)
- Phase 5 is read-only audit (advisory lock)
- Phase 6 modifies configuration (exclusive lock)

### Lock Timeout Handling

All locks have 300-second (5-minute) timeout:
- If agent cannot acquire lock within 5 minutes, fail fast
- Trigger saga compensation if in Phase 6
- Log lock contention for monitoring

## Conditional Execution Logic

### Project Structure Detection

The `threat-analyzer` in Phase 1 outputs `project_structure`:

```json
{
  "hasPython": true,
  "hasJavaScript": true,
  "hasTypeScript": true,
  "hasDockerfile": true,
  "hasDockerImages": true,
  "hasDocker": true,
  "hasIaC": true,
  "hasCloudFormation": false,
  "hasKubernetes": true,
  "hasNodeModules": true
}
```

### Skip Conditions

| Agent | Skip Condition | Impact |
|-------|----------------|--------|
| bandit-scanner | `!project_structure.hasPython` | Phase 2 runs 3 agents instead of 4 |
| eslint-security-scanner | `!project_structure.hasJavaScript && !project_structure.hasTypeScript` | Phase 2 runs 3 agents |
| npm-audit-scanner | `!project_structure.hasNodeModules` | Phase 3 runs 2 agents |
| dockerfile-linter | `!project_structure.hasDockerfile` | Phase 4 runs 2 agents |
| trivy-scanner | `!project_structure.hasDockerImages` | Phase 4 runs 2 agents |
| container-bench-scanner | `!project_structure.hasDocker` | Phase 4 runs 2 agents |
| bicep-terraform-scanner | `!project_structure.hasIaC` | Phase 5 runs 3 agents |
| cloudformation-scanner | `!project_structure.hasCloudFormation` | Phase 5 runs 3 agents |
| kubernetes-hardening-scanner | `!project_structure.hasKubernetes` | Phase 5 runs 3 agents |

**Performance Impact**: If a project has minimal tech stack (e.g., only Python backend, no containers, no IaC), execution time could drop to ~40 minutes.

## Agent Type Mapping

| Agent ID | Agent Type | Justification |
|----------|-----------|---------------|
| threat-analyzer | security-specialist | Threat modeling expertise |
| All SAST scanners | security-specialist | Code security analysis |
| All dependency scanners | security-specialist | Vulnerability assessment |
| All container scanners | security-specialist | Container security expertise |
| All IaC scanners | security-specialist | Infrastructure security |
| runtime-monitoring-setup | devops-automator | Infrastructure deployment |
| waf-configuration | devops-automator | Network/WAF configuration |
| secrets-rotation | security-specialist | Cryptography and secrets management |
| vulnerability-aggregator | security-specialist | Security data analysis |
| risk-prioritizer | security-specialist | Risk assessment |
| remediation-planner | security-specialist | Security strategy |

## Deliverables Summary

### Phase 1 Deliverables (3 files)
- `threat-model.md`
- `attack-surface-analysis.md`
- `security-priorities.json`

### Phase 2 Deliverables (8 files)
- `codeql-results.sarif`, `codeql-summary.md`
- `semgrep-results.json`, `semgrep-summary.md`
- `bandit-results.json`, `bandit-summary.md`
- `eslint-security-results.json`, `eslint-security-summary.md`

### Phase 3 Deliverables (9 files)
- `npm-audit-results.json`, `npm-audit-summary.md`, `npm-audit-fix-recommendations.md`
- `snyk-results.json`, `snyk-summary.md`, `snyk-fix-pr-candidates.md`
- `dependency-check-report.html`, `dependency-check-results.json`, `cve-summary.md`

### Phase 4 Deliverables (6 files)
- `hadolint-results.json`, `dockerfile-security-issues.md`
- `trivy-results.json`, `trivy-summary.md`, `image-vulnerabilities.md`
- `docker-bench-results.log`, `docker-cis-benchmark-summary.md`

### Phase 5 Deliverables (10 files)
- `iac-security-results.json`, `bicep-terraform-misconfigurations.md`, `cloud-security-posture.md`
- `cfn-nag-results.json`, `cloudformation-security-issues.md`
- `k8s-security-results.json`, `kubernetes-hardening-report.md`, `pod-security-recommendations.md`
- `network-policy-audit.md`, `network-segmentation-report.md`, `firewall-rules-analysis.md`

### Phase 6 Deliverables (9 files)
- `runtime-monitoring-config.yml`, `falco-rules.yml`, `runtime-security-setup.md`
- `waf-rules.json`, `waf-configuration.md`, `waf-testing-plan.md`
- `secrets-rotation-log.md`, `key-vault-audit.md`, `secrets-access-review.md`

### Phase 7 Deliverables (10 files + 1 directory)
- `vulnerability-database.json`, `aggregated-findings.md`, `deduplication-report.md`
- `risk-matrix.md`, `prioritized-vulnerabilities.json`, `cvss-analysis.md`
- `remediation-plan.md`, `executive-summary.md`, `security-metrics-dashboard.md`, `compliance-checklist.md`
- `technical-remediation-guides/` (directory with per-vulnerability fix guides)

**Total**: 55+ deliverable files across all phases

## Error Handling & Resilience

### Retry Policy

```json
{
  "maxAttempts": 3,
  "backoffMultiplier": 2,
  "initialDelay": 5000
}
```

**Example**: If `trivy-scanner` fails due to network timeout:
1. First retry after 5 seconds
2. Second retry after 10 seconds (5 × 2)
3. Third retry after 20 seconds (10 × 2)
4. After 3 failures, mark agent as failed

### Fallback Strategy

**Mode**: `continue-with-warnings`

**Behavior**:
- Non-critical agent failures don't stop the workflow
- Failed agents are logged as warnings
- Workflow continues to completion
- Final report includes list of skipped/failed scans

**Exception**: Phase 6 is marked as `criticalPhases`
- Any Phase 6 agent failure triggers saga compensation
- Workflow stops and rolls back Phase 6 changes

### Monitoring & Observability

**Progress Reporting**: Enabled

**Checkpoints** (5 total):
1. After Phase 2: "SAST scans completed"
2. After Phase 3: "Dependency vulnerabilities identified"
3. After Phase 5: "IaC security validated"
4. After Phase 6: "Runtime security configured (with rollback capability)"
5. After Phase 7: "Remediation plan ready"

**Metrics Collected**:
- Phase duration (actual vs. estimated)
- Agent execution time
- Number of vulnerabilities by severity
- Compensation events (if any)
- Lock contention events

## Success Criteria

The workflow is considered successful when:

- [x] All 7 phases completed
- [x] All enabled agents executed (respecting conditional logic)
- [x] Phase 7 generated remediation plan
- [x] No critical vulnerabilities left unaddressed (or documented acceptance)
- [x] Saga compensation tests pass (if Phase 6 had failures)
- [x] All resource locks released
- [x] All deliverables produced

**Partial Success**: If Phase 6 fails but compensation succeeds, workflow is marked as "Completed with warnings - Runtime security changes not applied."

## Migration Checklist

### Pre-Migration
- [ ] Review current v1.0 workflow execution patterns
- [ ] Identify custom security tools in use
- [ ] Document current WAF, monitoring, and secrets configuration (for rollback)
- [ ] Backup Key Vault secrets
- [ ] Test saga compensation in non-production environment

### Migration
- [ ] Deploy v2.0 workflow definition
- [ ] Configure conditional execution based on project structure
- [ ] Set up resource locks in orchestration platform
- [ ] Configure saga compensation handlers
- [ ] Update monitoring dashboards

### Post-Migration
- [ ] Execute v2.0 workflow on test project
- [ ] Verify parallelism is working (check execution logs)
- [ ] Test saga compensation (intentionally fail Phase 6 agent)
- [ ] Validate all deliverables are generated
- [ ] Compare v2.0 vs v1.0 findings (should be identical)
- [ ] Measure actual vs. estimated duration
- [ ] Document any workflow adjustments needed

## Troubleshooting

### Issue: Phase 2 not parallelizing

**Symptoms**: SAST scans run sequentially (40 min instead of 10 min)

**Diagnosis**:
```bash
# Check orchestration logs for parallel execution
grep "parallel" workflow-execution.log
```

**Solution**:
- Verify `"parallelism": { "enabled": true }` in Phase 2 definition
- Check max concurrent agents setting in orchestrator
- Ensure agents have no hidden dependencies

---

### Issue: Saga compensation not triggering

**Symptoms**: Phase 6 failure doesn't rollback changes

**Diagnosis**:
```bash
# Check saga configuration
grep "compensation" security-fortress.json
```

**Solution**:
- Verify `"saga": { "enabled": true }` at workflow level
- Ensure each Phase 6 agent has `compensation` block
- Check compensation agent IDs are valid
- Review orchestrator saga handler logs

---

### Issue: Resource lock timeout

**Symptoms**: `waf-configuration` fails with "Lock acquisition timeout"

**Diagnosis**:
```bash
# Check lock acquisition logs
grep "resource lock" workflow-execution.log
```

**Solution**:
- Increase lock timeout from 300s to 600s
- Check for orphaned locks from previous failed workflows
- Manually release stuck locks via orchestrator API

---

### Issue: Conditional execution skipping too many agents

**Symptoms**: Many agents skipped, execution time too short

**Diagnosis**:
```bash
# Check project structure detection
cat outputs/security-priorities.json | jq '.project_structure'
```

**Solution**:
- Verify `threat-analyzer` correctly detected project technologies
- Update conditional logic if detection is incorrect
- Manually override `project_structure` for testing

---

### Issue: Phase 7 missing findings from Phase 2-6

**Symptoms**: `aggregated_vulnerabilities` incomplete

**Diagnosis**:
```bash
# Check context propagation
grep "context.*outputs" workflow-execution.log
```

**Solution**:
- Ensure all Phase 2-6 agents specify `outputs` in context
- Verify Phase 7 agents list all inputs in `context.inputs`
- Check context TTL (3600s) hasn't expired
- Review orchestrator context storage

## Performance Tuning

### Optimize for Small Projects

If project has minimal tech stack (e.g., Python-only microservice):

**Expected Duration**: ~40 minutes (instead of 70)

**Skipped Agents**:
- eslint-security-scanner (no JS/TS)
- npm-audit-scanner (no Node.js)
- dockerfile-linter, trivy-scanner, container-bench-scanner (no containers)
- cloudformation-scanner (no AWS)

**Tuning**:
- Reduce timeout for conditional checks
- Skip Phase 4 entirely if no containers

### Optimize for Large Codebases

If codebase is very large (>100k LOC):

**Bottlenecks**:
- CodeQL analysis (can take >10 min)
- Trivy image scanning (large images)

**Tuning**:
- Increase Phase 2 estimated duration to 15 min
- Increase Phase 4 estimated duration to 12 min
- Use CodeQL incremental analysis
- Cache Trivy vulnerability database

### Optimize for Frequent Execution

If running security-fortress daily:

**Optimizations**:
- Cache dependency vulnerability databases
- Skip unchanged files in SAST scans
- Use incremental Trivy scans
- Reduce Phase 1 threat modeling to 5 min (use cached model)

**Expected Duration**: ~50 minutes (28% improvement)

## Best Practices

### 1. Run security-fortress regularly

**Recommended**: Weekly in CI/CD pipeline, blocking merges to main

### 2. Act on Critical findings immediately

**Process**:
1. Review `executive-summary.md` from Phase 7
2. Address all CRITICAL vulnerabilities within 24 hours
3. Plan HIGH vulnerabilities within 1 week
4. Schedule MEDIUM/LOW for next sprint

### 3. Test saga compensation

**Monthly drill**:
1. Intentionally fail `secrets-rotation` agent
2. Verify all Phase 6 changes rolled back
3. Confirm system returns to working state
4. Document compensation time and success

### 4. Monitor lock contention

**Alerting**: Set up alert if any lock wait time >60 seconds
- Indicates concurrent security workflows
- May need workflow scheduling

### 5. Keep threat model updated

**Quarterly review**:
- Re-run Phase 1 manually with architecture changes
- Update `security_priorities.json`
- Adjust scanner configurations based on new threats

## Appendix: Agent Configuration Examples

### CodeQL Configuration

```yaml
# .github/workflows/codeql.yml
queries:
  - uses: security-extended
  - uses: security-and-quality
languages:
  - javascript
  - typescript
  - python
  - csharp
paths-ignore:
  - 'tests/**'
  - 'docs/**'
```

### Semgrep Configuration

```yaml
# .semgrep.yml
rules:
  - id: hardcoded-secret
    pattern: |
      apiKey = "..."
    severity: ERROR
    languages: [javascript, python]
```

### Trivy Configuration

```yaml
# trivy.yaml
severity: CRITICAL,HIGH,MEDIUM
scanners:
  - vuln
  - config
  - secret
ignore-unfixed: false
```

### WAF Rules Example (Phase 6)

```json
{
  "ruleGroups": [
    {
      "name": "OWASP-CRS-3.3",
      "rules": [
        { "ruleId": "942100", "action": "Block" },
        { "ruleId": "942200", "action": "Block" }
      ]
    },
    {
      "name": "Custom-Application-Rules",
      "rules": [
        {
          "ruleId": "custom-001",
          "description": "Block suspicious user agents",
          "pattern": "sqlmap|nikto|nmap",
          "action": "Block"
        }
      ]
    }
  ],
  "rateLimits": {
    "requestsPerMinute": 1000,
    "burstSize": 100
  }
}
```

## References

- **STRIDE Threat Modeling**: Microsoft Security Development Lifecycle
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks/
- **CVSS v3.1**: https://www.first.org/cvss/
- **Saga Pattern**: https://microservices.io/patterns/data/saga.html
- **Azure Key Vault Versioning**: https://learn.microsoft.com/azure/key-vault/

---

**Migration Author**: Security Team
**Review Date**: 2025-10-08
**Next Review**: 2026-01-08
**Status**: Production Ready

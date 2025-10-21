# Documentation CI/CD Architecture

## System Architecture Diagram

```mermaid
graph TB
    subgraph "Developer Workflow"
        DEV[Developer] --> |1. Edit docs| EDIT[Edit Markdown Files]
        EDIT --> |2. Run locally| LOCAL[npm run docs:lint]
        LOCAL --> |3. Fix issues| EDIT
        LOCAL --> |4. Commit| GIT[Git Commit]
    end

    subgraph "Git Triggers"
        GIT --> |Push to main| TRIGGER1[Workflow Trigger]
        PR[Pull Request] --> |PR to main| TRIGGER1
        MANUAL[Manual Dispatch] --> TRIGGER1
    end

    subgraph "CI/CD Workflows"
        TRIGGER1 --> LINT[docs-lint.yml]
        TRIGGER1 --> BUILD[docs-build.yml]

        subgraph "docs-lint.yml Jobs"
            LINT --> FM[Frontmatter Validation]
            LINT --> LC[Link Checking]
            LINT --> SC[Spell Checking]
            LINT --> DC[Duplicate Detection]

            FM --> |validate-frontmatter.js| FM_OUT[docs-validation-report.json]
            LC --> |markdown-link-check| LC_OUT[Console Output]
            SC --> |cspell| SC_OUT[Console Output]
            DC --> |detect-duplicates.js| DC_OUT[duplicate-content-report.json]
        end

        subgraph "docs-build.yml Jobs"
            BUILD --> VB[VitePress Build]
            BUILD --> PC[Performance Check]
            BUILD --> AC[Accessibility Check]

            VB --> |npm run docs:build| DIST[dist/ folder]
            PC --> |Bundle Analysis| PC_OUT[Size Report]
            AC --> |HTML Validation| AC_OUT[A11y Report]
        end
    end

    subgraph "Quality Gates"
        FM_OUT --> GATE{All Checks Pass?}
        LC_OUT --> GATE
        SC_OUT --> GATE
        DC_OUT --> GATE
        DIST --> GATE

        GATE --> |Yes| SUCCESS[✅ Build Success]
        GATE --> |No| FAIL[❌ Build Failed]

        SUCCESS --> MERGE[Merge PR]
        FAIL --> NOTIFY[Notify Developer]
        NOTIFY --> EDIT
    end

    subgraph "Outputs"
        SUCCESS --> SUMMARY[GitHub Actions Summary]
        FAIL --> SUMMARY
        SUMMARY --> BADGE[Status Badges]
        FM_OUT --> ARTIFACT[Artifacts]
        DC_OUT --> ARTIFACT
        DIST --> ARTIFACT
    end

    style DEV fill:#e1f5fe
    style SUCCESS fill:#c8e6c9
    style FAIL fill:#ffcdd2
    style GATE fill:#fff9c4
    style SUMMARY fill:#f3e5f5
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "Input"
        MD[Markdown Files] --> |Read| PARSER[Parser]
    end

    subgraph "Validation Pipeline"
        PARSER --> FM_V[Frontmatter Validator]
        PARSER --> LINK_V[Link Validator]
        PARSER --> SPELL_V[Spell Validator]
        PARSER --> DUP_V[Duplicate Detector]

        FM_V --> |Validate YAML| FM_R{Valid?}
        LINK_V --> |Check URLs| LINK_R{Links OK?}
        SPELL_V --> |Check Words| SPELL_R{Spelling OK?}
        DUP_V --> |Compare Content| DUP_R{Duplicates?}
    end

    subgraph "Results Aggregation"
        FM_R --> |Errors| AGG[Result Aggregator]
        LINK_R --> |Errors| AGG
        SPELL_R --> |Errors| AGG
        DUP_R --> |Warnings| AGG

        AGG --> REPORT[Generate Reports]
    end

    subgraph "Output"
        REPORT --> JSON[JSON Reports]
        REPORT --> CONSOLE[Console Output]
        REPORT --> SUMMARY[GitHub Summary]
        REPORT --> EXIT{Exit Code}

        EXIT --> |0| PASS[Success]
        EXIT --> |1| ERROR[Failure]
    end

    style MD fill:#e3f2fd
    style PASS fill:#c8e6c9
    style ERROR fill:#ffcdd2
    style REPORT fill:#fff9c4
```

## Workflow Execution Timeline

```mermaid
gantt
    title Documentation CI/CD Execution Timeline
    dateFormat  ss
    section Frontmatter
    Validate frontmatter :fm, 00, 30s
    section Links
    Check all links :link, 00, 120s
    section Spelling
    Spell check docs :spell, 00, 15s
    section Duplicates
    Detect duplicates :dup, 00, 30s
    section Build
    VitePress build :build, 00, 60s
    Performance check :perf, after build, 10s
    Accessibility check :a11y, after build, 10s
    section Summary
    Generate summary :summary, after a11y, 10s
```

## Component Interaction Diagram

```mermaid
graph LR
    subgraph "Scripts Layer"
        VF[validate-frontmatter.js]
        DD[detect-duplicates.js]
    end

    subgraph "Tools Layer"
        MLC[markdown-link-check]
        CS[cspell]
        VP[VitePress]
    end

    subgraph "Config Layer"
        CSPELL_CFG[.cspell.json]
        LINK_CFG[.markdown-link-check.json]
        VP_CFG[.vitepress/config.ts]
    end

    subgraph "Data Layer"
        MD_FILES[docs/**/*.md]
        ASSETS[docs/assets/]
    end

    MD_FILES --> VF
    MD_FILES --> DD
    MD_FILES --> MLC
    MD_FILES --> CS
    MD_FILES --> VP

    CSPELL_CFG --> CS
    LINK_CFG --> MLC
    VP_CFG --> VP
    ASSETS --> VP

    VF --> REPORT1[validation-report.json]
    DD --> REPORT2[duplicate-report.json]
    VP --> DIST[dist/]

    style MD_FILES fill:#e3f2fd
    style REPORT1 fill:#fff9c4
    style REPORT2 fill:#fff9c4
    style DIST fill:#c8e6c9
```

## Quality Gate Decision Tree

```mermaid
graph TD
    START[Documentation Changed] --> FM{Frontmatter Valid?}

    FM --> |No| FM_FAIL[❌ Fail: Missing/Invalid Frontmatter]
    FM --> |Yes| LINKS{Links Valid?}

    LINKS --> |Broken Internal| LINK_FAIL[❌ Fail: Broken Internal Links]
    LINKS --> |All Valid| SPELL{Spelling Correct?}

    SPELL --> |Errors| SPELL_FAIL[❌ Fail: Spelling Errors]
    SPELL --> |OK| BUILD{Build Success?}

    BUILD --> |No| BUILD_FAIL[❌ Fail: Build Error]
    BUILD --> |Yes| DUP{Duplicates Found?}

    DUP --> |Yes| DUP_WARN[⚠️ Warning: Review Duplicates]
    DUP --> |No| PERF{Performance OK?}

    PERF --> |Large Bundles| PERF_WARN[⚠️ Warning: Large Bundles]
    PERF --> |OK| SUCCESS[✅ All Checks Passed]

    DUP_WARN --> SUCCESS
    PERF_WARN --> SUCCESS

    FM_FAIL --> NOTIFY[Notify Developer]
    LINK_FAIL --> NOTIFY
    SPELL_FAIL --> NOTIFY
    BUILD_FAIL --> NOTIFY

    SUCCESS --> MERGE[Approve Merge]
    NOTIFY --> FIX[Developer Fixes Issues]
    FIX --> START

    style SUCCESS fill:#c8e6c9
    style FM_FAIL fill:#ffcdd2
    style LINK_FAIL fill:#ffcdd2
    style SPELL_FAIL fill:#ffcdd2
    style BUILD_FAIL fill:#ffcdd2
    style DUP_WARN fill:#fff59d
    style PERF_WARN fill:#fff59d
```

## Integration Architecture

```mermaid
C4Context
    title Documentation CI/CD Integration Architecture

    Person(dev, "Developer", "Writes and updates documentation")

    System_Boundary(ci, "CI/CD System") {
        Container(gh_actions, "GitHub Actions", "Workflow Engine", "Executes validation workflows")
        Container(lint_workflow, "docs-lint.yml", "Workflow", "Quality checks")
        Container(build_workflow, "docs-build.yml", "Workflow", "Build validation")
    }

    System_Boundary(tools, "Validation Tools") {
        Container(scripts, "Custom Scripts", "Node.js", "Frontmatter & Duplicate detection")
        Container(cspell, "cspell", "CLI Tool", "Spell checking")
        Container(link_check, "markdown-link-check", "CLI Tool", "Link validation")
        Container(vitepress, "VitePress", "SSG", "Documentation build")
    }

    System_Boundary(storage, "Storage & Reports") {
        ContainerDb(artifacts, "Artifacts", "Storage", "JSON reports, build output")
        Container(summary, "GitHub Summary", "Markdown", "Visual reports")
        Container(badges, "Status Badges", "SVG", "Build status")
    }

    Rel(dev, gh_actions, "Push/PR")
    Rel(gh_actions, lint_workflow, "Triggers")
    Rel(gh_actions, build_workflow, "Triggers")

    Rel(lint_workflow, scripts, "Runs")
    Rel(lint_workflow, cspell, "Runs")
    Rel(lint_workflow, link_check, "Runs")
    Rel(build_workflow, vitepress, "Runs")

    Rel(scripts, artifacts, "Saves reports")
    Rel(lint_workflow, summary, "Generates")
    Rel(build_workflow, summary, "Generates")
    Rel(gh_actions, badges, "Updates")

    Rel(artifacts, dev, "Downloads for review")
    Rel(summary, dev, "Views in GitHub")
```

## Deployment Flow

```mermaid
sequenceDiagram
    participant D as Developer
    participant G as Git
    participant A as GitHub Actions
    participant V as Validators
    participant B as Build System
    participant R as Reports

    D->>G: git push origin main
    G->>A: Trigger workflows

    par Parallel Execution
        A->>V: Run frontmatter validation
        A->>V: Run link checking
        A->>V: Run spell checking
        A->>V: Run duplicate detection
    end

    V->>R: Generate validation reports

    alt All Validations Pass
        A->>B: Start VitePress build
        B->>B: Build documentation
        B->>B: Performance check
        B->>B: Accessibility check
        B->>R: Save build artifacts
        R->>A: ✅ Success summary
        A->>D: Notify success
    else Validation Fails
        R->>A: ❌ Failure report
        A->>D: Notify failure with details
        D->>D: Fix issues
        D->>G: git push (retry)
    end
```

## Error Handling Flow

```mermaid
stateDiagram-v2
    [*] --> Running: Workflow Starts

    Running --> Frontmatter: Validate Frontmatter
    Frontmatter --> Links: Success
    Frontmatter --> Failed: Missing/Invalid

    Links --> Spelling: All Links Valid
    Links --> Failed: Broken Internal Links
    Links --> Warning: Broken External Links (Continue)

    Warning --> Spelling: Continue

    Spelling --> Duplicates: No Errors
    Spelling --> Failed: Spelling Errors

    Duplicates --> Build: Check Complete

    Build --> Performance: Build Success
    Build --> Failed: Build Error

    Performance --> Accessibility: Size OK
    Performance --> Warning: Large Bundles (Continue)

    Warning --> Accessibility: Continue

    Accessibility --> Success: Valid HTML
    Accessibility --> Failed: Invalid HTML

    Success --> [*]: ✅ All Passed
    Failed --> Notify: ❌ Send Notification
    Notify --> [*]: Developer Fixes
```

## File Organization

```
Project-Ascension/
├── .github/
│   ├── workflows/
│   │   ├── docs-lint.yml          # Main linting workflow
│   │   └── docs-build.yml         # Build validation workflow
│   └── DOCS-QUALITY-GUIDE.md      # Quick reference guide
│
├── docs/
│   ├── .vitepress/
│   │   └── config.ts              # VitePress configuration
│   ├── assets/
│   │   └── diagrams/
│   │       └── docs-ci-architecture.md  # This file
│   ├── CI-CD-DOCUMENTATION.md     # Comprehensive documentation
│   └── **/*.md                    # Documentation files
│
├── scripts/
│   ├── validate-frontmatter.js    # Frontmatter validator
│   ├── detect-duplicates.js       # Duplicate detector
│   └── README.md                  # Scripts documentation
│
├── .cspell.json                   # Spell checker config
├── .markdown-link-check.json      # Link checker config
└── package.json                   # NPM scripts
```

---

## Key Performance Indicators (KPIs)

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Workflow Execution Time | <3 min | ~2.5 min | ✅ |
| Documentation Files | 44+ | 44 | ✅ |
| Frontmatter Coverage | 100% | TBD | 🔄 |
| Broken Links | 0 | 94 | ⚠️ |
| Spelling Errors | 0 | TBD | 🔄 |
| Build Success Rate | >95% | TBD | 🔄 |

## Next Steps

1. ✅ **Sprint 1, Task 2**: Implement CI/CD automated checks (COMPLETED)
2. 🔄 **Sprint 2**: Fix 94 dead links and consolidate duplicate content
3. 📋 **Sprint 3**: Add frontmatter to all files and optimize build
4. 🚀 **Sprint 4**: Deploy documentation to GitHub Pages

---

**Diagrams Created Using**: Mermaid.js
**Last Updated**: 2025-10-08
**Maintained By**: DevOps Team

# GAEH Installer Upgrade Spec (v0.2)

## Pre-output Self Review

### Alignment Check

Checked against prior agreed architecture:

-   [x] GAEH is positioned as **Protocol + Skills + State + Bootstrap**,
    not Runtime
-   [x] Codex / Cursor are treated as host runtimes
-   [x] Existing zip is preserved (not rewritten)
-   [x] Upgrade target is Installer Layer
-   [x] Adapter Layer for Codex/Cursor is added
-   [x] Bootstrap script is extended, not replaced
-   [x] State schema remains compatible
-   [x] Future CLI path remains open (`gaeh init`, `gaeh doctor`,
    `gaeh next`)

Review Decision:

**PASS**

Scope is consistent with prior discussion.

------------------------------------------------------------------------

# Goal

Upgrade the current GAEH zip package from:

``` text
Bootstrap Skeleton
```

to:

``` text
Installable Agent Kit
```

without changing core protocol.

------------------------------------------------------------------------

# Current State Assessment

Current package already has:

``` text
templates/project_control/
templates/ai_harness/
templates/plans/
templates/reviews/
templates/reports/
gaeh-bootstrap.ps1
README.md
GAEH_Implementation_Spec.md
```

Current capability:

``` text
Manual unzip
Manual bootstrap
Manual invocation
```

Current limitation:

``` text
No native Codex adapter
No native Cursor adapter
No installation validation
No installer abstraction
```

------------------------------------------------------------------------

# Upgrade Objectives

## Objective 1

Add Codex native adapter.

------------------------------------------------------------------------

## Objective 2

Add Cursor native adapter.

------------------------------------------------------------------------

## Objective 3

Upgrade bootstrap script.

------------------------------------------------------------------------

## Objective 4

Add installation validation.

------------------------------------------------------------------------

## Objective 5

Prepare future CLI migration.

------------------------------------------------------------------------

# Required File Changes

## 1. Add Codex Adapter

Create:

``` text
/adapters/codex/SKILL.md
```

Install target:

``` text
[target]/.codex/skills/gaeh/SKILL.md
```

Purpose:

Enable Codex native GAEH behavior.

------------------------------------------------------------------------

## 2. Add Cursor Adapter

Create:

``` text
/adapters/cursor/gaeh.mdc
```

Install target:

``` text
[target]/.cursor/rules/gaeh.mdc
```

Purpose:

Enable Cursor native GAEH behavior.

------------------------------------------------------------------------

## 3. Upgrade Bootstrap Script

Current:

``` powershell
.\gaeh-bootstrap.ps1
```

Upgrade to:

``` powershell
.\gaeh-bootstrap.ps1 -TargetPath D:\project -Adapters codex,cursor
```

New responsibilities:

-   create directories
-   copy templates
-   install adapters
-   validate installation
-   generate install log

------------------------------------------------------------------------

## 4. Add Doctor Script

Create:

``` text
gaeh-doctor.ps1
```

Purpose:

Validate installed GAEH project.

Checks:

-   required directories
-   required state files
-   adapters installed
-   task queue valid

------------------------------------------------------------------------

# Bootstrap Upgrade Tasks

## Task 1

Add adapters directory.

Structure:

``` text
/adapters
  /codex
    SKILL.md
  /cursor
    gaeh.mdc
```

Acceptance:

Adapters exist.

------------------------------------------------------------------------

## Task 2

Modify bootstrap installer.

Add parameter:

``` powershell
-Adapters
```

Acceptance:

Can install codex/cursor adapters.

------------------------------------------------------------------------

## Task 3

Add install verification.

Verify:

``` text
goal.md
phase_status.md
task_queue.json
harness_rules.md
SKILL.md
gaeh.mdc
```

Acceptance:

Installer reports success/failure.

------------------------------------------------------------------------

## Task 4

Add doctor script.

Acceptance:

Can validate any installed project.

------------------------------------------------------------------------

## Task 5

Fix task queue template.

Current:

``` json
"current_task_id": "bootstrap-0001"
```

Replace with:

``` json
"current_task_id": null
```

Reason:

Avoid false active task.

Acceptance:

No default fake task.

------------------------------------------------------------------------

# Adapter Content Requirements

## Codex SKILL.md

Must contain:

-   role boundary
-   workflow
-   required files
-   interaction policy

Must enforce:

``` text
Owner defines goal.
AI owns engineering.
```

------------------------------------------------------------------------

## Cursor Rule

Must contain:

-   same protocol
-   same owner boundary
-   same workflow rules

Must align with Codex adapter.

------------------------------------------------------------------------

# Installation Flow

## New Flow

``` text
Unzip GAEH
↓
Run bootstrap
↓
Install templates
↓
Install adapters
↓
Validate install
↓
Ready for Codex / Cursor
```

------------------------------------------------------------------------

# Validation Criteria

Installation is valid if:

``` text
/project_control exists
/ai_harness exists
/specs exists
/plans exists
/reviews exists
/reports exists
.codex/skills/gaeh exists (if codex selected)
.cursor/rules/gaeh.mdc exists (if cursor selected)
goal.md exists
phase_status.md exists
task_queue.json valid
```

------------------------------------------------------------------------

# Future Roadmap

## Phase 2

CLI installer

Target:

``` text
gaeh init
```

------------------------------------------------------------------------

## Phase 3

Upgrade system

Target:

``` text
gaeh upgrade
```

------------------------------------------------------------------------

## Phase 4

Doctor system

Target:

``` text
gaeh doctor
```

------------------------------------------------------------------------

## Phase 5

Task progression

Target:

``` text
gaeh next
gaeh status
```

------------------------------------------------------------------------

# Execution Instructions for Codex/Cursor

Use this package as base.

Do NOT redesign GAEH.

Only upgrade installer layer.

Execution order:

1.  Create adapters
2.  Upgrade bootstrap
3.  Add doctor
4.  Validate templates
5.  Fix task queue template
6.  Run install test

Review before code changes.

Execute only after plan approval.

------------------------------------------------------------------------

# Final Acceptance

Package is upgraded when:

``` text
A new project can install GAEH with one command
Codex can read native skill
Cursor can read native rule
State files initialize correctly
No manual copying beyond unzip + bootstrap
```

This marks:

``` text
GAEH v0.2 Installer Layer Complete
```

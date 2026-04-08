# modscape-sdd

A sample repository for **Spec-Driven Data Engineering (SDD)** using [Modscape](https://github.com/yujikawa/modscape).

[日本語版はこちら (Japanese version)](README.ja.md)

---

## What is SDD?

SDD adds a structured workflow on top of your data model, guiding you from business requirements through implementation to permanent, per-table documentation. Each pipeline is managed in its own named work folder and archived as table-level business specs when complete.

---

## Setup

```bash
# Claude Code
modscape init --claude --sdd

# Codex
modscape init --codex --sdd

# Gemini CLI
modscape init --gemini --sdd

# All agents
modscape init --all --sdd
```

Installs skills and a customization template. Creates `.modscape/changes/` and `.modscape/specs/` directories.

---

## Workflow

### 1. Define requirements — `/modscape:spec:requirements`

Interactively capture the pipeline spec with your AI agent.

- AI scaffolds the work folder via `modscape spec new <name>`
  - Creates `spec-config.yaml`, `spec-model.yaml`, `design.md`, `tasks.md`
- Collects goal, stakeholders, data sources, acceptance criteria, and target tool
- Resolves `main-model.yaml` path from `modscape-spec.custom.md` or prompts the user
- Output: `.modscape/changes/<name>/spec.md`

### 2. Design the model — `/modscape:spec:design <name>`

- Reads `spec.md` and existing `specs/*.md` to auto-identify affected tables
- Runs `modscape extract` to pull relevant tables from `main-model.yaml` into `changes/<name>/spec-model.yaml`
- Records which tables belong to `main-model.yaml` in `spec-config.yaml`
- Generates `design.md` (design decisions) and `tasks.md` (implementation checklist)
- **Re-runnable**: add findings under `### Requires Model Change` in `design.md`, re-run to update model and tasks

### 3. Implement — `/modscape:spec:implement <name>`

Work through tasks one by one, generating dbt / SQLMesh code and updating checkboxes.

### 4. Archive — `/modscape:spec:archive <name>`

Sync permanent table specs and clean up the work folder.

- Merges `changes/<name>/spec-model.yaml` into the correct `main-model.yaml` per `spec-config.yaml`
- Generates / updates `.modscape/specs/<table-id>.md` for each affected table
- Upstream tables receive a Changelog entry only
- Work folder is automatically moved to `.modscape/archives/YYYY-MM-DD-<name>/`

> **Tip**: Run `/modscape:spec:status <name>` at any time to check the current phase, task progress, and the next recommended command.

> **Customization**: Rename `.modscape/changes/modscape-spec.custom.md.example` to `modscape-spec.custom.md` to override default tool targets, required fields, and output conventions per project.

---

## Workflow Diagram

```mermaid
sequenceDiagram
    actor User
    participant AI as Claude (AI)
    participant CLI as modscape CLI
    participant FS as .modscape/

    rect rgb(240, 248, 255)
        Note over User,FS: ① /modscape:spec:requirements
        User->>AI: Describe requirements (goal, stakeholders, data sources, etc.)
        AI->>User: Propose folder name (e.g. monthly-sales-summary)
        User->>AI: Approve or rename
        AI->>FS: Create changes/<name>/spec.md
    end

    rect rgb(240, 255, 240)
        Note over User,FS: ② /modscape:spec:design <name>
        AI->>FS: Read spec.md and specs/*.md
        AI->>CLI: modscape extract main-model.yaml --tables <ids>
        CLI->>FS: Create changes/<name>/spec-model.yaml (extracted tables)
        AI->>CLI: modscape table add changes/<name>/spec-model.yaml ...
        CLI->>FS: Add new tables to changes/<name>/spec-model.yaml
        AI->>CLI: modscape layout changes/<name>/spec-model.yaml
        AI->>FS: Create changes/<name>/design.md + tasks.md
    end

    rect rgb(255, 253, 240)
        Note over User,FS: ③ /modscape:spec:implement <name>
        loop While incomplete tasks remain
            AI->>FS: Read changes/<name>/spec-model.yaml
            AI->>User: Generate code (dbt / SQLMesh etc.)
            AI->>FS: Update tasks.md checkbox [ ]→[x]
            AI->>User: Proceed to next task?
        end
        opt If real-data findings arise
            User->>FS: Add Findings to changes/<name>/design.md
            User->>AI: Re-run /modscape:spec:design <name>
            AI->>FS: Redesign spec-model.yaml, diff-update tasks.md
        end
    end

    rect rgb(255, 240, 245)
        Note over User,FS: ④ /modscape:spec:archive <name>
        AI->>CLI: modscape merge main-model.yaml changes/<name>/spec-model.yaml --patch
        CLI->>FS: Update main-model.yaml (in-place upsert)
        Note over CLI: ⚠ Warn on duplicate table IDs
        AI->>FS: Generate / update specs/<table-id>.md
        AI->>User: Delete changes/<name>/? (y=delete / n=move to archives/YYYY-MM-DD-<name>/)
    end
```

---

## Repository Structure

```
modscape-sdd/
├── modscape.yaml              # Main data model (SaaS subscription analytics)
├── dim_dates.yaml             # Imported conformed date dimension
├── .modscape/
│   ├── rules.md               # Modeling conventions (generated by modscape init)
│   ├── changes/               # Active work folders
│   │   └── <name>/
│   │       ├── spec.md        # Requirements
│   │       ├── spec-model.yaml
│   │       ├── spec-config.yaml
│   │       ├── design.md
│   │       └── tasks.md
│   ├── specs/                 # Permanent per-table documentation
│   │   └── <table-id>.md
│   └── archives/              # Completed work folders
│       └── YYYY-MM-DD-<name>/
```

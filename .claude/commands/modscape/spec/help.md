Display the SDD workflow overview, or answer a specific question about the workflow.

## Usage

```
/modscape:spec:help
/modscape:spec:help <topic>
```

`<topic>` is optional. Examples: `design`, `requirements vs design`, `files`, `resume`.

## Instructions

1. If an argument is provided:
   - If the topic is a **command name** (`requirements`, `design`, `tasks`, `implement`, `archive`, `status`, `amend`, `review`, `search`, `answer`, `validate`, `explain`, `generate`, `note`):
     Read `.claude/commands/modscape/spec/<topic>.md` and provide a user-friendly summary: what it does, what it produces, and when to use it. Do not dump the raw file — summarize for a human reader.
   - If the topic is a **question or concept** (e.g. `requirements vs design`, `files`, `resume`):
     Answer it using the reference content below.
   - After answering, offer:
     > Run `/modscape:spec:help` with no arguments to see the full workflow overview.

2. If no argument is provided:
   - Display the full workflow overview below.

---

## SDD Workflow Overview

Spec-Driven Development (SDD) is a workflow for building data pipelines with a clear trail of decisions and artifacts.

```
/modscape:spec:requirements        Create spec.md (business requirements)
         ↓
/modscape:spec:design <name>       Design the data model — iterate freely
/modscape:spec:design <name>       Re-run to continue from where you left off
         ↓  (satisfied with the design)
/modscape:spec:tasks <name>        Generate implementation task list
         ↓
/modscape:spec:implement <name>    Implement tasks one by one
         ↓
/modscape:spec:archive <name>      Merge into main model, sync permanent specs
```

For details on any command, run `/modscape:spec:help <command>`.

---

## Workflow Support Commands

These commands assist during an active SDD workflow. They require a `changes/<name>/` work folder.

| Command | Purpose |
|---------|---------|
| `/modscape:spec:status <name>` | Show current progress of a work folder |
| `/modscape:spec:review <name>` | Go/no-go review: unresolved questions, AC coverage |
| `/modscape:spec:amend <name>` | Update artifacts when issues are found mid-implementation |
| `/modscape:spec:answer <name>` | Answer a recorded Q-NNN question |
| `/modscape:spec:validate <name>` | Check cross-artifact consistency |
| `/modscape:spec:explain <name>` | Explain spec content for handoff or onboarding |

## Standalone Commands

These commands work independently — no active workflow or work folder required.

| Command | Purpose |
|---------|---------|
| `/modscape:spec:generate [files...]` | Generate `specs/<table-id>/spec.md` for existing tables from model.yaml, SQL, or Python files — use this to bootstrap specs for an existing project |
| `/modscape:spec:note [table-id]` | Append free-form knowledge (from a conversation, Slack, or meeting) to one or more `specs/<table-id>/spec.md` files |
| `/modscape:spec:search <keyword>` | Search past archives and permanent specs |
| `/modscape:spec:help [topic]` | This help |

---

## File Structure

```
.modscape/
├── modscape-spec.custom.md     # SDD workflow conventions (optional)
├── rules.custom.md             # Data model conventions (optional)
├── changes/
│   └── <name>/                 # Work folder (one per pipeline)
│       ├── spec.md             # Business requirements
│       ├── spec-config.yaml    # Main YAML mapping
│       ├── spec-model.yaml     # Work-scoped data model
│       ├── design.md           # Design decisions + findings
│       └── tasks.md            # Implementation task list
├── archives/
│   └── YYYY-MM-DD-<name>/      # Completed work folders
└── specs/
    ├── <table-id>/spec.md      # Permanent business spec per table
    ├── _questions.yaml         # Q&A history
    ├── _glossary.yaml          # Business term definitions
    └── _context.yaml           # Cross-project architectural decisions
```

---

## Common Questions

**Q: What is the difference between `requirements` and `design`?**
`requirements` captures the business goal in plain language — who needs it, what it solves, what sources are involved, and what "done" looks like. `design` translates those requirements into an actual data model: tables, columns, lineage, and relationships. Requirements answers *what*, design answers *how*.

**Q: Do I have to run `requirements` first?**
No, but it is strongly recommended. If you already have a `spec.md`, you can start from `design` directly.

**Q: Can I run `design` multiple times?**
Yes — this is the intended workflow. Run it as many times as needed until you are satisfied. Each re-run resumes the session from the current state.

**Q: When should I run `tasks`?**
Only when you are satisfied with the design. `tasks` reads the finalized `spec-model.yaml` and generates a phased task list. Running it too early is fine — you can always re-run it after further design changes.

**Q: What is `spec-model.yaml` vs `model.yaml`?**
`spec-model.yaml` is a work-scoped copy that only contains tables relevant to the current pipeline. `model.yaml` (or your project's main YAML) is the full model. `archive` merges the work copy back into the main model when you are done.

**Q: Where do my decisions and Q&A go after archiving?**
- Table specs → `.modscape/specs/<table-id>/spec.md`
- Q&A → `.modscape/specs/_questions.yaml`
- Business terms → `.modscape/specs/_glossary.yaml`
- Architectural decisions → `.modscape/specs/_context.yaml`
- Modeling conventions → `.modscape/rules.custom.md`
- Workflow conventions → `.modscape/modscape-spec.custom.md`

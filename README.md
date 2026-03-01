# Modscape SDD (Spec-Driven Data Engineering)

This repository is for **Spec-Driven Data Engineering (SDDE)**, integrating Modscape and OpenSpec.
It separates "Business Requirements," "Logical Models," and "Physical Design" to build robust data pipelines through collaboration between AI and humans.

[日本語版はこちら (Japanese version)](README.ja.md)

## 🚀 Concept: Spec-Driven Data Engineering (SDDE)

Instead of traditional ad-hoc data development, we use the **"Spec" as the single Source of Truth (SoT)** to derive implementations.

```mermaid
sequenceDiagram
    participant U as User (Data Engineer)
    participant A as AI Agent (OpenSpec)
    participant M as Modscape (Visualizer)
    participant C as Code (dbt/SQL/Python)

    Note over U, A: Phase 1: Discovery (/opsx:explore)
    U->>A: Communicate business requirements
    A->>A: Generate `specs/discovery.md`
    
    Note over A, M: Phase 2: Modeling (/opsx:model)
    A->>A: Generate/Update `modscape.yaml`
    A->>M: Reflect 3-layer structure (Conceptual/Logical/Physical)
    M-->>U: Verify the model visually in the browser
    U->>M: Adjust layout if necessary
    
    Note over U, C: Phase 3: Technical Design (/opsx:design)
    A->>A: Describe implementation details in `design.md`
    A->>A: (dbt model structure, Test strategy, Lineage)
    
    Note over A, C: Phase 4: Implementation (/opsx:apply)
    A->>C: Auto-generate code (dbt models, SQL)
    A->>C: Execute data quality tests
    C-->>U: Pipeline complete!
```

## 🛠 Setup

To introduce this workflow into your project, simply copy the following files:

1.  **Copy OpenSpec configuration**:
    - `openspec/schemas/data-platform.yaml`
    - `openspec/config.yaml`
2.  **Initialize Modscape**:
    ```bash
    npx modscape init
    ```
    This generates `.modscape/rules.md`, which defines the modeling conventions.

## 📋 Workflow Details

### 1. Discovery (`/opsx:explore`)
Clarify "Why" and "What" data needs to be created. Identify business definitions and data sources.

### 2. Modeling (`/opsx:model`)
Create or update `modscape.yaml`.
- **Conceptual**: Define `appearance.type` (fact, dimension, hub, sat, etc.).
- **Logical**: Define column names, types, PK/FK (Business Source of Truth).
- **Physical**: Define actual database table names and constraints.

### 3. Technical Design (`/opsx:design`)
Design how the modeled structure will be implemented using specific tools (dbt, Snowflake, Airflow, etc.).

### 4. Implementation (`/opsx:apply`)
Based on the design, generate and implement the actual code via `proposal.md` and `tasks.md`.

---
Produced by [Gemini CLI](https://github.com/google/gemini-cli) & [OpenSpec](https://openspec.dev)

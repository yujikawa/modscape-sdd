# Pipeline Spec: <title>

---

## Goal

<Who is this for and what problem does it solve?>

## Stakeholders

| Role | Name / Team |
|------|-------------|
| Owner | <team or person> |
| Consumers | <downstream users or systems> |

## Data Sources

- <source 1>
- <source 2>

## Table Relationships

| From | To | Cardinality |
|------|----|-------------|
| `<source_table>.<column>` | `<other_table>.<column>` | one-to-many |

*(Omit section if no FK relationships are known)*

## Business Context

<!-- Data-related business context that only humans know. Populated by step 3.5. -->

### Data Occurrence Conditions

- **`<table>`**: <What business event creates a row? Who enters it, in what system, for what purpose?>

### Business Process Flow

<End-to-end business process that generates or consumes this data. What happens before and after?>

### Domain Rules & Edge Cases

- <Rule or quirk that an engineer would not know from the schema alone>
- <Status codes, magic values, flags with business-specific meaning>
- <Common mistakes engineers make about this data>

## Acceptance Criteria

<!-- State only abstract conditions here. Move validation SQL, transformation expressions, and WHEN/THEN scenarios to design.md. -->
<!-- Good example: "Order amounts are correctly aggregated" -->
<!-- Bad example: "SELECT COUNT(*) FROM orders WHERE amount IS NULL = 0" → goes in design.md -->

- [ ] **AC-001** — <describe what should be satisfied, in abstract terms>
- [ ] **AC-002** — <describe what should be satisfied, in abstract terms>

## Target Tool

`<dbt | SQLMesh | Spark SQL | plain SQL>`

---

---
name: sql-server
description: Use when editing SQL Server schema scripts, update scripts, stored procedures, or mock data. Covers idempotent DDL, guards, naming, batches, and script style.
---

# SQL Server Editing

## Purpose

Use this guide when editing SQL Server schema scripts, update scripts, stored
procedures, or mock data in this repository.

## Required Workflow

- Inspect nearby SQL scripts before editing so the change matches repository
  style.
- Keep schema changes idempotent where possible.
- Validate affected database behavior with the repo’s DB workflow or tests when
  available.

## Required Conventions

### Edge Guards

- Guard DDL with `IF NOT EXISTS` or `IF OBJECT_ID(..., 'U') IS NULL`.
- Use `CREATE OR ALTER PROCEDURE` for procedures.
- Use `GO` between logical batches and after DDL blocks.
- Do not add destructive SQL without an explicit guard and a clear reason.

### Schema and Naming

- Schema-qualify new database objects with `dbo.` when creating shared objects.
- Keep constraint names consistent with the repo’s prefixes: `PK_`, `FK_`,
  `UQ_`, `IX_`, and `DF_`.
- Bracket reserved identifiers such as `[Password]`, `[From]`, or `[To]`.
- Keep table, column, and enum-like value names aligned with the existing
  domain vocabulary.

### Data Changes

- Use `SELECT 1` for existence checks.
- Use `N'...'` for Unicode text.
- Use UTC-oriented defaults and timestamps when the table already follows that
  pattern.
- Capture inserted IDs with `SCOPE_IDENTITY()` or a matching existing pattern
  before inserting dependent rows.
- Seed data only behind appropriate guards when the script may be rerun.

### Procedures and Batches

- Use `SET NOCOUNT ON;` in stored procedures.
- Prefer `THROW` for business-rule failures instead of silent exits.
- Keep procedure bodies linear and easy to scan.
- Return a clear result set when the procedure’s caller expects one.

### Style

- Keep scripts readable and block-oriented.
- Preserve the surrounding file’s casing and indentation style when editing an
  existing script.
- Split init, update, procedure, and mock-data scripts by purpose.

## Library Guidance

- Prefer repo-local SQL Server conventions over generic SQL style when they
  conflict.
- Prefer additive, rerunnable scripts over one-off manual changes.

## Research

- When SQL Server behavior is unclear, compare against existing repository
  scripts or official SQL Server documentation before guessing.

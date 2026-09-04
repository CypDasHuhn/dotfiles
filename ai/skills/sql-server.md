---
name: sql-server
description: Use when editing SQL Server scripts — schema or update scripts, stored procedures, or mock data.
---

# SQL Server Editing

- Match nearby scripts' style and casing; split init/update/procedure/mock-data
  scripts by purpose.
- Idempotent, rerunnable DDL: guard with `IF NOT EXISTS` /
  `IF OBJECT_ID(..., 'U') IS NULL`; `CREATE OR ALTER PROCEDURE`; `GO` between
  logical batches; no destructive SQL without a guard.
- Schema-qualify shared objects with `dbo.`; constraint prefixes `PK_`/`FK_`/
  `UQ_`/`IX_`/`DF_`; bracket reserved words (`[Password]`); keep names in the
  existing domain vocabulary.
- `SELECT 1` for existence checks; `N'...'` for Unicode; UTC defaults where the
  table already uses them; `SCOPE_IDENTITY()` before inserting dependent rows;
  seed only behind guards.
- Procedures: `SET NOCOUNT ON;`, `THROW` for business-rule failures, linear
  bodies, a clear result set when the caller expects one.

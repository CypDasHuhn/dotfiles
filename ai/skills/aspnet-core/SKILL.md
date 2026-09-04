---
name: aspnet-core
description: Use when editing ASP.NET Core API code in this repository — controllers, bootstraps, services, DTOs, validation, data access, and related test code. Covers project shape, EF Core usage, DTO mapping, and error handling.
---

# ASP.NET Core Editing

## Purpose

Use this guide when editing ASP.NET Core API code, bootstraps, controllers,
services, and related test code in this repository.

## Required Workflow

- Use `csharp-ls` via `lsp-bridge`.
- Run the affected API tests when behavior changes.
- Build the affected API project before finalizing larger changes when the repo
  supports it.

## Required Conventions

### Project Shape

- Prefer feature folders over type-based folders.
- Split large controllers into partial files by concern, such as `*.Read.cs`,
  `*.Create.cs`, or `*.Update.cs`.
- Keep flat namespaces that mirror the feature folder.
- Use primary-constructor injection on controllers and bootstrap classes when
  the file follows that pattern.

### Controllers

- Use `[ApiController]` and an explicit `[Route(...)]` on controller roots.
- Keep routes lowercase and stable.
- Use `[Authorize]`, `[FromRoute]`, and `[FromBody]` explicitly where they add
  clarity.
- Keep actions small and focused on one HTTP concern.
- Return `ActionResult<T>` or `ActionResult` and prefer `Ok`, `NotFound`,
  `BadRequest`, `NoContent`, or `StatusCode` over raw integers.
- Prefer DTOs over returning scaffold entities directly.

### Data Access

- Use `async`/`await` and accept `CancellationToken ct` on I/O-bound actions.
- Use `AsNoTracking()` for read-only EF Core queries.
- Check existence with `AnyAsync` or `FirstOrDefaultAsync` instead of loading
  full objects when only a guard is needed.
- Keep query logic simple and readable; prefer explicit locals over dense LINQ.

### DTOs

- Prefer DTOs that own their mapping to and from scaffold entities when the
  repository already uses that pattern for similar DTOs.
- Use `FromScaffold(...)` for response shaping and `ToScaffold(...)` for write
  paths.
- Keep validation on the DTO when the object knows the rules for its own
  fields.
- Prefer validation methods that return `ActionResult?` or a tuple containing
  the entity plus an `ActionResult?` error, matching the existing repo pattern.
- Compose validation from smaller methods such as `ValidateBasic`,
  `ValidateEmail`, `ValidateNew`, and `ValidateExisting` when that keeps the
  checks readable.
- Keep DTO methods responsible for normalization if the repo already does that,
  such as lower-casing or canonical email handling.

### Validation and Errors

- Validate route and body data early.
- Use guard clauses and return early on failure.
- Prefer repo-local helpers for domain validation when they already exist.
- Match existing authorization and role patterns instead of introducing new
  abstractions.

### Structure

- Use `#region` for larger logical sections in controllers and bootstraps.
- Use short, intention-revealing helper methods for repeated query or mapping
  logic.
- Keep bootstrap files small and use them only for registration/setup.

## Library Guidance

- Prefer the project’s existing service and EF Core patterns before adding new
  layers.
- Prefer partial controllers over inheritance for large API surfaces.
- Prefer the simplest workable abstraction for the task at hand.

## Research

- When framework or package behavior is unclear, check the repository code and
  official ASP.NET Core or EF Core docs before guessing.

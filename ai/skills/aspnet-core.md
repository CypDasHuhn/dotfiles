---
name: aspnet-core
description: Use when editing ASP.NET Core API code — controllers, bootstraps, services, DTOs, validation, EF Core data access, and related tests.
---

# ASP.NET Core Editing

- Feature folders over type folders; split large controllers into partial files
  by concern (`*.Read.cs`, `*.Create.cs`, ...); flat namespaces mirroring the
  folder; primary-constructor injection where the file already uses it.
- `[ApiController]` + explicit `[Route(...)]`; lowercase, stable routes; explicit
  `[Authorize]`/`[FromRoute]`/`[FromBody]` where they add clarity.
- Small single-concern actions; return `ActionResult<T>`/`ActionResult` via
  `Ok`/`NotFound`/`BadRequest`/`NoContent`/`StatusCode`, never raw ints; DTOs
  over scaffold entities.
- Data access: `async`/`await` with `CancellationToken`; `AsNoTracking()` on
  read-only queries; existence via `AnyAsync`/`FirstOrDefaultAsync`.
- DTOs own mapping (`FromScaffold(...)`/`ToScaffold(...)`) and validation,
  composed from small methods (`ValidateBasic`, `ValidateEmail`, ...); keep
  normalization (e.g. email lowercasing) in the DTO.
- Validate route/body early; guard clauses; reuse repo-local validation and
  existing authorization/role patterns; no new abstractions.
- `#region` larger logical sections; bootstraps stay small and only register.

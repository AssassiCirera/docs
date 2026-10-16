# AssassíCirera — Repositories

Six **local git repositories** under the GitHub org [AssassiCirera](https://github.com/AssassiCirera). The org already names the product — **repo names are short only** (no `assassi-cirera-` prefix).

Infra remains **Terraform + Kubernetes** with **Kafka on Amazon MSK**.

| Repo | GitHub | Stack | Owns |
|---|---|---|---|
| **api** | https://github.com/AssassiCirera/api | Java Spring Boot (modular monolith, DDD / hexagonal), PostgreSQL, Kafka client | HTTP API, domain logic, long-polling endpoints, Kafka producers/consumers, FCM dispatch hooks |
| **ios** | https://github.com/AssassiCirera/ios | SwiftUI | Player / assassin app **and** admin field view (separate flows/screens — not the same UI) |
| **android** | https://github.com/AssassiCirera/android | Jetpack Compose | Same surfaces as iOS |
| **web** | https://github.com/AssassiCirera/web | Angular | Admin **web dashboard** only (setup & roster CRUD) |
| **iac** | https://github.com/AssassiCirera/iac | Terraform + Kubernetes | AWS infra: cluster, networking, MSK, Postgres, secrets, CI deploy wiring |
| **docs** | https://github.com/AssassiCirera/docs | Markdown + [GitHub Wiki](https://github.com/AssassiCirera/docs/wiki) | Project documentation (context, requirements, MVP, repositories) |

Local clones (this machine): `~/WebstormProjects/{api,ios,android,web,iac}` — docs wiki at https://github.com/AssassiCirera/docs/wiki

## API-first

**Contract lives in `api` first.** Clients do not invent parallel APIs.

1. Design and version the HTTP API in `AssassiCirera/api` (OpenAPI / equivalent is the source of truth).
2. Implement and test the contract in `api` (unit / integration / E2E against that spec).
3. Publish the spec (and optionally generated client SDKs) for consumers.
4. **ios**, **android**, and **web** consume only that published contract — typed clients generated from OpenAPI where practical; no ad-hoc endpoints invented in UI repos.
5. Breaking changes go through API versioning / explicit migration; clients follow the `api` release, not the other way around.

Long-polling, auth, kills, ranking, kill feed, admin field actions, and web setup all go through this same backend API surface.

## Boundaries

### `api`

- **API-first owner:** OpenAPI (or equivalent) contract is defined and evolved here before client work depends on new endpoints.
- Single backend for all clients (ios, android, web).
- PostgreSQL: schema per town (or equivalent tenant isolation).
- **Event store:** publish/consume domain events via **Kafka on Amazon MSK**.
- **Live sync to clients:** HTTP **long polling** only — no WebSockets / SSE.
- Auth: invitation codes + admin verify + phone SMS OTP / Firebase Auth session as documented.
- Does **not** contain UI.

### `ios` / `android`

- Native mobile clients.
- **Player / assassin** experience: QR, victim, kill, check-in, ranking, kill feed, pushes.
- **Admin field view:** live match control only (start/pause/close, board, eliminate, broadcast, proclaim) — distinct UI from player; **no** roster/setup CRUD.
- Talk to `api` only via the published API contract; no direct DB / Kafka access from apps.
- Do not ship features that require undocumented or client-only endpoints.

### `web`

- Angular admin dashboard for **desk setup**: town, invitation codes, verify/create players, teams, match config, enrollment, checkpoint definition.
- Not the primary festival-day control surface (that is admin field mobile).
- Talk to `api` only via the published API contract.
- Do not ship features that require undocumented or client-only endpoints.

### `iac`

- Terraform modules/root for AWS (MSK required; EKS or chosen K8s flavor).
- Cluster workloads for `api` (and any sidecars), networking, IAM, secrets, observability hooks as needed.
- Environment promotion (e.g. staging / prod) lives here — not in app repos beyond image tags / chart values references.
- Optional **local** Compose/kind overlays for developer convenience are fine as helpers inside this repo; they do **not** replace Terraform + K8s + MSK as the target.
- Does **not** implement product business logic.

### `docs`

- Canonical project documentation published as the [GitHub Wiki](https://github.com/AssassiCirera/docs/wiki).
- Markdown copies also live on the `docs` repo `main` branch for non-wiki browsing.
- Product code stays in api / ios / android / web / iac — not here.

## Dependency direction

```
ios ──┐
android ├──► api ◄── Kafka (MSK) / PostgreSQL  (provisioned by iac)
web ──┘         ▲
                │
               iac (Terraform + K8s; no app code)

docs (wiki) — documentation only; no runtime dependency
```

## Testing (required in every repo)

Each **product** repo (api, ios, android, web, iac) MUST ship **unit**, **integration**, and **E2E** tests, runnable in CI. Tooling can differ by platform; the three layers are mandatory. The **docs** repo is documentation-only (wiki + markdown) and does not require those test layers.

| Repo | Unit | Integration | E2E |
|---|---|---|---|
| **api** | Domain / use-case / pure logic tests (no network) | API + DB and/or Kafka testcontainers (or equivalent); auth and long-poll contract tests | Full critical flows against a running stack (e.g. register → verify → start match → kill → ranking/feed); CI pipeline job |
| **ios** | ViewModel / domain helpers / pure Swift tests | Module tests with mocked `api` client / fakes | UI tests for player and admin field happy paths (login gate, QR/kill, field start/board) |
| **android** | ViewModel / use-case / pure Kotlin tests | Same with mocked API | Instrumented / UI E2E for player and admin field happy paths |
| **web** | Components / services / pipes (Jest or equivalent) | HTTP client + state against mocked or test API | Cypress/Playwright (or equivalent) for setup flows: verify player, teams, configure/start match from dashboard |
| **iac** | Module/policy unit checks (e.g. `terraform validate`, static module tests, lint) | `terraform plan` (and/or kitchen/terratest) against a non-prod account or localstack-style stand-in where used | Apply/smoke E2E in a dedicated ephemeral/staging environment: cluster up, MSK reachable, API deploy healthy |

### Rules

- Default branch CI fails if unit, integration, or E2E suites are missing or red for that repo.
- E2E may be slower / nightly where needed, but must exist and be documented how to run locally.
- Cross-repo contract: mobile/web E2E may hit a shared staging API; `api` owns backend contract truth (OpenAPI + its own E2E).
- Do not treat “manual QA only” as a substitute for any of the three layers.

## What does not get its own repo (MVP)

| Concern | Where it lives |
|---|---|
| Shared OpenAPI / client stubs | **Owned by `api`** (published artifact / generated SDKs); ios/android/web only consume — no separate “contracts” repo unless later needed |
| Project docs | **`docs`** repo + [GitHub Wiki](https://github.com/AssassiCirera/docs/wiki) |
| Player and admin field UIs | Same mobile repos, different modules/navigation trees |

## Related docs

- [project-context.md](project-context.md)
- [requirements.md](requirements.md) — [admin surfaces](requirements.md#admin-surfaces)
- [mvp.md](mvp.md) — stack table

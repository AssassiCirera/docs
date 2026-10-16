# AssassíCirera — MVP definition

Scoped MVP for the **digital** Assassí de la Cirera product. Substance from `assassi_cirera.md` (v3) reconciled with the ERS. This document defines **what** to ship first — not an implementation log.

## One-liner

A town festival product where **verified teams** hunt assigned victims by QR, check in at checkpoints, organizers **set up** on a web dashboard, and **control the live match** from a simple admin mobile field view.

## Client surfaces (three UIs)

| Surface | Who | Job |
|---|---|---|
| **Player / assassin mobile** | Players | Play the game (QR, victim, kill, check-in) |
| **Admin web dashboard (Angular)** | Admins at desk | Setup & roster — not the street-day primary control |
| **Admin mobile field view** | Admins outdoors | Live match control — **different UI** from player app and from Angular |

Do **not** reuse the player/assassin screens for admins. Do **not** put player/team create-edit on the admin mobile field view.

## In scope

### Player / assassin app

- Register and pass the town gate: **invitation code + admin verify** **and** **phone + SMS OTP** (both).
- See **own QR**.
- See **current victim team**.
- **Scan QR** to register a kill (only if target matches assignment and match is ACTIVE).
- **Check-in** at checkpoint QR.
- Receive **push** (or agreed interim channel): death, new victim, admin notices, start/end.
- **Live ranking** in the player app (teams ordered by survival / kills as the match runs).
- **Kill feed / death history** in the player app (recent eliminations).

### Admin web dashboard (Angular) — setup

- Town bootstrap + **invitation code** generation.
- **Manual verify** players; create/edit players as needed.
- Create / edit / delete **teams**; assign members.
- Create / configure match (name, dates / windows); enroll teams.
- Define checkpoints and windows.
- Optional full detailed board / history while at a desk.

### Admin mobile field view — live control

Simple field UI for festival day. **Not** for modifying or submitting new players/teams.

- Match status + **start / pause / resume / close**.
- Compact live board: team status, kills, current victims, checkpoint compliance.
- Manual eliminate team; proclaim winner.
- Broadcast short notice to all players.
- Explicitly **out** on this surface: invitation codes, verify/create players, team roster CRUD, match date/config editing, checkpoint definition.

### Domain (must work correctly)

- Circular **Assignment** at start.
- Kill validation + inherit next victim.
- Reassignment after checkpoint elimination.
- Detect / handle **chain closed**; proclaim winner (last standing; most kills if closed early).

## Feature split (web vs admin mobile)

| Feature | Web dashboard | Admin mobile field |
|---|---|---|
| Town + invitation codes | Yes | No |
| Verify / create / edit players | Yes | No |
| Team create / edit / delete / roster | Yes | No |
| Match create / configure / enroll | Yes | No |
| Define checkpoints & windows | Yes | No |
| Start / pause / resume / close | Secondary | **Primary** |
| Compact live board | Optional detail view | **Primary** |
| Manual eliminate team | Secondary | **Primary** |
| Proclaim winner | Secondary | **Primary** |
| Broadcast notice | Secondary | **Primary** |
| Play as assassin (QR / kill scan) | No | No (player app only) |

Detail of this split: [Admin surfaces](requirements.md#admin-surfaces).

## Out of scope

| Item | Notes |
|---|---|
| Solo / non-team modes | Out for **this MVP only**; not a permanent product ban |
| Self-service new towns | Post-MVP |
| Alternate rule modes in dashboard | Post-MVP |
| Enforcing glass / sticker in software | Street rules only |
| Perfect multi-channel notifications beyond FCM plan | Keep push as the MVP channel |
| Admin field view as a thin wrapper of Angular CRUD | Field view stays simple and control-only |

## User flows

### Access (both — decided)

```
Download app → register (name + email + phone)
  → enter invitation code
  → SMS OTP
  → profile photo
  → admin verifies identity (web)
  → player joins locality matches
  → later login: phone + OTP
```

### Setup (web)

```
Admin on Angular dashboard
  → create/verify players, form teams
  → configure match + checkpoints
  → enroll teams
```

### Game day

```
Admin field mobile: start match
  → player app shows own QR + assigned victim
  → assassin scans victim QR → death validated
  → push “you are dead” / “new victim assigned”
  → players check in at control QR in windows
  → admin field mobile: eliminate / broadcast as needed
  → admin field mobile: close → winner proclaimed → push to all
```

## Stack choice (with rationale)

**Recommended target stack** — take from digital MVP v3 unless Arnau overrides:

| Layer | Choice | Rationale |
|---|---|---|
| iOS | SwiftUI | Native UX for street play **and** admin field view (separate flows/screens) |
| Android | Jetpack Compose | Same |
| Admin web | Angular | Setup CRUD + detailed desk board |
| Backend | Java Spring Boot, modular monolith, DDD + hexagonal | Fits bounded contexts; as specified in source |
| DB | PostgreSQL, schema per town | Strong isolation for multi-town |
| Event store | Apache Kafka on **Amazon MSK** | Durable domain/event log; consumers drive notifications, long-poll views, projections |
| Live sync | HTTP **long polling** | Near-real-time ranking, kill feed, admin field board, match state — **not** WebSockets / SSE / similar |
| Push | Firebase FCM | OS wake/alerts; complements long polling when app is backgrounded |
| Auth | Firebase Auth + invitation codes + SMS OTP | **Both** town gate (code + manual verify) and phone OTP login |
| Contract | **API-first** (OpenAPI in `api`) | ios / android / web consume the published API only |
| Infra | Terraform + Kubernetes (AWS); **MSK** for Kafka | Cloud IaC in `iac` repo. “Local” = develop in local git repos, not Compose-as-production |

**Why not invent a different stack in docs:** the markdown already commits to a coherent native + Spring + FCM shape. A thinner web-only vertical slice can be a *delivery tactic* later if Arnau wants faster festival validation — it is **not** the documented product MVP stack unless he chooses it.

**Design-before-code:** Assignment bounded context (circular graph, kill reassignment, checkpoint elimination, chain closed) is the critical path — model it before writing feature code.

## Milestones (planning)

1. **Decide remaining open product choices** — UI locale; cloud/K8s flavor (EKS assumed with MSK); any slim-down of native clients. (Auth = both: invitation + SMS. Infra = Terraform + K8s.)  
2. **Domain design** — Assignment + Kill + Checkpoint state machines and invariants (see [Reconciled product rules](requirements.md#reconciled-product-rules) through [Game mechanics](requirements.md#game-mechanics)).  
3. **API contract** — OpenAPI in `api` first; clients consume only the published contract.  
4. **Identity & town** — codes, verify, player states (web).  
5. **Web setup** — teams, match config, enrollment, checkpoints.  
6. **Admin field view** — start/pause/close, compact board, eliminate, broadcast, proclaim.  
7. **Player kill & QR loop** — own QR, victim, scan, pushes.  
8. **Live ranking + kill feed** in the player app.  
9. **Checkpoints** — player check-in, double-miss elimination.  

## Success criteria

- A verified team can complete: see victim → kill via QR → receive new victim → check in.  
- Player app shows a live ranking and a kill feed / death history during the match.  
- Admin can **set up** on web (players, teams, match) without needing mobile.  
- Admin can **run festival day** on field mobile (start → board → eliminate/broadcast → close) without creating players or editing teams.  
- Player app and admin field view are visually/structurally distinct.  
- No team mutations allowed during ACTIVE.  
- Assignment remains a valid chain after every kill/elimination (or correctly collapses to winner).

## Related docs

- [project-context.md](project-context.md) — goals, glossary, [open decisions](project-context.md#open-decisions)  
- [requirements.md](requirements.md) — full refined requirements & [admin surface split](requirements.md#admin-surfaces)  
- [repositories.md](repositories.md) — api / ios / android / web / iac repos (each with unit, integration, E2E)  

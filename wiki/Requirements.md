# Assassí de la Cirera — Product & requirements (refined)

Merged and de-duplicated from:

- **ERS** — functional requirements for an MVP league/competition platform (teams of 2, SMS, admin-centric).
- **assassi_cirera.md** — digital MVP v3 (street rules, invitation access, checkpoints, stack, feature lists).

Where the two disagree, see [Reconciled product rules](#reconciled-product-rules) and [Open decisions](Project-Context#open-decisions).

---

## 1. Purpose

Define functional requirements for a digital platform that runs **Assassí de la Cirera**: team-based street eliminations, QR-validated kills, admin-operated competition control, checkpoints, and player notifications — aligned for business, design, and engineering.

## 2. Scope

### In scope

- Player registration and profile (name, photo; phone + invitation path — see [Reconciled product rules](#reconciled-product-rules)).
- Verification gate: **SMS OTP and** admin manual verification (both required in the happy path; admin may skip SMS in exceptional cases).
- Admin-managed **teams** of exactly 2.
- Competition configuration (name, description, key dates) and enrollment control.
- Game mechanics: circular assignment, QR kill, automatic reassignment, end of match / winner.
- Checkpoint check-ins with consecutive-miss elimination.
- Notifications: elimination, successful kill / new victim, game start/end, admin broadcast.
- Live ranking in the player app; kill feed / death history in the player app (refreshed via long polling).
- **Admin web dashboard** (setup): town, invitation codes, verify players, teams CRUD, match config, checkpoint definition, enrollment.
- **Admin mobile field view** (live control): simple UI distinct from the player/assassin app and from the Angular dashboard — run the match on the street without roster editing.
- Basic audit / permission control (admins vs players).

### Out of scope (this product MVP)

- Solo or non-team modalities (**this MVP only** — may come later).
- Anonymous users as a primary path.
- Self-service onboarding of new towns.
- Configurable alternate rule modes from the dashboard (post-MVP).
- Software enforcement of physical sticker or “glass in hand” (street rules only).

## 3. Actors

| Actor | Role |
|---|---|
| **Admin** | Full authority overall. **Web dashboard:** users, teams, competition setup, verify/skip verify, enroll outside date windows. **Mobile field view:** live match control only (see [Admin surfaces](#admin-surfaces)). |
| **Player / assassin** | Manages own profile; authenticates; plays (QR, victim, kill scan, check-in); sees live ranking and kill feed; receives notices. Uses the **player** mobile UI — not the admin field view. |
| **System** | Assignments, kill validation, state transitions, miss policy, notifications. |
| **Anonymous user** | Named in ERS; outside main MVP flow. |

<a id="reconciled-product-rules"></a>

## 4. Reconciled product rules

| Topic | Rule |
|---|---|
| Team size | Exactly **2** players per team. |
| Linked fate | Death/elimination of one member ⇒ team out. |
| Kill (digital) | While match is **ACTIVE**, an assassin scans a QR belonging to a member of the **currently assigned** victim team → victim team marked dead/eliminated → assassin inherits that team’s former victim. |
| Kill (physical) | Sticker only if victim has **no** glass in hand — **not** validated by software. |
| Invalid kill | Wrong target, self, already dead, match not ACTIVE → reject. |
| End condition | Prefer **last team standing** (chain closed). If closed otherwise, winner by **most kills** (markdown). |
| Team mutations | No create / edit / delete / roster change while competition is **in progress / ACTIVE** (ERS). |
| Enrollment dates | Apply to players/teams; **admins are not bound** by enrollment windows (ERS). |
| Checkpoints | Timed windows; scan control QR; **two consecutive absences → elimination** (markdown). |
| Access / auth (**decided: both**) | Players use **invitation code + admin manual town verification** to join the town, **and** **phone + SMS OTP** for verification/login. Admin may skip SMS in exceptional cases (ERS). Firebase Auth may wrap the session. |

## 5. State models

### Player (identity / participation)

```
REGISTERED → CODE_SUBMITTED → VERIFIED → ACTIVE_IN_GAME → DEAD | ELIMINATED
```

(ERS also describes OTP-gated registration/login; map OTP success into VERIFIED / session as an implementation detail.)

### Match / competition

```
DRAFT → CONFIGURED → ACTIVE → PAUSED → FINISHED
```

## 6. Access & identity flows

### Combined access path (decided: both)

1. Download app → register with **name + email** and **unique phone**.  
2. Enter **invitation code** issued by town admin.  
3. Validate **SMS OTP** (rate-limit / lockout after failed attempts; resend with cooldown).  
4. Complete profile (photo; name if not set).  
5. Admin **manually verifies** town membership (may skip SMS only in exceptional admin alta).  
6. Verified user can access matches for that locality.  
7. Later login: phone + OTP (session via Firebase Auth where used). Logout from app.

Admin may also create a player by phone on the web dashboard, optionally skip SMS, and complete or defer profile; not bound by enrollment dates.

## 7. Functional modules & use cases

### M1 — User management

| ID | Use case | Summary |
|---|---|---|
| UC 1.1 | Self-registration | Player self-registers with email, phone, invitation code, and OTP. |
| UC 1.2 | Admin create player | Admin creates player; may skip verification; may complete or defer profile. |
| UC 1.3 | Verification | OTP validation **and** admin verify (both); OTP attempt limits; admin may skip SMS exceptionally. |
| UC 1.4 | Edit profile | Player edits name/photo; admin may overwrite anytime. |

**Rules:** phone unique when used as id (ERS); invitation codes scoped to town (markdown).

### M2 — Authentication

| ID | Use case | Summary |
|---|---|---|
| UC 2.1 | Sign in | Player authenticates with phone + OTP (Firebase Auth session layer as applicable). |
| UC 2.2 | Sign out | Player logs out. |

### M3 — Teams

| ID | Use case | Summary |
|---|---|---|
| UC 3.1 | Create team | Admin creates team (optional name); may assign free players. Size 2. |
| UC 3.2 | Edit team | Rename and/or replace members. |
| UC 3.3 | Delete team | Delete team; members become free if allowed. |
| UC 3.4 | Assign / remove | Maintain exactly 2 members. |

**Restriction (all):** blocked if a competition is in progress.

### M4 — Competition management

| ID | Use case | Summary |
|---|---|---|
| UC 4.1 | Configure competition | Name, description, enrollment start/end, competition start; optional rule params later. |
| UC 4.2 | Enrollment | Admin enrolls complete teams; no duplicates; respect capacity/state if defined. |
| — | Lifecycle | Start / pause / close; on start, system appends domain events to Kafka (MSK) and builds assignments. |

<a id="game-mechanics"></a>

### M5 — Game mechanics

| ID | Use case | Summary |
|---|---|---|
| UC 5.1 | Initial assignment | Circular assignment of victim teams; players see their target in-app. |
| UC 5.2 | Elimination via QR | Scan assigned victim member QR → team eliminated. |
| UC 5.3 | Target update | Killer receives eliminated team’s former victims; notice + in-app update. |
| UC 5.4 | End of match | One active team left → winner; or admin closes → proclaim (including most-kills path). |

### M6 — Checkpoints

- Admin defines checkpoint(s) and time windows.  
- Player check-in by scanning checkpoint QR.  
- System tracks attendance; **two consecutive missed windows → team eliminated** (then reassignment as for other eliminations).

### M7 — Notifications

| ID | Event | Audience |
|---|---|---|
| UC 6.1 | Team eliminated | Members of dead/eliminated team. |
| UC 6.2 | Kill scored | Assassin team — new victim assigned. |
| UC 6.3 | Game started | All players — objectives visible. |
| UC 6.4 | Game finished | All players — winner / ranking outcome. |
| — | Admin broadcast | All players (org notices). |

**Delivery:**
- **In-app live updates** (ranking, kill feed, admin field board, match/victim state): backend uses **HTTP long polling**. Do **not** use WebSockets, Server-Sent Events, or similar streaming sockets.
- **OS wake / alerts** (death, new victim, start/end, admin broadcast): **push (FCM)** may still fire when the app is backgrounded.
- In-app notice inbox may complement both.

<a id="admin-surfaces"></a>

### M8 — Admin surfaces

Three client experiences — do **not** reuse the player/assassin UI for admins.

#### M8a — Web dashboard (Angular) — setup & roster

Desk / pre-festival work. CRUD and configuration live here.

| Capability | On web |
|---|---|
| Create town + generate invitation code(s) | Yes |
| Manually verify players; create/edit players; skip verification | Yes |
| Create / edit / delete teams; assign members | Yes |
| Configure match (name, dates, windows); enroll teams | Yes |
| Define checkpoints and time windows | Yes |
| Full historical / detailed board (teams, kills, check-ins) | Yes (optional also during match) |
| Start / pause / close; eliminate; proclaim; broadcast | Available, but **primary during festival is mobile field view** |

**Out of web’s festival-day focus:** organizers should not rely on a laptop in the street for live control.

#### M8b — Admin mobile field view — live match control

Simple, large-tap UI for organizers **in the field**. Distinct layout and navigation from the player/assassin app. **No** create/edit players, **no** submit new players, **no** team roster CRUD, **no** town/code setup.

| Capability | On admin mobile |
|---|---|
| See match status (DRAFT / CONFIGURED / ACTIVE / PAUSED / FINISHED) | Yes |
| Start / pause / resume / close match | Yes |
| Compact live board: teams alive/dead, kill counts, current victims, checkpoint compliance | Yes |
| Manual eliminate a team | Yes |
| Proclaim winner / close match | Yes |
| Broadcast a short notice to all players | Yes |
| Create or edit players / teams / invitation codes / match config | **No** — web only |
| Play as assassin (own QR, scan to kill) | **No** — that is the player app |

#### M8c — Player / assassin mobile — play

Separate from both admin surfaces (see [Player app must-haves](#player-app-must-haves)).

<a id="player-app-must-haves"></a>

## 8. Player / assassin app must-haves

- Registration with invitation code **and** phone + SMS OTP.  
- Own QR visible.  
- QR scanner to kill.  
- Current assigned victim visible.  
- Checkpoint check-in.  
- Push (death, new victim, admin notices).  
- **Live ranking** (teams; updates as the match runs).  
- **Kill feed / death history** (recent eliminations in-app).  
- **Not** an admin control surface.

## 9. Characteristics & non-functionals

- Play remains **100% on the street**, integrated with the festival.  
- Access gated so players belong to the town.  
- **Web dashboard** is the setup cockpit; **admin mobile field view** is the weekend live-control cockpit.  
- Designed to scale to **multiple towns independently** (schema-per-town or equivalent).  
- Player mobile UX: large QR, fast scan, readable outdoors.  
- Admin field UX: few screens, high contrast, one-thumb controls; no dense CRUD tables.  
- Domain events are written to **Kafka (Amazon MSK)** as the event store; consumers drive notifications, projections, and long-poll payloads.
- Do **not** rely on in-process Spring Application Events as the system of record for domain events.
- Backend live sync to clients is **long polling only** — no WebSockets / SSE / similar.
- Infra: **Terraform + Kubernetes** on AWS (MSK for Kafka), owned by the `iac` repo. Development uses **local git repos**; optional local helpers do not replace that target.
- **API-first:** the `api` repo owns the OpenAPI contract; ios, android, and web only consume it — see [repositories.md](Repositories#api-first).
- Every product repo (api, ios, android, web, iac) includes **unit**, **integration**, and **E2E** tests — see [repositories.md](Repositories#testing-required-in-every-repo).  
- Assignment bounded context needs careful design before implementation.

## 10. Post-MVP (explicit backlog)

- Configurable game modes from dashboard.  
- Self-service onboarding for new towns.

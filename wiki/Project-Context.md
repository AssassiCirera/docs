# AssassíCirera — Project context

| | |
|---|---|
| **Product** | Assassí de la Cirera (project slug: AssassíCirera) |
| **Kind** | Digital companion for a street / festival role-and-strategy game played in teams |
| **Sources** | `Assassí de la Cirera - ERS.docx` (functional ERS/MVP), `assassi_cirera.md` (digital MVP v3: rules, stack, bounded contexts, features) |
| **Audience** | Product, design, engineering |

## Goals

1. Digitize the weekend festival game so **teams** can hunt assigned victims across town with clear status and fair validation.
2. Give **players / assassins** a mobile play experience: identity, own QR, current victim, kill confirmation, checkpoint check-in, live ranking, kill feed, and timely notices.
3. Give **admins** two distinct surfaces (not the same UI):
   - **Web dashboard (Angular):** setup and roster — town, codes, verify players, form teams, configure the match.
   - **Admin mobile (field view):** simple on-street match control during the festival — not for creating or editing players/teams.
4. Structure the system so **towns** stay independent (multi-town later without shared player pools).

## What the game is (domain gist)

Assassí de la Cirera is a **live street game** during village festivities: strategy, stealth, and social life. Play is outdoors; the app supports the rules — it does not replace the physical festival.

- Play is in **teams** (exactly two). If one member dies, the team dies.
- Each team has one **victim** (target team) and one **assassin** (the team hunting them).
- **Kill (physical):** stick a sticker on a victim who is **not** holding a festival bar glass.
- **Survive (physical):** always hold one bar glass in hand.
- **Kill (digital):** scan the victim’s QR → system validates → assassin inherits the dead team’s next victim (the circular chain).
- **Checkpoints:** mandatory check-in windows; **two consecutive misses → elimination**.
- **Win:** close the chain (last team standing), else most kills if the match is closed otherwise.

## Constraints

- For **this MVP only**, modality is **teams of 2**; solo and other formats are deferred, not ruled out forever.
- Admins alone manage users, teams, and competition configuration (ERS).
- Team create/edit/delete/roster changes are **forbidden while a competition is in progress** (ERS).
- Access uses **both** invitation code + manual town verification **and** phone + SMS OTP (decided).
- Software does **not** enforce the glass-in-hand or sticker rules; those stay social / on-the-street.
- The **Assignment** domain (circular graph, reassignment after kill or checkpoint elimination, chain closed) is the hardest design surface — design it before coding.

## Decisions already clear from sources

| Topic | Decision |
|---|---|
| Team size | Exactly 2; linked fate |
| Kill digital mechanic | QR of a member of the **assigned** victim team |
| Reassignment | Killer inherits eliminated team’s former victim |
| Admin authority | Full control; can bypass enrollment windows; can skip verification in exceptional cases (ERS) |
| Access / auth | **Both:** invitation code + admin manual verify (town gate) **and** phone + SMS OTP (login/verify). Firebase Auth as session layer where it fits |
| Surfaces (target) | Native **player** app + native **admin field** app/mode (different UI) + Angular **web dashboard** for setup |
| Backend (target) | Modular Spring Boot monolith (DDD / hexagonal), PostgreSQL per town schema; domain events persisted to **Kafka (Amazon MSK)** as the event store |
| Event store | **Kafka on Amazon MSK** — append-only event log for domain facts; not Spring in-process Application Events |
| Infra | **Terraform + Kubernetes** (AWS/MSK). Work happens in **local git repos**; that does not mean Compose replaces cloud IaC |
| Integration style | **API-first:** backend OpenAPI contract in `api`; ios / android / web only consume it |
| Live sync (API) | **HTTP long polling** for near-real-time updates (ranking, kill feed, admin board, match state). **No** WebSockets, SSE, or similar |
| Notifications (target) | Push (FCM) for wake/alerts (death, new victim, org notices, start/end); in-app freshness via long polling |
| Product language | English for durable project docs; player-facing UI language is an open product choice (festival context may prefer Catalan) |

<a id="open-decisions"></a>

## Open decisions

Need Arnau when building. These do **not** block documentation; they block a production build.

| Topic | Options in sources | Why it matters |
|---|---|---|
| **First ship surface** | Full native + Angular + Spring vs thinner vertical slice | Cost and time to first playable festival |
| **Win on admin close** | Last standing only vs “most kills” tie-break (markdown) | Closing ceremony rules |
| **Branding** | Name only in docs; no assets in sources | Store / splash / festival identity |
| **Hosting / cloud** | AWS assumed for **MSK**; confirm EKS (or other) under Terraform | Ops for first town |
| **UI locale** | Catalan-first for festival players vs English | Copy and App Store listing |

## Glossary

| Term | Meaning |
|---|---|
| **Team** | Exactly two players; shared life/death |
| **Victim** | Team currently assigned as the hunt target |
| **Assassin** | Team that has this team as its victim |
| **Kill** | Physical sticker (rules) + QR validation (system) |
| **Sticker** | Applied for the physical kill |
| **Bar glass** | Glass held in hand = protected from sticker kill |
| **Chain** | Circular assignment ring of teams |
| **Chain closed** | Ring resolved to a single surviving team (or equivalent close) |
| **Checkpoint** | Control point; timed check-in; miss policy applies |
| **Town** | Tenant locality: own codes, admins, matches |
| **Invitation code** | Admin-issued join gate for a town (markdown) |
| **OTP** | SMS one-time password for verify/login (ERS) |
| **Admin** | Operator for a town / match; uses web for setup and mobile field view for live control |
| **Player / assassin** | Registered user; profile + play only (mobile play UI) |
| **Admin field view** | Simple mobile admin UI for live match control outdoors — not roster/setup CRUD |
| **Web dashboard** | Angular admin UI for setup, verification, teams, and match configuration |
| **Match / competition** | One configured game instance with lifecycle states |
| **Long polling** | HTTP request held open until new data or timeout; used instead of WebSockets for live sync |
| **Event store** | Kafka (MSK) log of domain events; source for projections and notification consumers |
| **MSK** | Amazon Managed Streaming for Apache Kafka |

## Bounded contexts (from digital MVP v3)

| Context | Responsibility |
|---|---|
| **Town** | Locality setup, invitation codes, admins |
| **Identity** | Registration, verification, player states |
| **Game** | Match config, dates, lifecycle |
| **Assignment** | Circular chain, chain-closed detection, reassignment |
| **Kill** | QR death validation |
| **Checkpoint** | Control points, check-ins, miss policy |
| **Notification** | Kafka consumers → FCM wake + long-poll payloads for in-app live views |

## Source map

| Concern | Primary source |
|---|---|
| Use cases, SMS, team CRUD, enrollment dates, IEEE-style modules | ERS |
| Street rules, invitation flow, stack, bounded contexts, checkpoints, feature MVP list | Markdown |
| Conflicts (auth, stack timing) | Captured in [Open decisions](#open-decisions); reconciled product rules in [requirements.md](Requirements#4-reconciled-product-rules) |

## Related docs

- [repositories.md](Repositories) — repository layout (api, ios, android, web, iac)
- [requirements.md](Requirements)
- [mvp.md](MVP)

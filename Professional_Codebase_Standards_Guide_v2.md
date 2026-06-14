# Professional Codebase Standards Guide
> Architecture · Design · Security · Database · Clean Code · System Design
> Version 2.0 — 2026

---

## Table of Contents
1. [Project Structure & Architecture](#1-project-structure--architecture)
2. [Naming Conventions](#2-naming-conventions)
3. [Design System & Theming](#3-design-system--theming)
4. [Reusable Components & DRY Principle](#4-reusable-components--dry-principle)
5. [Clean Code Principles](#5-clean-code-principles)
6. [Database Design & ACID Properties](#6-database-design--acid-properties)
7. [Security Standards](#7-security-standards)
8. [API Design Standards (REST)](#8-api-design-standards-rest)
9. [Git & Version Control](#9-git--version-control-standards)
10. [Code Documentation & Comments](#10-code-documentation--comments)
11. [System Design Fundamentals](#11-system-design-fundamentals)
12. [AI Assistant Prompt — Surgical Edit Standard](#12-ai-assistant-prompt--surgical-edit-standard)
13. [Master Checklist](#13-master-checklist)

---

## 1. Project Structure & Architecture

A well-organized project structure is the foundation of maintainable code. Prefer **feature-based** organization over file-type-based grouping.

### Recommended Folder Structure

```
src/
├── core/                  # App-wide config, constants, global helpers
├── features/              # Each feature is self-contained
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── types/
│   └── queue/
│       ├── components/
│       ├── hooks/
│       ├── services/
│       └── types/
├── shared/                # Truly reusable across multiple features
│   ├── components/
│   ├── hooks/
│   └── utils/
└── layouts/
```

> **Rule:** If a component or utility is used in more than one feature, move it to `shared/`.

### Architecture Principles

- **Separation of Concerns** — keep UI, business logic, and data layers separate
- **Dependency Inversion** — depend on abstractions, not concrete implementations
- **Open/Closed Principle** — open for extension, closed for modification
- Keep files small and focused — aim for under **200 lines per file**

---

## 2. Naming Conventions

Consistency in naming is one of the highest-impact, lowest-cost improvements you can make. Pick a convention and **never mix them**.

| Thing | Convention | Example |
|---|---|---|
| React / Vue Components | PascalCase | `QueueTicketCard` |
| Functions | camelCase | `fetchQueueTickets()` |
| Variables | camelCase | `isLoading`, `ticketList` |
| Boolean variables | camelCase with is/has/can | `isActive`, `hasError`, `canEdit` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_QUEUE_LENGTH` |
| Database Tables | snake_case plural | `queue_tickets`, `user_roles` |
| Database Columns | snake_case | `created_at`, `is_active` |
| CSS Classes | kebab-case (BEM) | `queue-card__title--active` |
| Component Files | PascalCase | `QueueTicketCard.jsx` |
| Utility / Hook Files | camelCase | `useQueueStatus.js` |
| API Endpoints | kebab-case nouns | `/api/queue-tickets` |
| Environment Variables | SCREAMING_SNAKE_CASE | `DB_CONNECTION` |

### Be Descriptive — Not Short

```js
// ❌ Bad
const d = new Date();
const fn = (x) => x * 2;

// ✅ Good
const createdAt = new Date();
const doubleTicketCount = (count) => count * 2;
```

---

## 3. Design System & Theming

Build a **design token system** so themes (light/dark/brand) are swappable without touching component logic. Every color, size, and spacing value lives in one place.

### CSS Design Tokens

```css
/* tokens.css — single source of truth */
:root {
  --color-primary:   #4f46e5;
  --color-surface:   #ffffff;
  --color-text:      #111827;
  --radius-md:        8px;
  --spacing-md:      16px;
  --shadow-card:     0 2px 8px rgba(0,0,0,0.08);
}

[data-theme="dark"] {
  --color-surface:   #1f2937;
  --color-text:      #f9fafb;
}
```

```css
/* ✅ Good — theme-aware */
.card { background: var(--color-surface); }

/* ❌ Bad — hardcoded values break theming */
.card { background: #ffffff; }
```

### Design Token Categories

- **Colors** — primary, surface, text, error, success, warning
- **Typography** — font families, sizes, weights, line heights
- **Spacing** — margin and padding scale (4px, 8px, 16px, 24px, 32px...)
- **Borders** — radius values and border widths
- **Shadows** — elevation levels
- **Breakpoints** — responsive layout thresholds

---

## 4. Reusable Components & DRY Principle

**DRY = Don't Repeat Yourself.** Every piece of knowledge should have a single, authoritative representation in the codebase.

### Reusable Component Pattern

```jsx
// ✅ Good — configurable, reusable Button component
const Button = ({
  label,
  variant  = 'primary',   // primary | ghost | danger
  size     = 'md',        // sm | md | lg
  onClick,
  disabled = false,
  loading  = false,
}) => (
  <button
    className={`btn btn--${variant} btn--${size}`}
    onClick={onClick}
    disabled={disabled || loading}
  >
    {loading ? <Spinner /> : label}
  </button>
);

// Usage
<Button label="Confirm" variant="primary" onClick={handleConfirm} />
<Button label="Cancel"  variant="ghost"   onClick={handleCancel} />
<Button label="Delete"  variant="danger"  loading={isDeleting} />
```

### When to Extract a Component or Function

- You have copy-pasted the same block **more than once**
- A function exceeds **~30 lines**
- A component file exceeds **~200 lines**
- The same logic appears in **two or more features**

---

## 5. Clean Code Principles

### Single Responsibility

One function does one thing. If you need "and" to describe what a function does, split it.

```js
// ❌ Bad — does too much
async function handleTicket(ticket) {
  validateTicket(ticket);
  await saveToDatabase(ticket);
  sendEmailNotification(ticket);
  updateQueueDisplay(ticket);
  logActivity(ticket);
}

// ✅ Good — orchestrator delegates to focused functions
async function processTicket(ticket) {
  validate(ticket);
  await save(ticket);
  await notify(ticket);
}
```

### Avoid Magic Numbers

```js
// ❌ Bad
if (queue.length > 50) { ... }

// ✅ Good
const MAX_QUEUE_LENGTH = 50;
if (queue.length > MAX_QUEUE_LENGTH) { ... }
```

### Guard Clauses — Fail Early

```js
// ❌ Bad — deeply nested pyramid of doom
function processTicket(ticket) {
  if (ticket) {
    if (ticket.status === 'waiting') {
      if (ticket.department_id) {
        // actual logic buried here
      }
    }
  }
}

// ✅ Good — flat and readable
function processTicket(ticket) {
  if (!ticket)                     throw new Error('Ticket required');
  if (ticket.status !== 'waiting') return;
  if (!ticket.department_id)       throw new Error('Department required');
  // actual logic here — clean and clear
}
```

### Additional Rules

- **Don't comment out dead code** — delete it, git history preserves it
- **Avoid boolean traps** — `setStatus(true)` is unclear; prefer `setStatus('active')`
- **Return early** over deeply nested else blocks
- **Prefer pure functions** — same input always gives same output, no hidden side effects

---

## 6. Database Design & ACID Properties

The ACID properties guarantee that database transactions are processed reliably, especially in concurrent systems like a queue.

| Property | Meaning | How to Enforce |
|---|---|---|
| **Atomicity** | All-or-nothing — either everything succeeds or nothing does | Wrap multi-step operations in DB transactions |
| **Consistency** | Data always satisfies all defined rules and constraints | Use foreign keys, CHECK constraints, NOT NULL |
| **Isolation** | Concurrent transactions do not interfere with each other | Use appropriate transaction isolation levels |
| **Durability** | Committed data survives crashes and restarts | PostgreSQL WAL (Write-Ahead Logging) handles this |

### Transaction Example (Laravel)

```php
// Always wrap multi-step DB operations in a transaction
DB::transaction(function () use ($ticket) {
    $ticket->update([
        'status'    => 'serving',
        'called_at' => now(),
    ]);
    StaffSession::where('id', $sessionId)->increment('total_served');
    ActivityLog::create([...]);
});
// If ANY step fails, ALL steps are automatically rolled back
```

### Database Best Practices

- Always define **foreign keys** with explicit `ON DELETE` behavior
- **Index** every column used in `WHERE`, `JOIN`, and `ORDER BY` clauses
- Follow **3NF normalization** — eliminate redundant data
- Use `NOT NULL` unless NULL is genuinely meaningful
- Store passwords **hashed** (bcrypt, cost >= 10) — never plain text
- Always include `created_at` and `updated_at` audit columns
- Use `SERIAL` / `BIGSERIAL` for primary keys in PostgreSQL
- Never store calculated values that can be derived from other columns

---

## 7. Security Standards

### Authentication & Authorization

- Hash passwords with **bcrypt** (cost factor >= 10)
- Use **short-lived access tokens** + refresh tokens
- Implement **Role-Based Access Control (RBAC)**
- Never expose passwords, tokens, or secrets in logs or API responses
- **Rate-limit** all authentication endpoints

### Input Validation

```php
// Always validate on the server — never trust the client
$request->validate([
    'student_name' => 'required|string|max:100',
    'service_id'   => 'required|integer|exists:services,id',
    'email'        => 'nullable|email|max:100',
    'phone'        => 'nullable|regex:/^[0-9+\-\s]{7,20}$/',
]);
```

### Security Checklist

- **HTTPS everywhere** — never transmit data over plain HTTP
- Set strict **CORS policies** — whitelist allowed origins only
- Use **parameterized queries** always — never raw string SQL (prevents SQL injection)
- Store all secrets in `.env` — **never commit them to version control**
- Add `.env` to `.gitignore` immediately when starting a project
- **Sanitize and escape** all user-generated content before rendering
- Implement **CSRF protection** on all state-changing endpoints
- Set `Secure`, `HttpOnly`, `SameSite` flags on cookies
- All redirect URLs are validated against an allow list before redirecting the user
- If needed, create storage policies so users can only access files they uploaded
- Before Deployment, remove all console.log statements and replace with proper error logging
- Verify Webhooks signature if using payment platform SDKs such as Stripe before processing any payment data
- Every protected routes needs role checking for users such as 'user.role = 'admin'' on the server before executing
- Before each build run npm audit fix and do carefully audit in a detailed format the breaking changes in the latest version that I should know about
- Add Rate Limiting to authentication features such as in the password reset route: Max 3 requests per email per hour
- Catch all errors and return generic messages to users. Log detailed errors server side only
- Set JWT Tokens expiration or any Tokens to 7 days and implement refresh token rotation
- When in Production, CORS should only allow requests from the production domain

---

## 8. API Design Standards (REST)

### Endpoint Structure

```
GET    /api/v1/tickets          → List all tickets (paginated)
GET    /api/v1/tickets/{id}     → Get a single ticket
POST   /api/v1/tickets          → Create a new ticket
PUT    /api/v1/tickets/{id}     → Replace a ticket (full update)
PATCH  /api/v1/tickets/{id}     → Partially update a ticket
DELETE /api/v1/tickets/{id}     → Delete a ticket
```

- Use **nouns**, not verbs in endpoints (`/tickets` not `/getTickets`)
- Always **version your API** — `/api/v1/...`

### Consistent Response Shape

```json
{
  "success": true,
  "data":    { "id": 1, "ticket_number": "TR-001" },
  "message": "Ticket created successfully.",
  "errors":  null
}
```

### HTTP Status Codes

| Code | Meaning | When to Use |
|---|---|---|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST that creates a resource |
| 400 | Bad Request | Malformed request or missing required fields |
| 401 | Unauthorized | Not authenticated — no valid token |
| 403 | Forbidden | Authenticated but lacks permission |
| 404 | Not Found | Resource does not exist |
| 422 | Unprocessable Entity | Validation failed |
| 409 | Conflict | Duplicate resource or constraint violation (e.g. duplicate queue ticket) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server-side failure |

---

## 9. Git & Version Control Standards

### Branch Naming

```
feature/queue-priority-system
fix/session-timeout-bug
hotfix/payment-crash
chore/update-dependencies
docs/update-api-readme
refactor/extract-ticket-service
```

### Commit Messages (Conventional Commits)

```
feat:      add priority queue support
fix:       resolve session expiry on mobile
docs:      update API endpoint documentation
refactor:  extract ticket validation to service class
chore:     update npm dependencies
style:     format controller to PSR-12 standard
test:      add unit tests for queue calculator
```

### Git Rules

- **Never commit directly to `main`** or `master`
- Use **Pull Requests** with at least one code review
- Keep commits **small and focused** — one logical change per commit
- Write a **meaningful commit message** — never `"fix stuff"` or `"wip"`
- Always review your diff before committing: `git diff --staged`
- **Squash** related micro-commits before merging a PR

---

## 10. Code Documentation & Comments

Comments should explain **WHY** — not WHAT. The code itself explains what it does; the comment explains the reasoning behind a decision.

```js
// ❌ Bad comment — states the obvious
// increment i by 1
i++;

// ✅ Good comment — explains WHY, not WHAT
// Priority tickets skip ahead, but are capped at MAX_PRIORITY_SLOTS
// to prevent starvation of regular queue tickets
if (ticket.is_priority && priorityCount < MAX_PRIORITY_SLOTS) { ... }
```

### JSDoc / PHPDoc for Public Functions

```js
/**
 * Calculates estimated wait time based on queue position.
 *
 * @param {number} position   - Ticket's position in queue (1-based)
 * @param {number} avgMinutes - Average service time per ticket in minutes
 * @returns {number}          - Estimated wait time in minutes
 */
function estimateWaitTime(position, avgMinutes) {
  return position * avgMinutes;
}
```

---

## 11. System Design Fundamentals

System design is about how real-world applications are built to handle real users, real traffic, and real failures. These are not advanced topics reserved for large companies — they are decisions every production system must make. Understanding them lets you build systems that are scalable, reliable, secure, and maintainable from the start.

---

### 11.1 Client–Server Architecture

Almost every system begins here. The **client** is what the user interacts with — a web browser or mobile app. The **server** is where business logic and data live. When a user logs in, fetches data, or submits a form, the client sends a request and the server responds.

This separation allows the **same backend to serve multiple clients** — web, mobile, and internal tools — without duplicating logic.

```
[Browser / Mobile App]  ──request──►  [Server: Business Logic + Database]
                        ◄──response──
```

> **Rule:** Business logic always lives on the server. Never trust client-side validation alone — it can be bypassed.

---

### 11.2 Load Balancing

A single server quickly becomes a bottleneck as usage grows. Requests pile up, response times increase, and a single crash takes down the entire application.

A **load balancer** sits in front of multiple servers and distributes incoming traffic among them. If one server goes down, traffic is automatically routed to healthy servers.

```
                    ┌──► Server A
Client ──► Load Balancer ──► Server B
                    └──► Server C
```

**Common strategies:**

| Strategy | How it works | Best for |
|---|---|---|
| Round Robin | Each request goes to the next server in sequence | Servers with similar capacity |
| Least Connections | Route to the server with fewest active connections | Long-lived connections |
| IP Hash | Route based on client IP — same client always hits same server | Session-sensitive apps |

> **Rule:** Design your application to be **stateless** so any server can handle any request. Store sessions in a shared store (Redis, database) — not in server memory.

---

### 11.3 Caching

Repeatedly fetching the same data from a database is expensive. **Caching** stores frequently requested data in fast in-memory systems so it can be returned almost instantly.

```
Client ──► [Cache Hit?] ──YES──► Return cached data (microseconds)
                └── NO ──► Query database ──► Store in cache ──► Return data
```

**Cache levels:**

| Level | Where | Example |
|---|---|---|
| In-memory | Server RAM | Variables, memoization |
| Application cache | Redis, Memcached | API responses, session data |
| CDN | Edge servers globally | Static assets, images |
| Database query cache | DB engine | Repeated identical queries |

**When to cache:**

- Data that is read frequently but changes rarely (e.g. office list, service types)
- Expensive computed results (e.g. analytics aggregations)
- External API responses

**Cache invalidation rules:**

- Set an appropriate **TTL (Time To Live)** for every cached item
- **Invalidate on write** — when data changes, clear or update the relevant cache entry immediately
- Never cache data that must always be real-time (e.g. current queue position)

```php
// Laravel Cache example
$officeList = Cache::remember('offices.all', now()->addHours(6), function () {
    return Office::with('services')->active()->get();
});

// Invalidate when an office is updated
Cache::forget('offices.all');
```

> **Rule:** Caching reduces latency and database load significantly, but introduces **data freshness risks**. Always define what "stale is acceptable" for each piece of data before caching it.

---

### 11.4 Relational vs. NoSQL Databases

Not all data fits the same storage model. Choosing the right database type is a system design decision, not just a preference.

| Type | Best for | Examples | Characteristics |
|---|---|---|---|
| **Relational (SQL)** | Structured data, strong consistency, relationships | PostgreSQL, MySQL | ACID guarantees, joins, schema-enforced |
| **NoSQL (Document)** | Flexible schemas, high write throughput, unstructured data | MongoDB, Firestore | Horizontal scaling, eventual consistency |
| **NoSQL (Key-Value)** | Fast lookups, caching, sessions | Redis, DynamoDB | Sub-millisecond reads, simple structure |
| **NoSQL (Time-Series)** | Metrics, logs, events over time | InfluxDB, TimescaleDB | Optimized for append-heavy, time-ordered data |

> **Rule:** In most systems, **both are used together**. Use PostgreSQL for your core transactional data (users, tickets, payments). Use Redis for caching and sessions. Use a document store only when your data genuinely has no fixed schema.

---

### 11.5 Microservices vs. Monolith

As a codebase grows, maintaining one large application becomes difficult. Changes take longer, deployments become risky, and teams block each other.

**Monolith:**
- Single deployable unit
- Simple to develop and debug early on
- Becomes harder to scale and maintain as it grows
- A bug in one area can crash the whole system

**Microservices:**
- System is split into smaller services, each responsible for a single capability (e.g. users, payments, notifications)
- Each service can be developed, deployed, and scaled independently
- Introduces distributed systems complexity (network failures, data consistency, service discovery)

```
Monolith:                    Microservices:
┌─────────────────┐          ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Users          │          │  Users   │  │ Payments │  │  Notify  │
│  Payments       │    vs    │  Service │  │  Service │  │  Service │
│  Notifications  │          └──────────┘  └──────────┘  └──────────┘
│  Queue          │               ▲              ▲              ▲
└─────────────────┘               └──────────────┴──────────────┘
                                          API Gateway
```

> **Rule for smaller teams and projects:** Start with a well-structured monolith. Extract services only when a specific area has clearly different scaling requirements or team ownership. Premature microservices add complexity without benefit.

---

### 11.6 Synchronous vs. Asynchronous Communication

When services (or layers within a monolith) need to communicate, you must choose how they wait for each other.

**Synchronous** — one process waits for the other to respond before continuing:

```
Service A ──request──► Service B
          ◄──response── (Service A is blocked until B responds)
```

- Simple to reason about
- Dangerous under high load — slow responses cascade into timeouts and failures across the whole system

**Asynchronous** — one process publishes an event and continues without waiting:

```
Service A ──event──► [Message Queue] ──► Service B (processes independently)
(Service A continues immediately — not blocked)
```

- More resilient — a slow consumer does not block the producer
- Harder to debug — failures are not immediately visible
- Use for: sending emails, push notifications, generating reports, analytics processing

**Laravel Queue example:**

```php
// Dispatch a job asynchronously — controller returns immediately
dispatch(new SendQueueNotification($ticket));

// The job runs in a background worker, independently of the HTTP request
class SendQueueNotification implements ShouldQueue {
    public function handle(): void {
        // send push notification to client's mobile app
    }
}
```

> **Rule:** Use synchronous communication for operations the user must wait for (create ticket, call next). Use asynchronous queues for everything the user does not need to wait for (notifications, emails, analytics, report generation).

---

### 11.7 Circuit Breaker Pattern

In distributed systems, failures are not rare events — they are expected. When a downstream service (external API, payment gateway, notification service) starts failing or responding slowly, naively retrying floods it further and wastes resources across the whole system.

A **circuit breaker** monitors calls to a downstream service. When failures exceed a threshold, it "opens" — temporarily blocking all requests to that service and returning a fast fallback response instead. After a cool-down period, it allows a small number of test requests through. If those succeed, the circuit closes and normal traffic resumes.

```
         ┌─── CLOSED (normal) ──── too many failures ───► OPEN (blocking) ───┐
         │                                                       │            │
         └──────────────────── test requests succeed ──── HALF-OPEN ◄────────┘
```

**States:**

| State | Behaviour |
|---|---|
| **Closed** | Requests flow normally; failures are counted |
| **Open** | All requests fail fast with a fallback; no calls reach the service |
| **Half-Open** | A limited number of test requests are allowed through to check recovery |

> **Rule:** Always implement timeouts, retries with exponential back-off, and circuit breakers for any call that crosses a network boundary — external APIs, payment providers, notification services, or separate internal services.

---

### 11.8 Data Replication and Sharding

As data volume and read traffic grow, a single database server becomes a bottleneck.

**Replication** keeps multiple copies of data across different machines:

```
        Writes ──► Primary DB ──► replicates ──► Replica 1
                                              └──► Replica 2 (read traffic)
```

- Improves **read throughput** — read replicas handle read queries
- Improves **availability** — if the primary fails, a replica can be promoted
- Introduces **replication lag** — replicas may be slightly behind the primary

**Sharding (Partitioning)** splits data across multiple servers horizontally:

```
Users A–M ──► Shard 1 (DB Server 1)
Users N–Z ──► Shard 2 (DB Server 2)
```

- Allows the dataset to grow beyond what one server can hold
- Each shard handles a subset of the data
- Introduces complexity: cross-shard queries, resharding, and routing logic

> **Rule:** For most applications at university-project to small-production scale, a single well-indexed PostgreSQL instance with read replicas is sufficient. Do not shard prematurely — it adds significant operational complexity.

---

### 11.9 Consistency Trade-offs (CAP Theorem)

In any distributed system, you cannot simultaneously guarantee all three of:

| Guarantee | Meaning |
|---|---|
| **Consistency (C)** | Every read receives the most recent write |
| **Availability (A)** | Every request receives a response (not necessarily the latest data) |
| **Partition Tolerance (P)** | The system continues operating even if network failures split it |

Network partitions always happen in distributed systems — so the real trade-off is between **C** and **A**:

- **Prioritize Consistency** — financial systems, inventory, booking. A user must never see stale data that could cause a wrong transaction.
- **Prioritize Availability** — social feeds, analytics dashboards, queue status displays. It is acceptable for data to be slightly out of date.

> **Rule:** Be explicit about which trade-off you are making for each feature. Queue position must be consistent. Analytics reports can tolerate eventual consistency. Make this decision consciously — not by accident.

---

### 11.10 Observability: Logs, Metrics, and Traces

As systems grow, visibility into what is happening in production becomes just as important as the features themselves. **Observability** is the practice of instrumenting a system so its internal state can be understood from its outputs.

The three pillars:

| Pillar | What it answers | Tool examples |
|---|---|---|
| **Logs** | What happened? Discrete events with context | Laravel Log, Monolog, Papertrail |
| **Metrics** | How is the system performing over time? | Prometheus, Grafana, Datadog |
| **Traces** | How did this request flow across services? | Jaeger, Zipkin, OpenTelemetry |

**Logging levels — use the right level:**

```php
Log::debug('Queue status fetched',   ['office_id' => $id]);        // Dev only
Log::info('Ticket created',          ['ticket' => $ticket->id]);   // Normal operation
Log::warning('Retry attempt 2/3',    ['job' => $jobId]);            // Unexpected but recoverable
Log::error('Payment gateway failed', ['error' => $e->getMessage()]); // Needs attention
Log::critical('Database unreachable', ['host' => config('db.host')]); // System down
```

**What to log:**

- Every state transition (ticket created → called → served → skipped)
- Every external API call and its outcome
- Every authentication event (login, failed login, token refresh)
- Every error with full context — never swallow exceptions silently

**What NOT to log:**

- Passwords, tokens, or any credential — ever
- Full credit card numbers or personal identification numbers
- Raw request bodies that may contain sensitive fields

> **Rule:** If you cannot answer "what happened in the last hour that caused this error?" from your logs alone, your logging is insufficient.

---

### 11.11 CI/CD and Infrastructure as Code

Modern systems are designed with automation in mind. Manual deployments introduce human error, inconsistent environments, and slow release cycles.

**Continuous Integration (CI)** — every push to a branch automatically:
1. Runs linting and code style checks
2. Runs the test suite
3. Builds the application
4. Blocks the merge if any step fails

**Continuous Deployment (CD)** — after a successful merge to `main`:
1. Deploys to a staging environment automatically
2. Runs smoke tests
3. Deploys to production (manually triggered or fully automated)

**Infrastructure as Code (IaC)** — server configuration is defined in version-controlled files, not set up manually:

```yaml
# Example: GitHub Actions CI workflow
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: composer install && npm install
      - name: Run tests
        run: php artisan test
      - name: Run linter
        run: ./vendor/bin/pint --test
```

> **Rule:** No code reaches production without passing CI. Automate everything that can be automated — environments, tests, deployments. Manual steps are human error waiting to happen.

---

### 11.12 Graceful Degradation and Fault Tolerance

Good system design assumes that **failure will happen**. Servers crash, networks fail, and traffic spikes unexpectedly. The goal is not to prevent all failure — it is to ensure that failure in one part does not take down the whole system.

**Patterns for resilience:**

| Pattern | What it does | Example |
|---|---|---|
| **Redundancy** | Multiple instances so one failure does not matter | Two app servers behind a load balancer |
| **Retries with back-off** | Retry failed operations with increasing delay | Retry failed push notification after 1s, 2s, 4s |
| **Fallbacks** | Return cached or default data when live data is unavailable | Show cached office list if database is slow |
| **Timeouts** | Never wait indefinitely for a response | HTTP client timeout: 5 seconds max |
| **Graceful degradation** | Serve partial functionality instead of a full error page | Queue display works even if analytics are down |

```php
// Timeout + fallback example
try {
    $status = Http::timeout(5)->get('https://notification-service/status');
} catch (ConnectionException $e) {
    // Service is down — log it, return a safe default, do not crash
    Log::warning('Notification service unreachable', ['error' => $e->getMessage()]);
    $status = ['available' => false];
}
```

> **Rule:** Every external call must have a timeout. Every critical feature must have a fallback. Design for the worst case — not the happy path only.

---

### 11.13 System Design Decision Checklist

Before making a significant architecture decision, answer these questions:

- **Scale** — How many concurrent users does this need to handle now? In 6 months?
- **Consistency** — Does this data need to be instantly correct, or is eventual consistency acceptable?
- **Availability** — What happens to the user if this component is unavailable? Is a fallback possible?
- **Failure mode** — If this fails, what fails with it? Is failure isolated or cascading?
- **Observability** — Can you tell from logs and metrics when this is degraded or broken?
- **Simplicity** — Is this the simplest solution that solves the problem? Complexity has a cost.

> **The goal of system design is not to use every pattern available — it is to make deliberate trade-offs that match the actual scale, team size, and reliability requirements of your system.**

---

## 12. AI Assistant Prompt — Surgical Edit Standard

Use this prompt at the start of **every coding session** with an AI assistant to enforce safe, surgical, non-destructive edits.

---

```
You are a senior software engineer assisting me with this codebase.
Follow these rules STRICTLY on every single response without exception:

1. SURGICAL EDITS ONLY.
   - Only modify the exact lines, functions, or blocks directly required
     to fulfill my request.
   - Do NOT touch, reformat, rename, or reorganize any code that is not
     explicitly part of the task.
   - Do NOT add, remove, or move imports unless the task requires it.
   - Do NOT change whitespace, indentation style, or formatting in
     unrelated sections.

2. ZERO SIDE EFFECTS.
   - Your changes must not alter the behavior, output, or state of any
     other part of the system.
   - If a change has necessary side effects, explicitly flag them before
     proceeding.

3. PRESERVE ALL EXISTING PATTERNS.
   - Match the naming conventions, code style, and architectural patterns
     already present in the file.
   - Do not introduce new patterns, abstractions, or libraries unless I
     explicitly ask.

4. SHOW ONLY WHAT CHANGES.
   - When showing code, show only the changed function or block with clear
     markers.
   - Use comments like // CHANGED: <reason> to annotate what changed and why.
   - Do not show entire files unless I ask for a full file view.

5. CONFIRM SCOPE BEFORE ACTING.
   - If my request is ambiguous or could affect more than one area, ask me
     to clarify before writing any code.
   - State exactly what you will change and what you will not change.

6. NO UNREQUESTED IMPROVEMENTS.
   - Do not refactor, optimize, or "clean up" anything I did not ask about.
   - If you notice a bug or improvement opportunity outside my request,
     mention it as a separate note AFTER completing my task — do not
     implement it.

7. EXPLAIN BRIEFLY.
   - After every change, provide a 2–3 sentence plain-English summary of
     what changed and why.
   - Do not pad responses with unnecessary context or filler.

8. DEPRECATED VALUES MITIGATION AND AVOIDANCE.
   - before finishing you response, always check the problems tab for usage of deprecated values and then mitigate them before confirming or finishing your response(no problems must exist in the problem tab every response you finish).

9. STANDARDS ADHERANCE(VERY IMPORTANT).
   - Always follow the @Professional_Codebase_Standards_Guide_v2.md.
   - Do not break any existing patterns or conventions.
   - Do not introduce any new patterns or conventions.
   - No inline styles - use CSS classes only in their respective CSS files.

If you understand and will follow all of these rules, confirm with:
"Understood. Surgical edits only. What do you need changed?"
```

---

## 13. Master Checklist

Use this before every Pull Request or project milestone review.

### Architecture & Structure
- [ ] Feature-based folder structure in place
- [ ] Shared components extracted to `shared/` directory
- [ ] No circular dependencies between modules
- [ ] No file exceeds ~200 lines without good reason

### Naming & Code Quality
- [ ] Consistent naming conventions across all files
- [ ] No magic numbers — all constants are named
- [ ] Guard clauses used — no deeply nested conditionals
- [ ] Single responsibility respected — functions do one thing
- [ ] No duplicated logic — DRY principle applied

### Design & Theming
- [ ] Design tokens in place — no hardcoded colors or sizes
- [ ] All reusable UI components are configurable via props
- [ ] Dark/light theme switching works without touching components

### Database
- [ ] Foreign keys defined with correct `ON DELETE` behavior
- [ ] Indexes on all `WHERE`, `JOIN`, `ORDER BY` columns
- [ ] Multi-step DB operations wrapped in transactions
- [ ] Passwords stored as bcrypt hashes
- [ ] `created_at` and `updated_at` on all tables

### Security
- [ ] All endpoints validate input server-side
- [ ] All redirect URLs are validated against an allow list before redirecting the user
- [ ] If needed, create storage policies so users can only access files they uploaded
- [ ] Before Deployment, remove all console.log statements and replace with proper error logging
- [ ] Verify Webhooks signature if using payment platform SDKs such as Stripe before processing any payment data
- [ ] Every protected routes needs role checking for users such as 'user.role = 'admin'' on the server before executing
- [ ] Before each build run npm audit fix and do carefully audit in a detailed format the breaking changes in the latest version that I should know about
- [ ] Add Rate Limiting to authentication features such as in the password reset route: Max 3 requests per email per hour
- [ ] Catch all errors and return generic messages to users. Log detailed errors server side only
- [ ] Set JWT Tokens expiration or any Tokens to 7 days and implement refresh token rotation
- [ ] HTTPS enforced — no plain HTTP
- [ ] Secrets stored in `.env` and excluded from git
- [ ] Parameterized queries used everywhere — no raw SQL strings
- [ ] CORS policy configured and restrictive
- [ ] When in Production, CORS should only allow request from my production domain

### API
- [ ] Consistent response shape on all endpoints
- [ ] Correct HTTP status codes used (including 409 Conflict and 429 Too Many Requests)
- [ ] API is versioned (`/api/v1/...`)

### Git
- [ ] All commits follow Conventional Commits format
- [ ] No direct commits to `main`
- [ ] Pull Request reviewed before merging
- [ ] `.env` and `node_modules` in `.gitignore`

### System Design
- [ ] Application is stateless — session/state stored in shared store, not server memory
- [ ] Caching applied to frequently read, rarely changed data — TTL and invalidation defined
- [ ] Correct database type chosen for each data concern (relational vs. NoSQL)
- [ ] Long-running tasks dispatched to async queues — not blocking HTTP requests
- [ ] All external/network calls have timeouts configured
- [ ] Fallback behavior defined for every critical external dependency
- [ ] Error logging covers all state transitions, external calls, and auth events
- [ ] CI pipeline runs tests and linting before any merge to `main`
- [ ] Consistency trade-off explicitly decided for each feature (strong vs. eventual)
- [ ] Circuit breaker or retry-with-back-off applied to all third-party API calls

---

*This guide applies universally whether you're building in Laravel, React, Vue, Node, or any other stack. The principles are language-agnostic — only the syntax changes.*

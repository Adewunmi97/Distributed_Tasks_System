# Distributed Task System Constraints

**Purpose:** Document the technical, operational, and business constraints that shape the system's design.  
**Last Updated:** January 2026

---

## 📋 Table of Contents

- [Why Document Constraints?](#why-document-constraints)
- [Technical Constraints](#technical-constraints)
- [Architecture Constraints](#architecture-constraints)
- [Database Constraints](#database-constraints)
- [Background Job Constraints](#background-job-constraints)
- [API Constraints](#api-constraints)
- [Operational Constraints](#operational-constraints)
- [Security Constraints](#security-constraints)

---

## Why Document Constraints?

**Distributed systems are shaped by real-world limitations.**

Design decisions stem from **unavoidable constraints**:

- Network latency affects response times
- Database transactions limit concurrency
- Background jobs have failure modes
- Memory and CPU are finite

By making these constraints explicit:

1. **Justify design decisions** - "We chose X because constraint Y"
2. **Set realistic expectations** - "We can't do Z because of W"
3. **Avoid impossible goals** - "Sub-millisecond API + complex transactions = impossible"

---

## Technical Constraints

### 1. Network Latency

**Constraint:** Network communication adds latency that cannot be eliminated.

**Impact on System:**

| Communication Type | Typical Latency | Example |
|--------------------|-----------------|---------|
| **Same process** | <1 μs | Method call |
| **Same machine (IPC)** | 1-10 μs | Unix socket |
| **Same data center** | 1-5 ms | HTTP within AWS AZ |
| **Cross-region** | 50-150 ms | US East → US West |
| **Intercontinental** | 100-300 ms | US → Europe |

**Design Implications:**

- ✅ **Single-region deployment preferred** - Keep API response <100ms
- ✅ **Async processing for slow operations** - Don't block HTTP requests
- ❌ **Synchronous cross-region calls** - Would add 100+ ms latency

**System's Approach:**

- **Phase 1-4:** Single-region deployment
- **Phase 5:** Service extraction within same region
- **Future:** Multi-region (if needed) with async replication

**Quote from Martin Kleppmann:**

> "The network is unreliable, and even when working, introduces latency. Design for failure, not success."

---

### 2. Database Connection Limits

**Constraint:** PostgreSQL has a finite connection pool.

**Default Limits:**

| Configuration | Default | Typical Production |
|---------------|---------|-------------------|
| **max_connections** | 100 | 200-300 |
| **Rails connection pool** | 5 per process | 5-10 per process |
| **Sidekiq workers** | 10-25 per process | 10-25 per process |

**Impact:**

- 10 API servers × 5 connections = 50 connections
- 5 Sidekiq workers × 10 connections = 50 connections
- Total: 100 connections (at default limit)

**Design Implications:**

- Connection pooling required (PgBouncer)
- Long-running queries block connections
- Must close connections properly

**System's Approach:**

```ruby
# config/database.yml
production:
  pool: <%= ENV.fetch("DB_POOL_SIZE", 5) %>
  timeout: 5000
  
# Use PgBouncer in production
# Max connections: 200
# Pool mode: transaction (not session)
```

---

### 3. Memory Limits

**Constraint:** Each process has finite memory.

**Typical Memory Usage:**

| Component | Memory per Process | Notes |
|-----------|-------------------|-------|
| **Rails API** | 300-500 MB | Base + gems |
| **Sidekiq Worker** | 200-400 MB | Base + job data |
| **PostgreSQL** | 2-8 GB | Shared buffers, cache |
| **Redis** | 1-4 GB | Queue data, cache |

**Impact:**

- Memory leaks crash processes
- Large payloads (>10 MB) cause issues
- Garbage collection pauses affect latency

**Design Implications:**

- Limit JSON payload sizes (<1 MB)
- Use pagination for large result sets
- Monitor memory usage (alerts at 80%)

**System's Approach:**

```ruby
# Limit request body size
Rails.application.config.middleware.use(
  Rack::Utils::ParameterTypeError,
  max_body_size: 1.megabyte
)

# Pagination required for large collections
GET /api/v1/tasks?page=1&per_page=25
```

---

## Architecture Constraints

### 1. Clean Architecture Boundaries

**Constraint:** Domain layer must not depend on infrastructure.

**Rule:** Dependencies point inward (toward domain).

```
Controllers → Services → Domain ← Repositories
                           ↑
                 (no outward dependencies)
```

**Violations to Avoid:**

❌ **Domain model uses ActiveRecord:**
```ruby
class Task < ApplicationRecord  # BAD: couples domain to Rails
  validates :title, presence: true
end
```

✅ **Pure domain model:**
```ruby
class Task  # GOOD: pure Ruby
  attr_reader :title
  
  def initialize(title:)
    raise ArgumentError if title.blank?
    @title = title
  end
end
```

**Why This Matters:**

- Can test domain without database
- Can swap ActiveRecord for Sequel
- Can extract services without rewriting logic

---

### 2. Single Responsibility Principle

**Constraint:** Each class should have one reason to change.

**Component Responsibilities:**

| Component | Responsibility | Changes When |
|-----------|---------------|--------------|
| **Controller** | HTTP request/response | API contract changes |
| **Service** | Business logic orchestration | Business rules change |
| **Domain Model** | Business rules | Domain concepts change |
| **Repository** | Data persistence | Storage strategy changes |
| **Worker** | Async execution | Queue strategy changes |

**Violation Example:**

❌ **Controller with business logic:**
```ruby
class TasksController < ApplicationController
  def create
    # BAD: business logic in controller
    task = Task.create!(task_params)
    if task.assignee_id
      NotificationWorker.perform_async(task.id)
    end
    render json: task
  end
end
```

✅ **Service handles business logic:**
```ruby
class TasksController < ApplicationController
  def create
    result = TaskCreationService.call(task_params)
    render json: result.task, status: result.status
  end
end
```

---

### 3. Dependency Injection

**Constraint:** Concrete implementations should be injected, not hard-coded.

**Bad Pattern (Tight Coupling):**

```ruby
class TaskCreationService
  def call(params)
    task = TaskRecord.create!(params)  # Hard-coded dependency
    Sidekiq::Client.push(...)          # Hard-coded dependency
  end
end
```

**Good Pattern (Dependency Injection):**

```ruby
class TaskCreationService
  def initialize(task_repository:, event_publisher:)
    @task_repository = task_repository
    @event_publisher = event_publisher
  end
  
  def call(params)
    task = @task_repository.save(Task.new(params))
    @event_publisher.publish(event: TaskCreatedEvent.new(task))
  end
end
```

**Benefits:**

- Easy to test (inject mocks)
- Easy to swap implementations
- Explicit dependencies

---

## Database Constraints

### 1. Transaction Isolation Levels

**Constraint:** PostgreSQL's isolation levels have trade-offs.

| Isolation Level | Prevents | Performance | Our Usage |
|----------------|----------|-------------|-----------|
| **Read Uncommitted** | Nothing | Fastest | ❌ Never |
| **Read Committed** | Dirty reads | Fast | ✅ Default |
| **Repeatable Read** | Non-repeatable reads | Slower | ✅ For consistency |
| **Serializable** | All anomalies | Slowest | ⚠️ Rarely |

**Default:**

```ruby
# Rails default: Read Committed
Task.transaction do
  task = Task.find(id)
  task.update!(state: 'completed')
end
```

**When to Use Repeatable Read:**

```ruby
# When consistency matters
Task.transaction(isolation: :repeatable_read) do
  task = Task.lock.find(id)  # SELECT FOR UPDATE
  task.assignee = user
  task.save!
end
```

**Trade-off:** Higher isolation = more locks = less concurrency.

---

### 2. Index Constraints

**Constraint:** Indexes speed up reads but slow down writes.

**Index Strategy:**

| Query Type | Index Needed | Write Penalty |
|------------|--------------|---------------|
| `WHERE email = ?` | Yes (unique) | Low |
| `WHERE state = ?` | Yes (non-unique) | Low |
| `WHERE creator_id = ?` | Yes (foreign key) | Low |
| `WHERE title LIKE '%foo%'` | No (full scan) | N/A |
| `WHERE created_at > ?` | Yes (range) | Low |

**System's Indexes:**

```ruby
# db/schema.rb
create_table :tasks do |t|
  t.string :title, null: false
  t.string :state, null: false, index: true
  t.references :creator, index: true, foreign_key: { to_table: :users }
  t.references :assignee, index: true, foreign_key: { to_table: :users }
  t.timestamps
  
  # Composite index for common query
  t.index [:assignee_id, :state], name: 'index_tasks_on_assignee_and_state'
end
```

**Why This Matters:**

- Missing index → Full table scan (slow)
- Too many indexes → Slow inserts/updates
- Monitor: `EXPLAIN ANALYZE` for slow queries

---

### 3. Foreign Key Constraints

**Constraint:** Referential integrity enforced at database level.

**Configuration:**

```ruby
# All foreign keys have constraints
add_foreign_key :tasks, :users, column: :creator_id, on_delete: :restrict
add_foreign_key :tasks, :users, column: :assignee_id, on_delete: :nullify
```

**Delete Strategies:**

| Strategy | Behavior | Use Case |
|----------|----------|----------|
| **RESTRICT** | Prevent deletion if references exist | Creator (tasks should remain) |
| **CASCADE** | Delete referenced rows | N/A in our system |
| **NULLIFY** | Set foreign key to NULL | Assignee (user deleted) |

**Impact:**

- Cannot delete user with tasks (creator)
- Deleting assignee sets `assignee_id = NULL`
- Prevents orphaned records

---

## Background Job Constraints

### 1. Job Execution Guarantees

**Constraint:** Sidekiq provides **at-least-once delivery**, not exactly-once.

**Implications:**

- Jobs may be executed multiple times
- Jobs must be **idempotent**
- Duplicate notifications are possible

**Idempotency Strategy:**

```ruby
# Store idempotency key
class EventRecord < ApplicationRecord
  validates :idempotency_key, uniqueness: true
end

# In service
def publish_event(task)
  EventRecord.create!(
    event_type: 'task.created',
    idempotency_key: "task:#{task.id}:created",
    payload: { task_id: task.id }
  )
rescue ActiveRecord::RecordNotUnique
  # Already published, skip
end
```

**Result:** Even if worker runs twice, event stored once.

---

### 2. Job Retry Limits

**Constraint:** Infinite retries would exhaust resources.

**Sidekiq Defaults:**

```ruby
class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5  # Default: 25
  
  # Retry schedule: 15s, 1m, 10m, 3h, 1d
end
```

**Trade-offs:**

- **Too few retries:** Transient failures cause data loss
- **Too many retries:** Dead jobs pile up, waste resources

**System's Strategy:**

- **Transient errors (network):** Retry 5 times
- **Permanent errors (validation):** Don't retry, log error
- **Dead jobs:** Manual review/retry

---

### 3. Queue Priority

**Constraint:** High-priority jobs can starve low-priority jobs.

**Queue Configuration:**

```ruby
# config/sidekiq.yml
:queues:
  - [critical, 3]      # Process 3 critical jobs...
  - [default, 2]       # ...per 2 default jobs...
  - [low_priority, 1]  # ...per 1 low-priority job
```

**Usage:**

| Queue | Use Case | Processing Time |
|-------|----------|-----------------|
| **critical** | Password resets | <1s |
| **default** | Task notifications | 1-5s |
| **low_priority** | Analytics, cleanup | >10s |

---

## API Constraints

### 1. Rate Limiting

**Constraint:** Prevent abuse and ensure fair usage.

**Rate Limits:**

| User Type | Limit | Window | Action |
|-----------|-------|--------|--------|
| **Unauthenticated** | 10 req/min | 1 minute | 429 Too Many Requests |
| **Authenticated** | 100 req/min | 1 minute | 429 Too Many Requests |
| **Admin** | 1000 req/min | 1 minute | No limit (monitoring) |

**Implementation:**

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 10, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api')
end

Rack::Attack.throttle('api/user', limit: 100, period: 1.minute) do |req|
  req.env['current_user']&.id if req.path.start_with?('/api')
end
```

---

### 2. Payload Size Limits

**Constraint:** Large payloads consume memory and slow down responses.

**Limits:**

| Payload Type | Max Size | Reason |
|--------------|----------|--------|
| **JSON request** | 1 MB | Memory per request |
| **Response body** | 5 MB | Client parsing |
| **File upload** | 10 MB | Disk space, bandwidth |

**Enforcement:**

```ruby
# Rack middleware
use Rack::Utils::ParameterTypeError, max_body_size: 1.megabyte
```

---

### 3. Pagination Requirements

**Constraint:** Large result sets must be paginated.

**Rules:**

- Default page size: 25
- Max page size: 100
- Return pagination metadata

**Example:**

```json
GET /api/v1/tasks?page=2&per_page=25

{
  "data": [...],
  "meta": {
    "current_page": 2,
    "per_page": 25,
    "total_pages": 10,
    "total_count": 250
  }
}
```

---

## Operational Constraints

### 1. Deployment Window

**Constraint:** Minimize downtime during deployments.

**Requirements:**

- Zero-downtime deployments
- Database migrations before code deploy
- Rollback in <5 minutes

**Strategy:**

1. Deploy new code (blue-green)
2. Run migrations (if backward compatible)
3. Switch traffic to new version
4. Monitor for errors
5. Rollback if needed

**Downtime Target:** <1 minute per month

---

### 2. Monitoring & Alerting

**Constraint:** Cannot fix what you cannot see.

**Required Metrics:**

| Metric | Threshold | Action |
|--------|-----------|--------|
| **API latency (p99)** | >1s | Page on-call |
| **Error rate** | >1% | Page on-call |
| **Queue depth** | >1000 | Alert Slack |
| **Database connections** | >80% | Alert Slack |
| **Disk usage** | >80% | Alert Slack |

**Tools:**

- **Metrics:** Prometheus + Grafana
- **Logs:** ELK Stack or Papertrail
- **Errors:** Sentry or Rollbar
- **Alerts:** PagerDuty

---

### 3. Backup & Recovery

**Constraint:** Must be able to recover from data loss.

**Requirements:**

- **Database backups:** Daily, retained 30 days
- **Point-in-time recovery:** Within last 7 days
- **Backup testing:** Monthly restoration drill
- **RTO (Recovery Time Objective):** <1 hour
- **RPO (Recovery Point Objective):** <24 hours

**Implementation:**

```bash
# Automated daily backup
0 2 * * * pg_dump -Fc production_db > backup_$(date +%Y%m%d).dump

# Restore command
pg_restore -d production_db backup_20260109.dump
```

---

## Security Constraints

### 1. Authentication

**Constraint:** Users must be authenticated for all API access.

**Strategy:** JWT tokens with expiry.

```ruby
# Token expiry: 24 hours
JWT.encode(
  { user_id: user.id, exp: 24.hours.from_now.to_i },
  Rails.application.secret_key_base
)
```

**Consequences:**

- Logout requires token blacklist (Redis)
- Short expiry = better security, more reauth
- Long expiry = worse security, better UX

---

### 2. Authorization

**Constraint:** Users can only access their authorized resources.

**Rules:**

| Action | Requirement |
|--------|-------------|
| **Create task** | Authenticated user |
| **Update task** | Creator or admin |
| **Assign task** | Manager or admin |
| **Delete task** | Admin only |

**Enforcement:**

```ruby
class TaskPolicy
  def update?
    user.admin? || record.creator_id == user.id
  end
  
  def assign?
    user.role.in?(['manager', 'admin'])
  end
end
```

---

### 3. Input Validation

**Constraint:** Never trust user input.

**Validations:**

```ruby
# Strong parameters
def task_params
  params.require(:task).permit(:title, :description, :assignee_id)
end

# Domain validation
class Task
  def initialize(title:, description:)
    raise ArgumentError, "Title required" if title.blank?
    raise ArgumentError, "Title too short" if title.length < 3
    raise ArgumentError, "Title too long" if title.length > 200
  end
end
```

**XSS Prevention:**

```ruby
# Rails escapes by default
<%= task.title %>  # Auto-escaped

# Explicit HTML safe (use carefully)
<%= sanitize(task.description) %>
```

---

## Summary Table

| Constraint Category | Key Limitation | System's Approach |
|---------------------|---------------|-------------------|
| **Network** | Latency adds delay | Single-region, async processing |
| **Database** | Connection limits | PgBouncer, connection pooling |
| **Memory** | Finite per process | Payload limits, pagination |
| **Architecture** | Domain isolation | Clean architecture boundaries |
| **Background Jobs** | At-least-once delivery | Idempotency keys |
| **API** | Rate limits | Rack::Attack throttling |
| **Operations** | Deployment downtime | Blue-green deployments |
| **Security** | Unauthorized access | JWT + Pundit authorization |

---

## 🤝 Contributing

When proposing features, check if they violate constraints:

- "Can we support 10 MB uploads?" → ❌ Memory constraint
- "Can we have 100% uptime?" → ❌ Deployment constraint
- "Can we skip auth for convenience?" → ❌ Security constraint

---

<div align="center">

**Constraints shape design. Embrace them.**

[⬆ Back to Top](#distributed-task-system-constraints)

</div>
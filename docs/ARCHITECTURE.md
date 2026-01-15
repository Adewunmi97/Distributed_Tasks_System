# Distributed Task System Architecture

**Status:** Early Development  
**Last Updated:** January 2026  
**Author:** [@adewunmi97](https://github.com/adewunmi97)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [System Architecture](#system-architecture)
- [Module Breakdown](#module-breakdown)
- [Data Flow](#data-flow)
- [Service Architecture](#service-architecture)
- [Failure Handling](#failure-handling)
- [Future Evolution](#future-evolution)

---

## Overview

The Distributed Task & Notification System is a **production-grade event-driven architecture** built to demonstrate mastery of distributed systems concepts. The architecture is designed to be:

- **Maintainable** - Clear separation of concerns with explicit boundaries
- **Testable** - Hexagonal architecture enables testing without infrastructure
- **Scalable** - Event-driven design supports horizontal scaling
- **Resilient** - Async processing with retry strategies and failure handling
- **Evolvable** - Monolith boundaries prepare for service extraction

**Core Philosophy:** Controllers are thin HTTP adapters. Business logic lives in services. Infrastructure is replaceable. Tests provide guarantees.

---

## Design Principles

### 1. Clean Architecture (Hexagonal)

```
┌─────────────────────────────────────────────────────────┐
│              Presentation Layer (Rails)                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Controllers (HTTP/JSON)                         │  │
│  │  - No business logic                             │  │
│  │  - Parameter validation                          │  │
│  │  - Response formatting                           │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│               Application Layer (Services)               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Use Cases / Service Objects                     │  │
│  │  - TaskCreationService                           │  │
│  │  - TaskAssignmentService                         │  │
│  │  - TaskStateTransitionService                    │  │
│  │  - NotificationPublisherService                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Domain Layer (Core)                    │
│  ┌──────────┬──────────────┬──────────────────────┐    │
│  │  Task    │   User       │   Event              │    │
│  │  Domain  │   Domain     │   Domain             │    │
│  │          │              │                      │    │
│  │ - State  │ - Auth       │ - Publishing         │    │
│  │   Machine│ - Authz      │ - Queue              │    │
│  │ - Rules  │ - Roles      │ - Delivery           │    │
│  └──────────┴──────────────┴──────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│          Infrastructure Layer (Adapters)                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Repositories (ActiveRecord)                     │  │
│  │  Background Jobs (Sidekiq)                       │  │
│  │  Cache (Redis)                                   │  │
│  │  Email (ActionMailer)                            │  │
│  │  External APIs                                   │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Why Hexagonal Architecture?** Allows replacing PostgreSQL with MongoDB, swapping Sidekiq for AWS SQS, testing domain logic without Rails, and extracting services without rewriting core logic.

### 2. Domain-Driven Design (DDD)

Each module represents a **bounded context**:

- **Task Context** - Task lifecycle, state transitions, assignments
- **User Context** - Authentication, authorization, permissions
- **Event Context** - Event publishing, notification delivery, audit trail

**Ubiquitous Language:**
- Task states: `draft`, `assigned`, `in_progress`, `completed`, `cancelled`
- User roles: `admin`, `manager`, `member`
- Event types: `task.created`, `task.assigned`, `task.completed`

### 3. Dependency Inversion Principle

Dependencies point **inward** (toward domain):
- Controllers depend on Services
- Services depend on Domain Models
- Domain Models depend on nothing
- Infrastructure depends on Domain (not vice versa)

---

## System Architecture

### High-Level Overview

```
┌────────────────────────────────────────────────────────┐
│                   Client Applications                   │
│              (Web, Mobile, Third-party APIs)           │
└────────────────────────────────────────────────────────┘
                         ↓ HTTP/REST
┌────────────────────────────────────────────────────────┐
│                  Rails API Servers                      │
│  Controllers → Services → Domain → Repositories        │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│                Message Queue (Redis/Sidekiq)            │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│              Background Job Workers                     │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│            PostgreSQL + Redis (Data Layer)              │
└────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Technology | Responsibility | Key Components |
|-------|-----------|----------------|----------------|
| **Presentation** | Rails Controllers | HTTP handling, auth checks | TasksController, UsersController |
| **Application** | Service Objects | Business logic orchestration | TaskCreationService, EventPublisher |
| **Domain** | Ruby Classes | Business rules, state machines | Task, User, TaskStateMachine |
| **Infrastructure** | ActiveRecord, Sidekiq | External systems integration | TaskRepository, NotificationWorker |

---

## Module Breakdown

### Project Structure (Hexagonal Architecture)

```
app/
├── controllers/                    # Presentation Layer
│   ├── api/
│   │   └── v1/
│   │       ├── tasks_controller.rb
│   │       ├── users_controller.rb
│   │       └── auth_controller.rb
│   └── concerns/
│       ├── authenticable.rb
│       └── error_handler.rb
│
├── services/                       # Application Layer
│   ├── tasks/
│   │   ├── creation_service.rb
│   │   ├── assignment_service.rb
│   │   ├── state_transition_service.rb
│   │   └── validation_service.rb
│   ├── notifications/
│   │   ├── publisher_service.rb
│   │   ├── formatter_service.rb
│   │   └── delivery_service.rb
│   └── users/
│       ├── authentication_service.rb
│       └── authorization_service.rb
│
├── domain/                         # Domain Layer
│   ├── tasks/
│   │   ├── task.rb                # Domain model (not ActiveRecord)
│   │   ├── task_state_machine.rb
│   │   ├── assignment_rules.rb
│   │   └── task_policy.rb
│   ├── users/
│   │   ├── user.rb
│   │   ├── permission.rb
│   │   └── role.rb
│   └── events/
│       ├── event.rb
│       ├── task_event.rb
│       └── notification_event.rb
│
├── repositories/                   # Infrastructure Boundary
│   ├── task_repository.rb
│   ├── user_repository.rb
│   └── event_repository.rb
│
├── models/                         # Infrastructure (ActiveRecord)
│   ├── task_record.rb
│   ├── user_record.rb
│   └── event_record.rb
│
├── workers/                        # Infrastructure (Background Jobs)
│   ├── notification_worker.rb
│   ├── email_delivery_worker.rb
│   └── event_processor_worker.rb
│
└── adapters/                       # Infrastructure (External Systems)
    ├── email/
    │   ├── smtp_adapter.rb
    │   └── sendgrid_adapter.rb
    ├── cache/
    │   └── redis_adapter.rb
    └── queue/
        └── sidekiq_adapter.rb

spec/
├── requests/                      # Integration tests
├── services/                      # Service tests
├── domain/                        # Domain logic tests
└── workers/                       # Worker tests
```

---

## Data Flow

### Write Path (Create Task)

```
Client → POST /api/v1/tasks
    ↓
TasksController#create
    ↓
Authenticate user (JWT)
    ↓
TaskCreationService.call
    ↓
┌─────────────────────────────┐
│ 1. Validate (domain rules)  │
│ 2. Save (repository)        │
│ 3. Publish event            │
│ 4. Return result            │
└─────────────────────────────┘
    ↓
Event persisted → NotificationWorker enqueued
    ↓
[Async] Email sent
    ↓
201 Created response
```

### State Transition Path

```
POST /api/v1/tasks/123/transition { state: "in_progress" }
    ↓
Authenticate + Authorize
    ↓
TaskStateTransitionService.call
    ↓
┌──────────────────────────────────┐
│ 1. Load task                     │
│ 2. Validate transition (FSM)     │
│ 3. Update state                  │
│ 4. Publish event                 │
└──────────────────────────────────┘
    ↓
Notification sent
    ↓
200 OK response
```

---

## Service Architecture

### Phase Evolution

**Phase 1-3: Monolith**
- All modules in one Rails app
- Shared database
- Simple deployment

**Phase 5: Extracted Services**
```
Task API ──→ Redis Queue ──→ Notification Service
    ↓                              ↓
PostgreSQL                   PostgreSQL
(tasks DB)                   (events DB)
```

**Communication:**
- Async: Event publishing via Redis
- Sync: HTTP REST when needed

---

## Failure Handling

### Retry Strategies

```ruby
class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5
  
  def perform(event_id)
    deliver_notification(event_id)
  rescue RecoverableError => e
    raise e  # Sidekiq retries: 15s, 1m, 10m, 3h, 1d
  rescue UnrecoverableError => e
    ErrorTracker.notify(e)
    # Don't retry
  end
end
```

### Idempotency

```ruby
class EventRecord < ApplicationRecord
  validates :idempotency_key, uniqueness: true
end

# Usage
EventPublisher.publish(
  event_type: 'task.created',
  idempotency_key: "task:#{task.id}:created"
)
```

---

## Future Evolution

### Phase 1 → Phase 2: Add Background Jobs
- Add Sidekiq for async processing
- Extract notification logic to workers
- No changes to domain logic

### Phase 2 → Phase 3: Add Observability
- Structured logging
- Health checks
- Metrics (Prometheus)

### Phase 3 → Phase 5: Extract Services
- Split notification into separate app
- Redis as message bus
- Independent scaling

---

## 📚 References

- **Clean Architecture** by Robert C. Martin
- **Designing Data-Intensive Applications** by Martin Kleppmann
- **Ruby Science** by thoughtbot
- **Domain-Driven Design** by Eric Evans

---

<div align="center">

**Built with ❤️ by [@adewunmi97](https://github.com/adewunmi97)**

[⬆ Back to Top](#distributed-task-system-architecture)

</div>
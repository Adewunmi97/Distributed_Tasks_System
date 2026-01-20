# Distributed Tasks System

<div align="center">

![Status](https://img.shields.io/badge/status-early%20development-orange)
![Ruby Version](https://img.shields.io/badge/ruby-3.4+-red)
![Rails Version](https://img.shields.io/badge/rails-8.0+-red)
![License](https://img.shields.io/badge/license-MIT-green)
[![CI](https://github.com/adewunmi97/distributed_tasks_system/workflows/CI/badge.svg)](https://github.com/adewunmi97/distributed_tasks_system/actions)

**A Distributed System for Task Management and Asynchronous Notifications**

_Understanding distributed systems by building real infrastructure, not CRUD apps._

[Architecture](docs/ARCHITECTURE.md) • [Roadmap](docs/ROADMAP.md) • [Constraints](docs/CONSTRAINTS.md)

</div>

---

## 🎯 What is This?

This is **NOT a todo app**. This is a **distributed system** designed to teach how multiple services coordinate, communicate asynchronously, and handle real-world constraints.

A production-grade implementation demonstrating mastery of:

- **Clean Architecture** (controllers ≠ business logic, explicit boundaries)
- **Event-Driven Design** (async notifications, background processing)
- **Service-Oriented Thinking** (monolith → extracted services)
- **Database Design** (indexes, constraints, foreign keys with purpose)
- **Testing as Guarantees** (RSpec for system reliability)
- **Observability** (logs, health checks, error tracking)
- **DevOps Practices** (Docker, CI/CD, cloud deployment)

**⚠️ Core Philosophy:** Code is the smallest part of the system. Understanding architecture, trade-offs, and operational concerns separates engineers from code writers.

---

## 🚀 Status

| Component | Status | Description |
|-----------|--------|-------------|
| **Project Structure** | ✅ Complete | Clean architecture, domain boundaries |
| **API Service** | ✅ Complete | Rails API-only, explicit controllers |
| **Authentication** | ✅ Complete | Devise/custom auth, session management |
| **Authorization** | 🔄 In Progress | Pundit, role-based access control |
| **Background Jobs** | 📋 Planned | Sidekiq, Redis queue management |
| **Notification Service** | 📋 Planned | Extract as separate service |
| **Testing Suite** | 📋 Planned | RSpec unit & request specs |
| **Docker Setup** | 📋 Planned | Multi-container orchestration |
| **CI/CD Pipeline** | 📋 Planned | GitHub Actions, automated testing |
| **Cloud Deployment** | 📋 Planned | Production environment, secrets management |

**Current Milestone:** Building API service with clean architecture foundations

---

## 🏗️ Architecture

This system follows **Clean Architecture** principles with explicit separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    HTTP API Layer                        │
│           (Routes, Controllers, Middleware)              │
└─────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────┐
│                  Application Layer (Rails)               │
│              Use Cases • Service Objects                 │
│            (Business Logic Lives Here)                   │
└─────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────┬──────────────────┬──────────────────┐
│  Task Domain     │   User Domain    │   Event Domain   │
│                  │                  │                  │
│  - Task State    │  - Authentication│  - Notification  │
│    Machine       │  - Authorization │    Queue         │
│  - Assignment    │  - Permissions   │  - Event         │
│    Logic         │                  │    Publishing    │
│  - Validation    │                  │                  │
└──────────────────┴──────────────────┴──────────────────┘
                              ↓
┌──────────────────┬──────────────────┬──────────────────┐
│  Repository      │  Repository      │  Repository      │
│  Interfaces      │  Interfaces      │  Interfaces      │
│  (ActiveRecord)  │  (ActiveRecord)  │  (ActiveRecord)  │
└──────────────────┴──────────────────┴──────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────┐
│           Infrastructure Layer (Adapters)                │
│    PostgreSQL • Redis • Sidekiq • External APIs          │
└─────────────────────────────────────────────────────────┘
```

### Architecture Principles (Non-Negotiable)

1. **Controllers contain NO business logic** - Only handle HTTP concerns
2. **Business rules live in domain/use cases** - Explicit service objects
3. **Infrastructure details are replaceable** - Database, queue, etc.
4. **Dependencies point inward** - Domain knows nothing about Rails
5. **Tests provide guarantees** - Not chores, but system contracts

For detailed architecture, see [`docs/architecture.md`](docs/ARCHITECTURE.md).

---

## 🎓 What You'll Learn

Building this system teaches real distributed systems concepts used at companies like Stripe, Shopify, and GitHub:

<details>
<summary><b>Clean Architecture & Separation of Concerns</b></summary>

- Controllers vs Services vs Domain Logic
- Dependency Inversion Principle
- Hexagonal Architecture (Ports & Adapters)
- Single Responsibility Principle in practice
- Testable business logic without Rails

</details>

<details>
<summary><b>Event-Driven Architecture</b></summary>

- Asynchronous task processing
- Event publishing and subscription
- Message queues (Redis, Sidekiq)
- Decoupling services through events
- Idempotency and retry strategies

</details>

<details>
<summary><b>Database Design Fundamentals</b></summary>

- Schema design with purpose (no mindless migrations)
- Indexes: when, where, and why
- Foreign keys and referential integrity
- Database constraints as business rules
- Query optimization and N+1 prevention

</details>

<details>
<summary><b>Service-Oriented Thinking</b></summary>

- Monolith boundaries (preparing for extraction)
- Inter-service communication (HTTP, message queues)
- Service contracts and APIs
- Data ownership and bounded contexts
- When to split vs when to stay monolithic

</details>

<details>
<summary><b>Testing as System Guarantees</b></summary>

- Unit tests for domain logic
- Request specs for API contracts
- Testing business rules in isolation
- Test-Driven Development (TDD) workflow
- Mocking external dependencies

</details>

<details>
<summary><b>DevOps & Production Operations</b></summary>

- Docker containerization (multi-container apps)
- CI/CD pipelines (GitHub Actions)
- Environment variable management
- Secrets handling in production
- Application logging and observability
- Health check endpoints

</details>

---

## 📍 Roadmap

### **Phase 1: Monolithic Foundation** (Current)

- [x] Project initialization (Rails API-only)
- [ ] Database schema design (Users, Tasks, Events)
- [ ] User authentication (Devise/custom)
- [ ] Authorization layer (Pundit)
- [ ] Task CRUD with business logic in services
- [ ] Task state machine (draft → assigned → in_progress → completed)
- [ ] Basic RSpec test suite

**Goal:** Solid monolith with clear domain boundaries

### **Phase 2: Asynchronous Processing**

- [ ] Sidekiq setup with Redis
- [ ] Background job for notifications
- [ ] Event publishing system
- [ ] Email notifications (ActionMailer)
- [ ] Job retry and failure handling
- [ ] Request specs for async behavior

**Goal:** Event-driven architecture within monolith

### **Phase 3: Observability & Operations**

- [ ] Structured logging (JSON logs)
- [ ] Health check endpoints (`/health`, `/ready`)
- [ ] Error tracking setup
- [ ] Application metrics
- [ ] Docker multi-container setup
- [ ] Docker Compose orchestration

**Goal:** Production-ready observability

### **Phase 4: CI/CD & Deployment**

- [ ] GitHub Actions CI pipeline
- [ ] Automated RSpec runs on PR
- [ ] Fail builds on test failure
- [ ] Cloud deployment (Heroku/AWS/Railway)
- [ ] Environment configuration management
- [ ] Secrets management

**Goal:** Automated deployment pipeline

### **Phase 5: Service Extraction** (Future)

- [ ] Identify notification service boundaries
- [ ] Extract notification service (separate Rails API)
- [ ] HTTP communication between services
- [ ] Message queue communication (Redis Pub/Sub)
- [ ] Service contract testing
- [ ] Distributed tracing basics

**Goal:** True distributed system with multiple services

For detailed milestones, see [`docs/ROADMAP.md`](docs/roadmap.md).

---

## 🛠️ Tech Stack

| Layer | Technology | Why |
|-------|------------|-----|
| **Backend** | Ruby on Rails 8.0+ (API-only) | Battle-tested, excellent ecosystem |
| **Database** | PostgreSQL 14+ | ACID guarantees, JSON support, reliability |
| **Cache/Queue** | Redis 7+ | In-memory performance, Sidekiq backend |
| **Background Jobs** | Sidekiq | Industry standard, Redis-backed |
| **Authentication** | Devise / Custom | Token-based auth for APIs |
| **Authorization** | Pundit | Policy-based authorization |
| **Testing** | RSpec | Expressive, comprehensive testing |
| **Containerization** | Docker + Docker Compose | Local dev parity with production |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Cloud** | Heroku / AWS / Railway | Real-world deployment constraints |

---

## 🚦 Quick Start

### Prerequisites

- Ruby 3.4+
- Rails 8.0+
- PostgreSQL 14+
- Redis 7+
- Docker & Docker Compose (recommended)

### Run Locally

```bash
# Clone the repository
git clone https://github.com/adewunmi97/distributed_tasks_system.git
cd distributed_tasks_system

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run with Docker Compose (recommended)
docker-compose up

# Or run manually
bundle install
rails db:create db:migrate db:seed
redis-server &
bundle exec sidekiq &
rails server
```

### Verify It's Working

```bash
# Health check
curl http://localhost:3000/health

# Create a user (example)
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'

# Create a task
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "task": {
      "title": "Deploy to production",
      "description": "Final deployment checks",
      "assigned_to": 2
    }
  }'
```

---

## 📖 Documentation

- **[Architecture Overview](docs/ARCHITECTURE.md)** - Deep dive into system design, trade-offs
- **[ROADMAP](docs/ROADMAP.md)** - Complete API documentation
- **[CONSTRAINTS](docs/CONSTRAINTS.md)** - Step-by-step installation and configuration

---

## 🧪 Testing

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/task_creation_service_spec.rb

# Run request specs only
bundle exec rspec spec/requests

# Run with documentation format
bundle exec rspec --format documentation
```

### Testing Strategy

- **Unit Tests** - Domain logic, service objects, business rules
- **Request Specs** - API endpoints, authentication, authorization
- **Integration Tests** - Background jobs, database interactions
- **Contract Tests** - Service boundaries (Phase 5)

**Remember:** Tests are system guarantees, not chores.

---

## 🗄️ Database Schema

### Core Tables

**users**
- `id` (PK)
- `email` (unique, indexed)
- `name` (text)
- `encrypted_password`
- `role` (enum: admin, manager, member)
- `created_at`, `updated_at`

**tasks**
- `id` (PK)
- `title` (not null)
- `description` (text)
- `state` (enum: draft, assigned, in_progress, completed, cancelled)
- `creator_id` (FK → users, indexed)
- `assignee_id` (FK → users, indexed)
- `created_at`, `updated_at`

**events**
- `id` (PK)
- `event_type` (string, indexed)
- `payload` (jsonb)
- `processed_at` (timestamp, indexed)
- `created_at`

### Design Principles

- Every foreign key has an index (query performance)
- Enums enforce valid states (database constraints)
- JSONB for flexible event payloads
- Timestamps for audit trails

---

## 📊 Core Features

### API Endpoints

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/v1/auth/login` | POST | User authentication | No |
| `/api/v1/auth/logout` | DELETE | User logout | Yes |
| `/api/v1/tasks` | GET | List all tasks | Yes |
| `/api/v1/tasks/:id` | GET | Get task details | Yes |
| `/api/v1/tasks` | POST | Create new task | Yes |
| `/api/v1/tasks/:id` | PATCH | Update task | Yes (owner/admin) |
| `/api/v1/tasks/:id/assign` | POST | Assign task to user | Yes (manager+) |
| `/api/v1/tasks/:id/transition` | POST | Change task state | Yes (assignee) |
| `/api/v1/users` | GET | List users | Yes (admin) |
| `/health` | GET | Health check | No |

### Task State Machine

```
draft → assigned → in_progress → completed
  ↓         ↓           ↓
cancelled ← cancelled ← cancelled
```

**Business Rules:**
- Only managers can assign tasks
- Only assignees can transition tasks
- State transitions are logged as events
- Notifications sent on state changes

---

## 🌟 Why This Exists

> "Most 'portfolio projects' are CRUD apps with scaffolding. This is different. This proves you understand how real systems work: asynchronous processing, clean architecture, service boundaries, and operational concerns. This is what separates junior engineers from those ready for production systems."

**What This Project Demonstrates:**

- **Architectural Thinking** - Separation of concerns, not everything in controllers
- **Distributed Systems Concepts** - Events, async processing, service extraction
- **Database Fundamentals** - Schema design, indexes, constraints with purpose
- **Testing Discipline** - Tests as guarantees, not afterthoughts
- **Operational Maturity** - Logging, health checks, deployment pipelines
- **Growth Mindset** - Progression from monolith to distributed system

**"I don't just build CRUD apps. I architect systems."**

---

## 🎯 Who This Is For

- **Junior engineers ready to level up** - Understand production systems
- **Backend engineers** - See clean architecture in practice
- **Students** - Bridge theory with real implementation
- **Hiring managers** - This demonstrates architectural maturity

---

## 🧠 The One Rule (Repeated Constantly)

> **Code is the smallest part of the system.**

If you understand this, you will grow fast. This means:

- Architecture matters more than syntax
- Trade-offs matter more than features
- Observability matters more than code cleverness
- Documentation matters more than clever abstractions

---

## 📈 Success Metrics

By the end of this project, you should be able to answer:

- ✅ Why is business logic in services, not controllers?
- ✅ How do you handle async notifications without blocking requests?
- ✅ Why does this table have this index?
- ✅ How do you test state transitions without hitting the database?
- ✅ What happens when the notification service fails?
- ✅ How do you deploy this to production safely?
- ✅ What logs would you check when debugging a failure?

If you can answer these, you understand systems, not just code.

---

## 👤 Author

**[@adewunmi97](https://github.com/adewunmi97)** • Building distributed systems with architectural discipline

💼 **Open to opportunities** at companies building serious backend infrastructure where clean architecture and distributed systems thinking matter.

📧 **Contact:** ashonibare63@gmail.com  
🐦 **Twitter:** [@adewunmi_97](https://twitter.com/adewunmi_97)  
💼 **LinkedIn:** [Adewunmi Adebisi](https://linkedin.com/in/adewunmi-adebisi)

---

## ⚠️ Important Notes

### What This Is NOT

- ❌ A tutorial to copy-paste
- ❌ A quick portfolio filler
- ❌ A showcase of every gem in existence
- ❌ A project where I fix bugs for you

### What This IS

- ✅ A learning journey through distributed systems
- ✅ An architectural exercise with real constraints
- ✅ A demonstration of engineering maturity
- ✅ A project where you debug, research, and grow

**Remember:** I don't fix bugs for you. I'll work you through it. That's how you learn.

---

## 📚 Recommended Reading

- **Clean Architecture** by Robert C. Martin
- **Designing Data-Intensive Applications** by Martin Kleppmann
- **Ruby Science** by thoughtbot
- **Database Internals** by Alex Petrov
- **Site Reliability Engineering** by Google

---

## 📜 License

Licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Building Systems, Building Engineers - One Service at a Time**

_"Whatever you do, work at it with all your heart, as working for the Lord." - Colossians 3:23_

[⬆ Back to Top](#distributed-tasks-system)

</div>

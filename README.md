# Reading Sanctuary

Reading Sanctuary is an all-in-one digital sanctuary for book lovers, offering e-reading, audiobooks, personal annotations, and journaling.

## Project Structure

```
reading-sanctuary/
│
├── frontend/
│   └── reading_sanctuary_app/       # Flutter application
│       ├── lib/
│       │   ├── core/
│       │   ├── data/
│       │   ├── models/
│       │   ├── services/
│       │   ├── features/
│       │   │   ├── authentication/
│       │   │   ├── library/
│       │   │   ├── bookshelf/
│       │   │   ├── reader/
│       │   │   ├── audiobook/
│       │   │   ├── annotations/
│       │   │   ├── journal/
│       │   │   └── profile/
│       │   └── main.dart
│       └── test/
│
├── backend/
│   └── reading-sanctuary-api/       # Backend API service
│       └── src/
│
├── database/
│   ├── migrations/                  # Schema migrations
│   ├── diagrams/                    # ERDs and architecture diagrams
│   ├── seeds/                       # Development & test seeds
│   └── documentation/               # Schema documentation
│
├── infrastructure/
│   ├── docker/                      # Dockerfiles & compose configurations
│   └── deployment/                  # CI/CD and deployment scripts
│
├── docs/
│   ├── PRD.md                       # Product Requirements Document
│   ├── DATABASE_DESIGN.md           # Database Architecture
│   └── API_SPECIFICATION.md         # API Endpoints & Contracts
│
├── .gitignore
└── README.md
```

## Documentation
- [PRD](docs/PRD.md)
- [Database Design](docs/DATABASE_DESIGN.md)
- [API Specification](docs/API_SPECIFICATION.md)

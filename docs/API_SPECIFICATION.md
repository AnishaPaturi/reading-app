# API Specification

## Overview
Specification for the Reading Sanctuary Backend REST/GraphQL API (`reading-sanctuary-api`).

## Base URL
- Development: `http://localhost:8080/api/v1`
- Production: `https://api.readingsanctuary.app/api/v1`

## Authentication
JWT Bearer Token header:
`Authorization: Bearer <token>`

## Endpoints

### Authentication
- `POST /auth/register` - Create a new user account
- `POST /auth/login` - Authenticate user and issue JWT
- `POST /auth/refresh` - Refresh access token

### Library & Books
- `GET /books` - Search and list available books
- `GET /books/:id` - Fetch details of a specific book
- `GET /user/bookshelf` - Retrieve current user's bookshelf
- `POST /user/bookshelf` - Add a book to a user shelf
- `PATCH /user/bookshelf/:id` - Update reading status or progress

### Annotations & Journal
- `GET /books/:id/annotations` - List highlights and notes for a book
- `POST /books/:id/annotations` - Create a new annotation
- `GET /journal` - List journal entries
- `POST /journal` - Create a new journal entry

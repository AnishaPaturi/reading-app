# Database Design

## Overview
This document outlines the entity relationships, schema architecture, and data models for Reading Sanctuary.

## Core Entities
- **Users:** Account credentials, preferences, settings.
- **Books / Media:** Metadata, cover images, authors, ISBN/ASIN, file references.
- **UserBooks / Shelves:** User-book relation, shelf designation, reading progress, dates.
- **Annotations:** Highlights, page references, text content, color tags.
- **Journal Entries:** Reading reflections, ratings, timestamps.
- **Audiobook Tracks:** Audio file references, durations, chapter markers.

## Schemas & Migrations
- Migration files are located in `/database/migrations/`.
- Seed scripts are in `/database/seeds/`.
- Visual ER diagrams and schema models are maintained in `/database/diagrams/`.

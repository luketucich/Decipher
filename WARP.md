# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Decipher is a daily guessing game where players guess topics based on progressively revealing hints. It consists of:
- **Backend**: Express.js API server (TypeScript)
- **Frontend**: React + Vite single-page application (TypeScript)
- **Database**: PostgreSQL with Prisma ORM

## Development Commands

### Backend (Express API)
```bash
# Development server with hot reload
npm run dev

# Build TypeScript to JavaScript
npm run build

# Production (runs migrations then starts server)
npm start

# Generate Prisma client (runs automatically on postinstall)
npm run postinstall
```

### Frontend (React + Vite)
```bash
# Development server (from src/web/)
cd src/web && npm run dev

# Build for production (from src/web/)
cd src/web && npm run build

# Lint check (from src/web/)
cd src/web && npm run lint

# Preview production build (from src/web/)
cd src/web && npm run preview
```

### Database (Prisma)
```bash
# Run migrations
npx prisma migrate dev

# Deploy migrations (production)
npx prisma migrate deploy

# Generate Prisma client
npx prisma generate

# Open Prisma Studio (database GUI)
npx prisma studio
```

### Admin Scripts
```bash
# Generate N new topics using AI (requires ADMIN_TOKEN and XAI_API_KEY)
npm run topic <number>

# Example game simulation
npm run play
```

## Architecture

### Backend Structure

The backend follows a repository-controller-route pattern:

- **Routes** (`src/server/routes/`): Define API endpoints
  - `playRoutes.ts`: Public gameplay endpoints (`/play/*`)
  - `adminRoutes.ts`: Admin-only endpoints (`/admin/*`)

- **Controllers** (`src/server/controllers/`): Handle request/response logic
  - `playController.ts`: Daily topic fetching, guess submission, stats, content moderation
  - `adminController.ts`: Topic creation (admin-only)

- **Repositories** (`src/server/repositories/`): Database access layer
  - `topicRepository.ts`: Topic CRUD operations
  - `submissionRepository.ts`: Game submission tracking and statistics

- **Middleware** (`src/server/middleware/`): Request processing
  - `adminAuth.ts`: Validates `ADMIN_TOKEN` from headers
  - `errorHandler.ts`: Global error handling

- **Utils** (`src/server/utils/`):
  - `guessMatcher.ts`: Fuzzy string matching (45% Levenshtein distance threshold)
  - `contentModeration.ts`: OpenAI Moderation API integration

### Frontend Structure

The frontend is a React SPA with client-side routing:

- **Pages** (`src/web/src/pages/`):
  - `Home.tsx`: Landing page with game introduction
  - `Play.tsx`: Main game interface with hint progression

- **Components** (`src/web/src/components/`):
  - `GameResultsModal.tsx`: End-game results and statistics
  - `HowToPlayModal.tsx`: Instructions modal
  - `SettingsModal.tsx`: User preferences
  - `MatrixRain.tsx`: Animated background effect
  - `ui/`: Reusable UI components (Button, Dialog)

- **Services** (`src/web/src/services/`):
  - `api.ts`: API client for backend communication

- **Utils** (`src/web/src/utils/`):
  - `guessMatcher.ts`: Client-side fuzzy matching (mirrors backend)
  - `gameState.ts`: LocalStorage persistence for game progress
  - `theme.ts`: Theme management

### Database Schema

**Topic**: Daily puzzle with answer and type
- Has many **Hint** (ordered 1-5, with types: Category, Emoji, Quote, Trivia, Definition)
- Has many **Submission** (player attempts)

**Submission**: Records player game completions
- Tracks attempts, guesses array, duration, and success status

### Key Game Logic

1. **Hint Progression**: Players unlock hints sequentially after incorrect guesses (max 5 attempts)
2. **Fuzzy Matching**: Accepts typos/variations using Levenshtein distance (45% threshold)
3. **Content Moderation**: Guesses are checked via OpenAI Moderation API before processing
4. **Daily Topics**: Generated using Grok AI with themed days (Mon=Movie, Tue=Book, etc.)
5. **Game State**: Persisted in LocalStorage, allowing resume after page refresh

### Environment Variables

Required for development:
- `PORT`: API server port (default: 3000)
- `DATABASE_URL`: PostgreSQL connection string
- `DIRECT_URL`: Direct PostgreSQL connection (for migrations)
- `ADMIN_TOKEN`: Secret token for admin API endpoints
- `XAI_API_KEY`: X.AI/Grok API key for topic generation
- `OPENAI_API_KEY`: OpenAI API key for content moderation
- `CORS_ORIGINS`: Comma-separated allowed origins (optional)

## Development Workflow

1. **Adding API Endpoints**: Create controller function → Add route → Update API client in frontend
2. **Database Changes**: Modify `prisma/schema.prisma` → Run `npx prisma migrate dev` → Update repository methods
3. **New Features**: Implement backend logic first → Update frontend API client → Build UI components
4. **Topic Generation**: Use `npm run topic <N>` to generate topics; requires server to be running at `API_BASE_URL`

## Technology Stack

- **Backend**: Node.js 18+, Express 5, TypeScript 5.9, Prisma 6
- **Frontend**: React 19, Vite 7, TypeScript 5.9, Tailwind CSS 4, ESLint 9
- **Database**: PostgreSQL
- **AI**: Grok-4 (topic generation), OpenAI Moderation API
- **Security**: Helmet, CORS, rate limiting, compression

## Code Patterns

- **Strict TypeScript**: Enabled strict mode with `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`
- **ES Modules**: All code uses ESM (`"type": "module"` in package.json)
- **Error Handling**: Async errors caught in controllers, passed to centralized error handler
- **Normalization**: Text matching removes articles (the/a/an), punctuation, and is case-insensitive
- **Repository Pattern**: Database access isolated from business logic
- **Graceful Shutdown**: Server handles SIGINT/SIGTERM with Prisma cleanup

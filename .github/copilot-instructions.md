# GitHub Copilot Project Instructions

## 🏗️ Architecture Overview

**PacePilot** is a full-stack running training plan generator with a rules-based engine core:

- **Frontend**: React 19 + TypeScript + Vite (MUI components, Zustand state)
- **Backend**: Node.js + Express 5 + TypeScript ESM modules
- **Rules Engine**: json-rules-engine for all business logic (NOT imperative code)
- **Data Layer**: MongoDB (Azure Cosmos DB) + file-based token storage
- **Auth**: Microsoft Entra ID + Intervals.icu OAuth
- **Deployment**: Azure Container Apps with GitHub Actions CI/CD

### Critical Architecture Decisions

1. **Rules Engine First**: ALL training logic in `backend/engine/core/*-rules.ts` uses json-rules-engine, not if/else statements. See [backend/engine/ADDING_NEW_RULES_JSON.md](../backend/engine/ADDING_NEW_RULES_JSON.md)
2. **TypeScript ESM**: Backend uses `"type": "module"` - all imports need `.js` extensions even for `.ts` files
3. **Shared Types**: `shared/types.ts` is single source of truth for types used across frontend/backend
4. **Schema Architecture**: See [backend/docs/SCHEMA_ARCHITECTURE.md](../backend/docs/SCHEMA_ARCHITECTURE.md) - validation in `middleware/validation.ts`, types inferred from Zod schemas

## 🔧 Essential Developer Commands

### Backend Development

```powershell
cd backend
npm run dev              # Hot reload with tsx
npm run build            # TypeScript compilation
npm test                 # Run Jest unit tests
npm run test:coverage    # Coverage reports
npm run type-check       # TypeScript validation only
```

### Frontend Development

```powershell
cd frontend
npm run dev              # Vite dev server on :5173
npm run build            # Production build
npm run preview          # Preview production build
npm test                 # Playwright tests
```

### Full Stack

```powershell
npm run dev              # Runs both frontend + backend with concurrently
npm run build:all        # Builds both projects
npm run typecheck        # Type checks both projects
```

### Critical Files to Check Before Changes

- `shared/types.ts` - All shared interfaces
- `backend/engine/core/*-rules.ts` - Rules engine logic
- `backend/middleware/asyncHandler.ts` - Use this for all route handlers
- `backend/utils/logger.ts` - Structured logging (don't use console.log)
- `backend/config/env.ts` - Environment validation (Zod)

## 📋 Code Patterns & Conventions

### Backend: Rules Engine Pattern (MANDATORY)

**❌ NEVER write imperative logic for training decisions:**

```typescript
// DON'T DO THIS
if (userProfile.fatigueLevel === "high") {
  workout = createEasyRun();
} else if (weekType === "Threshold") {
  workout = createThresholdWorkout();
}
```

**✅ ALWAYS use json-rules-engine:**

```typescript
// DO THIS - see backend/engine/core/daily-workout-rules.ts
const rule = new Rule({
  conditions: {
    all: [{ fact: "needsRecovery", operator: "equal", value: true }],
  },
  event: { type: "assign-recovery-base-run" },
  priority: 80, // Higher = evaluated first
});

engine.addRule(rule);
engine.addFact("needsRecovery", () => context.HRV < 40 || context.ATL > 80);
```

**Key Files:**

- `backend/engine/core/training-week-rules.ts` - Weekly progression (Tempo → Threshold → VO2max → Deload)
- `backend/engine/core/daily-workout-rules.ts` - Daily workout assignment with fatigue awareness
- `backend/engine/ADDING_NEW_RULES_JSON.md` - Complete guide with examples

### Backend: Route Handler Pattern

**Always use asyncHandler** to eliminate try-catch boilerplate:

```typescript
import { asyncHandler } from "../middleware/asyncHandler";

router.post(
  "/api/endpoint",
  asyncHandler(async (req, res) => {
    const data = await someAsyncOperation();
    res.json({ success: true, data });
    // No try-catch needed - asyncHandler handles it
  })
);
```

### Backend: Logging Pattern

**Use structured logger** with OpenTelemetry correlation:

```typescript
import { logger } from "../utils/logger";

// ❌ DON'T: console.log('Error:', error)
// ✅ DO:
logger.info("User created", { userId: user.id });
logger.error("Database operation failed", error, { operation: "insert", collection: "users" });
logger.http(req.method, req.path, res.statusCode, duration); // For HTTP requests
logger.database("query", "users", duration, { query: "find" }); // For DB operations
```

### TypeScript: Shared Types Pattern

**CRITICAL**: Always import from `shared/types.ts` for cross-boundary types:

```typescript
// ✅ DO: Import shared types
import type { WorkoutCategoryType, UserProfile, TrainingPlan } from '../../../shared/types';

// ❌ DON'T: Duplicate type definitions
type UserProfile = { ... }  // This creates divergence!
```

### Frontend: Modal Styling Convention

**All modals MUST have backdrop blur** (design system requirement):

```typescript
<Dialog
  open={isOpen}
  onClose={onClose}
  slotProps={{
    backdrop: {
      sx: {
        backdropFilter: 'blur(8px)',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
      },
    },
  }}
>
```

### Environment Validation

Environment variables are **validated at startup** via `backend/config/env.ts`:

```typescript
import { validateEnv, getEnv, hasIntervalsConfig } from "./config/env";

// At app startup (in index.ts):
validateEnv(); // Throws if invalid - fail fast!
const env = getEnv(); // Type-safe access

// Check optional features:
if (hasIntervalsConfig(env)) {
  // Setup Intervals.icu integration
}
```

## 🧪 Testing Patterns

### Unit Tests (Jest)

- Test files: `backend/tests/*.test.ts`
- Example: [backend/tests/calculate-zones.test.ts](../backend/tests/calculate-zones.test.ts)
- Run: `npm test` (backend) or `npm run test:coverage`
- Focus: Engine logic, utilities, calculations

### Integration Tests (Playwright)

- Test files: `frontend/tests/*.spec.ts`
- Run: `npm test` (frontend) or `npm run test:headed`
- Focus: User flows, API integration, UI interactions

### Test Coverage Priorities

1. Training rules engine (`engine/core/*-rules.ts`)
2. Zone calculations (`engine/calculate_zones.ts`)
3. Date utilities (`engine/core/date-utils.ts`)
4. Volume calculations (`engine/core/volume-calculator.ts`)

## 🚀 Deployment & CI/CD

### Automated Deployment

- **Trigger**: Push to `main` branch
- **Pipeline**: `.github/workflows/deploy.yml`
- **Platform**: Azure Container Apps (free tier)
- **Infrastructure**: Bicep templates in `infra/bicep/`

### Local Docker Testing

```powershell
.\infra\scripts\local-dev.ps1 -Mode run  # Full Docker stack
```

### Environment Files

- `backend/.env.example` - Backend configuration template
- `frontend/.env.example` - Frontend configuration template
- `infra/.env.example` - Deployment secrets template

**See [infra/DEPLOYMENT.md](../infra/DEPLOYMENT.md) for complete deployment guide**

## 🔐 Security & Best Practices

### Implemented Security Measures

- **Helmet**: Security headers (configured in `backend/index.ts`)
- **Rate Limiting**: 100 req/15min per IP on `/api/*`
- **CORS**: Configured in `backend/middleware/cors.ts`
- **Environment Validation**: Zod schemas validate all env vars at startup
- **Authentication**: Entra ID tokens validated via `backend/middleware/entraAuth.ts`

### Data Storage

- **User Profiles**: MongoDB collection `user_profiles`
- **Training Plans**: MongoDB collection `training_plans`
- **OAuth Tokens**: File-based in `backend/data/tokens.json` (excluded from git)
- **Favorite Routes**: MongoDB collection `favorite_routes`

**See [backend/docs/SCHEMA_ARCHITECTURE.md](../backend/docs/SCHEMA_ARCHITECTURE.md) for data models**

## 📦 Key Dependencies to Know

### Backend Critical Deps

- **json-rules-engine** (^7.3.1) - Business logic engine
- **express** (^5.1.0) - Web framework
- **mongodb** (^6.11.0) - Database client
- **zod** (^3.x) - Runtime validation
- **@opentelemetry/\*** - Distributed tracing
- **helmet** (^7.x) - Security headers
- **express-rate-limit** (^7.x) - Rate limiting

### Frontend Critical Deps

- **react** (^19.2.0) + **react-dom**
- **@mui/material** (^7.3.4) - UI components
- **zustand** - State management
- **axios** (^1.6.2) - HTTP client
- **leaflet** (^1.9.4) - Map rendering
- **chart.js** (^4.5.1) - Data visualization

## 🎯 Component Creation Guidelines

### When to Create Components

- UI element will be reused across multiple features
- Component exceeds 100 lines
- Has 3+ state variables (complex logic)
- Needs specific interaction patterns

### When to Keep Inline

- Used only once and <50 lines
- Too granular (single styled button)
- Breaking up only for file size (keep cohesive)
  - API endpoints
- Use meaningful test descriptions
- Test error cases
- Mock external dependencies

## Documentation Requirements

- Include JSDoc comments for functions
- Keep README.md updated
- Document environment variables
- Add inline comments for non-obvious code

## Performance Considerations

- Implement lazy loading for large components
- Optimize images and assets
- Use proper caching strategies
- Monitor bundle size
- Implement proper error handling

---

_These instructions guide GitHub Copilot to maintain code quality and consistency across the project. Update them as the project evolves._

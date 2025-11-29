# GitHub Copilot Project Instructions

## Project Structure

```
src/
├── components/     # React components
│   ├── ui/        # Shared UI components
│   └── features/  # Feature-specific components
├── types/         # TypeScript types and interfaces
├── Store/         # State management
├── assets/        # Static assets (images, fonts)
└── styles/        # Global styles and theme configurations

server/
│   └── src/           # Service source code
    └── api/           # API endpoints
```

## Code Organization Guidelines

### Component Creation

- Create new components when:

  - UI element will be reused
  - Code exceeds 100 lines
  - Logic becomes complex (3+ state variables)
  - Component has specific interaction patterns

- Avoid components when:
  - Used only once and simple (<50 lines)
  - Too granular (e.g., single styled button)
  - Breaking up code only for file size

### TypeScript Types and Interfaces

**IMPORTANT**: Always use shared types from `shared/types.ts` for data structures used across frontend and backend.

- **Export common types to shared/types.ts when:**

  - Type is used in both frontend and backend
  - Type represents domain concepts (e.g., `WorkoutCategoryType`, `DayOfWeek`)
  - Type appears in multiple files (DRY principle)
  - Type is part of API contracts between client and server

- **Keep types local when:**

  - Only used within a single file
  - Component-specific props or state
  - Internal implementation details

- **Best Practices:**

  ```typescript
  // ✅ DO: Import from shared types
  import type { WorkoutCategoryType, DayOfWeek, UserProfile } from "../../../shared/types";

  // ❌ DON'T: Duplicate type definitions
  type WorkoutCategoryType = "Tempo" | "Threshold" | "VO2max" | "Base" | "Benchmark";
  ```

- **Benefits:**
  - Single source of truth for domain types
  - Type safety across frontend and backend
  - Easier refactoring and maintenance
  - Consistent API contracts

### State Management

- Use Zustand store for:
  - Global application state
  - Shared data between components
  - Complex state logic
- Keep local state in components when:
  - State is only used in one component
  - No child components need the data

## Backend (Node.js) Guidelines

- Keep functions under 20 lines
- Use Express.js for API endpoints
- Implement proper error handling
  ```typescript
  try {
    // Main logic
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Error:`, error);
    res.status(500).json({ error: "Internal server error" });
  }
  ```
- Use environment variables for configuration
- Validate input with middleware
- Use async/await for asynchronous operations
- Write meaningful log messages

### Business Logic with json-rules-engine

**IMPORTANT**: All business logic and workflow rules should be implemented using **json-rules-engine**, not as imperative code.

- **Rule Structure:**

  ```typescript
  const myRule = new Rule({
    conditions: {
      all: [
        {
          fact: "needsRecovery",
          operator: "equal",
          value: true,
        },
      ],
    },
    event: {
      type: "assign-recovery-run",
    },
    priority: 70, // Higher priority rules evaluated first
  });

  engine.addRule(myRule);

  // Add custom facts for derived data
  engine.addFact("needsRecovery", () => {
    return context.HRV < 40 || context.ATL > 80;
  });

  // Handle events
  engine.on("success", (event) => {
    if (event.type === "assign-recovery-run") {
      // Update context based on rule firing
    }
  });
  ```

- **Best Practices:**

  - Keep rule conditions pure and declarative
  - Use custom facts for complex logic
  - Assign priorities appropriately (100+ for critical rules)
  - Handle all events in event listeners
  - Use descriptive event type names (e.g., `assign-recovery-base-run`)
  - See `backend/engine/ADDING_NEW_RULES_JSON.md` for detailed patterns

- **Examples in Codebase:**
  - `backend/engine/core/training-week-rules.ts` - Weekly progression
  - `backend/engine/core/daily-workout-rules.ts` - Daily workout assignment
  - Recovery adjustments, fatigue handling, deload weeks all use json-rules-engine

## Frontend (React + TypeScript) Guidelines

- Use functional components with hooks
- Keep components focused and simple
- Type everything properly:

  ```typescript
  interface Props {
    data: SomeType;
    onAction: (id: string) => void;
  }

  const Component: React.FC<Props> = ({ data, onAction }) => {
    // Component logic
  };
  ```

- Use Material-UI components consistently
- Implement proper error boundaries
- Follow React's best practices for performance
- **Modal Styling**: When creating modals/dialogs, always add backdrop blur effect:
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

## Build and Development

- Development: `npm run dev`
- Production: `npm run build`
- Linting: `npm run lint`
- Configure Vite for optimal performance

## Testing Guidelines

- Write unit tests for:
  - Utility functions
  - React components
  - API endpoints
- Use meaningful test descriptions
- Test error cases
- Mock external dependencies
- Use playwright for end-to-end tests

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

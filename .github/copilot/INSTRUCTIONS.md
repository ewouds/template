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
├── logbookAnalyzer/    # Logbook analysis service
│   └── src/           # Service source code
└── runwayAPI/         # Runway information service
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

## Documentation Requirements

- Include JSDoc comments for functions
- Document complex logic
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

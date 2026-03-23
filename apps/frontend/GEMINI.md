# GEMINI.md — Frontend Refactor Mandates (Prismatica)

This document serves as the foundational authority for the frontend refactor. All code changes, architectural decisions, and new implementations MUST strictly adhere to these mandates.

## 1. Core Architecture: FSD + Atomic Design Fusion
We use **Feature-Sliced Design (FSD)** for business logic organization and **Atomic Design** for UI component complexity.

- **FSD Layers (Strict Hierarchy):** `app` > `pages` > `widgets` > `features` > `entities` > `shared`.
- **Dependency Rule:** A module can ONLY import from layers strictly below it. Circular dependencies are forbidden.
- **Atomic Mapping:**
    - `shared/ui/atoms` & `shared/ui/molecules`: 100% generic UI.
    - `entities/*/ui`: Domain-specific molecules (e.g., `FieldTypeTag`).
    - `features/*/ui` & `widgets/*/ui`: Organisms (e.g., `LoginForm`, `SchemaBuilder`).
    - `pages/*/ui`: Templates and final screen composition.

## 2. The Golden Rule: Public API (index.ts)
- Every slice (e.g., `features/auth`, `entities/user`) MUST have an `index.ts`.
- **Encapsulation:** Only symbols exported via `index.ts` are accessible from the outside.
- **Forbidden:** Never import from internal paths (e.g., `import { ... } from '@/features/auth/model/store'`). Use the Public API: `import { ... } from '@/features/auth'`.

## 3. Technical Standards
- **TypeScript Strict:** `strict: true` is mandatory. No `any`. Use `readonly` for API data. Prefer `interface` for objects and `type` for unions.
- **State Management:** Use **Zustand**. One store per feature slice. Components must access stores via custom hooks (e.g., `useAuth()`), never directly.
- **Styling (SCSS + CSS Modules):**
    - `_graphical-chart.scss` is the ONLY source of truth for tokens (colors, spacing, typography).
    - Use **CSS Modules** (`*.module.scss`) for component-level styles.
    - No hardcoded literal values in SCSS; use tokens from `@/styles/abstracts`.
- **Polymorphism:** Use the **Strategy Pattern** for views and adapters. Adding a new type should only require registering a new strategy in `app/App.tsx`.

## 4. Refactoring Workflow (src-temp -> src)
When moving code from `src-temp/` to the FSD structure in `src/`:
1. **Identify the Layer:** Determine if the component is generic (`shared`), domain-specific (`entities`), interactive (`features`), or a complex organism (`widgets`).
2. **Deconstruct:** Split legacy files into FSD segments: `ui/` (view), `model/` (logic/hooks/store), `api/` (services), and `index.ts` (Public API).
3. **Surgical Updates:** Ensure all imports are updated to use the absolute `@/` alias and respect layer boundaries.
4. **Validation:** Every refactored piece MUST have a corresponding test (Vitest/Testing Library) next to it before being considered "done."

## 5. Testing & TDD
- **TDD is Mandatory:** Write the test before the implementation for any logic (Red -> Green -> Refactor).
- **Test Location:** Tests must live next to the code they test (e.g., `useAuth.spec.ts` inside `features/auth/model/`).
- **Safety Net:** No Pull Request will be accepted without 100% passing tests and verified layer integrity.

## 6. Documentation & Metadata Standards
Every single file (.tsx, .ts, .scss) created or refactored MUST start with a standardized JSDoc header. This ensures traceability and immediate context for any developer.

Mandatory Header Block:

```TypeScript
/**
 * @file [FileName.ext]
 * @description [Brief and clear explanation of the file's responsibility].
 * [Optionally: Mention key compositions or dependencies].
 * @author [author_username]
 * @date [YYYY-MM-DD]
 * @version [X.Y.Z]
 */
```

- Version Control: Use Semantic Versioning (SemVer) for versioning individual complex components or logic hooks.

- Description Quality: Don't just repeat the filename. Explain why the file exists or how it fits into the FSD layer (e.g., "Composes the SplitLayout with specific landing copy").
/**
 * @file main.tsx
 * @description Main entry point of the React application.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.1.0
 */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';

import App from './App';
import './styles/main.scss';

// =============================================================================
// ROOT CONTAINER VALIDATION
// =============================================================================

/**
 * DOM element where the React app will be mounted.
 * It must exist in index.html: <div id="root"></div>
 */
const rootElement = document.getElementById('root');

/**
 * Verify that the root container exists before attempting to mount the app.
 * This prevents cryptic runtime errors and simplifies debugging.
 */
if (!rootElement) {
  throw new Error(
    "[main.tsx] Could not find element with id 'root'. " +
      "Make sure your index.html contains <div id='root'></div>",
  );
}

// =============================================================================
// REACT 18+ CONCURRENT ROOT INITIALIZATION
// =============================================================================

/**
 * Create a concurrent React root (React 18+).
 *
 * The createRoot API enables:
 * - Concurrent rendering for better user experience
 * - React 18 features (Suspense, Transitions, etc.)
 * - Improved performance for updates
 *
 * @see https://react.dev/reference/react-dom/client/createRoot
 */
const root = createRoot(rootElement);

// =============================================================================
// APPLICATION RENDERING
// =============================================================================

/**
 * Mount the application with the following configurations:
 *
 * 1. StrictMode: Enables additional checks in development
 *    - Detects unintended side effects
 *    - Identifies deprecated APIs
 *    - Warns about incorrect ref usage
 *    ⚠️ Components render twice in DEV (intentional to surface bugs)
 *
 * 2. BrowserRouter: Enables URL‑based routing for the browser
 *    - Uses the History API (pushState/replaceState)
 *    - Clean URLs: /route instead of /#/route (unlike HashRouter)
 *    - Requires server configuration for SPA (fallback to index.html)
 */
root.render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
);

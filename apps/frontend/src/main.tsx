/**
 * @file main.tsx
 * @description Main entry point for the React application.
 * Mounts the App component within BrowserRouter and StrictMode.
 * @author serjimen
 * @date 2026-03-24
 * @version 1.5.0
 */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';

import App from './app/App';
import './app/styles/main.scss';

const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error(
    "[main.tsx] element 'root' not found. Verify your index.html."
  );
}

const root = createRoot(rootElement);

root.render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
);
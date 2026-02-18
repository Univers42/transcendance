import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 1,
    },
  },
});

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route
            path="/"
            element={
              <main style={{ textAlign: 'center', padding: '4rem' }}>
                <h1>🏓 ft_transcendence</h1>
                <p>Infrastructure ready. Start building features!</p>
                <ul style={{ listStyle: 'none', padding: 0, lineHeight: 2 }}>
                  <li>
                    ✅ Backend API →{' '}
                    <a href="/api/docs" target="_blank" rel="noreferrer">
                      /api/docs
                    </a>
                  </li>
                  <li>✅ WebSocket ready (Socket.IO)</li>
                  <li>✅ PostgreSQL + Prisma ORM</li>
                  <li>✅ Redis (cache + pub/sub)</li>
                  <li>
                    ✅ Mailpit →{' '}
                    <a
                      href="http://localhost:4212"
                      target="_blank"
                      rel="noreferrer"
                    >
                      :4212
                    </a>
                  </li>
                </ul>
              </main>
            }
          />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

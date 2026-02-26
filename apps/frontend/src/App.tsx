import { useEffect, useState } from 'react';
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

// ── Types ───────────────────────────────────────────

interface HealthData {
  status: string;
  timestamp: string;
  uptime: number;
  environment: string;
  version: string;
}

// ── Helpers ─────────────────────────────────────────

function StatusDot({ ok }: { ok: boolean | null }) {
  if (ok === null)
    return (
      <span
        className="badge badge--no-dot badge--info"
        style={{ animation: 'pulse 1.5s ease-in-out infinite' }}
      >
        checking
      </span>
    );
  return ok ? (
    <span className="badge badge--no-dot badge--success">online</span>
  ) : (
    <span className="badge badge--no-dot badge--error">offline</span>
  );
}

function formatUptime(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m < 60) return `${m}m ${s}s`;
  const h = Math.floor(m / 60);
  return `${h}h ${m % 60}m`;
}

// ── Welcome Page ────────────────────────────────────

function WelcomePage() {
  const [health, setHealth] = useState<HealthData | null>(null);
  const [backendOk, setBackendOk] = useState<boolean | null>(null);

  useEffect(() => {
    const check = () =>
      fetch('/api/health')
        .then((r) => {
          if (!r.ok) throw new Error('Backend unreachable');
          return r.json();
        })
        .then((d: HealthData) => {
          setHealth(d);
          setBackendOk(true);
        })
        .catch(() => setBackendOk(false));

    check();
    const id = setInterval(check, 30_000);
    return () => clearInterval(id);
  }, []);

  const bp = 3000;
  const fp = 5173;
  const mp = 8025;
  const pp = 5555;

  return (
    <div className="app">

      {/* ── Header ──────────────────────────────── */}
      <header className="app__header">
        <div className="header">
          <div className="header__container">
            <div className="header__brand">
              <span style={{ fontSize: '1.5rem' }}>⚡</span>
              <span className="header__title">Transcendence</span>
            </div>
            <div className="header__actions">
              <span className="badge badge--no-dot badge--accent">Full-Stack Platform</span>
            </div>
          </div>
        </div>
      </header>

      {/* ── Main ────────────────────────────────── */}
      <main className="app__main">

        {/* ── Hero ────────────────────────────────── */}
        <section className="hero">
          <div className="hero__container">
            <div className="hero__content">
              <h1 className="hero__title">
                ⚡ Transcendence
              </h1>
              <p className="hero__subtitle">
                Full-Stack Platform · Ready to Build
              </p>
              <div className="hero__actions">
                <span className="badge badge--no-dot badge--accent">TypeScript</span>
                <span className="badge badge--no-dot badge--info">NestJS 11</span>
                <span className="badge badge--no-dot badge--success">React 19</span>
                <span className="badge badge--no-dot badge--warning">Prisma 7</span>
              </div>
            </div>
          </div>
        </section>

        {/* ── Services ─────────────────────────────── */}
        <section style={{ padding: '3rem 0' }}>
          <div className="container">
            <h2 style={{ marginBottom: '2rem' }}>Services</h2>

            <div
              style={{
                display: 'grid',
                gap: '1.5rem',
                gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
              }}
            >
              {/* API Docs */}
              <a
                href={`http://localhost:${bp}/api/docs`}
                target="_blank"
                rel="noreferrer"
                className="card card--interactive"
                style={{ textDecoration: 'none' }}
              >
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      📖 API Documentation
                    </p>
                    <p className="card__subtitle">localhost:{bp}/api/docs</p>
                  </div>
                  <div className="card__actions">
                    <StatusDot ok={backendOk} />
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>Swagger / OpenAPI interactive docs</p>
                </div>
              </a>

              {/* Backend */}
              <div className="card card--data">
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      🚀 Backend API
                    </p>
                    <p className="card__subtitle">localhost:{bp}</p>
                  </div>
                  <div className="card__actions">
                    <StatusDot ok={backendOk} />
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>
                    {backendOk && health
                      ? `Up ${formatUptime(health.uptime)} · ${health.environment}`
                      : backendOk === false
                        ? 'Offline — run make dev'
                        : 'Checking…'}
                  </p>
                  {backendOk && health && (
                    <div style={{ marginTop: '0.75rem' }}>
                      <span className="card__value data-sm">
                        {formatUptime(health.uptime)}
                      </span>
                      <span className="card__label" style={{ marginLeft: '0.5rem' }}>
                        uptime
                      </span>
                    </div>
                  )}
                </div>
              </div>

              {/* Frontend */}
              <div className="card card--data card--success">
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      ⚛️ Frontend
                    </p>
                    <p className="card__subtitle">localhost:{fp}</p>
                  </div>
                  <div className="card__actions">
                    <StatusDot ok={true} />
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>React 19 + Vite — you are here</p>
                </div>
              </div>

              {/* Mailpit */}
              <a
                href={`http://localhost:${mp}`}
                target="_blank"
                rel="noreferrer"
                className="card card--interactive"
                style={{ textDecoration: 'none' }}
              >
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      📬 Mailpit
                    </p>
                    <p className="card__subtitle">localhost:{mp}</p>
                  </div>
                  <div className="card__actions">
                    <span className="badge badge--no-dot">idle</span>
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>Dev email catcher</p>
                </div>
              </a>

              {/* Prisma Studio */}
              <a
                href={`http://localhost:${pp}`}
                target="_blank"
                rel="noreferrer"
                className="card card--interactive"
                style={{ textDecoration: 'none' }}
              >
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      🗄️ Prisma Studio
                    </p>
                    <p className="card__subtitle">localhost:{pp}</p>
                  </div>
                  <div className="card__actions">
                    <span className="badge badge--no-dot">idle</span>
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>Visual database browser</p>
                </div>
              </a>

              {/* Redis */}
              <div className="card">
                <div className="card__header">
                  <div>
                    <p className="card__title" style={{ fontSize: '1rem' }}>
                      ⚡ Redis
                    </p>
                    <p className="card__subtitle">localhost:6379</p>
                  </div>
                  <div className="card__actions">
                    <span className="badge badge--no-dot">idle</span>
                  </div>
                </div>
                <div className="card__body">
                  <p style={{ margin: 0 }}>Cache + real-time pub/sub</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ── Quick Start ──────────────────────────── */}
        <section className="quickstart">
          <div className="quickstart__container">
            <h2 className="quickstart__title">Quick Start</h2>
            <div className="table-container">
              <table className="table">
                <thead className="table__head">
                  <tr className="table__header-row">
                    <th className="table__header-cell">Command</th>
                    <th className="table__header-cell">Description</th>
                  </tr>
                </thead>
                <tbody className="table__body">
                  {[
                    ['make', 'Full bootstrap (default)'],
                    ['make turn-on', 'Start dev servers + open browser'],
                    ['make turn-off', 'Stop everything + free ports'],
                    ['make help', 'All available commands'],
                    ['make doctor', 'Full environment diagnostic'],
                  ].map(([cmd, desc]) => (
                    <tr className="table__row" key={cmd}>
                      <td className="table__cell">
                        <code className="table__data data-sm">{cmd}</code>
                      </td>
                      <td className="table__cell table__cell--secondary">{desc}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>

      </main>

      {/* ── Footer ───────────────────────────────── */}
      <footer className="app__footer">
        <div className="footer">
          <div className="footer__container">
            <div className="footer__content">
              <span className="footer__brand">⚡ Transcendence</span>
              <span className="footer__copy">Built with ❤️ and TypeScript</span>
              <div className="footer__links">
                <a
                  href={`http://localhost:${bp}/api/docs`}
                  target="_blank"
                  rel="noreferrer"
                  className="footer__link"
                >
                  API Docs
                </a>
                <a
                  href={`http://localhost:${mp}`}
                  target="_blank"
                  rel="noreferrer"
                  className="footer__link"
                >
                  Mailpit
                </a>
                <a
                  href={`http://localhost:${pp}`}
                  target="_blank"
                  rel="noreferrer"
                  className="footer__link"
                >
                  Prisma Studio
                </a>
              </div>
            </div>
          </div>
        </div>
      </footer>

    </div>
  );
}

// ── Root App ────────────────────────────────────────

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<WelcomePage />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
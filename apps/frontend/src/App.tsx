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
  if (ok === null) return <span className="dot loading" />;
  return <span className={`dot ${ok ? 'ok' : 'error'}`} />;
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
      {/* ── Hero ──────────────────────────────────── */}
      <header className="hero">
        <div className="hero-glow" />
        <h1 className="title">
          <span className="title-icon">⚡</span>
          Transcendence
        </h1>
        <p className="subtitle">Full-Stack Platform · Ready to Build</p>
        <div className="badge-row">
          <span className="badge">TypeScript</span>
          <span className="badge">NestJS 11</span>
          <span className="badge">React 19</span>
          <span className="badge">Prisma 7</span>
        </div>
      </header>

      {/* ── Services ─────────────────────────────── */}
      <section className="services">
        <h2 className="section-title">Services</h2>
        <div className="card-grid">
          <a
            href={`http://localhost:${bp}/api/docs`}
            target="_blank"
            rel="noreferrer"
            className="card"
          >
            <div className="card-header">
              <span className="card-icon">📖</span>
              <StatusDot ok={backendOk} />
            </div>
            <h3>API Documentation</h3>
            <p className="card-url">localhost:{bp}/api/docs</p>
            <p className="card-desc">Swagger / OpenAPI interactive docs</p>
          </a>

          <div className="card">
            <div className="card-header">
              <span className="card-icon">🚀</span>
              <StatusDot ok={backendOk} />
            </div>
            <h3>Backend API</h3>
            <p className="card-url">localhost:{bp}</p>
            <p className="card-desc">
              {backendOk && health
                ? `Up ${formatUptime(health.uptime)} · ${health.environment}`
                : backendOk === false
                  ? 'Offline — run make dev'
                  : 'Checking…'}
            </p>
          </div>

          <div className="card active">
            <div className="card-header">
              <span className="card-icon">⚛️</span>
              <StatusDot ok={true} />
            </div>
            <h3>Frontend</h3>
            <p className="card-url">localhost:{fp}</p>
            <p className="card-desc">React 19 + Vite — you are here</p>
          </div>

          <a
            href={`http://localhost:${mp}`}
            target="_blank"
            rel="noreferrer"
            className="card"
          >
            <div className="card-header">
              <span className="card-icon">📬</span>
              <span className="dot neutral" />
            </div>
            <h3>Mailpit</h3>
            <p className="card-url">localhost:{mp}</p>
            <p className="card-desc">Dev email catcher</p>
          </a>

          <a
            href={`http://localhost:${pp}`}
            target="_blank"
            rel="noreferrer"
            className="card"
          >
            <div className="card-header">
              <span className="card-icon">🗄️</span>
              <span className="dot neutral" />
            </div>
            <h3>Prisma Studio</h3>
            <p className="card-url">localhost:{pp}</p>
            <p className="card-desc">Visual database browser</p>
          </a>

          <div className="card">
            <div className="card-header">
              <span className="card-icon">⚡</span>
              <span className="dot neutral" />
            </div>
            <h3>Redis</h3>
            <p className="card-url">localhost:6379</p>
            <p className="card-desc">Cache + real-time pub/sub</p>
          </div>
        </div>
      </section>

      {/* ── Quick Start ──────────────────────────── */}
      <section className="quickstart">
        <h2 className="section-title">Quick Start</h2>
        <div className="commands">
          <div className="cmd">
            <code>make</code>
            <span>Full bootstrap (default)</span>
          </div>
          <div className="cmd">
            <code>make turn-on</code>
            <span>Start dev servers + open browser</span>
          </div>
          <div className="cmd">
            <code>make turn-off</code>
            <span>Stop everything + free ports</span>
          </div>
          <div className="cmd">
            <code>make help</code>
            <span>All available commands</span>
          </div>
          <div className="cmd">
            <code>make doctor</code>
            <span>Full environment diagnostic</span>
          </div>
        </div>
      </section>

      {/* ── Footer ───────────────────────────────── */}
      <footer className="footer">
        <p>Transcendence · Built with ❤️ and TypeScript</p>
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

import { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 1,
    },
  },
});

// ── API helper ──────────────────────────────────────

const API = '/api';

async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json() as Promise<T>;
}

// ── Types ───────────────────────────────────────────

interface ApiDiscovery {
  service: string;
  version: string;
  sql_resources: string[];
  nosql_resources: string[];
}

interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  perPage: number;
}

interface HealthData {
  status: string;
  service: string;
  timestamp: string;
}

// ── Hooks ───────────────────────────────────────────

function useHealth() {
  return useQuery<HealthData>({
    queryKey: ['health'],
    queryFn: () => fetchJson<HealthData>('/health'),
    refetchInterval: 15_000,
  });
}

function useDiscovery() {
  return useQuery<ApiDiscovery>({
    queryKey: ['discovery'],
    queryFn: () => fetchJson<ApiDiscovery>(API),
  });
}

function useSqlResource(resource: string, page = 1, perPage = 10) {
  return useQuery<PaginatedResponse<Record<string, unknown>>>({
    queryKey: ['sql', resource, page],
    queryFn: () =>
      fetchJson(`${API}/${resource}?page=${page}&perPage=${perPage}`),
    enabled: !!resource,
  });
}

function useNosqlResource(resource: string, page = 1, perPage = 10) {
  return useQuery<PaginatedResponse<Record<string, unknown>>>({
    queryKey: ['nosql', resource, page],
    queryFn: () =>
      fetchJson(`${API}/nosql/${resource}?page=${page}&perPage=${perPage}`),
    enabled: !!resource,
  });
}

// ── Components ──────────────────────────────────────

function StatusDot({ status }: { status: 'ok' | 'error' | 'loading' }) {
  const colors = { ok: '#22c55e', error: '#ef4444', loading: '#f59e0b' };
  return (
    <span
      style={{
        display: 'inline-block',
        width: 10,
        height: 10,
        borderRadius: '50%',
        background: colors[status],
        marginRight: 8,
      }}
    />
  );
}

function DataTable({ rows }: { rows: Record<string, unknown>[] }) {
  if (!rows.length) return <p style={{ color: 'var(--prisma-text-secondary, #888)', padding: '1rem' }}>No data found.</p>;

  // Determine columns from first row (limit to 6 for readability)
  const allCols = Object.keys(rows[0]);
  const cols = allCols.slice(0, 6);

  function formatCell(val: unknown): string {
    if (val === null || val === undefined) return '—';
    if (typeof val === 'object') return JSON.stringify(val).slice(0, 60);
    return String(val).slice(0, 60);
  }

  return (
    <div className="table-container">
      <table className="table">
        <thead className="table__head">
          <tr>
            {cols.map((col) => (
              <th key={col} className="table__header-cell">{col}</th>
            ))}
            {allCols.length > 6 && <th className="table__header-cell">…+{allCols.length - 6}</th>}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} className="table__row">
              {cols.map((col) => (
                <td key={col} className="table__cell">{formatCell(row[col])}</td>
              ))}
              {allCols.length > 6 && <td className="table__cell">…</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ResourceExplorer({ type, resources }: { type: 'sql' | 'nosql'; resources: string[] }) {
  const [selected, setSelected] = useState(resources[0] ?? '');
  const [page, setPage] = useState(1);

  const sqlQuery = useSqlResource(type === 'sql' ? selected : '', page);
  const nosqlQuery = useNosqlResource(type === 'nosql' ? selected : '', page);
  const query = type === 'sql' ? sqlQuery : nosqlQuery;

  useEffect(() => { setPage(1); }, [selected]);

  return (
    <div style={{ marginBottom: '2rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <label style={{ fontWeight: 600, fontSize: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--prisma-text-secondary, #999)' }}>
          {type === 'sql' ? 'PostgreSQL' : 'MongoDB'} →
        </label>
        <select
          value={selected}
          onChange={(e) => setSelected(e.target.value)}
          style={{
            padding: '0.5rem 1rem',
            borderRadius: 8,
            border: '1px solid var(--prisma-border, #333)',
            background: 'var(--prisma-bg-secondary, #111)',
            color: 'var(--prisma-text-primary, #eee)',
            fontSize: '0.875rem',
            minWidth: 200,
          }}
        >
          {resources.map((r) => (
            <option key={r} value={r}>{r}</option>
          ))}
        </select>
        {query.data && (
          <span style={{ fontSize: '0.75rem', color: 'var(--prisma-text-secondary, #888)' }}>
            {query.data.total} records · Page {query.data.page}
          </span>
        )}
      </div>

      {query.isLoading && <p style={{ color: '#f59e0b' }}>Loading…</p>}
      {query.isError && <p style={{ color: '#ef4444' }}>Error: {String(query.error)}</p>}
      {query.data && <DataTable rows={query.data.data} />}

      {query.data && query.data.total > 10 && (
        <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.75rem' }}>
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
            style={{ padding: '0.35rem 1rem', borderRadius: 6, border: '1px solid var(--prisma-border, #333)', background: 'var(--prisma-bg-secondary, #111)', color: 'var(--prisma-text-primary, #eee)', cursor: page <= 1 ? 'not-allowed' : 'pointer', opacity: page <= 1 ? 0.4 : 1 }}
          >
            ← Prev
          </button>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={page * 10 >= (query.data?.total ?? 0)}
            style={{ padding: '0.35rem 1rem', borderRadius: 6, border: '1px solid var(--prisma-border, #333)', background: 'var(--prisma-bg-secondary, #111)', color: 'var(--prisma-text-primary, #eee)', cursor: page * 10 >= (query.data?.total ?? 0) ? 'not-allowed' : 'pointer', opacity: page * 10 >= (query.data?.total ?? 0) ? 0.4 : 1 }}
          >
            Next →
          </button>
        </div>
      )}
    </div>
  );
}

// ── Dashboard Page ──────────────────────────────────

function DashboardPage() {
  const health = useHealth();
  const discovery = useDiscovery();

  const apiStatus: 'ok' | 'error' | 'loading' = health.isLoading
    ? 'loading'
    : health.isError
      ? 'error'
      : 'ok';

  return (
    <div style={{ minHeight: '100vh', background: 'var(--prisma-bg-primary, #0a0a1a)', color: 'var(--prisma-text-primary, #e0e0e0)' }}>
      {/* Hero */}
      <header style={{ padding: '3rem 2rem 2rem', textAlign: 'center', borderBottom: '1px solid var(--prisma-border, #222)' }}>
        <h1 style={{ fontSize: '2.5rem', fontWeight: 800, letterSpacing: '-0.02em', margin: 0 }}>
          ⚡ Transcendence
        </h1>
        <p style={{ fontSize: '1.1rem', color: 'var(--prisma-text-secondary, #888)', marginTop: '0.5rem' }}>
          Data Explorer — PostgreSQL + MongoDB via data-api
        </p>
        <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem', marginTop: '1rem', flexWrap: 'wrap' }}>
          <span className="badge" style={{ display: 'inline-flex', alignItems: 'center' }}>
            <StatusDot status={apiStatus} /> data-api
          </span>
          {discovery.data && (
            <>
              <span className="badge">{discovery.data.sql_resources.length} SQL tables</span>
              <span className="badge">{discovery.data.nosql_resources.length} NoSQL collections</span>
            </>
          )}
        </div>
      </header>

      {/* Main content */}
      <main style={{ maxWidth: 1100, margin: '0 auto', padding: '2rem 1.5rem' }}>
        {/* Stats cards */}
        {discovery.data && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2.5rem' }}>
            <div className="card">
              <div className="card__body">
                <div style={{ fontSize: '2rem', fontWeight: 700 }}>{discovery.data.sql_resources.length}</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--prisma-text-secondary, #888)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>PostgreSQL Tables</div>
              </div>
            </div>
            <div className="card">
              <div className="card__body">
                <div style={{ fontSize: '2rem', fontWeight: 700 }}>{discovery.data.nosql_resources.length}</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--prisma-text-secondary, #888)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>MongoDB Collections</div>
              </div>
            </div>
            <div className="card">
              <div className="card__body">
                <div style={{ fontSize: '2rem', fontWeight: 700 }}>
                  <StatusDot status={apiStatus} />
                  {apiStatus === 'ok' ? 'Online' : apiStatus === 'loading' ? '…' : 'Offline'}
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--prisma-text-secondary, #888)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  {health.data?.service ?? 'data-api'}
                </div>
              </div>
            </div>
          </div>
        )}

        {discovery.isLoading && (
          <p style={{ textAlign: 'center', color: '#f59e0b', padding: '3rem 0' }}>
            Connecting to data-api…
          </p>
        )}

        {discovery.isError && (
          <div style={{ textAlign: 'center', padding: '3rem 0' }}>
            <p style={{ color: '#ef4444', fontSize: '1.2rem', fontWeight: 600 }}>
              Cannot reach data-api
            </p>
            <p style={{ color: 'var(--prisma-text-secondary, #888)', marginTop: '0.5rem' }}>
              Run <code style={{ background: 'var(--prisma-bg-secondary, #111)', padding: '2px 8px', borderRadius: 4 }}>make docker-up</code> to start the stack
            </p>
          </div>
        )}

        {/* SQL Explorer */}
        {discovery.data && discovery.data.sql_resources.length > 0 && (
          <section style={{ marginBottom: '3rem' }}>
            <h2 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '1rem', borderBottom: '1px solid var(--prisma-border, #222)', paddingBottom: '0.5rem' }}>
              🐘 PostgreSQL Data
            </h2>
            <ResourceExplorer type="sql" resources={discovery.data.sql_resources} />
          </section>
        )}

        {/* NoSQL Explorer */}
        {discovery.data && discovery.data.nosql_resources.length > 0 && (
          <section style={{ marginBottom: '3rem' }}>
            <h2 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '1rem', borderBottom: '1px solid var(--prisma-border, #222)', paddingBottom: '0.5rem' }}>
              🍃 MongoDB Data
            </h2>
            <ResourceExplorer type="nosql" resources={discovery.data.nosql_resources} />
          </section>
        )}
      </main>

      {/* Footer */}
      <footer style={{ textAlign: 'center', padding: '2rem', borderTop: '1px solid var(--prisma-border, #222)', color: 'var(--prisma-text-secondary, #666)', fontSize: '0.85rem' }}>
        Transcendence · data-api v0.1.0
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
          <Route path="/" element={<DashboardPage />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

import {
  Database,
  Users,
  LayoutDashboard,
  Shield,
  Zap,
  Globe,
  Upload,
  ArrowRight,
} from 'lucide-react';
import { Link } from 'react-router-dom';

const FEATURES = [
  {
    icon: Database,
    color: '#2563EB',
    title: 'Crea o importa tus datos',
    description:
      'Diseña tu esquema desde cero, importa archivos CSV/JSON o conecta tus bases de datos existentes (PostgreSQL, MySQL, MongoDB). Todo en minutos.',
  },
  {
    icon: Users,
    color: '#7C3AED',
    title: 'Roles y permisos granulares',
    description:
      'Define quién puede leer, editar o administrar cada tabla o campo. Asigna roles personalizados por proyecto, equipo u organización.',
  },
  {
    icon: LayoutDashboard,
    color: '#DB2777',
    title: 'Dashboard 100% personalizable',
    description:
      'Construye tu espacio de trabajo con widgets de métricas, gráficas, tablas y alertas. Arrastra, suelta y guarda múltiples vistas.',
  },
  {
    icon: Shield,
    color: '#059669',
    title: 'Seguridad empresarial',
    description:
      'Encriptación en reposo y en tránsito, auditoría de accesos, cumplimiento GDPR/SOC2 y backups automáticos con retención configurable.',
  },
  {
    icon: Zap,
    color: '#EA580C',
    title: 'API completa y webhooks',
    description:
      'Conecta cualquier servicio externo mediante REST API o GraphQL. Configura webhooks para automatizar flujos de trabajo en tiempo real.',
  },
  {
    icon: Globe,
    color: '#0891B2',
    title: 'Escala a tu ritmo',
    description:
      'Desde un proyecto personal hasta millones de registros en una corporación global. Infraestructura multi-región con SLA garantizado.',
  },
];

const TIERS = [
  {
    icon: '👤',
    name: 'Personal',
    tagline: 'Para desarrolladores y freelancers',
    perks: [
      'Hasta 3 bases de datos',
      '100 MB de almacenamiento',
      'Dashboard básico',
      'API REST incluida',
    ],
    cta: 'Empezar gratis',
    accent: false,
  },
  {
    icon: '🏢',
    name: 'Equipo',
    tagline: 'Para startups y PYMEs',
    perks: [
      'Bases de datos ilimitadas',
      '50 GB de almacenamiento',
      'Roles y permisos avanzados',
      'Dashboard personalizable',
      'Soporte prioritario',
    ],
    cta: 'Prueba 14 días gratis',
    accent: true,
  },
  {
    icon: '🌐',
    name: 'Enterprise',
    tagline: 'Para grandes organizaciones',
    perks: [
      'Todo lo del plan Equipo',
      'Almacenamiento ilimitado',
      'SSO / SAML / LDAP',
      'Cumplimiento GDPR & SOC2',
      'SLA 99.99% · Multi-región',
      'Gestor de cuenta dedicado',
    ],
    cta: 'Contactar ventas',
    accent: false,
  },
];

export function ProductDescription() {
  return (
    <div id="producto" style={{ backgroundColor: 'var(--bg-primary)' }}>

      {/* ── FEATURES ── */}
      <section className="max-w-7xl mx-auto px-5 sm:px-6 py-16 sm:py-24">
        {/* Heading */}
        <div className="flex flex-col items-center text-center mb-12 sm:mb-16 gap-3">
          <span
            className="inline-flex items-center px-3 py-1 rounded-full border"
            style={{
              borderColor: 'var(--border-strong)',
              color: 'var(--text-secondary)',
              fontSize: '12px',
              fontWeight: 500,
              letterSpacing: '0.06em',
            }}
          >
            FUNCIONALIDADES
          </span>
          <h2
            style={{
              fontSize: 'clamp(22px, 4vw, 32px)',
              fontWeight: 600,
              lineHeight: 1.25,
              letterSpacing: '-0.01em',
              color: 'var(--text-primary)',
            }}
          >
            Todo lo que necesitas, en un solo lugar
          </h2>
          <p
            style={{
              fontSize: '14px',
              lineHeight: 1.6,
              color: 'var(--text-secondary)',
              maxWidth: '520px',
              letterSpacing: '0.01em',
            }}
          >
            Datrix combina la potencia de una base de datos profesional con la
            simplicidad de un dashboard moderno. Sin infraestructura propia que gestionar.
          </p>
        </div>

        {/* Feature grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {FEATURES.map((feat, i) => {
            const Icon = feat.icon;
            return (
              <div
                key={i}
                className="flex flex-col gap-3 p-6 rounded-2xl border transition-all duration-300"
                style={{
                  backgroundColor: 'var(--bg-elevated)',
                  borderColor: 'var(--border-default)',
                }}
                onMouseEnter={e => {
                  e.currentTarget.style.borderColor = feat.color + '55';
                  e.currentTarget.style.boxShadow = `0 4px 20px ${feat.color}18`;
                }}
                onMouseLeave={e => {
                  e.currentTarget.style.borderColor = 'var(--border-default)';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              >
                {/* Icon */}
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                  style={{ backgroundColor: feat.color + '18' }}
                >
                  <Icon className="w-5 h-5" style={{ color: feat.color }} />
                </div>
                {/* Text */}
                <div>
                  <h3
                    style={{
                      fontSize: '15px',
                      fontWeight: 600,
                      color: 'var(--text-primary)',
                      marginBottom: '6px',
                      lineHeight: 1.3,
                    }}
                  >
                    {feat.title}
                  </h3>
                  <p
                    style={{
                      fontSize: '13px',
                      lineHeight: 1.6,
                      color: 'var(--text-secondary)',
                      letterSpacing: '0.01em',
                    }}
                  >
                    {feat.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ── DIVIDER ── */}
      <div
        className="max-w-7xl mx-auto px-5 sm:px-6"
        style={{ height: '1px', backgroundColor: 'var(--border-default)' }}
      />

      {/* ── WHO IS IT FOR ── */}
      <section
        className="py-16 sm:py-24"
        style={{ backgroundColor: 'var(--bg-secondary)' }}
      >
        <div className="max-w-7xl mx-auto px-5 sm:px-6">
          {/* Heading */}
          <div className="flex flex-col items-center text-center mb-12 gap-3">
            <span
              className="inline-flex items-center px-3 py-1 rounded-full border"
              style={{
                borderColor: 'var(--border-strong)',
                color: 'var(--text-secondary)',
                fontSize: '12px',
                fontWeight: 500,
                letterSpacing: '0.06em',
              }}
            >
              PARA QUIÉN
            </span>
            <h2
              style={{
                fontSize: 'clamp(22px, 4vw, 32px)',
                fontWeight: 600,
                lineHeight: 1.25,
                letterSpacing: '-0.01em',
                color: 'var(--text-primary)',
              }}
            >
              Diseñado para cada escala
            </h2>
            <p
              style={{
                fontSize: '14px',
                lineHeight: 1.6,
                color: 'var(--text-secondary)',
                maxWidth: '480px',
              }}
            >
              Tanto si estás construyendo tu primer proyecto como si gestionas la
              infraestructura de datos de una multinacional, Datrix se adapta.
            </p>
          </div>

          {/* Tier cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {TIERS.map((tier, i) => (
              <div
                key={i}
                className="flex flex-col gap-5 p-7 rounded-2xl border relative overflow-hidden transition-all duration-300"
                style={{
                  backgroundColor: tier.accent ? 'var(--accent-default)' : 'var(--bg-elevated)',
                  borderColor: tier.accent ? 'transparent' : 'var(--border-default)',
                  boxShadow: tier.accent ? '0 8px 32px rgba(59,130,246,0.28)' : 'none',
                }}
              >
                {tier.accent && (
                  <div
                    className="absolute top-3 right-3 px-2.5 py-0.5 rounded-full"
                    style={{ backgroundColor: 'rgba(255,255,255,0.22)', fontSize: '11px', color: '#fff', fontWeight: 500 }}
                  >
                    Popular
                  </div>
                )}

                {/* Header */}
                <div className="flex items-center gap-3">
                  <span style={{ fontSize: '24px' }}>{tier.icon}</span>
                  <div>
                    <p
                      style={{
                        fontSize: '16px',
                        fontWeight: 600,
                        color: tier.accent ? '#FFFFFF' : 'var(--text-primary)',
                        lineHeight: 1.2,
                      }}
                    >
                      {tier.name}
                    </p>
                    <p
                      style={{
                        fontSize: '12px',
                        color: tier.accent ? 'rgba(255,255,255,0.75)' : 'var(--text-secondary)',
                        marginTop: '1px',
                      }}
                    >
                      {tier.tagline}
                    </p>
                  </div>
                </div>

                {/* Perks */}
                <ul className="flex flex-col gap-2.5">
                  {tier.perks.map((perk, j) => (
                    <li key={j} className="flex items-start gap-2.5">
                      <span
                        className="w-4 h-4 rounded-full flex items-center justify-center shrink-0 mt-0.5"
                        style={{
                          backgroundColor: tier.accent ? 'rgba(255,255,255,0.25)' : 'var(--bg-tertiary)',
                        }}
                      >
                        <svg width="8" height="8" viewBox="0 0 8 8" fill="none">
                          <path d="M1.5 4L3 5.5L6.5 2" stroke={tier.accent ? '#fff' : 'var(--accent-default)'} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </span>
                      <span
                        style={{
                          fontSize: '13px',
                          color: tier.accent ? 'rgba(255,255,255,0.88)' : 'var(--text-secondary)',
                          lineHeight: 1.5,
                        }}
                      >
                        {perk}
                      </span>
                    </li>
                  ))}
                </ul>

                {/* CTA */}
                <Link
                  to="/auth"
                  className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl mt-auto transition-all duration-200"
                  style={{
                    backgroundColor: tier.accent ? '#FFFFFF' : 'var(--accent-default)',
                    color: tier.accent ? 'var(--accent-default)' : '#FFFFFF',
                    fontSize: '14px',
                    fontWeight: 500,
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.opacity = '0.9';
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.opacity = '1';
                  }}
                >
                  {tier.cta}
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── IMPORT HIGHLIGHT ── */}
      <section
        className="py-16 sm:py-20 border-t"
        style={{ backgroundColor: 'var(--bg-primary)', borderColor: 'var(--border-default)' }}
      >
        <div className="max-w-7xl mx-auto px-5 sm:px-6 flex flex-col lg:flex-row items-center gap-10">
          {/* Text */}
          <div className="flex-1 flex flex-col gap-4">
            <span
              className="inline-flex w-fit items-center gap-2 px-3 py-1 rounded-full border"
              style={{
                borderColor: '#059669' + '44',
                color: '#059669',
                fontSize: '12px',
                fontWeight: 500,
                letterSpacing: '0.06em',
              }}
            >
              <Upload className="w-3 h-3" />
              IMPORTACIÓN
            </span>
            <h2
              style={{
                fontSize: 'clamp(20px, 3.5vw, 28px)',
                fontWeight: 600,
                lineHeight: 1.3,
                letterSpacing: '-0.01em',
                color: 'var(--text-primary)',
              }}
            >
              Trae tus datos existentes,<br />sin fricción.
            </h2>
            <p
              style={{
                fontSize: '14px',
                lineHeight: 1.6,
                color: 'var(--text-secondary)',
                maxWidth: '440px',
              }}
            >
              Importa desde CSV, Excel, JSON o mediante conexión directa a PostgreSQL,
              MySQL, MongoDB y más. Tu historial de datos siempre contigo.
            </p>
          </div>

          {/* Faux code block */}
          <div
            className="flex-1 rounded-2xl border overflow-hidden w-full"
            style={{
              backgroundColor: 'var(--bg-secondary)',
              borderColor: 'var(--border-default)',
              fontFamily: 'var(--font-mono)',
              maxWidth: '480px',
            }}
          >
            {/* Mac-style bar */}
            <div
              className="flex items-center gap-2 px-4 py-3 border-b"
              style={{ borderColor: 'var(--border-default)' }}
            >
              <span className="w-3 h-3 rounded-full" style={{ backgroundColor: '#FF5F57' }} />
              <span className="w-3 h-3 rounded-full" style={{ backgroundColor: '#FEBC2E' }} />
              <span className="w-3 h-3 rounded-full" style={{ backgroundColor: '#28C840' }} />
              <span style={{ fontSize: '12px', color: 'var(--text-tertiary)', marginLeft: '8px' }}>
                import.sql
              </span>
            </div>
            {/* Code lines */}
            <div className="p-5 flex flex-col gap-2" style={{ fontSize: '12px', lineHeight: 1.6 }}>
              {[
                { indent: 0, color: '#60A5FA', text: '-- Conexión a tu base de datos' },
                { indent: 0, color: 'var(--text-secondary)', text: 'CONNECT TO postgresql://your-db' },
                { indent: 0, color: 'var(--text-tertiary)', text: '' },
                { indent: 0, color: '#60A5FA', text: '-- Importar tabla completa' },
                { indent: 0, color: 'var(--text-secondary)', text: 'IMPORT TABLE users' },
                { indent: 2, color: '#34D399', text: 'FROM ./users_backup.csv' },
                { indent: 2, color: '#34D399', text: 'FORMAT CSV DELIMITER \',\'' },
                { indent: 2, color: '#34D399', text: 'HEADER ON;' },
                { indent: 0, color: 'var(--text-tertiary)', text: '' },
                { indent: 0, color: '#FBBF24', text: '-- ✓ 48 312 registros importados' },
              ].map((line, i) => (
                <p key={i} style={{ paddingLeft: `${line.indent * 12}px`, color: line.color, margin: 0 }}>
                  {line.text || '\u00A0'}
                </p>
              ))}
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
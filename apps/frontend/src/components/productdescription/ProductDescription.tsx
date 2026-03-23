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
      <section style={{ paddingTop: '4rem', paddingBottom: '4rem' }}>
        <div className="container">
          {/* Heading */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              textAlign: 'center',
              marginBottom: '3rem',
              gap: '0.75rem',
            }}
          >
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                paddingLeft: '0.75rem',
                paddingRight: '0.75rem',
                paddingTop: '0.25rem',
                paddingBottom: '0.25rem',
                borderRadius: '9999px',
                border: '1px solid var(--border-strong)',
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
              simplicidad de un dashboard moderno. Sin infraestructura propia
              que gestionar.
            </p>
          </div>

          {/* Feature grid */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
              gap: '1.25rem',
            }}
          >
            {FEATURES.map((feat, i) => {
              const Icon = feat.icon;
              return (
                <div
                  key={i}
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.75rem',
                    padding: '1.5rem',
                    borderRadius: '1rem',
                    border: '1px solid var(--border-default)',
                    backgroundColor: 'var(--bg-elevated)',
                    transition: 'all 300ms cubic-bezier(0.4, 0, 0.2, 1)',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = feat.color + '55';
                    e.currentTarget.style.boxShadow = `0 4px 20px ${feat.color}18`;
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'var(--border-default)';
                    e.currentTarget.style.boxShadow = 'none';
                  }}
                >
                  {/* Icon */}
                  <div
                    style={{
                      width: '2.5rem',
                      height: '2.5rem',
                      borderRadius: '0.75rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                      backgroundColor: feat.color + '18',
                    }}
                  >
                    <Icon
                      style={{
                        width: '1.25rem',
                        height: '1.25rem',
                        color: feat.color,
                      }}
                    />
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
        </div>
      </section>

      {/* ── DIVIDER ── */}
      <div
        className="container"
        style={{ height: '1px', backgroundColor: 'var(--border-default)' }}
      />

      {/* ── WHO IS IT FOR ── */}
      <section
        style={{
          paddingTop: '4rem',
          paddingBottom: '4rem',
          backgroundColor: 'var(--bg-secondary)',
        }}
      >
        <div className="container">
          {/* Heading */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              textAlign: 'center',
              marginBottom: '2.5rem',
              gap: '0.75rem',
            }}
          >
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                paddingLeft: '0.75rem',
                paddingRight: '0.75rem',
                paddingTop: '0.25rem',
                paddingBottom: '0.25rem',
                borderRadius: '9999px',
                border: '1px solid var(--border-strong)',
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
              Tanto si estás construyendo tu primer proyecto como si gestionas
              la infraestructura de datos de una multinacional, Datrix se
              adapta.
            </p>
          </div>

          {/* Tier cards */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: '1.25rem',
            }}
          >
            {TIERS.map((tier, i) => (
              <div
                key={i}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '1.25rem',
                  padding: '1.75rem',
                  borderRadius: '1rem',
                  border: tier.accent
                    ? 'none'
                    : '1px solid var(--border-default)',
                  position: 'relative',
                  overflow: 'hidden',
                  backgroundColor: tier.accent
                    ? 'var(--accent-default)'
                    : 'var(--bg-elevated)',
                  boxShadow: tier.accent
                    ? '0 8px 32px rgba(59,130,246,0.28)'
                    : 'none',
                  transition: 'all 300ms cubic-bezier(0, 0, 0.2, 1)',
                }}
              >
                {tier.accent && (
                  <div
                    style={{
                      position: 'absolute',
                      top: '0.75rem',
                      right: '0.75rem',
                      backgroundColor: 'rgba(255,255,255,0.22)',
                      paddingLeft: '0.625rem',
                      paddingRight: '0.625rem',
                      paddingTop: '0.125rem',
                      paddingBottom: '0.125rem',
                      borderRadius: '9999px',
                      fontSize: '11px',
                      color: '#fff',
                      fontWeight: 500,
                    }}
                  >
                    Popular
                  </div>
                )}

                {/* Header */}
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                  }}
                >
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
                        color: tier.accent
                          ? 'rgba(255,255,255,0.75)'
                          : 'var(--text-secondary)',
                        marginTop: '0.25px',
                      }}
                    >
                      {tier.tagline}
                    </p>
                  </div>
                </div>

                {/* Perks */}
                <ul
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.625rem',
                  }}
                >
                  {tier.perks.map((perk, j) => (
                    <li
                      key={j}
                      style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '0.625rem',
                      }}
                    >
                      <span
                        style={{
                          width: '1rem',
                          height: '1rem',
                          borderRadius: '9999px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flexShrink: 0,
                          marginTop: '0.125rem',
                          backgroundColor: tier.accent
                            ? 'rgba(255,255,255,0.25)'
                            : 'var(--bg-tertiary)',
                        }}
                      >
                        <svg width="8" height="8" viewBox="0 0 8 8" fill="none">
                          <path
                            d="M1.5 4L3 5.5L6.5 2"
                            stroke={
                              tier.accent ? '#fff' : 'var(--accent-default)'
                            }
                            strokeWidth="1.5"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      </span>
                      <span
                        style={{
                          fontSize: '13px',
                          color: tier.accent
                            ? 'rgba(255,255,255,0.88)'
                            : 'var(--text-secondary)',
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
                  className="btn"
                  style={{
                    marginTop: 'auto',
                    backgroundColor: tier.accent
                      ? '#FFFFFF'
                      : 'var(--accent-default)',
                    color: tier.accent ? 'var(--accent-default)' : '#FFFFFF',
                    fontSize: '14px',
                    fontWeight: 500,
                    textDecoration: 'none',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.opacity = '0.9';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.opacity = '1';
                  }}
                >
                  {tier.cta}
                  <ArrowRight
                    style={{ width: '0.875rem', height: '0.875rem' }}
                  />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── IMPORT HIGHLIGHT ── */}
      <section
        style={{
          paddingTop: '4rem',
          paddingBottom: '5rem',
          backgroundColor: 'var(--bg-primary)',
          borderTop: '1px solid var(--border-default)',
        }}
      >
        <div
          className="container"
          style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}
        >
          {/* Text */}
          <div
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              gap: '1rem',
            }}
          >
            <span
              style={{
                display: 'inline-flex',
                width: 'fit-content',
                alignItems: 'center',
                gap: '0.5rem',
                paddingLeft: '0.75rem',
                paddingRight: '0.75rem',
                paddingTop: '0.25rem',
                paddingBottom: '0.25rem',
                borderRadius: '9999px',
                border: '1px solid #05966944',
                color: '#059669',
                fontSize: '12px',
                fontWeight: 500,
                letterSpacing: '0.06em',
              }}
            >
              <Upload style={{ width: '0.75rem', height: '0.75rem' }} />
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
              Trae tus datos existentes,
              <br />
              sin fricción.
            </h2>
            <p
              style={{
                fontSize: '14px',
                lineHeight: 1.6,
                color: 'var(--text-secondary)',
                maxWidth: '440px',
              }}
            >
              Importa desde CSV, Excel, JSON o mediante conexión directa a
              PostgreSQL, MySQL, MongoDB y más. Tu historial de datos siempre
              contigo.
            </p>
          </div>

          {/* Faux code block */}
          <div
            style={{
              flex: 1,
              borderRadius: '1rem',
              border: '1px solid var(--border-default)',
              overflow: 'hidden',
              width: '100%',
              backgroundColor: 'var(--bg-secondary)',
              fontFamily: 'var(--font-mono)',
              maxWidth: '480px',
            }}
          >
            {/* Mac-style bar */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                paddingLeft: '1rem',
                paddingRight: '1rem',
                paddingTop: '0.75rem',
                paddingBottom: '0.75rem',
                borderBottom: '1px solid var(--border-default)',
              }}
            >
              <span
                style={{
                  width: '0.75rem',
                  height: '0.75rem',
                  borderRadius: '9999px',
                  backgroundColor: '#FF5F57',
                }}
              />
              <span
                style={{
                  width: '0.75rem',
                  height: '0.75rem',
                  borderRadius: '9999px',
                  backgroundColor: '#FEBC2E',
                }}
              />
              <span
                style={{
                  width: '0.75rem',
                  height: '0.75rem',
                  borderRadius: '9999px',
                  backgroundColor: '#28C840',
                }}
              />
              <span
                style={{
                  fontSize: '12px',
                  color: 'var(--text-tertiary)',
                  marginLeft: '0.5rem',
                }}
              >
                import.sql
              </span>
            </div>
            {/* Code lines */}
            <div
              style={{
                paddingLeft: '1.25rem',
                paddingRight: '1.25rem',
                paddingTop: '1.25rem',
                paddingBottom: '1.25rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.5rem',
                fontSize: '12px',
                lineHeight: 1.6,
              }}
            >
              {[
                {
                  indent: 0,
                  color: '#60A5FA',
                  text: '-- Conexión a tu base de datos',
                },
                {
                  indent: 0,
                  color: 'var(--text-secondary)',
                  text: 'CONNECT TO postgresql://your-db',
                },
                { indent: 0, color: 'var(--text-tertiary)', text: '' },
                {
                  indent: 0,
                  color: '#60A5FA',
                  text: '-- Importar tabla completa',
                },
                {
                  indent: 0,
                  color: 'var(--text-secondary)',
                  text: 'IMPORT TABLE users',
                },
                {
                  indent: 2,
                  color: '#34D399',
                  text: 'FROM ./users_backup.csv',
                },
                {
                  indent: 2,
                  color: '#34D399',
                  text: "FORMAT CSV DELIMITER ','",
                },
                { indent: 2, color: '#34D399', text: 'HEADER ON;' },
                { indent: 0, color: 'var(--text-tertiary)', text: '' },
                {
                  indent: 0,
                  color: '#FBBF24',
                  text: '-- ✓ 48 312 registros importados',
                },
              ].map((line, i) => (
                <p
                  key={i}
                  style={{
                    paddingLeft: `${line.indent * 12}px`,
                    color: line.color,
                    margin: 0,
                  }}
                >
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

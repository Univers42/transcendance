import { Database, Twitter, Github, Linkedin, Mail } from 'lucide-react';

const FOOTER_LINKS = [
  {
    heading: 'Producto',
    links: [
      { label: 'Funcionalidades', href: '#funcionalidades' },
      { label: 'Precios', href: '#precios' },
      { label: 'Integraciones', href: '#' },
      { label: 'Novedades', href: '#' },
      { label: 'Roadmap', href: '#' },
    ],
  },
  {
    heading: 'Empresa',
    links: [
      { label: 'Acerca de', href: '#' },
      { label: 'Blog', href: '#' },
      { label: 'Empleo', href: '#' },
      { label: 'Prensa', href: '#' },
      { label: 'Contacto', href: '#' },
    ],
  },
  {
    heading: 'Recursos',
    links: [
      { label: 'Documentación', href: '#docs' },
      { label: 'API Reference', href: '#' },
      { label: 'Estado del servicio', href: '#' },
      { label: 'Comunidad', href: '#' },
      { label: 'Soporte', href: '#' },
    ],
  },
  {
    heading: 'Legal',
    links: [
      { label: 'Privacidad', href: '#' },
      { label: 'Términos de uso', href: '#' },
      { label: 'Política de cookies', href: '#' },
      { label: 'GDPR', href: '#' },
      { label: 'Aviso legal', href: '#' },
    ],
  },
];

const SOCIAL = [
  { icon: Twitter, label: 'Twitter / X', href: '#' },
  { icon: Github, label: 'GitHub', href: '#' },
  { icon: Linkedin, label: 'LinkedIn', href: '#' },
  { icon: Mail, label: 'Email', href: 'mailto:hola@datrix.io' },
];

export function Footer() {
  return (
    <footer
      style={{
        backgroundColor: 'var(--bg-secondary)',
        borderColor: 'var(--border-default)',
        borderTop: '1px solid var(--border-default)',
      }}
    >
      <div className="container" style={{ paddingTop: '3.5rem', paddingBottom: '2rem' }}>

        {/* Top grid: brand + links */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '2rem', marginBottom: '3rem' }}>

          {/* Brand column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {/* Logo */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
              <div
                style={{
                  width: '1.75rem',
                  height: '1.75rem',
                  borderRadius: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                  backgroundColor: 'var(--accent-default)',
                }}
              >
                <Database style={{ width: '1rem', height: '1rem', color: 'white' }} />
              </div>
              <span
                style={{
                  fontSize: '16px',
                  fontWeight: 600,
                  letterSpacing: '-0.02em',
                  color: 'var(--text-primary)',
                }}
              >
                Prismatica
              </span>
            </div>
            <p
              style={{
                fontSize: '13px',
                lineHeight: 1.6,
                color: 'var(--text-secondary)',
                maxWidth: '200px',
              }}
            >
              La plataforma de datos en la nube diseñada para equipos de todos los tamaños.
            </p>
            {/* Social icons */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
              {SOCIAL.map(s => {
                const Icon = s.icon;
                return (
                  <a
                    key={s.label}
                    href={s.href}
                    aria-label={s.label}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      width: '2rem',
                      height: '2rem',
                      borderRadius: '0.5rem',
                      border: '1px solid var(--border-default)',
                      color: 'var(--text-tertiary)',
                      transition: 'all 200ms cubic-bezier(0.4, 0, 0.2, 1)',
                    }}
                    onMouseEnter={e => {
                      e.currentTarget.style.borderColor = 'var(--accent-default)';
                      e.currentTarget.style.color = 'var(--accent-default)';
                    }}
                    onMouseLeave={e => {
                      e.currentTarget.style.borderColor = 'var(--border-default)';
                      e.currentTarget.style.color = 'var(--text-tertiary)';
                    }}
                  >
                    <Icon style={{ width: '0.875rem', height: '0.875rem' }} />
                  </a>
                );
              })}
            </div>
          </div>

          {/* Link columns */}
          {FOOTER_LINKS.map(col => (
            <div key={col.heading} style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              <p
                style={{
                  fontSize: '12px',
                  fontWeight: 600,
                  color: 'var(--text-primary)',
                  letterSpacing: '0.06em',
                  textTransform: 'uppercase',
                  marginBottom: '2px',
                }}
              >
                {col.heading}
              </p>
              {col.links.map(link => (
                <a
                  key={link.label}
                  href={link.href}
                  style={{ fontSize: '13px', color: 'var(--text-secondary)', lineHeight: 1.4, transition: 'color 150ms cubic-bezier(0.4, 0, 0.2, 1)' }}
                  onMouseEnter={e => (e.currentTarget.style.color = 'var(--accent-default)')}
                  onMouseLeave={e => (e.currentTarget.style.color = 'var(--text-secondary)')}
                >
                  {link.label}
                </a>
              ))}
            </div>
          ))}
        </div>

        {/* Divider */}
        <div style={{ height: '1px', marginBottom: '1.5rem', backgroundColor: 'var(--border-default)' }} />

        {/* Bottom row */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <p style={{ fontSize: '12px', color: 'var(--text-tertiary)', lineHeight: 1.5 }}>
            © {new Date().getFullYear()} Prismatica S.L. Todos los derechos reservados.
          </p>
          <p
            style={{
              fontSize: '12px',
              color: 'var(--text-tertiary)',
              lineHeight: 1.5,
              maxWidth: '480px',
              textAlign: 'right',
            }}
          >
            Prismatica es una plataforma SaaS. Los datos almacenados son responsabilidad
            del usuario. Consulta nuestra{' '}
            <a
              href="#"
              style={{ color: 'var(--accent-default)' }}
              onMouseEnter={e => (e.currentTarget.style.textDecoration = 'underline')}
              onMouseLeave={e => (e.currentTarget.style.textDecoration = 'none')}
            >
              política de privacidad
            </a>{' '}
            y{' '}
            <a
              href="#"
              style={{ color: 'var(--accent-default)' }}
              onMouseEnter={e => (e.currentTarget.style.textDecoration = 'underline')}
              onMouseLeave={e => (e.currentTarget.style.textDecoration = 'none')}
            >
              términos de uso
            </a>{' '}
            para más información.
          </p>
        </div>
      </div>
    </footer>
  );
}

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
      className="border-t"
      style={{
        backgroundColor: 'var(--bg-secondary)',
        borderColor: 'var(--border-default)',
      }}
    >
      <div className="max-w-7xl mx-auto px-5 sm:px-6 pt-14 pb-8">

        {/* Top grid: brand + links */}
        <div className="grid grid-cols-2 gap-8 sm:grid-cols-3 lg:grid-cols-5 mb-12">

          {/* Brand column */}
          <div className="col-span-2 sm:col-span-3 lg:col-span-1 flex flex-col gap-4">
            {/* Logo */}
            <div className="flex items-center gap-2.5">
              <div
                className="w-7 h-7 rounded-lg flex items-center justify-center shrink-0"
                style={{ backgroundColor: 'var(--accent-default)' }}
              >
                <Database className="w-4 h-4 text-white" />
              </div>
              <span
                style={{
                  fontSize: '16px',
                  fontWeight: 600,
                  letterSpacing: '-0.02em',
                  color: 'var(--text-primary)',
                }}
              >
                Datrix
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
            <div className="flex items-center gap-2 mt-1">
              {SOCIAL.map(s => {
                const Icon = s.icon;
                return (
                  <a
                    key={s.label}
                    href={s.href}
                    aria-label={s.label}
                    className="flex items-center justify-center w-8 h-8 rounded-lg border transition-all duration-200"
                    style={{
                      borderColor: 'var(--border-default)',
                      color: 'var(--text-tertiary)',
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
                    <Icon className="w-3.5 h-3.5" />
                  </a>
                );
              })}
            </div>
          </div>

          {/* Link columns */}
          {FOOTER_LINKS.map(col => (
            <div key={col.heading} className="flex flex-col gap-3">
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
                  className="transition-colors duration-150"
                  style={{ fontSize: '13px', color: 'var(--text-secondary)', lineHeight: 1.4 }}
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
        <div className="h-px mb-6" style={{ backgroundColor: 'var(--border-default)' }} />

        {/* Bottom row */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
          <p style={{ fontSize: '12px', color: 'var(--text-tertiary)', lineHeight: 1.5 }}>
            © {new Date().getFullYear()} Datrix Technologies S.L. Todos los derechos reservados.
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
            Datrix es una plataforma SaaS. Los datos almacenados son responsabilidad
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

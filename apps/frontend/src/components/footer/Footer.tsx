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
    <footer className="footer">
      <div className="container footer__container">
        {/* Top grid: brand + links */}
        <div className="footer__grid">
          {/* Brand column */}
          <div className="footer__column">
            {/* Logo */}
            <div className="footer__brand">
              <div className="footer__brand-icon">
                <Database />
              </div>
              <span className="footer__brand-name">Prismatica</span>
            </div>
            <p className="footer__description">
              La plataforma de datos en la nube diseñada para equipos de todos
              los tamaños.
            </p>
            {/* Social icons */}
            <div className="footer__socials">
              {SOCIAL.map((s) => {
                const Icon = s.icon;
                return (
                  <a
                    key={s.label}
                    href={s.href}
                    aria-label={s.label}
                    className="footer__social-link"
                  >
                    <Icon />
                  </a>
                );
              })}
            </div>
          </div>

          {/* Link columns */}
          {FOOTER_LINKS.map((col) => (
            <div key={col.heading} className="footer__section">
              <p className="footer__section-title">{col.heading}</p>
              <div className="footer__section-links">
                {col.links.map((link) => (
                  <a key={link.label} href={link.href} className="footer__link">
                    {link.label}
                  </a>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Divider */}
        <div className="footer__divider" />

        {/* Bottom row */}
        <div className="footer__bottom">
          <p className="footer__copyright">
            © {new Date().getFullYear()} Prismatica S.L. Todos los derechos
            reservados.
          </p>
          <div className="footer__bottom-links">
            <p className="footer__disclaimer">
              Prismatica es una plataforma SaaS. Los datos almacenados son
              responsabilidad del usuario. Consulta nuestra{' '}
              <a href="#" className="footer__bottom-link">
                política de privacidad
              </a>{' '}
              y{' '}
              <a href="#" className="footer__bottom-link">
                términos de uso
              </a>{' '}
              para más información.
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}

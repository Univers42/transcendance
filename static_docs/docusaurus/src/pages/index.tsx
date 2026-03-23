import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HeroBanner() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={styles.hero}>
      <div className={styles.heroInner}>
        <div className={styles.heroGlow} />
        <Heading as="h1" className={styles.heroTitle}>
          <span className={styles.heroTitleGradient}>Prismatica</span>
        </Heading>
        <p className={styles.heroSubtitle}>{siteConfig.tagline}</p>
        <p className={styles.heroDescription}>
          A polymorphic data platform that unifies PostgreSQL and MongoDB behind
          a single API — with real-time sync, ABAC security, and a visual
          dashboard built for exploration.
        </p>
        <div className={styles.heroButtons}>
          <Link className={styles.heroBtnPrimary} to="/docs/intro">
            Get Started
          </Link>
          <Link className={styles.heroBtnSecondary} to="/docs/architecture">
            Architecture →
          </Link>
        </div>
      </div>
    </header>
  );
}

type FeatureItem = {
  icon: string;
  title: string;
  description: string;
  link: string;
};

const features: FeatureItem[] = [
  {
    icon: '🗄️',
    title: 'Dual-Database Engine',
    description:
      'PostgreSQL for relational data with full ABAC security. MongoDB for flexible documents, preferences, and caching. One unified API.',
    link: '/docs/architecture',
  },
  {
    icon: '🔌',
    title: 'REST Data API',
    description:
      'Express-based data-api with CRUD routes for both SQL and NoSQL. Dynamic collection endpoints, seed runners, and health checks built in.',
    link: '/docs/api',
  },
  {
    icon: '🎨',
    title: 'Data Explorer Dashboard',
    description:
      'React 19 + Vite 6 frontend with real-time table browsing. Switch between SQL tables and NoSQL collections in one interface.',
    link: '/docs/design/design-system',
  },
  {
    icon: '🐳',
    title: 'Docker-First Infrastructure',
    description:
      'Full Docker Compose stack: PostgreSQL, MongoDB, data-api, and frontend — all orchestrated with a single `make dev` command.',
    link: '/docs/setup',
  },
  {
    icon: '🔐',
    title: 'ABAC Security Model',
    description:
      'Attribute-Based Access Control baked into the SQL schema. Row-level policies, organization scoping, and audit logging from day one.',
    link: '/docs/database/sql-diagram',
  },
  {
    icon: '📐',
    title: 'Comprehensive Schema Design',
    description:
      '12 SQL schema modules, 13 NoSQL collections, views, triggers, and seed data — all documented with entity diagrams.',
    link: '/docs/database/sql-diagram',
  },
];

function FeatureCard({icon, title, description, link}: FeatureItem) {
  return (
    <Link to={link} className={styles.featureCard}>
      <div className={styles.featureIcon}>{icon}</div>
      <Heading as="h3" className={styles.featureTitle}>{title}</Heading>
      <p className={styles.featureDesc}>{description}</p>
    </Link>
  );
}

function FeaturesSection() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <Heading as="h2" className={styles.sectionTitle}>
            Platform Capabilities
          </Heading>
          <p className={styles.sectionSubtitle}>
            Everything you need to manage polymorphic data at scale
          </p>
        </div>
        <div className={styles.featureGrid}>
          {features.map((feat, idx) => (
            <FeatureCard key={idx} {...feat} />
          ))}
        </div>
      </div>
    </section>
  );
}

function QuickLinksSection() {
  return (
    <section className={styles.quickLinks}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <Heading as="h2" className={styles.sectionTitle}>
            Quick Navigation
          </Heading>
        </div>
        <div className={styles.linkGrid}>
          <Link to="/docs/intro" className={styles.linkCard}>
            <span className={styles.linkIcon}>📖</span>
            <div>
              <strong>Introduction</strong>
              <span>Project overview and goals</span>
            </div>
          </Link>
          <Link to="/docs/setup" className={styles.linkCard}>
            <span className={styles.linkIcon}>⚡</span>
            <div>
              <strong>Setup Guide</strong>
              <span>Get running in minutes</span>
            </div>
          </Link>
          <Link to="/docs/api" className={styles.linkCard}>
            <span className={styles.linkIcon}>🔗</span>
            <div>
              <strong>API Reference</strong>
              <span>REST endpoints and routes</span>
            </div>
          </Link>
          <Link to="/docs/contributing" className={styles.linkCard}>
            <span className={styles.linkIcon}>🤝</span>
            <div>
              <strong>Contributing</strong>
              <span>Branch workflow and conventions</span>
            </div>
          </Link>
          <Link to="/docs/strategy/mini-baas" className={styles.linkCard}>
            <span className={styles.linkIcon}>🧠</span>
            <div>
              <strong>Mini-BaaS Strategy</strong>
              <span>Architecture decisions</span>
            </div>
          </Link>
          <Link to="/docs/faq" className={styles.linkCard}>
            <span className={styles.linkIcon}>❓</span>
            <div>
              <strong>FAQ</strong>
              <span>Common questions answered</span>
            </div>
          </Link>
        </div>
      </div>
    </section>
  );
}

function TechStackSection() {
  const techs = [
    {name: 'React 19', cat: 'Frontend'},
    {name: 'Vite 6', cat: 'Build'},
    {name: 'TypeScript 5', cat: 'Language'},
    {name: 'Express', cat: 'API'},
    {name: 'PostgreSQL 16', cat: 'SQL'},
    {name: 'MongoDB 7', cat: 'NoSQL'},
    {name: 'Docker', cat: 'Infra'},
    {name: 'NestJS', cat: 'Backend'},
  ];

  return (
    <section className={styles.techStack}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <Heading as="h2" className={styles.sectionTitle}>Tech Stack</Heading>
        </div>
        <div className={styles.techGrid}>
          {techs.map((t, i) => (
            <div key={i} className={styles.techBadge}>
              <span className={styles.techName}>{t.name}</span>
              <span className={styles.techCat}>{t.cat}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout
      title="Prismatica — Polymorphic Data Platform"
      description="Documentation for Prismatica: a polymorphic data platform unifying PostgreSQL and MongoDB with real-time sync, ABAC security, and a visual dashboard.">
      <HeroBanner />
      <main>
        <FeaturesSection />
        <QuickLinksSection />
        <TechStackSection />
      </main>
    </Layout>
  );
}

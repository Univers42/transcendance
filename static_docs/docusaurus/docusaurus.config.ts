import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Prismatica',
  tagline: 'Polymorphic Data Platform — Documentation',
  favicon: 'img/favicon.ico',

  url: 'https://univers42.github.io',
  baseUrl: '/',

  organizationName: 'univers42',
  projectName: 'transcendance',

  onBrokenLinks: 'warn',

  markdown: {
    format: 'md',
  },

  plugins: [
    function enableHMR() {
      return {
        name: 'enable-hmr',
        configureWebpack(config, isServer) {
          if (isServer) return {};
          // Docusaurus 3.x + Node 25: webpack-dev-server may not inject
          // HotModuleReplacementPlugin automatically. Force it via plugins.
          const webpack = require('webpack');
          return {
            plugins: [new webpack.HotModuleReplacementPlugin()],
          };
        },
      };
    },
  ],

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/Univers42/ft_transcendence/tree/develop/static_docs/docusaurus/',
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          editUrl:
            'https://github.com/Univers42/ft_transcendence/tree/develop/static_docs/docusaurus/',
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Prismatica',
      logo: {
        alt: 'Prismatica Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {to: '/blog', label: 'Blog', position: 'left'},
        {
          href: 'https://github.com/Univers42/ft_transcendence',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {label: 'Getting Started', to: '/docs/intro'},
            {label: 'Architecture', to: '/docs/architecture'},
            {label: 'API Reference', to: '/docs/api'},
            {label: 'Setup Guide', to: '/docs/setup'},
          ],
        },
        {
          title: 'Project',
          items: [
            {label: 'Contributing', to: '/docs/contributing'},
            {label: 'Changelog', to: '/docs/changelog'},
            {label: 'FAQ', to: '/docs/faq'},
          ],
        },
        {
          title: 'Links',
          items: [
            {label: 'Blog', to: '/blog'},
            {
              label: 'GitHub',
              href: 'https://github.com/Univers42/ft_transcendence',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Univers42 — Prismatica. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'sql', 'json', 'typescript', 'scss'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;

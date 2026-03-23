import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: ['setup', 'architecture', 'api', 'subject'],
    },
    {
      type: 'category',
      label: 'Strategy',
      items: [
        'strategy/mini-baas',
        'strategy/infrastructure',
        'strategy/refactoring-plan',
      ],
    },
    {
      type: 'category',
      label: 'Design',
      items: ['design/design-system', 'design/frontend-design'],
    },
    {
      type: 'category',
      label: 'Database',
      items: [
        'database/sql-diagram',
        'database/nosql-diagram',
        'database/sql-norm',
        'database/business-mindmap',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: ['faq', 'troubleshooting', 'changelog'],
    },
    {
      type: 'category',
      label: 'Community',
      items: ['contributing', 'code-of-conduct', 'security', 'contributors'],
    },
    {
      type: 'category',
      label: 'Fixes & Workarounds',
      collapsed: true,
      items: ['fixes/prisma-datasource', 'fixes/broken-submodule'],
    },
  ],
};

export default sidebars;

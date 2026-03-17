/**
 * @file Sidebar.tsx
 * @description Refactored Prismatica Sidebar.
 */
import { 
  Building2, Folder, Database, LayoutDashboard, 
  Plug, ChevronDown, ChevronRight, 
  Moon, Sun, PanelLeftClose, PanelLeft
} from 'lucide-react';
import { clsx } from 'clsx';
import { useState } from 'react';

interface SidebarProps {
  isOpen: boolean;
  onToggle: () => void;
  isMobile: boolean;
  isDarkMode: boolean;
  onToggleTheme: () => void;
}

export function Sidebar({ isOpen, onToggle, isMobile, isDarkMode, onToggleTheme }: SidebarProps) {
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    'Workspace': true,
    'Build': true
  });

  const toggleSection = (title: string) => {
    if (!isOpen) {
      onToggle();
      setExpandedSections(prev => ({ ...prev, [title]: true }));
      return;
    }
    setExpandedSections(prev => ({ ...prev, [title]: !prev[title] }));
  };

  const navSections = [
    {
      title: 'Workspace',
      items: [
        { id: 'dashboards', label: 'Dashboards', icon: LayoutDashboard, path: '/app' },
        { id: 'projects', label: 'Projects', icon: Folder, path: '/app/projects' },
        { id: 'organizations', label: 'Organizations', icon: Building2, path: '/app/orgs' },
      ]
    },
    {
      title: 'Build',
      items: [
        { id: 'collections', label: 'Collections', icon: Database, path: '/app/collections' },
        { id: 'adapters', label: 'Adapters', icon: Plug, path: '/app/adapters' },
      ]
    }
  ];

  return (
    <>
      {isMobile && isOpen && (
        <div className="fixed inset-0 bg-black/50 z-40" onClick={onToggle} />
      )}
      
      <aside className={clsx("sidebar", isOpen && "sidebar--open")}>
        {/* Header: Logo & Toggle */}
        <div className="sidebar__header">
          <div className="flex items-center">
            <div className="sidebar__logo-box">
              <div className="sidebar__logo-box-icon" />
            </div>
            {isOpen && <span className="sidebar__brand-name">PRISMATICA</span>}
          </div>
          {!isMobile && (
            <button onClick={onToggle} className="p-1 hover:bg-hover rounded">
              {isOpen ? <PanelLeftClose size={20} /> : <PanelLeft size={20} />}
            </button>
          )}
        </div>

        {/* Navigation */}
        <nav className="sidebar__nav">
          {navSections.map((section) => (
            <div key={section.title} className="mb-4">
              <div 
                className="sidebar__section-title" 
                onClick={() => toggleSection(section.title)}
              >
                {isOpen ? (
                  <>
                    <span>{section.title}</span>
                    {expandedSections[section.title] ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                  </>
                ) : (
                  <span>{section.title.substring(0, 1)}</span>
                )}
              </div>

              {(expandedSections[section.title] || !isOpen) && (
                <div className="mt-1">
                </div>
              )}
            </div>
          ))}
        </nav>

        {/* Footer: User & Theme */}
        <div className="sidebar__footer">
          <div className={clsx("sidebar__user", !isOpen && "justify-center")}>
            <div className="sidebar__avatar">DJ</div>
            {isOpen && (
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold truncate">DJ Surgeon</span>
                <span className="text-xs text-tertiary">Admin</span>
              </div>
            )}
          </div>
          <button 
            onClick={onToggleTheme} 
            className={clsx("sidebar__item", !isOpen && "justify-center")}
          >
            {isDarkMode ? <Sun size={20} /> : <Moon size={20} />}
            {isOpen && <span>{isDarkMode ? 'Light Mode' : 'Dark Mode'}</span>}
          </button>
        </div>
      </aside>
    </>
  );
}
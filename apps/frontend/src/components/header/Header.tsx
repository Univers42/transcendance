/**
 * @file AppHeader.tsx
 * @description Refactored Header for Prismatica App Shell.
 */
import React, { useState, useRef, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  Menu, Search, Bell, ChevronRight, User, Settings, 
  HelpCircle, BookOpen, LogOut, Building2, Folder, 
  LayoutTemplate, Database, LayoutDashboard, Layers, Globe 
} from 'lucide-react';
import { clsx } from 'clsx';

interface AppHeaderProps {
  onMenuClick: () => void;
}

export function AppHeader({ onMenuClick }: AppHeaderProps) {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [isSearchExpanded, setIsSearchExpanded] = useState(false);
  
  // Refs para cerrar al hacer clic fuera
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setIsProfileOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <header className="header">
      {/* Lado Izquierdo: Mobile Toggle & Breadcrumbs */}
      <div className="header__left">
        <button onClick={onMenuClick} className="md:hidden p-2 hover:bg-hover rounded">
          <Menu size={20} />
        </button>
        
        <nav className="breadcrumb hidden md:flex">
          <span className="breadcrumb__item">Prismatica</span>
          <ChevronRight size={14} className="text-tertiary" />
          <span className="breadcrumb__item breadcrumb__item--active">Dashboard</span>
        </nav>
      </div>

      {/* Centro: Título Dinámico */}
      <h1 className="header__title">Overview</h1>

      {/* Lado Derecho: Search, Notifications & Profile */}
      <div className="header__right">
        
        <div className={clsx("header__search", isSearchExpanded && "header__search--expanded")}>
          <Search size={16} className={isSearchExpanded ? "text-accent" : "text-tertiary"} />
          <input 
            type="text" 
            placeholder="Search assets..." 
            onFocus={() => setIsSearchExpanded(true)}
            onBlur={() => setIsSearchExpanded(false)}
          />
        </div>

        <button className="p-2 hover:bg-hover rounded text-secondary relative">
          <Bell size={20} />
          <span className="absolute top-2 right-2 w-2 h-2 bg-error rounded-full border-2 border-primary" />
        </button>

        <div className="relative" ref={profileRef}>
          <button 
            onClick={() => setIsProfileOpen(!isProfileOpen)}
            className={clsx("p-2 rounded-lg transition-colors", isProfileOpen ? "bg-hover text-accent" : "text-secondary hover:bg-hover")}
          >
            <User size={20} />
          </button>

          {isProfileOpen && (
            <div className="header__dropdown">
              <div className="p-4 border-b border-default bg-secondary">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-accent text-white flex-center font-bold">JD</div>
                  <div>
                    <div className="text-sm font-bold">John Doe</div>
                    <div className="text-xs text-tertiary">john@prismatica.io</div>
                  </div>
                </div>
              </div>
              
              <div className="p-2">
                <button className="sidebar__item w-full" onClick={() => navigate('/settings')}>
                  <Settings size={16} /> Account Settings
                </button>
                <div className="h-px bg-default my-2" />
                <button className="sidebar__item w-full text-error" onClick={() => navigate('/login')}>
                  <LogOut size={16} /> Sign Out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
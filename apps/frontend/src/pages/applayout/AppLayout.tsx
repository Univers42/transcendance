/**
 * @file AppLayout.tsx
 * @description Main shell for the authenticated area. 
 * Orchestrates Sidebar, Header and dynamic content via Outlet.
 */

import { useState, useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Sidebar } from '../components/sidebar/Sidebar';
import { AppHeader } from '../components/header/AppHeader';

export function AppLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const { pathname } = useLocation(); // La URL nos dice qué "tab" está activa

  // Lógica de Responsividad
  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      // En escritorio empezamos abierto, en móvil cerrado
      setIsSidebarOpen(!mobile);
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Cerrar sidebar automáticamente al cambiar de ruta en móvil
  useEffect(() => {
    if (isMobile) setIsSidebarOpen(false);
  }, [pathname, isMobile]);

  return (
    <div className="app-shell">
      <Sidebar 
        isOpen={isSidebarOpen} 
        onToggle={() => setIsSidebarOpen(!isSidebarOpen)}
        isMobile={isMobile}
      />
      
      <div className="app-shell__main">
        <AppHeader 
          onMenuClick={() => setIsSidebarOpen(!isSidebarOpen)} 
          isSidebarOpen={isSidebarOpen}
        />
        
        <main id="main-content" className="app-shell__content">
          <div className="app-shell__container">
            {/* Aquí es donde React Router inyectará el AdminDashboard */}
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
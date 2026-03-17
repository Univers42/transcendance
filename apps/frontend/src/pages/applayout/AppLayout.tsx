import { useState, useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Sidebar } from '@/components/sidebar/Sidebar';
import { AppHeader } from '@/components/header/Header';

// 1. Interfaz para las props
interface AppLayoutProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
}

// 2. APLICAR la interfaz aquí (esto quita el error TS6196 y TS2322)
export function AppLayout({ isDarkMode, onToggleTheme }: AppLayoutProps) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const { pathname } = useLocation();

  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      setIsSidebarOpen(!mobile);
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    if (isMobile) setIsSidebarOpen(false);
  }, [pathname, isMobile]);

  return (
    <div className="app-shell">
      <Sidebar 
        isOpen={isSidebarOpen} 
        onToggle={() => setIsSidebarOpen(!isSidebarOpen)}
        isMobile={isMobile}
        // 3. Pasamos las props al Sidebar (quita el error TS2739)
        isDarkMode={isDarkMode}
        onToggleTheme={onToggleTheme}
      />
      
      <div className="app-shell__main">
        <AppHeader 
          onMenuClick={() => setIsSidebarOpen(!isSidebarOpen)} 
          // 4. Eliminamos isSidebarOpen (quita el error TS2322)
        />
        
        <main id="main-content" className="app-shell__content">
          <div className="app-shell__container">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
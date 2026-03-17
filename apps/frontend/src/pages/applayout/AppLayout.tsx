import { useState, useEffect } from "react";
import { Outlet, useLocation } from "react-router-dom";
import { Sidebar } from "@/components/sidebar/Sidebar";
import { AppHeader } from "@/components/header/Header";
import type { AppLayoutProps } from "./AppLayout.types";

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
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
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
        isDarkMode={isDarkMode}
        onToggleTheme={onToggleTheme}
      />

      <div className="app-shell__main">
        <AppHeader onMenuClick={() => setIsSidebarOpen(!isSidebarOpen)} />

        <main id="main-content" className="app-shell__content">
          <div className="app-shell__container">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
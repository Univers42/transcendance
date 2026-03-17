export interface SidebarProps {
  isOpen: boolean;
  onToggle: () => void;
  isMobile: boolean;
  isDarkMode: boolean;
  onToggleTheme: () => void;
}

export interface SidebarNavItem {
  id: string;
  label: string;
  icon: React.ComponentType<{ size?: number }>;
  path: string;
}

export interface SidebarSection {
  title: string;
  items: SidebarNavItem[];
}
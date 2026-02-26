import type { NavLink } from "./types";

interface NavLinksProps {
  links: readonly NavLink[];
  onClick?: () => void;
  variant?: "desktop" | "mobile";
}

export function NavLinks({
  links,
  onClick,
  variant = "desktop",
}: NavLinksProps) {
  const baseClass =
    variant === "desktop"
      ? "px-4 py-2 rounded-lg"
      : "flex items-center px-4 py-3 rounded-xl";

  return (
    <>
      {links.map((link) => (
        <a
          key={link.label}
          href={link.href}
          onClick={onClick}
          className={`${baseClass} transition-colors duration-150`}
          style={{ fontSize: "14px" }}
        >
          {link.label}
        </a>
      ))}
    </>
  );
}

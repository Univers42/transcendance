// ============================================
// Prisma Config — ft_transcendence
// ============================================
// Required since Prisma 7: database URL moved from
// schema.prisma to this config file.
//
// See: https://pris.ly/d/config-datasource
// ============================================

import "dotenv/config";
import { defineConfig } from "prisma/config";

// Fallback URL for CI/generate-only scenarios (not used for actual connections)
const DATABASE_URL = process.env.DATABASE_URL || "postgresql://placeholder:placeholder@localhost:5432/placeholder";

export default defineConfig({
  // Schema location
  schema: "prisma/schema.prisma",

  // Database connection (used by Prisma CLI: migrate, studio, etc.)
  datasource: {
    url: DATABASE_URL,
  },

  // Migrations directory
  migrations: {
    path: "prisma/migrations",
  },
});

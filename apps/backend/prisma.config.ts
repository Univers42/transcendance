// ============================================
// Prisma Config — ft_transcendence
// ============================================
// Required since Prisma 7: database URL moved from
// schema.prisma to this config file.
//
// See: https://pris.ly/d/config-datasource
// ============================================

import "dotenv/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  // Schema location
  schema: "prisma/schema.prisma",

  // Database connection (used by Prisma CLI: migrate, studio, etc.)
  datasource: {
    url: env("DATABASE_URL"),
  },

  // Migrations directory
  migrations: {
    path: "prisma/migrations",
  },
});

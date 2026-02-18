// ============================================
// ft_transcendence — Root Application Module
// ============================================
// Wires together ALL feature modules.
// Each module maps to an IV.1 Web requirement.
// ============================================

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';

// Feature modules (uncomment as you implement them)
// import { AuthModule } from './auth/auth.module';
// import { UsersModule } from './users/users.module';
// import { ChatModule } from './chat/chat.module';
// import { GameModule } from './game/game.module';
// import { NotificationsModule } from './notifications/notifications.module';
// import { FilesModule } from './files/files.module';
// import { SearchModule } from './search/search.module';
// import { PrismaModule } from './prisma/prisma.module';
// import { RedisModule } from './redis/redis.module';

@Module({
  imports: [
    // ── Configuration ───────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // ── Rate Limiting (API key + public) ────────────
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,  // 1 second
        limit: 3,   // 3 requests per second
      },
      {
        name: 'medium',
        ttl: 10000, // 10 seconds
        limit: 20,
      },
      {
        name: 'long',
        ttl: 60000, // 1 minute
        limit: 100,
      },
    ]),

    // ── Event System (notifications) ────────────────
    EventEmitterModule.forRoot(),

    // ── Scheduled Tasks ─────────────────────────────
    ScheduleModule.forRoot(),

    // ── Feature Modules ─────────────────────────────
    // Uncomment these as you build them:
    // PrismaModule,    // ORM — database access
    // RedisModule,     // Cache + pub/sub
    // AuthModule,      // JWT + OAuth 42
    // UsersModule,     // Profiles + friends
    // ChatModule,      // Real-time messaging (WebSocket)
    // GameModule,      // Pong game (WebSocket)
    // NotificationsModule,  // Push + email
    // FilesModule,     // Upload + management
    // SearchModule,    // Filters + pagination
  ],
})
export class AppModule {}

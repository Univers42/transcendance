// ── Chat Types ──────────────────────────────────────

export enum ChannelType {
  DIRECT = 'DIRECT',
  GROUP = 'GROUP',
  PUBLIC = 'PUBLIC',
}

export enum ChannelMemberRole {
  OWNER = 'OWNER',
  ADMIN = 'ADMIN',
  MEMBER = 'MEMBER',
}

export interface ChatMessagePayload {
  channelId: string;
  content: string;
}

export interface ChatMessageResponse {
  id: string;
  content: string;
  senderId: string;
  senderUsername: string;
  channelId: string;
  createdAt: string;
}

// ── WebSocket Events ────────────────────────────────

export const WS_EVENTS = {
  // Chat
  CHAT_SEND: 'chat:send',
  CHAT_RECEIVE: 'chat:receive',
  CHAT_TYPING: 'chat:typing',
  CHAT_JOIN_CHANNEL: 'chat:join',
  CHAT_LEAVE_CHANNEL: 'chat:leave',

  // Presence
  USER_ONLINE: 'user:online',
  USER_OFFLINE: 'user:offline',
  USER_STATUS: 'user:status',

  // Notifications
  NOTIFICATION_NEW: 'notification:new',
} as const;

// ── Game Types ──────────────────────────────────────

export enum GameStatus {
  WAITING = 'WAITING',
  IN_PROGRESS = 'IN_PROGRESS',
  FINISHED = 'FINISHED',
  CANCELLED = 'CANCELLED',
}

export interface GameState {
  ball: { x: number; y: number; vx: number; vy: number };
  paddle1: { y: number };
  paddle2: { y: number };
  score: { player1: number; player2: number };
  status: GameStatus;
}

export interface GameResult {
  id: string;
  player1Id: string;
  player2Id: string;
  player1Score: number;
  player2Score: number;
  winnerId: string | null;
  finishedAt: string;
}

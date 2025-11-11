export interface Hint {
  id: string;
  content: string;
  type: string;
  order: number;
}

export interface Topic {
  id: string;
  answer: string;
  date: string;
  type: string;
  hints: Hint[];
  topicNumber: number;
}

export interface Submission {
  id: string;
  topicId: string;
  attempts: number;
  guesses: string[];
  duration: number;
  success: boolean;
  createdAt: string;
}

export interface GuessCount {
  guess: string;
  count: number;
}

export interface GameStats {
  totalSubmissions: number;
  avgGuessTime: number;
  fastestGuessTime: number;
  commonGuesses: GuessCount[];
}

export interface ModerationResponse {
  appropriate: boolean;
  message?: string;
}

export interface GameProgress {
  topicId: string;
  date: string;
  currentHintIndex: number;
  attempts: number;
  guesses: string[];
  startTime: number;
  completed: boolean;
  success: boolean;
}

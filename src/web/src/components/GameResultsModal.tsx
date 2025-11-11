import { useState } from 'react';
import { X, ChevronDown, ChevronUp, CheckCircle, XCircle, Target, Clock, Users, Zap, RefreshCw, Share2 } from 'lucide-react';
import { Dialog, DialogContent } from './ui/Dialog';
import { Button } from './ui/Button';
import type { GameStats } from '../types';

interface GameResultsModalProps {
  open: boolean;
  onClose: () => void;
  success: boolean;
  answer: string;
  attempts: number;
  duration: number;
  stats: GameStats | null;
  onStatsRefresh: () => Promise<void>;
}

export function GameResultsModal({
  open,
  onClose,
  success,
  answer,
  attempts,
  duration,
  stats,
  onStatsRefresh,
}: GameResultsModalProps) {
  const [statsExpanded, setStatsExpanded] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const formatTime = (seconds: number) => {
    if (seconds < 60) return `${seconds}s`;
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}m ${secs}s`;
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await onStatsRefresh();
    setRefreshing(false);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent className="text-center relative">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-purple-primary hover:text-purple-variant transition-colors cursor-pointer z-10"
        >
          <X className="w-6 h-6" />
        </button>

        <div className="mb-6 mt-2">
          {success ? (
            <CheckCircle className="w-16 h-16 text-success mx-auto mb-4" />
          ) : (
            <XCircle className="w-16 h-16 text-failure mx-auto mb-4" />
          )}
          <h2 className="text-3xl font-bold mb-2">{answer}</h2>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="glass rounded-2xl p-4">
            <Target className="w-8 h-8 text-purple-primary mx-auto mb-2" />
            <div className="text-sm opacity-60 mb-1">Attempts</div>
            <div className="text-2xl font-bold">{attempts}/5</div>
          </div>
          <div className="glass rounded-2xl p-4">
            <Clock className="w-8 h-8 text-purple-primary mx-auto mb-2" />
            <div className="text-sm opacity-60 mb-1">Time</div>
            <div className="text-2xl font-bold">{formatTime(duration)}</div>
          </div>
        </div>

        {stats && (
          <>
            <button
              className="w-full glass rounded-2xl p-4 mb-4 hover:bg-white/10 transition-all cursor-pointer flex items-center justify-between"
              onClick={() => {
                if (!statsExpanded) handleRefresh();
                setStatsExpanded(!statsExpanded);
              }}
            >
              <span className="font-semibold">Statistics</span>
              <div className="flex items-center gap-2">
                {refreshing && <RefreshCw className="w-4 h-4 animate-spin" />}
                {statsExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
              </div>
            </button>

            {statsExpanded && (
              <div className="space-y-4 mb-6">
                <div className="glass rounded-2xl p-4">
                  <h3 className="font-semibold mb-4 flex items-center justify-between">
                    <span>Top Guesses</span>
                  </h3>
                  <div className="space-y-2">
                    {stats.commonGuesses.slice(0, 5).map((guess) => (
                      <div
                        key={guess.guess}
                        className="flex items-center justify-between text-sm"
                      >
                        <span className="flex-1 text-left truncate">{guess.guess}</span>
                        <div className="flex items-center gap-2">
                          <div className="w-24 bg-white/10 rounded-full h-2">
                            <div
                              className="h-full bg-gradient-purple rounded-full"
                              style={{
                                width: `${(guess.count / stats.commonGuesses[0].count) * 100}%`,
                              }}
                            />
                          </div>
                          <span className="w-8 text-right font-medium">{guess.count}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  <div className="glass rounded-xl p-3">
                    <Users className="w-6 h-6 text-purple-primary mx-auto mb-1" />
                    <div className="text-xs opacity-60 mb-1">Players</div>
                    <div className="text-lg font-bold">{stats.totalSubmissions}</div>
                  </div>
                  <div className="glass rounded-xl p-3">
                    <Clock className="w-6 h-6 text-purple-primary mx-auto mb-1" />
                    <div className="text-xs opacity-60 mb-1">Avg Time</div>
                    <div className="text-lg font-bold">{formatTime(stats.avgGuessTime)}</div>
                  </div>
                  <div className="glass rounded-xl p-3">
                    <Zap className="w-6 h-6 text-purple-primary mx-auto mb-1" />
                    <div className="text-xs opacity-60 mb-1">Fastest</div>
                    <div className="text-lg font-bold">{formatTime(stats.fastestGuessTime)}</div>
                  </div>
                </div>
              </div>
            )}
          </>
        )}

        <Button onClick={() => navigator.share ? navigator.share({ text: `Decipher\n${success ? 'Success' : 'Failed'} ${attempts}/5 attempts\nTime: ${formatTime(duration)}\n\nPlay at: ${window.location.origin}` }) : navigator.clipboard.writeText(`Decipher\n${success ? 'Success' : 'Failed'} ${attempts}/5 attempts\nTime: ${formatTime(duration)}\n\nPlay at: ${window.location.origin}`)} className="w-full mb-3" size="lg">
          <Share2 className="w-4 h-4 mr-2" />
          Share Results
        </Button>
      </DialogContent>
    </Dialog>
  );
}

import { useState, useEffect, useRef } from 'react';
import { ArrowLeft, ChevronLeft, ChevronRight, Target, Clock, Tag, Lightbulb, HelpCircle, BookOpen, X } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { GameResultsModal } from '../components/GameResultsModal';
import { api } from '../services/api';
import { isCorrectGuess } from '../utils/guessMatcher';
import { saveGameProgress, loadGameProgress, clearGameProgress } from '../utils/gameState';
import type { Topic, GameStats } from '../types';

interface PlayProps {
  onBack: () => void;
}

export function Play({ onBack }: PlayProps) {
  const [topic, setTopic] = useState<Topic | null>(null);
  const [currentHintIndex, setCurrentHintIndex] = useState(0);
  const [maxUnlockedHint, setMaxUnlockedHint] = useState(0);
  const [guess, setGuess] = useState('');
  const [attempts, setAttempts] = useState(0);
  const [guesses, setGuesses] = useState<string[]>([]);
  const [startTime] = useState(Date.now());
  const [gameOver, setGameOver] = useState(false);
  const [success, setSuccess] = useState(false);
  const [stats, setStats] = useState<GameStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [moderationError, setModerationError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const MAX_ATTEMPTS = 5;

  useEffect(() => {
    loadGame();
  }, []);

  useEffect(() => {
    // Keyboard navigation - only navigate to unlocked hints
    const handleKeyDown = (e: KeyboardEvent) => {
      if (gameOver || submitting) return;
      
      if (e.key === 'ArrowLeft' && currentHintIndex > 0) {
        setCurrentHintIndex(i => i - 1);
      } else if (e.key === 'ArrowRight' && currentHintIndex < maxUnlockedHint && topic && currentHintIndex < topic.hints.length - 1) {
        setCurrentHintIndex(i => i + 1);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentHintIndex, topic, gameOver, maxUnlockedHint, submitting]);

  async function loadGame() {
    try {
      const savedProgress = loadGameProgress();
      const dailyTopic = await api.fetchDailyTopic();
      
      if (savedProgress && savedProgress.topicId === dailyTopic.id) {
        // Restore progress
        setTopic(dailyTopic);
        setCurrentHintIndex(savedProgress.currentHintIndex);
        setMaxUnlockedHint(savedProgress.currentHintIndex);
        setAttempts(savedProgress.attempts);
        setGuesses(savedProgress.guesses);
        
        if (savedProgress.completed) {
          setGameOver(true);
          setSuccess(savedProgress.success);
          setShowResults(true);
          const gameStats = await api.getStats(dailyTopic.id);
          setStats(gameStats);
        }
      } else {
        // New game
        clearGameProgress();
        setTopic(dailyTopic);
        setMaxUnlockedHint(0);
      }
      
      setLoading(false);
    } catch (err) {
      setError('Failed to load game');
      setLoading(false);
    }
  }

  function saveProgress(completed = false, won = false) {
    if (!topic) return;
    
    saveGameProgress({
      topicId: topic.id,
      date: new Date().toISOString().split('T')[0],
      currentHintIndex: maxUnlockedHint,
      attempts,
      guesses,
      startTime,
      completed,
      success: won,
    });
  }

  async function handleSubmitGuess() {
    if (!guess.trim() || !topic || submitting) return;

    setSubmitting(true);
    setModerationError(null);

    try {
      // First, moderate the guess
      const moderationResult = await api.moderateGuess(guess.trim());
      
      if (!moderationResult.appropriate) {
        setModerationError(moderationResult.message || 'Please keep your guesses appropriate.');
        setSubmitting(false);
        return;
      }

      const newAttempts = attempts + 1;
      const newGuesses = [...guesses, guess.trim()];
      
      setAttempts(newAttempts);
      setGuesses(newGuesses);

      const correct = isCorrectGuess(topic.answer, guess.trim());

      if (correct || newAttempts >= MAX_ATTEMPTS) {
        // Game over
        const duration = Math.floor((Date.now() - startTime) / 1000);
        setGameOver(true);
        setSuccess(correct);
        setShowResults(true);
        
        try {
          await api.submitGame({
            topicId: topic.id,
            attempts: newAttempts,
            guesses: newGuesses,
            duration,
            success: correct,
          });

          const gameStats = await api.getStats(topic.id);
          setStats(gameStats);
        } catch (err) {
          console.error('Failed to submit game:', err);
        }

        saveProgress(true, correct);
      } else {
        // Unlock next hint if available
        if (maxUnlockedHint < topic.hints.length - 1) {
          const newMaxHint = maxUnlockedHint + 1;
          setMaxUnlockedHint(newMaxHint);
          setCurrentHintIndex(newMaxHint);
        }
        saveProgress();
      }

      setGuess('');
    } catch (err) {
      console.error('Error processing guess:', err);
      setModerationError('Failed to process guess. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }

  function handleCloseResults() {
    setShowResults(false);
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-game flex items-center justify-center">
        <div className="text-2xl font-semibold text-purple-primary animate-pulse-primary">
          Loading...
        </div>
      </div>
    );
  }

  if (error || !topic) {
    return (
      <div className="min-h-screen bg-gradient-game flex flex-col items-center justify-center p-6 gap-6">
        <div className="text-6xl">😞</div>
        <p className="text-xl text-center">{error || 'Failed to load game'}</p>
        <Button onClick={onBack}>Go Back</Button>
      </div>
    );
  }

  const currentHint = topic.hints[currentHintIndex];
  const elapsedTime = Math.floor((Date.now() - startTime) / 1000);

  return (
    <div className="min-h-screen bg-gradient-game flex flex-col p-4 sm:p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-purple-primary hover:text-purple-variant transition-colors cursor-pointer group"
        >
          <ArrowLeft className="w-6 h-6 group-hover:-translate-x-1 transition-transform" />
          <span className="hidden sm:inline font-medium">Back</span>
        </button>
        <div className="text-center">
          <div className="text-sm font-semibold opacity-80 mb-1">Daily #{topic.topicNumber}</div>
          <div className="text-xs opacity-60 uppercase tracking-wider">{topic.type}</div>
        </div>
        <div className="w-20" />
      </div>

      {/* Progress Bar */}
      <div className="mb-8">
        <div className="flex items-center justify-between text-sm mb-3 opacity-80 font-medium">
          <span className="flex items-center gap-2">
            <Lightbulb className="w-4 h-4" />
            Hint {currentHintIndex + 1} of {maxUnlockedHint + 1}
          </span>
          <span className="flex items-center gap-2">
            <Target className="w-4 h-4" />
            {attempts}/{MAX_ATTEMPTS}
          </span>
        </div>
        <div className="w-full bg-white/10 rounded-full h-2.5 overflow-hidden shadow-inner">
          <div
            className="h-full bg-gradient-purple rounded-full transition-all duration-500 ease-out shadow-lg"
            style={{ width: `${((maxUnlockedHint + 1) / topic.hints.length) * 100}%` }}
          />
        </div>
      </div>

      {/* Hint Display */}
      <div className="flex-1 flex items-center justify-center mb-8 px-2">
        <div className="w-full max-w-3xl">
          <div className="glass rounded-3xl p-6 sm:p-8 md:p-12 text-center shadow-2xl transform transition-all duration-300">
            <div className="mb-6">
              {getHintIcon(currentHint.type)}
            </div>
            <div className="text-xs uppercase tracking-widest mb-6 opacity-70 font-bold">
              {currentHint.type}
            </div>
            <div className="text-xl sm:text-2xl md:text-4xl font-bold leading-relaxed">
              {currentHint.content}
            </div>
          </div>

          {/* Hint Navigation */}
          <div className="flex items-center justify-center gap-6 mt-8">
            <button
              onClick={() => setCurrentHintIndex(i => Math.max(0, i - 1))}
              disabled={currentHintIndex === 0}
              className="p-3 rounded-full glass disabled:opacity-30 disabled:cursor-not-allowed hover:bg-white/10 transition-all cursor-pointer active:scale-95"
            >
              <ChevronLeft className="w-6 h-6 text-purple-primary" />
            </button>
            
            <div className="flex gap-2">
              {topic.hints.map((_, i) => (
                <button
                  key={i}
                  onClick={() => i <= maxUnlockedHint && setCurrentHintIndex(i)}
                  disabled={i > maxUnlockedHint}
                  className={`w-3 h-3 rounded-full transition-all ${
                    i === currentHintIndex
                      ? 'bg-purple-primary scale-125 shadow-lg'
                      : i <= maxUnlockedHint
                      ? 'bg-white/40 hover:bg-white/60 cursor-pointer'
                      : 'bg-white/10 cursor-not-allowed'
                  }`}
                />
              ))}
            </div>
            
            <button
              onClick={() => setCurrentHintIndex(i => Math.min(maxUnlockedHint, i + 1))}
              disabled={currentHintIndex >= maxUnlockedHint}
              className="p-3 rounded-full glass disabled:opacity-30 disabled:cursor-not-allowed hover:bg-white/10 transition-all cursor-pointer active:scale-95"
            >
              <ChevronRight className="w-6 h-6 text-purple-primary" />
            </button>
          </div>
        </div>
      </div>

      {/* Input Section */}
      {!gameOver && (
        <div className="w-full max-w-3xl mx-auto space-y-4">
          {moderationError && (
            <div className="glass rounded-2xl p-4 bg-failure/10 border-2 border-failure text-center">
              <p className="text-sm font-medium">{moderationError}</p>
            </div>
          )}
          
          <input
            ref={inputRef}
            type="text"
            value={guess}
            onChange={(e) => setGuess(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && !submitting && handleSubmitGuess()}
            placeholder="Type your answer..."
            disabled={attempts >= MAX_ATTEMPTS || submitting}
            className="w-full px-6 py-4 rounded-2xl glass text-lg font-medium focus:outline-none focus:ring-2 focus:ring-purple-primary bg-white/5 placeholder:opacity-50 transition-all"
            autoFocus
          />
          <Button
            onClick={handleSubmitGuess}
            disabled={!guess.trim() || attempts >= MAX_ATTEMPTS || submitting}
            className="w-full"
            size="lg"
          >
            {submitting ? 'Checking...' : 'Submit Guess'}
          </Button>
        </div>
      )}

      {/* Game Results Modal */}
      <GameResultsModal
        open={showResults}
        onClose={handleCloseResults}
        success={success}
        answer={topic.answer}
        attempts={attempts}
        duration={elapsedTime}
        stats={stats}
        onStatsRefresh={async () => {
          const freshStats = await api.getStats(topic.id);
          setStats(freshStats);
        }}
      />
    </div>
  );
}

function getHintIcon(type: string) {
  const iconClass = "w-12 h-12 text-purple-primary mx-auto";
  
  switch (type.toUpperCase()) {
    case 'CATEGORY':
      return <Tag className={iconClass} />;
    case 'DESCRIPTION':
    case 'DEFINITION':
      return <BookOpen className={iconClass} />;
    case 'CLUE':
      return <Target className={iconClass} />;
    case 'FACT':
    case 'TRIVIA':
      return <Lightbulb className={iconClass} />;
    case 'HINT':
      return <HelpCircle className={iconClass} />;
    case 'EMOJI':
      return <span className="text-5xl">{type}</span>;
    case 'QUOTE':
      return <span className="text-5xl">💬</span>;
    default:
      return <HelpCircle className={iconClass} />;
  }
}

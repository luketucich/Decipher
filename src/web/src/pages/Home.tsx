import { Heart, HelpCircle, Info, Play, Settings } from "lucide-react";
import { useState } from "react";
import { HowToPlayModal } from "../components/HowToPlayModal";
import { MatrixRain } from "../components/MatrixRain";
import { SettingsModal } from "../components/SettingsModal";
import { Button } from "../components/ui/Button";
import type { Theme } from "../utils/theme";

interface HomeProps {
  onPlayClick: () => void;
  theme: Theme;
  onThemeChange: (theme: Theme) => void;
}

export function Home({ onPlayClick, theme, onThemeChange }: HomeProps) {
  const [showHowToPlay, setShowHowToPlay] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-game flex flex-col items-center justify-center p-6 relative overflow-hidden">
      <MatrixRain />

      <div className="z-10 w-full max-w-md space-y-8">
        {/* Title Section */}
        <div className="text-center space-y-3">
          <h1 className="text-6xl md:text-7xl font-bold tracking-wider text-purple-primary drop-shadow-[0_4px_10px_rgba(163,51,255,0.3)] animate-pulse-primary" style={{ fontFamily: 'Righteous, sans-serif' }}>
            DECIPHER
          </h1>
          <p className="text-sm md:text-base tracking-widest opacity-70">
            Crack the Daily Topic
          </p>
        </div>

        {/* Play Button */}
        <Button
          onClick={onPlayClick}
          size="lg"
          className="w-full flex items-center justify-center gap-3 cursor-pointer"
        >
          <Play className="w-5 h-5 fill-current" />
          PLAY
        </Button>

        {/* Secondary Buttons */}
        <div className="grid grid-cols-2 gap-4">
          <Button
            onClick={(e) => {
              (e.target as HTMLElement).blur();
              setShowHowToPlay(true);
            }}
            variant="secondary"
            className="flex items-center justify-center gap-2 cursor-pointer"
          >
            <HelpCircle className="w-5 h-5" />
            How to Play
          </Button>

          <Button
            onClick={(e) => {
              (e.target as HTMLElement).blur();
              setShowSettings(true);
            }}
            variant="secondary"
            className="flex items-center justify-center gap-2 cursor-pointer"
          >
            <Settings className="w-5 h-5" />
            Settings
          </Button>
        </div>

        {/* Footer Links */}
        <div className="flex justify-center gap-6 text-sm">
          <button
            className="opacity-70 hover:opacity-100 transition-opacity flex items-center gap-1.5 cursor-pointer"
            onClick={() => window.open("/privacy", "_blank")}
          >
            <Info className="w-4 h-4" />
            About
          </button>
          <button
            className="opacity-70 hover:opacity-100 transition-opacity flex items-center gap-1.5 cursor-pointer"
            onClick={() => window.open("mailto:support@deciphergame.com")}
          >
            <Heart className="w-4 h-4" />
            Support
          </button>
        </div>
      </div>

      {/* Modals */}
      <HowToPlayModal
        open={showHowToPlay}
        onClose={() => setShowHowToPlay(false)}
      />
      <SettingsModal
        open={showSettings}
        onClose={() => setShowSettings(false)}
        theme={theme}
        onThemeChange={onThemeChange}
      />
    </div>
  );
}

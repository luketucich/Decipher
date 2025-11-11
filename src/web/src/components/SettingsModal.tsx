import { Monitor, Moon, Palette, Sun, X } from "lucide-react";
import type { Theme } from "../utils/theme";
import { Dialog, DialogContent } from "./ui/Dialog";

interface SettingsModalProps {
  open: boolean;
  onClose: () => void;
  theme: Theme;
  onThemeChange: (theme: Theme) => void;
}

export function SettingsModal({
  open,
  onClose,
  theme,
  onThemeChange,
}: SettingsModalProps) {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent className="max-w-sm">
        <div className="flex justify-between items-center mb-4">
          <div className="flex items-center gap-2">
            <Palette className="w-4 h-4 text-purple-primary" />
            <h2 className="text-lg font-bold tracking-wide text-purple-primary">
              SETTINGS
            </h2>
          </div>
          <button
            onClick={onClose}
            className="text-purple-primary/70 hover:text-purple-primary transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div>
          <p className="text-xs text-foreground/60 mb-2 uppercase tracking-wider">
            Theme
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => onThemeChange("light")}
              className={`flex-1 px-3 py-2 rounded-lg glass transition-all cursor-pointer hover:bg-white/10 ${
                theme === "light"
                  ? "bg-purple-primary/20 ring-1 ring-purple-primary"
                  : ""
              }`}
            >
              <Sun className="w-5 h-5 mx-auto text-purple-primary" />
            </button>
            <button
              onClick={() => onThemeChange("dark")}
              className={`flex-1 px-3 py-2 rounded-lg glass transition-all cursor-pointer hover:bg-white/10 ${
                theme === "dark"
                  ? "bg-purple-primary/20 ring-1 ring-purple-primary"
                  : ""
              }`}
            >
              <Moon className="w-5 h-5 mx-auto text-purple-primary" />
            </button>
            <button
              onClick={() => onThemeChange("auto")}
              className={`flex-1 px-3 py-2 rounded-lg glass transition-all cursor-pointer hover:bg-white/10 ${
                theme === "auto"
                  ? "bg-purple-primary/20 ring-1 ring-purple-primary"
                  : ""
              }`}
            >
              <Monitor className="w-5 h-5 mx-auto text-purple-primary" />
            </button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

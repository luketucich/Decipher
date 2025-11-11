import { Check, Lightbulb, Target, X } from "lucide-react";
import { Dialog, DialogContent } from "./ui/Dialog";

interface HowToPlayModalProps {
  open: boolean;
  onClose: () => void;
}

export function HowToPlayModal({ open, onClose }: HowToPlayModalProps) {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent className="max-w-sm">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-bold tracking-wide text-purple-primary">
            HOW TO PLAY
          </h2>
          <button
            onClick={onClose}
            className="text-purple-primary/70 hover:text-purple-primary transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="space-y-3 text-foreground">
          <div className="flex items-start gap-3">
            <div className="shrink-0 w-7 h-7 rounded-full bg-purple-primary/20 flex items-center justify-center">
              <Target className="w-4 h-4 text-purple-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-sm mb-0.5">Objective</h3>
              <p className="text-xs opacity-70 leading-relaxed">
                Guess with as few hints as possible
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="shrink-0 w-7 h-7 rounded-full bg-purple-primary/20 flex items-center justify-center">
              <Lightbulb className="w-4 h-4 text-purple-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-sm mb-0.5">Hints</h3>
              <p className="text-xs opacity-70 leading-relaxed">
                5 hints. Swipe left/right or use arrow keys to navigate
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="shrink-0 w-7 h-7 rounded-full bg-purple-primary/20 flex items-center justify-center">
              <Check className="w-4 h-4 text-purple-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-sm mb-0.5">Win</h3>
              <p className="text-xs opacity-70 leading-relaxed">
                Guess correctly on any hint
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="shrink-0 w-7 h-7 rounded-full bg-purple-primary/20 flex items-center justify-center">
              <X className="w-4 h-4 text-purple-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-sm mb-0.5">Lose</h3>
              <p className="text-xs opacity-70 leading-relaxed">
                5 wrong guesses and you're out
              </p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

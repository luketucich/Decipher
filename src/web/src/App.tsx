import { useEffect, useState } from "react";
import { Home } from "./pages/Home";
import { Play } from "./pages/Play";
import {
  applyTheme,
  getStoredTheme,
  setStoredTheme,
  type Theme,
} from "./utils/theme";

type Screen = "home" | "play";

function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>("home");
  const [theme, setTheme] = useState<Theme>(() => getStoredTheme());

  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  useEffect(() => {
    // Listen for system theme changes when in auto mode
    if (theme === "auto") {
      const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
      const handleChange = () => applyTheme(theme);
      mediaQuery.addEventListener("change", handleChange);
      return () => mediaQuery.removeEventListener("change", handleChange);
    }
  }, [theme]);

  const handleThemeChange = (newTheme: Theme) => {
    setTheme(newTheme);
    setStoredTheme(newTheme);
    applyTheme(newTheme);
  };

  return (
    <>
      {currentScreen === "home" && (
        <Home
          onPlayClick={() => setCurrentScreen("play")}
          theme={theme}
          onThemeChange={handleThemeChange}
        />
      )}
      {currentScreen === "play" && (
        <Play onBack={() => setCurrentScreen("home")} />
      )}
    </>
  );
}

export default App;

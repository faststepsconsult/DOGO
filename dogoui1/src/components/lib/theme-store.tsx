import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

export type DogoTheme = "black" | "white";

type ThemeContextValue = {
  theme: DogoTheme;
  setTheme: (theme: DogoTheme) => void;
  toggleTheme: () => void;
};

const STORAGE_KEY = "dogo.theme.v1";
const ThemeContext = createContext<ThemeContextValue | null>(null);

function applyTheme(theme: DogoTheme) {
  const root = document.documentElement;
  root.classList.remove("black", "white");
  root.classList.add(theme);
  root.dataset["theme"] = theme;
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<DogoTheme>("black");

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    const initial: DogoTheme = stored === "white" ? "white" : "black";
    setThemeState(initial);
    applyTheme(initial);
  }, []);

  const value = useMemo<ThemeContextValue>(
    () => ({
      theme,
      setTheme: (next) => {
        setThemeState(next);
        applyTheme(next);
        localStorage.setItem(STORAGE_KEY, next);
      },
      toggleTheme: () => {
        const next = theme === "black" ? "white" : "black";
        setThemeState(next);
        applyTheme(next);
        localStorage.setItem(STORAGE_KEY, next);
      },
    }),
    [theme],
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error("useTheme must be used inside ThemeProvider");
  return context;
}

export const themeInitScript = `
  try {
    var theme = localStorage.getItem('${STORAGE_KEY}') === 'white' ? 'white' : 'black';
    document.documentElement.classList.add(theme);
    document.documentElement.dataset.theme = theme;
  } catch (_) {
    document.documentElement.classList.add('black');
    document.documentElement.dataset.theme = 'black';
  }
`;
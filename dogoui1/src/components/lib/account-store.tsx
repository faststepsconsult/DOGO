import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

export type Role = "customer" | "rider" | "vendor";

export type VerificationTier = "kyc" | "kyv" | "kyb" | "kyw";
export type VerificationStatus = "unverified" | "review" | "verified";

export type Account = {
  name: string;
  email: string;
  phone: string;
  role: Role;
  businessName?: string | undefined;
  vehicle?: string | undefined;
  plate?: string | undefined;
  online?: boolean | undefined;
  verification: Record<VerificationTier, VerificationStatus>;
};

type Ctx = {
  account: Account | null;
  signIn: (a: Omit<Account, "verification"> & { verification?: Account["verification"] | undefined }) => void;
  signOut: () => void;
  update: (patch: Partial<Account>) => void;
  setVerification: (tier: VerificationTier, status: VerificationStatus) => void;
};

const AccountContext = createContext<Ctx | null>(null);
const KEY = "dogo.account.v1";

export const emptyVerification: Record<VerificationTier, VerificationStatus> = {
  kyc: "unverified",
  kyv: "unverified",
  kyb: "unverified",
  kyw: "unverified",
};

export function AccountProvider({ children }: { children: ReactNode }) {
  const [account, setAccount] = useState<Account | null>(null);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) setAccount(JSON.parse(raw) as Account);
    } catch {
      /* ignore */
    }
  }, []);

  function persist(next: Account | null) {
    setAccount(next);
    try {
      if (next) localStorage.setItem(KEY, JSON.stringify(next));
      else localStorage.removeItem(KEY);
    } catch {
      /* ignore */
    }
  }

  const value = useMemo<Ctx>(
    () => ({
      account,
      signIn: (a) => persist({ ...a, verification: a.verification ?? { ...emptyVerification } }),
      signOut: () => persist(null),
      update: (patch) => {
        if (!account) return;
        persist({ ...account, ...patch });
      },
      setVerification: (tier, status) => {
        if (!account) return;
        persist({ ...account, verification: { ...account.verification, [tier]: status } });
      },
    }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [account],
  );

  return <AccountContext.Provider value={value}>{children}</AccountContext.Provider>;
}

export function useAccount() {
  const ctx = useContext(AccountContext);
  if (!ctx) throw new Error("useAccount must be used inside AccountProvider");
  return ctx;
}

export const roleLabels: Record<Role, string> = {
  customer: "Passenger",
  rider: "Rider / Driver",
  vendor: "Previous account",
};

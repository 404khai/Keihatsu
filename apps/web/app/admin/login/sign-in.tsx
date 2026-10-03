"use client";
import Script from "next/script";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (options: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (
            element: HTMLElement,
            options: Record<string, string | number>,
          ) => void;
        };
      };
    };
  }
}
export function GoogleSignIn({ clientId }: { clientId: string }) {
  const button = useRef<HTMLDivElement>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const router = useRouter();
  function initialize() {
    if (!window.google || !button.current || !clientId) return;
    window.google.accounts.id.initialize({
      client_id: clientId,
      callback: async ({ credential }) => {
        setBusy(true);
        setError("");
        try {
          const response = await fetch("/api/admin/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ credential }),
          });
          const result = await response.json();
          if (!response.ok) throw new Error(result.error);
          router.replace("/admin");
          router.refresh();
        } catch (e) {
          setError(e instanceof Error ? e.message : "Unable to sign in.");
        } finally {
          setBusy(false);
        }
      },
    });
    window.google.accounts.id.renderButton(button.current, {
      theme: "outline",
      size: "large",
      shape: "pill",
      width: 320,
      text: "signin_with",
    });
  }
  return (
    <>
      <Script
        src="https://accounts.google.com/gsi/client"
        onReady={initialize}
        onError={() =>
          setError("Google sign-in could not load. Please refresh to retry.")
        }
      />
      <div ref={button} className="google-sign-in" aria-busy={busy} />
      {busy && <p role="status">Verifying your access…</p>}
      {!clientId && (
        <p role="alert">Google sign-in has not been configured yet.</p>
      )}
      {error && <p role="alert">{error}</p>}
    </>
  );
}

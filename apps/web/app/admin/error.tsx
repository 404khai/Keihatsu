"use client";
export default function AdminError({ reset }: { reset: () => void }) {
  return (
    <div className="admin-panel">
      <h1>Workspace temporarily unavailable</h1>
      <p>We couldn’t load your session or metrics.</p>
      <button className="admin-button" onClick={reset}>
        Try again
      </button>
      <a href="/admin/login">Return to sign in</a>
    </div>
  );
}

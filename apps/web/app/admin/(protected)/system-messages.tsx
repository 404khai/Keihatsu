"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { Announcement } from "@/lib/admin/types";

export function SystemMessages({ messages }: { messages: Announcement[] }) {
  const router = useRouter();
  const sending = useRef(false);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [severity, setSeverity] = useState("INFO");
  const [pushEnabled, setPushEnabled] = useState(false);
  const [reviewing, setReviewing] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  async function send() {
    if (sending.current) return;
    sending.current = true;
    setBusy(true);
    setError("");
    setNotice("");
    try {
      const response = await fetch("/api/admin/announcements", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, body, severity, pushEnabled }),
      });
      const result = await response.json();
      if (!response.ok)
        throw new Error(
          result.error ||
            "Unable to confirm sending. Check message history before retrying.",
        );
      setTitle("");
      setBody("");
      setReviewing(false);
      setNotice(
        "System message submitted for delivery to all registered users. Check its publication status below.",
      );
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : "Unable to confirm sending. Check message history before retrying.",
      );
      setReviewing(false);
    } finally {
      sending.current = false;
      setBusy(false);
      router.refresh();
    }
  }
  return (
    <>
      <div className="admin-grid">
        <section className="admin-panel">
          <h2>Send a system message</h2>
          <p>
            Every registered user receives it in their Inbox. Optional push
            notifications respect each user’s notification settings.
          </p>
          <form
            className="admin-message-form"
            onChange={() => setReviewing(false)}
            onSubmit={(e) => {
              e.preventDefault();
              setError("");
              setNotice("");
              setReviewing(true);
            }}
          >
            <fieldset disabled={busy}>
              <label>
                Title
                <input
                  required
                  maxLength={160}
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                />
              </label>
              <label>
                Message
                <textarea
                  required
                  maxLength={500}
                  rows={5}
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                />
              </label>
              <small>{body.length}/500 characters</small>
              <label>
                Importance
                <select
                  value={severity}
                  onChange={(e) => setSeverity(e.target.value)}
                >
                  <option value="INFO">Information</option>
                  <option value="IMPORTANT">Important</option>
                  <option value="CRITICAL">Critical</option>
                </select>
              </label>
              <label className="admin-message-check">
                <input
                  type="checkbox"
                  checked={pushEnabled}
                  onChange={(e) => setPushEnabled(e.target.checked)}
                />{" "}
                Also send a push notification
              </label>
              <button
                className="admin-button"
                type="submit"
                disabled={!title.trim() || !body.trim() || busy}
              >
                Review message
              </button>
            </fieldset>
          </form>
        </section>
        <section className="admin-panel">
          <h2>Preview &amp; confirm</h2>
          {reviewing ? (
            <>
              <p>
                <strong>{title.trim()}</strong>
              </p>
              <p className="admin-message-body">{body.trim()}</p>
              <p>
                Audience: all registered users
                <br />
                Importance: {severity.toLowerCase()}
                <br />
                Push notification: {pushEnabled ? "Enabled" : "Off"}
              </p>
              <button className="admin-button" onClick={send} disabled={busy}>
                {busy ? "Sending…" : "Send to all users"}
              </button>
            </>
          ) : (
            <p>
              Review your message to see exactly what users will receive before
              sending it.
            </p>
          )}
          {notice && <p role="status">{notice}</p>}
          {error && (
            <p role="alert" className="admin-message-error">
              {error}
            </p>
          )}
        </section>
      </div>
      <section className="admin-panel admin-message-history">
        <div className="admin-panel-heading">
          <h2>Recent system messages</h2>
          <button className="admin-button" onClick={() => router.refresh()}>
            Refresh
          </button>
        </div>
        <p>
          Latest 25 messages. Published means Inbox delivery completed; it does
          not mean users have read the message.
        </p>
        <div className="admin-table-wrap">
          <table>
            <thead>
              <tr>
                <th>Message</th>
                <th>Audience</th>
                <th>Status</th>
                <th>Published (UTC)</th>
              </tr>
            </thead>
            <tbody>
              {messages.map((message) => (
                <tr key={message.id}>
                  <td>
                    <strong>{message.title}</strong>
                    <small className="admin-message-body">{message.body}</small>
                  </td>
                  <td>
                    {message.platform ||
                    message.minAppVersion ||
                    message.maxAppVersion
                      ? "Targeted users"
                      : "All users"}
                  </td>
                  <td>
                    {message.publishedAt
                      ? "Published"
                      : message.expiresAt &&
                          new Date(message.expiresAt) <= new Date()
                        ? "Expired"
                        : new Date(message.publishAt) > new Date()
                          ? "Scheduled"
                          : "Queued"}
                  </td>
                  <td>
                    {message.publishedAt
                      ? new Date(message.publishedAt)
                          .toISOString()
                          .replace("T", " ")
                          .slice(0, 19)
                      : "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!messages.length && <p>No system messages yet.</p>}
        </div>
      </section>
    </>
  );
}

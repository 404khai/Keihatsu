import Link from "next/link";
import { notFound } from "next/navigation";
import { apiFetch, requireAdmin } from "@/lib/admin/server";
import type { Analytics } from "@/lib/admin/types";
import { GrowthChart, PlatformChart, ExportReport } from "../charts";
const labels: Record<string, string> = {
  readers: "Readers",
  catalogue: "Catalogue",
  extensions: "Extensions",
  community: "Community",
  reports: "Reports",
  team: "Team & access",
  settings: "Settings",
};
const number = (n: number) => n.toLocaleString("en-US");
export default async function AdminPage({
  params,
}: {
  params: Promise<{ section?: string[] }>;
}) {
  const { section = [] } = await params;
  if (section.length > 1 || (section[0] && !labels[section[0]])) notFound();
  const slug = section[0] || "";
  const { user, token } = await requireAdmin();
  const response = await apiFetch("admin/analytics", token);
  if (response.status === 401 || response.status === 403) {
    const { redirect } = await import("next/navigation");
    redirect("/admin/login");
  }
  if (!response.ok) throw new Error("Analytics are temporarily unavailable");
  const data: Analytics = await response.json();
  const title = labels[slug] || "Overview";
  const cards = [
    ["Total users", data.totalUsers, "All registered accounts"],
    ["Active readers", data.activeReaders, "Read in the last 30 days"],
    ["New users", data.newUsers, "Registered in the last 30 days"],
    ["Chapters in history", data.history, "Current, non-deleted entries"],
  ] as const;
  return (
    <>
      <header className="admin-topbar">
        <span>
          Workspace <i>/</i> <strong>{title}</strong>
        </span>
        <Link href="/">Visit website ↗</Link>
      </header>
      <div className="admin-heading">
        <div>
          <h1>{slug ? title : "Your platform, at a glance."}</h1>
          <p>
            Welcome back, {user.username}. Here’s what’s happening across
            Keihatsu.
          </p>
        </div>
        <ExportReport data={data} />
      </div>
      {!slug && (
        <>
          <div className="admin-metrics">
            {cards.map(([label, value, detail]) => (
              <article key={label}>
                <p>{label}</p>
                <strong>{number(value)}</strong>
                <small>{detail}</small>
              </article>
            ))}
          </div>
          <div className="admin-grid">
            <section className="admin-panel">
              <h2>User growth</h2>
              <p>Total registered users · Monthly snapshots in UTC</p>
              <GrowthChart data={data.growth} />
            </section>
            <section className="admin-panel">
              <h2>Devices by platform</h2>
              <p>Enabled push devices · A reader may have multiple devices</p>
              <PlatformChart data={data.platforms} />
            </section>
          </div>
        </>
      )}
      {(!slug || slug === "readers" || slug === "team") && (
        <div className="admin-grid">
          <section className="admin-panel">
            <div className="admin-panel-heading">
              <h2>{slug === "team" ? "Account access" : "Recent signups"}</h2>
              {!slug && <Link href="/admin/readers">View readers ↗</Link>}
            </div>
            <div className="admin-table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Joined (UTC)</th>
                    <th>{slug === "team" ? "Role" : "Onboarding"}</th>
                  </tr>
                </thead>
                <tbody>
                  {data.recentSignups.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <strong>{u.username}</strong>
                        <small>{u.email}</small>
                      </td>
                      <td>
                        {new Date(u.createdAt).toISOString().slice(0, 10)}
                      </td>
                      <td>
                        {slug === "team"
                          ? u.role
                          : u.isOnboarded
                            ? "Completed"
                            : "Pending"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {!data.recentSignups.length && (
                <p>No readers have signed up yet.</p>
              )}
            </div>
          </section>
          <section className="admin-panel">
            <h2>{slug === "team" ? "Access policy" : "Acquisition sources"}</h2>
            <p>
              {slug === "team"
                ? "Only accounts with the ADMIN database role can enter this workspace. Role changes take effect on the next request. Use the existing API promotion tool to manage access."
                : "Acquisition attribution is not collected yet. No estimated or sample traffic data is shown."}
            </p>
          </section>
        </div>
      )}
      {slug === "catalogue" && (
        <section className="admin-panel">
          <h2>Reader libraries</h2>
          <div className="admin-big-number">{number(data.library)}</div>
          <p>
            Saved library entries across all accounts. Titles are supplied by
            external extensions; there is no central catalogue database.
          </p>
        </section>
      )}
      {slug === "community" && (
        <section className="admin-panel">
          <h2>Community activity</h2>
          <div className="admin-big-number">{number(data.comments)}</div>
          <p>Total comments and replies stored in the database.</p>
        </section>
      )}
      {(slug === "extensions" || slug === "reports") && (
        <section className="admin-panel">
          <h2>
            {slug === "reports" ? "Source health reports" : "Extension health"}
          </h2>
          <p>
            Recorded by the chapter update monitor. Missing records mean the
            source has not been checked.
          </p>
          <div className="admin-table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Source</th>
                  <th>Failures</th>
                  <th>Last success (UTC)</th>
                  <th>Last failure (UTC)</th>
                </tr>
              </thead>
              <tbody>
                {data.sources.map((s) => (
                  <tr key={s.sourceId}>
                    <td>{s.sourceId}</td>
                    <td>{s.failureCount}</td>
                    <td>{s.lastSuccessAt || "Not recorded"}</td>
                    <td>{s.lastFailureAt || "Not recorded"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!data.sources.length && <p>No source health records yet.</p>}
          </div>
        </section>
      )}
      {slug === "settings" && (
        <section className="admin-panel">
          <h2>Your session</h2>
          <p>
            Signed in as {user.email}. Google sign-in and administrator access
            are managed by the API.
          </p>
          <form action="/api/admin/logout" method="post">
            <button className="admin-button">Sign out</button>
          </form>
        </section>
      )}
      <footer className="admin-footer">
        All times in UTC · Updated {new Date(data.generatedAt).toISOString()}
        <span>Keihatsu admin · Live database metrics</span>
      </footer>
    </>
  );
}

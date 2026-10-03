"use client";
import { ResponsiveLine } from "@nivo/line";
import { ResponsivePie } from "@nivo/pie";
import type { Analytics } from "@/lib/admin/types";
const theme = {
  text: { fill: "#a4a4a4", fontSize: 11 },
  axis: { ticks: { text: { fill: "#999" }, line: { stroke: "#333" } } },
  grid: { line: { stroke: "#292929", strokeDasharray: "3 5" } },
  tooltip: { container: { background: "#222", color: "#fff", fontSize: 12 } },
};
export function GrowthChart({ data }: { data: Analytics["growth"] }) {
  return (
    <div
      className="admin-chart"
      role="img"
      aria-label={data
        .map((d) => `${d.date.slice(0, 10)}: ${d.users} users`)
        .join(", ")}
    >
      <ResponsiveLine
        data={[
          {
            id: "Total users",
            data: data.map((d) => ({ x: d.date.slice(0, 10), y: d.users })),
          },
        ]}
        margin={{ top: 20, right: 20, bottom: 40, left: 50 }}
        xScale={{ type: "point" }}
        yScale={{ type: "linear", min: 0, max: "auto" }}
        axisBottom={{
          format: (v) =>
            new Date(String(v)).toLocaleDateString("en-US", {
              month: "short",
              timeZone: "UTC",
            }),
        }}
        axisLeft={{
          format: (v) => (Number.isInteger(Number(v)) ? String(v) : ""),
        }}
        colors={["#f4cb00"]}
        theme={theme}
        enableGridX={false}
        enableArea
        areaOpacity={0.08}
        pointSize={6}
        pointColor="#111"
        pointBorderWidth={2}
        pointBorderColor="#f4cb00"
        useMesh
        animate={false}
      />
    </div>
  );
}
export function PlatformChart({ data }: { data: Analytics["platforms"] }) {
  const total = data.reduce((n, p) => n + p.devices, 0);
  return total ? (
    <div className="admin-platform">
      <div className="admin-pie">
        <ResponsivePie
          data={data.map((p) => ({ id: p.platform, value: p.devices }))}
          colors={["#f4cb00", "#ddd", "#777"]}
          theme={theme}
          borderWidth={2}
          borderColor="#111"
          enableArcLabels={false}
          enableArcLinkLabels={false}
          animate={false}
        />
      </div>
      <div>
        {data.map((p) => (
          <p key={p.platform}>
            {p.platform} · {Math.round((p.devices / total) * 100)}%
            <small>{p.devices} devices</small>
          </p>
        ))}
      </div>
    </div>
  ) : (
    <p>No enabled push devices yet.</p>
  );
}
export function ExportReport({ data }: { data: Analytics }) {
  return (
    <button
      className="admin-button"
      onClick={() => {
        const rows = [
          ["Metric", "Value"],
          ["Generated at", data.generatedAt],
          ...(
            [
              "totalUsers",
              "activeReaders",
              "newUsers",
              "comments",
              "library",
              "history",
            ] as const
          ).map((k) => [k, data[k]]),
        ];
        const url = URL.createObjectURL(
          new Blob([rows.map((r) => r.join(",")).join("\n")], {
            type: "text/csv",
          }),
        );
        const a = document.createElement("a");
        a.href = url;
        a.download = "keihatsu-admin-report.csv";
        a.click();
        URL.revokeObjectURL(url);
      }}
    >
      ↓ Export report
    </button>
  );
}

import { NextResponse } from "next/server";
import { adminSession, apiFetch, sameOrigin } from "@/lib/admin/server";

export async function POST(request: Request) {
  if (!sameOrigin(request))
    return NextResponse.json(
      { error: "Invalid request origin" },
      { status: 403 },
    );
  const session = await adminSession();
  if (!session)
    return NextResponse.json(
      { error: "Administrator sign-in required" },
      { status: 401 },
    );
  let input;
  try {
    input = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid message" }, { status: 400 });
  }
  if (
    !input ||
    typeof input.title !== "string" ||
    !input.title.trim() ||
    input.title.length > 160 ||
    typeof input.body !== "string" ||
    !input.body.trim() ||
    input.body.length > 500 ||
    !["INFO", "IMPORTANT", "CRITICAL"].includes(input.severity) ||
    typeof input.pushEnabled !== "boolean"
  ) {
    return NextResponse.json(
      { error: "Enter a title, message and valid importance level." },
      { status: 400 },
    );
  }
  try {
    const response = await apiFetch("admin/announcements", session.token, {
      method: "POST",
      body: JSON.stringify({
        title: input.title.trim(),
        body: input.body.trim(),
        severity: input.severity,
        pushEnabled: input.pushEnabled,
        publishAt: new Date().toISOString(),
      }),
    });
    if (!response.ok)
      return NextResponse.json(
        {
          error:
            response.status === 429
              ? "Please wait a minute before sending another message."
              : "Unable to confirm sending. Check message history before retrying.",
        },
        { status: response.status },
      );
    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json(
      {
        error:
          "Unable to confirm sending. Check message history before retrying.",
      },
      { status: 502 },
    );
  }
}

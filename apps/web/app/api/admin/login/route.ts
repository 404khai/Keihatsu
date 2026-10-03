import { NextResponse } from "next/server";
import { apiFetch, sameOrigin, SESSION_COOKIE } from "@/lib/admin/server";
export async function POST(request: Request) {
  if (!sameOrigin(request))
    return NextResponse.json({ error: "Invalid origin" }, { status: 403 });
  try {
    const { credential } = await request.json();
    if (typeof credential !== "string" || credential.length > 10000)
      return NextResponse.json(
        { error: "Invalid credential" },
        { status: 400 },
      );
    const response = await apiFetch("auth/google", undefined, {
      method: "POST",
      body: JSON.stringify({ token: credential }),
    });
    if (!response.ok)
      return NextResponse.json(
        { error: "Google sign-in failed. Please try again." },
        { status: 401 },
      );
    const session = await response.json();
    if (session.user?.role !== "ADMIN")
      return NextResponse.json(
        { error: "This account does not have administrator access." },
        { status: 403 },
      );
    const result = NextResponse.json({ ok: true });
    result.cookies.set(SESSION_COOKIE, session.accessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 8,
    });
    return result;
  } catch {
    return NextResponse.json(
      { error: "Sign-in is temporarily unavailable." },
      { status: 503 },
    );
  }
}

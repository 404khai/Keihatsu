import "server-only";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export const SESSION_COOKIE = "keihatsu_admin";
export type AdminUser = {
  id: string;
  username: string;
  email: string;
  role: string;
};
export async function apiFetch(
  path: string,
  token?: string,
  init?: RequestInit,
) {
  const origin = process.env.API_URL;
  if (!origin) throw new Error("API_URL is not configured");
  return fetch(`${origin.replace(/\/$/, "")}/${path}`, {
    ...init,
    cache: "no-store",
    signal: AbortSignal.timeout(15000),
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  });
}
export async function adminSession() {
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!token) return null;
  const response = await apiFetch("auth/me", token);
  if (!response.ok) {
    if (response.status === 401 || response.status === 403) return null;
    throw new Error("Unable to verify admin session");
  }
  const user: AdminUser = await response.json();
  return user.role === "ADMIN" ? { user, token } : null;
}
export async function requireAdmin() {
  const session = await adminSession();
  if (!session) redirect("/admin/login");
  return session;
}
export function sameOrigin(request: Request) {
  return request.headers.get("origin") === new URL(request.url).origin;
}

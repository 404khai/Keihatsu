import Image from "next/image";
import { redirect } from "next/navigation";
import { adminSession, apiFetch } from "@/lib/admin/server";
import { GoogleSignIn } from "./sign-in";
export default async function LoginPage() {
  if (await adminSession()) redirect("/admin");
  let clientId =
    process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID_WEB ||
    process.env.GOOGLE_CLIENT_ID_WEB ||
    "";
  if (!clientId) {
    try {
      const response = await apiFetch("auth/google/client");
      if (response.ok) clientId = (await response.json()).clientId || "";
    } catch {
      /* The button explains unavailable configuration without breaking login. */
    }
  }
  return (
    <main className="admin-login">
      <a className="admin-brand" href="/">
        <Image src="/logo.png" alt="" width={32} height={32} priority />{" "}
        keihatsu.
      </a>
      <section>
        <span className="admin-eyebrow">ADMIN WORKSPACE</span>
        <h1>
          A little control.
          <br />A bigger picture.
        </h1>
        <p>Sign in to see what’s happening across Keihatsu.</p>
        <GoogleSignIn clientId={clientId} />
        <small>Any account with the administrator role can sign in.</small>
      </section>
      <footer>Keihatsu · Built for readers.</footer>
    </main>
  );
}

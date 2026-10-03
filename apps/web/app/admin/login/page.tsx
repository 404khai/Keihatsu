import Image from "next/image";
import { redirect } from "next/navigation";
import { adminSession } from "@/lib/admin/server";
import { GoogleSignIn } from "./sign-in";
export default async function LoginPage() {
  if (await adminSession()) redirect("/admin");
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
        <GoogleSignIn
          clientId={process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID_WEB || ""}
        />
        <small>Access is limited to approved administrators.</small>
      </section>
      <footer>Keihatsu · Built for readers.</footer>
    </main>
  );
}

import Image from "next/image";
import Link from "next/link";
import { requireAdmin } from "@/lib/admin/server";
import { AdminNav } from "./nav";
export default async function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user } = await requireAdmin();
  return (
    <div className="admin-shell">
      <aside>
        <Link className="admin-brand" href="/admin">
          <Image src="/logo.png" alt="" width={32} height={32} priority />{" "}
          keihatsu.
        </Link>
        <div className="admin-workspace">
          Keihatsu workspace<small>Administrator workspace</small>
        </div>
        <AdminNav />
        <div className="admin-account">
          <strong>{user.username}</strong>
          <small>Administrator</small>
          <form action="/api/admin/logout" method="post">
            <button>Sign out</button>
          </form>
        </div>
      </aside>
      <main>{children}</main>
    </div>
  );
}

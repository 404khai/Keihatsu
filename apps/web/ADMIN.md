# Admin workspace

Run the API on port 3000 and the web app on port 3001 (`npm run dev -- --port 3001`). Copy `.env.example` to `.env.local`. Set API_URL to the server-only API origin. NEXT_PUBLIC_GOOGLE_CLIENT_ID_WEB must match the API GOOGLE_CLIENT_ID_WEB. Add the web origin to the Google OAuth client's authorized JavaScript origins. Production requires HTTPS.

Google Identity Services exchanges its ID token with the existing API. Only ADMIN accounts receive a web session. Use apps/api/promote-user.ts to grant access. Tokens stay in an HttpOnly, SameSite cookie; every protected render revalidates the database role. Login and logout require same-origin POSTs. The API independently protects analytics with JWT and role guards.

Routes: /admin/login, /admin, /admin/readers, /admin/catalogue, /admin/extensions, /admin/community, /admin/reports, /admin/team, /admin/settings. Session endpoints: POST /api/admin/login and POST /api/admin/logout. API metrics: GET /admin/analytics.

Counts and monthly growth come from Prisma. Active readers are distinct users with non-deleted history updated in the last 30 days. Platforms count enabled push devices, not people. Recent signups show the latest 20 accounts. Reports show stored source-health checks. Acquisition and retention are not instrumented and are not fabricated. Catalogue/community expose aggregate counts; team access uses the API CLI.

Design: Paper “Keihatsu — Admin Dashboard”, “Keihatsu Website”.

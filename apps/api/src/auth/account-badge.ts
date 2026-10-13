// Cosmetic badges come from authenticated database identity, never usernames.
// Being an admin alone does not identify the app's developer.
export function accountBadge(user: { email?: string; role?: string }): string | null {
  const email = user.email?.trim().toLowerCase();
  if (email === '404khai@gmail.com' && user.role === 'ADMIN') return 'developer';
  if (email === 'dexgamingacct@gmail.com') return 'android_beta_tester';
  return null;
}
